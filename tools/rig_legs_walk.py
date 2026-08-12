"""Add a skeleton and in-place walk cycle to the police legs GLB.

The source file is a static mesh (no bones). This script places hip / knee /
ankle bones from the mesh shape, paints skin weights, and bakes a looping
walk animation using two-bone IK (the computer aims each foot at a target,
then bends the knee to reach it).
"""
from __future__ import annotations

import argparse
import json
import math
import struct
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_INPUT = ROOT / "assets" / "characters" / "policial" / "3d" / "policial-legs-3d.glb"
DEFAULT_OUTPUT = ROOT / "assets" / "characters" / "policial" / "3d" / "policial-legs-3d-walk.glb"

CYCLE_SEC = 0.85
FRAME_COUNT = 32
STEP_LENGTH = 0.20
STEP_HEIGHT = 0.068
DUTY = 0.62
HIP_BOB = 0.016
HIP_SWAY = 0.010
HIP_YAW = 0.07
HIP_ROLL = 0.05
HIP_PITCH = 0.04

JOINT_NAMES = [
	"Hips",
	"Thigh_L",
	"Calf_L",
	"Foot_L",
	"Thigh_R",
	"Calf_R",
	"Foot_R",
]


def _pad4(data: bytes, pad: bytes) -> bytes:
	extra = (4 - (len(data) % 4)) % 4
	return data + pad * extra


def _minmax(arr: np.ndarray) -> tuple[list, list]:
	flat_min = arr.min(axis=0)
	flat_max = arr.max(axis=0)
	if arr.ndim == 1:
		return [float(flat_min)], [float(flat_max)]
	return [float(x) for x in flat_min], [float(x) for x in flat_max]


def _read_glb(path: Path) -> tuple[dict, bytes]:
	raw = path.read_bytes()
	magic, version, length = struct.unpack_from("<III", raw, 0)
	if magic != 0x46546C67:
		raise ValueError("Not a GLB file: %s" % path)
	offset = 12
	doc = None
	bin_data = b""
	while offset + 8 <= length:
		chunk_len, chunk_type = struct.unpack_from("<II", raw, offset)
		offset += 8
		chunk = raw[offset : offset + chunk_len]
		offset += chunk_len
		if chunk_type == 0x4E4F534A:
			doc = json.loads(chunk)
		elif chunk_type == 0x004E4942:
			bin_data = chunk
	if doc is None:
		raise ValueError("GLB has no JSON chunk")
	return doc, bin_data


def _accessor_numpy(doc: dict, bin_data: bytes, index: int) -> np.ndarray:
	acc = doc["accessors"][index]
	view = doc["bufferViews"][acc["bufferView"]]
	start = view.get("byteOffset", 0) + acc.get("byteOffset", 0)
	count = acc["count"]
	comp = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4}[acc["type"]]
	fmt, width = {5121: ("B", 1), 5123: ("H", 2), 5125: ("I", 4), 5126: ("f", 4)}[
		acc["componentType"]
	]
	stride = view.get("byteStride", comp * width)
	out = np.empty((count, comp), dtype=np.float64 if fmt == "f" else np.int64)
	for i in range(count):
		vals = struct.unpack_from("<" + fmt * comp, bin_data, start + i * stride)
		out[i] = vals
	if comp == 1:
		return out.reshape(-1)
	return out


def _quat_mul(a: np.ndarray, b: np.ndarray) -> np.ndarray:
	ax, ay, az, aw = a
	bx, by, bz, bw = b
	return np.array(
		[
			aw * bx + ax * bw + ay * bz - az * by,
			aw * by - ax * bz + ay * bw + az * bx,
			aw * bz + ax * by - ay * bx + az * bw,
			aw * bw - ax * bx - ay * by - az * bz,
		],
		dtype=np.float64,
	)


def _quat_conj(q: np.ndarray) -> np.ndarray:
	return np.array([-q[0], -q[1], -q[2], q[3]], dtype=np.float64)


def _quat_norm(q: np.ndarray) -> np.ndarray:
	n = math.sqrt(float(np.dot(q, q)))
	if n < 1e-12:
		return np.array([0.0, 0.0, 0.0, 1.0])
	return q / n


def _quat_from_axis_angle(axis: np.ndarray, angle: float) -> np.ndarray:
	n = np.linalg.norm(axis)
	if n < 1e-12 or abs(angle) < 1e-12:
		return np.array([0.0, 0.0, 0.0, 1.0])
	axis = axis / n
	s = math.sin(angle * 0.5)
	return _quat_norm(np.array([axis[0] * s, axis[1] * s, axis[2] * s, math.cos(angle * 0.5)]))


def _quat_from_matrix(m: np.ndarray) -> np.ndarray:
	t = float(m[0, 0] + m[1, 1] + m[2, 2])
	if t > 0.0:
		s = math.sqrt(t + 1.0) * 2.0
		q = np.array(
			[
				(m[2, 1] - m[1, 2]) / s,
				(m[0, 2] - m[2, 0]) / s,
				(m[1, 0] - m[0, 1]) / s,
				0.25 * s,
			]
		)
	elif m[0, 0] > m[1, 1] and m[0, 0] > m[2, 2]:
		s = math.sqrt(1.0 + m[0, 0] - m[1, 1] - m[2, 2]) * 2.0
		q = np.array(
			[
				0.25 * s,
				(m[0, 1] + m[1, 0]) / s,
				(m[0, 2] + m[2, 0]) / s,
				(m[2, 1] - m[1, 2]) / s,
			]
		)
	elif m[1, 1] > m[2, 2]:
		s = math.sqrt(1.0 + m[1, 1] - m[0, 0] - m[2, 2]) * 2.0
		q = np.array(
			[
				(m[0, 1] + m[1, 0]) / s,
				0.25 * s,
				(m[1, 2] + m[2, 1]) / s,
				(m[0, 2] - m[2, 0]) / s,
			]
		)
	else:
		s = math.sqrt(1.0 + m[2, 2] - m[0, 0] - m[1, 1]) * 2.0
		q = np.array(
			[
				(m[0, 2] + m[2, 0]) / s,
				(m[1, 2] + m[2, 1]) / s,
				0.25 * s,
				(m[1, 0] - m[0, 1]) / s,
			]
		)
	return _quat_norm(q)


def _quat_rotate(q: np.ndarray, v: np.ndarray) -> np.ndarray:
	qv = np.array([v[0], v[1], v[2], 0.0])
	out = _quat_mul(_quat_mul(q, qv), _quat_conj(q))
	return out[:3]


def _bone_quat(origin: np.ndarray, child: np.ndarray, pole: np.ndarray) -> np.ndarray:
	"""World rotation whose local -Y points toward child (bind bones go down)."""
	to_child = child - origin
	length = np.linalg.norm(to_child)
	if length < 1e-8:
		return np.array([0.0, 0.0, 0.0, 1.0])
	y_axis = -to_child / length
	z = pole - origin
	z = z - y_axis * float(np.dot(z, y_axis))
	if np.linalg.norm(z) < 1e-6:
		z = np.array([0.0, 0.0, 1.0])
		z = z - y_axis * float(np.dot(z, y_axis))
	if np.linalg.norm(z) < 1e-6:
		z = np.array([1.0, 0.0, 0.0])
		z = z - y_axis * float(np.dot(z, y_axis))
	z = z / np.linalg.norm(z)
	x = np.cross(y_axis, z)
	x = x / (np.linalg.norm(x) + 1e-8)
	z = np.cross(x, y_axis)
	z = z / (np.linalg.norm(z) + 1e-8)
	return _quat_from_matrix(np.column_stack((x, y_axis, z)))


def _two_bone_ik(
	hip: np.ndarray,
	foot: np.ndarray,
	thigh_len: float,
	calf_len: float,
	pole: np.ndarray,
) -> np.ndarray:
	delta = foot - hip
	dist = float(np.linalg.norm(delta))
	max_reach = (thigh_len + calf_len) * 0.985
	min_reach = abs(thigh_len - calf_len) + 0.012
	dist = max(min_reach, min(max_reach, dist))
	direction = delta / (float(np.linalg.norm(delta)) + 1e-8)
	pole_dir = pole - hip
	pole_dir = pole_dir - direction * float(np.dot(pole_dir, direction))
	if np.linalg.norm(pole_dir) < 1e-6:
		pole_dir = np.array([0.0, 0.0, 1.0])
		pole_dir = pole_dir - direction * float(np.dot(pole_dir, direction))
	pole_dir = pole_dir / (np.linalg.norm(pole_dir) + 1e-8)
	x = (dist * dist + thigh_len * thigh_len - calf_len * calf_len) / (2.0 * dist)
	h_sq = max(thigh_len * thigh_len - x * x, 0.0)
	return hip + direction * x + pole_dir * math.sqrt(h_sq)


def _segment_distance(points: np.ndarray, a: np.ndarray, b: np.ndarray) -> np.ndarray:
	ab = b - a
	denom = float(np.dot(ab, ab)) + 1e-8
	t = np.clip((points - a) @ ab / denom, 0.0, 1.0)
	proj = a + t[:, None] * ab
	return np.linalg.norm(points - proj, axis=1)


def _envelope(dist: np.ndarray, radius: float) -> np.ndarray:
	w = np.clip(1.0 - dist / radius, 0.0, 1.0)
	return w * w


def _compute_normals(positions: np.ndarray, indices: np.ndarray) -> np.ndarray:
	normals = np.zeros_like(positions, dtype=np.float64)
	p0 = positions[indices[0::3]]
	p1 = positions[indices[1::3]]
	p2 = positions[indices[2::3]]
	face = np.cross(p1 - p0, p2 - p0)
	np.add.at(normals, indices[0::3], face)
	np.add.at(normals, indices[1::3], face)
	np.add.at(normals, indices[2::3], face)
	lens = np.linalg.norm(normals, axis=1, keepdims=True)
	lens = np.maximum(lens, 1e-8)
	return (normals / lens).astype(np.float32)


def _smoothstep(edge0: float, edge1: float, x: np.ndarray) -> np.ndarray:
	t = np.clip((x - edge0) / (edge1 - edge0), 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)


def _paint_weights(positions: np.ndarray, bones: dict[str, np.ndarray]) -> tuple[np.ndarray, np.ndarray]:
	hips = bones["Hips"]
	thigh_l, calf_l, foot_l = bones["Thigh_L"], bones["Calf_L"], bones["Foot_L"]
	thigh_r, calf_r, foot_r = bones["Thigh_R"], bones["Calf_R"], bones["Foot_R"]
	toe_l = foot_l + np.array([0.0, -0.02, 0.16])
	toe_r = foot_r + np.array([0.0, -0.02, 0.16])
	pelvis_top = hips + np.array([0.0, 0.22, 0.0])

	x = positions[:, 0]
	left_mask = 1.0 - _smoothstep(-0.04, 0.04, x)
	right_mask = _smoothstep(-0.04, 0.04, x)

	w = np.zeros((len(positions), 7), dtype=np.float64)
	w[:, 0] = _envelope(_segment_distance(positions, hips, pelvis_top), 0.32)
	w[:, 0] += _envelope(np.linalg.norm(positions - hips, axis=1), 0.22) * 0.65
	# Keep the waist on the hip bone even at the sides.
	high = _smoothstep(0.12, 0.28, positions[:, 1])
	w[:, 0] += high * 0.85

	w[:, 1] = _envelope(_segment_distance(positions, thigh_l, calf_l), 0.17) * left_mask
	w[:, 2] = _envelope(_segment_distance(positions, calf_l, foot_l), 0.14) * left_mask
	w[:, 3] = _envelope(_segment_distance(positions, foot_l, toe_l), 0.13) * left_mask
	w[:, 4] = _envelope(_segment_distance(positions, thigh_r, calf_r), 0.17) * right_mask
	w[:, 5] = _envelope(_segment_distance(positions, calf_r, foot_r), 0.14) * right_mask
	w[:, 6] = _envelope(_segment_distance(positions, foot_r, toe_r), 0.13) * right_mask

	# Feet must not be pulled by the opposite leg.
	low = 1.0 - _smoothstep(-0.28, -0.12, positions[:, 1])
	w[:, 3] += low * left_mask * 0.9
	w[:, 6] += low * right_mask * 0.9
	w[:, 1] *= 1.0 - 0.75 * low * left_mask
	w[:, 4] *= 1.0 - 0.75 * low * right_mask

	row_sum = w.sum(axis=1, keepdims=True)
	row_sum = np.maximum(row_sum, 1e-8)
	w = w / row_sum

	order = np.argsort(w, axis=1)[:, ::-1][:, :4]
	top_w = np.take_along_axis(w, order, axis=1)
	top_w = np.where(top_w < 0.02, 0.0, top_w)
	norm = np.maximum(top_w.sum(axis=1, keepdims=True), 1e-8)
	top_w = top_w / norm
	return order.astype(np.uint8), top_w.astype(np.float32)


def _foot_target(phase: float, side_x: float, ankle_y: float, ankle_z: float) -> tuple[np.ndarray, float]:
	phase = phase % 1.0
	if phase < DUTY:
		t = phase / DUTY
		z = (0.5 - t) * STEP_LENGTH + ankle_z
		y = ankle_y
		if t < 0.18:
			pitch = 0.22 * (1.0 - t / 0.18)
		elif t > 0.78:
			pitch = -0.32 * ((t - 0.78) / 0.22)
		else:
			pitch = 0.0
	else:
		t = (phase - DUTY) / (1.0 - DUTY)
		ease = t * t * (3.0 - 2.0 * t)
		z = (-0.5 + ease) * STEP_LENGTH + ankle_z
		y = ankle_y + STEP_HEIGHT * math.sin(math.pi * t)
		pitch = 0.38 * math.sin(math.pi * t)
	return np.array([side_x, y, z], dtype=np.float64), pitch


def _euler_xyz(pitch: float, yaw: float, roll: float) -> np.ndarray:
	qx = _quat_from_axis_angle(np.array([1.0, 0.0, 0.0]), pitch)
	qy = _quat_from_axis_angle(np.array([0.0, 1.0, 0.0]), yaw)
	qz = _quat_from_axis_angle(np.array([0.0, 0.0, 1.0]), roll)
	return _quat_norm(_quat_mul(qy, _quat_mul(qx, qz)))


def _local_from_world(parent_world: np.ndarray, world: np.ndarray) -> np.ndarray:
	return _quat_norm(_quat_mul(_quat_conj(parent_world), world))


def _bind_bones() -> dict[str, np.ndarray]:
	# Landmarks taken from the police-legs mesh (Y up, character faces +Z).
	return {
		"Hips": np.array([0.0, 0.22, -0.01]),
		"Thigh_L": np.array([-0.20, 0.15, -0.03]),
		"Calf_L": np.array([-0.205, -0.12, -0.02]),
		"Foot_L": np.array([-0.23, -0.40, 0.03]),
		"Thigh_R": np.array([0.22, 0.15, -0.02]),
		"Calf_R": np.array([0.23, -0.12, -0.02]),
		"Foot_R": np.array([0.25, -0.40, 0.035]),
	}


def _local_translation(parent: np.ndarray, child: np.ndarray) -> list[float]:
	d = child - parent
	return [float(d[0]), float(d[1]), float(d[2])]


def _inverse_bind(world_pos: np.ndarray) -> np.ndarray:
	m = np.eye(4, dtype=np.float32)
	m[0, 3] = -float(world_pos[0])
	m[1, 3] = -float(world_pos[1])
	m[2, 3] = -float(world_pos[2])
	return m.T.reshape(-1)  # glTF column-major


def _bake_walk(bones: dict[str, np.ndarray]) -> dict[str, np.ndarray]:
	thigh_len_l = float(np.linalg.norm(bones["Calf_L"] - bones["Thigh_L"]))
	calf_len_l = float(np.linalg.norm(bones["Foot_L"] - bones["Calf_L"]))
	thigh_len_r = float(np.linalg.norm(bones["Calf_R"] - bones["Thigh_R"]))
	calf_len_r = float(np.linalg.norm(bones["Foot_R"] - bones["Calf_R"]))
	times = np.linspace(0.0, CYCLE_SEC, FRAME_COUNT, endpoint=False, dtype=np.float32)
	# Repeat first pose at the end so LINEAR interpolation loops cleanly.
	times_out = np.concatenate([times, np.array([CYCLE_SEC], dtype=np.float32)])

	hip_t = []
	rot = {name: [] for name in JOINT_NAMES}

	for i, t in enumerate(list(times) + [CYCLE_SEC]):
		u = 0.0 if i == FRAME_COUNT else float(t) / CYCLE_SEC
		bob = HIP_BOB * (0.5 - 0.5 * math.cos(4.0 * math.pi * u))
		sway = HIP_SWAY * math.sin(2.0 * math.pi * u)
		yaw = HIP_YAW * math.sin(2.0 * math.pi * u)
		roll = HIP_ROLL * math.sin(2.0 * math.pi * u)
		hips_q = _euler_xyz(HIP_PITCH, yaw, roll)
		hips_p = bones["Hips"] + np.array([sway, bob, 0.0])
		hip_t.append(hips_p.astype(np.float32))
		rot["Hips"].append(hips_q.astype(np.float32))

		def leg(side: str, phase: float, thigh_len: float, calf_len: float) -> None:
			bind_hip = bones["Thigh_%s" % side]
			bind_foot = bones["Foot_%s" % side]
			offset = bind_hip - bones["Hips"]
			hip_joint = hips_p + _quat_rotate(hips_q, offset)
			foot, pitch = _foot_target(phase, float(bind_foot[0]), float(bind_foot[1]), float(bind_foot[2]))
			pole = hip_joint + np.array([0.0, 0.0, 0.45])
			knee = _two_bone_ik(hip_joint, foot, thigh_len, calf_len, pole)
			thigh_q = _bone_quat(hip_joint, knee, pole)
			calf_q = _bone_quat(knee, foot, pole)
			foot_q = _quat_norm(_quat_mul(calf_q, _quat_from_axis_angle(np.array([1.0, 0.0, 0.0]), pitch)))
			rot["Thigh_%s" % side].append(_local_from_world(hips_q, thigh_q).astype(np.float32))
			rot["Calf_%s" % side].append(_local_from_world(thigh_q, calf_q).astype(np.float32))
			rot["Foot_%s" % side].append(_local_from_world(calf_q, foot_q).astype(np.float32))

		leg("L", u, thigh_len_l, calf_len_l)
		leg("R", u + 0.5, thigh_len_r, calf_len_r)

	return {
		"times": times_out,
		"hips_t": np.stack(hip_t),
		**{"rot_%s" % name: np.stack(rot[name]) for name in JOINT_NAMES},
	}


def _write_glb(path: Path, doc: dict, blob: bytes) -> None:
	json_bytes = _pad4(json.dumps(doc, separators=(",", ":")).encode("utf-8"), b" ")
	bin_bytes = _pad4(blob, b"\x00")
	length = 12 + 8 + len(json_bytes) + 8 + len(bin_bytes)
	out = bytearray()
	out += struct.pack("<III", 0x46546C67, 2, length)
	out += struct.pack("<II", len(json_bytes), 0x4E4F534A)
	out += json_bytes
	out += struct.pack("<II", len(bin_bytes), 0x004E4942)
	out += bin_bytes
	path.parent.mkdir(parents=True, exist_ok=True)
	path.write_bytes(out)


def build(input_path: Path, output_path: Path) -> None:
	doc, bin_data = _read_glb(input_path)
	prim = doc["meshes"][0]["primitives"][0]
	positions = _accessor_numpy(doc, bin_data, prim["attributes"]["POSITION"]).astype(np.float32)
	uvs = _accessor_numpy(doc, bin_data, prim["attributes"]["TEXCOORD_0"]).astype(np.float32)
	indices = _accessor_numpy(doc, bin_data, prim["indices"]).astype(np.uint32)
	normals = _compute_normals(positions.astype(np.float64), indices)
	img_view = doc["bufferViews"][doc["images"][0]["bufferView"]]
	png = bin_data[img_view.get("byteOffset", 0) : img_view.get("byteOffset", 0) + img_view["byteLength"]]

	bones = _bind_bones()
	joints, weights = _paint_weights(positions.astype(np.float64), bones)
	anim = _bake_walk(bones)

	blob = bytearray()
	views: list[dict] = []
	accessors: list[dict] = []

	def add_view(data: bytes, target: int | None = None) -> int:
		if len(blob) % 4:
			blob.extend(b"\x00" * (4 - (len(blob) % 4)))
		view = {"buffer": 0, "byteOffset": len(blob), "byteLength": len(data)}
		if target is not None:
			view["target"] = target
		views.append(view)
		blob.extend(data)
		return len(views) - 1

	def add_accessor(array: np.ndarray, type_name: str, comp_type: int, target: int | None = None) -> int:
		data = array.tobytes()
		view = add_view(data, target)
		acc: dict = {
			"bufferView": view,
			"componentType": comp_type,
			"count": int(array.shape[0]),
			"type": type_name,
		}
		mn, mx = _minmax(array)
		acc["min"] = mn
		acc["max"] = mx
		accessors.append(acc)
		return len(accessors) - 1

	idx_acc = add_accessor(indices, "SCALAR", 5125, 34963)
	pos_acc = add_accessor(positions, "VEC3", 5126, 34962)
	nrm_acc = add_accessor(normals, "VEC3", 5126, 34962)
	uv_acc = add_accessor(uvs, "VEC2", 5126, 34962)
	jnt_acc = add_accessor(joints, "VEC4", 5121, 34962)
	wgt_acc = add_accessor(weights, "VEC4", 5126, 34962)

	ibm = np.stack([_inverse_bind(bones[name]) for name in JOINT_NAMES]).astype(np.float32)
	ibm_acc = add_accessor(ibm, "MAT4", 5126)

	time_acc = add_accessor(anim["times"], "SCALAR", 5126)
	hips_t_acc = add_accessor(anim["hips_t"], "VEC3", 5126)
	rot_acc = {name: add_accessor(anim["rot_%s" % name], "VEC4", 5126) for name in JOINT_NAMES}
	img_view_i = add_view(png)

	hips_t = _local_translation(np.zeros(3), bones["Hips"])
	nodes = [
		{"name": "Legs", "children": [1, 8]},
		{"name": "Hips", "translation": hips_t, "children": [2, 5]},
		{"name": "Thigh_L", "translation": _local_translation(bones["Hips"], bones["Thigh_L"]), "children": [3]},
		{"name": "Calf_L", "translation": _local_translation(bones["Thigh_L"], bones["Calf_L"]), "children": [4]},
		{"name": "Foot_L", "translation": _local_translation(bones["Calf_L"], bones["Foot_L"])},
		{"name": "Thigh_R", "translation": _local_translation(bones["Hips"], bones["Thigh_R"]), "children": [6]},
		{"name": "Calf_R", "translation": _local_translation(bones["Thigh_R"], bones["Calf_R"]), "children": [7]},
		{"name": "Foot_R", "translation": _local_translation(bones["Calf_R"], bones["Foot_R"])},
		{"name": "LegsMesh", "mesh": 0, "skin": 0},
	]

	channels = [
		{"sampler": 0, "target": {"node": 1, "path": "translation"}},
	]
	samplers = [{"input": time_acc, "output": hips_t_acc, "interpolation": "LINEAR"}]
	for i, name in enumerate(JOINT_NAMES):
		samplers.append({"input": time_acc, "output": rot_acc[name], "interpolation": "LINEAR"})
		channels.append({"sampler": i + 1, "target": {"node": i + 1, "path": "rotation"}})

	out_doc = {
		"asset": {"version": "2.0", "generator": "unbox-fighters/tools/rig_legs_walk.py"},
		"scene": 0,
		"scenes": [{"nodes": [0], "name": "LegsWalk"}],
		"nodes": nodes,
		"meshes": [
			{
				"name": "LegsMesh",
				"primitives": [
					{
						"attributes": {
							"POSITION": pos_acc,
							"NORMAL": nrm_acc,
							"TEXCOORD_0": uv_acc,
							"JOINTS_0": jnt_acc,
							"WEIGHTS_0": wgt_acc,
						},
						"indices": idx_acc,
						"material": 0,
					}
				],
			}
		],
		"skins": [
			{
				"name": "LegsRig",
				"joints": [1, 2, 3, 4, 5, 6, 7],
				"skeleton": 1,
				"inverseBindMatrices": ibm_acc,
			}
		],
		"animations": [{"name": "walk", "samplers": samplers, "channels": channels}],
		"materials": [
			{
				"name": "LegsMaterial",
				"pbrMetallicRoughness": {
					"baseColorTexture": {"index": 0},
					"baseColorFactor": [1.0, 1.0, 1.0, 1.0],
					"metallicFactor": 0.0,
					"roughnessFactor": 0.85,
				},
				"doubleSided": False,
			}
		],
		"textures": [{"source": 0}],
		"images": [{"bufferView": img_view_i, "mimeType": "image/png", "name": "LegsAlbedo"}],
		"accessors": accessors,
		"bufferViews": views,
		"buffers": [{"byteLength": len(blob)}],
	}
	_write_glb(output_path, out_doc, bytes(blob))
	print("Wrote", output_path, "bytes", output_path.stat().st_size)


def main() -> None:
	parser = argparse.ArgumentParser(description="Rig police legs and bake a walk cycle.")
	parser.add_argument("--input", type=Path, default=DEFAULT_INPUT)
	parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
	args = parser.parse_args()
	if not args.input.is_file():
		raise SystemExit("Missing input GLB: %s" % args.input)
	build(args.input, args.output)


if __name__ == "__main__":
	main()
