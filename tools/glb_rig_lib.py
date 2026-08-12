"""Shared helpers to read a static GLB, add a skeleton, and bake animations."""
from __future__ import annotations

import json
import math
import struct
from pathlib import Path

import numpy as np


def pad4(data: bytes, pad: bytes) -> bytes:
	extra = (4 - (len(data) % 4)) % 4
	return data + pad * extra


def minmax(arr: np.ndarray) -> tuple[list, list]:
	flat_min = arr.min(axis=0)
	flat_max = arr.max(axis=0)
	if arr.ndim == 1:
		return [float(flat_min)], [float(flat_max)]
	return [float(x) for x in flat_min], [float(x) for x in flat_max]


def read_glb(path: Path) -> tuple[dict, bytes]:
	raw = path.read_bytes()
	magic, _version, length = struct.unpack_from("<III", raw, 0)
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


def accessor_numpy(doc: dict, bin_data: bytes, index: int) -> np.ndarray:
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


def load_mesh(path: Path) -> dict:
	doc, bin_data = read_glb(path)
	prim = doc["meshes"][0]["primitives"][0]
	positions = accessor_numpy(doc, bin_data, prim["attributes"]["POSITION"]).astype(np.float32)
	uvs = accessor_numpy(doc, bin_data, prim["attributes"]["TEXCOORD_0"]).astype(np.float32)
	indices = accessor_numpy(doc, bin_data, prim["indices"]).astype(np.uint32)
	img_view = doc["bufferViews"][doc["images"][0]["bufferView"]]
	png = bin_data[img_view.get("byteOffset", 0) : img_view.get("byteOffset", 0) + img_view["byteLength"]]
	return {
		"positions": positions,
		"uvs": uvs,
		"indices": indices,
		"png": png,
		"normals": compute_normals(positions.astype(np.float64), indices),
	}


def quat_mul(a: np.ndarray, b: np.ndarray) -> np.ndarray:
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


def quat_conj(q: np.ndarray) -> np.ndarray:
	return np.array([-q[0], -q[1], -q[2], q[3]], dtype=np.float64)


def quat_norm(q: np.ndarray) -> np.ndarray:
	n = math.sqrt(float(np.dot(q, q)))
	if n < 1e-12:
		return np.array([0.0, 0.0, 0.0, 1.0])
	return q / n


def quat_from_axis_angle(axis: np.ndarray, angle: float) -> np.ndarray:
	n = np.linalg.norm(axis)
	if n < 1e-12 or abs(angle) < 1e-12:
		return np.array([0.0, 0.0, 0.0, 1.0])
	axis = axis / n
	s = math.sin(angle * 0.5)
	return quat_norm(np.array([axis[0] * s, axis[1] * s, axis[2] * s, math.cos(angle * 0.5)]))


def quat_from_matrix(m: np.ndarray) -> np.ndarray:
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
	return quat_norm(q)


def quat_rotate(q: np.ndarray, v: np.ndarray) -> np.ndarray:
	qv = np.array([v[0], v[1], v[2], 0.0])
	return quat_mul(quat_mul(q, qv), quat_conj(q))[:3]


def euler_xyz(pitch: float, yaw: float, roll: float) -> np.ndarray:
	qx = quat_from_axis_angle(np.array([1.0, 0.0, 0.0]), pitch)
	qy = quat_from_axis_angle(np.array([0.0, 1.0, 0.0]), yaw)
	qz = quat_from_axis_angle(np.array([0.0, 0.0, 1.0]), roll)
	return quat_norm(quat_mul(qy, quat_mul(qx, qz)))


def local_from_world(parent_world: np.ndarray, world: np.ndarray) -> np.ndarray:
	return quat_norm(quat_mul(quat_conj(parent_world), world))


def bone_quat(origin: np.ndarray, child: np.ndarray, pole: np.ndarray) -> np.ndarray:
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
	return quat_from_matrix(np.column_stack((x, y_axis, z)))


def two_bone_ik(
	root: np.ndarray,
	tip: np.ndarray,
	upper_len: float,
	lower_len: float,
	pole: np.ndarray,
) -> np.ndarray:
	delta = tip - root
	dist = float(np.linalg.norm(delta))
	max_reach = (upper_len + lower_len) * 0.985
	min_reach = abs(upper_len - lower_len) + 0.012
	dist = max(min_reach, min(max_reach, dist))
	direction = delta / (float(np.linalg.norm(delta)) + 1e-8)
	pole_dir = pole - root
	pole_dir = pole_dir - direction * float(np.dot(pole_dir, direction))
	if np.linalg.norm(pole_dir) < 1e-6:
		pole_dir = np.array([0.0, 0.0, 1.0])
		pole_dir = pole_dir - direction * float(np.dot(pole_dir, direction))
	pole_dir = pole_dir / (np.linalg.norm(pole_dir) + 1e-8)
	x = (dist * dist + upper_len * upper_len - lower_len * lower_len) / (2.0 * dist)
	h_sq = max(upper_len * upper_len - x * x, 0.0)
	return root + direction * x + pole_dir * math.sqrt(h_sq)


def segment_distance(points: np.ndarray, a: np.ndarray, b: np.ndarray) -> np.ndarray:
	ab = b - a
	denom = float(np.dot(ab, ab)) + 1e-8
	t = np.clip((points - a) @ ab / denom, 0.0, 1.0)
	proj = a + t[:, None] * ab
	return np.linalg.norm(points - proj, axis=1)


def envelope(dist: np.ndarray, radius: float) -> np.ndarray:
	w = np.clip(1.0 - dist / radius, 0.0, 1.0)
	return w * w


def compute_normals(positions: np.ndarray, indices: np.ndarray) -> np.ndarray:
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


def smoothstep(edge0: float, edge1: float, x: np.ndarray) -> np.ndarray:
	t = np.clip((x - edge0) / (edge1 - edge0), 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)


def top4_weights(w: np.ndarray) -> tuple[np.ndarray, np.ndarray]:
	n_verts, n_bones = w.shape
	take = min(4, n_bones)
	order = np.argsort(w, axis=1)[:, ::-1][:, :take]
	top_w = np.take_along_axis(w, order, axis=1)
	top_w = np.where(top_w < 0.02, 0.0, top_w)
	norm = np.maximum(top_w.sum(axis=1, keepdims=True), 1e-8)
	top_w = (top_w / norm).astype(np.float32)
	joints = np.zeros((n_verts, 4), dtype=np.uint8)
	weights = np.zeros((n_verts, 4), dtype=np.float32)
	joints[:, :take] = order.astype(np.uint8)
	weights[:, :take] = top_w
	return joints, weights


def local_translation(parent: np.ndarray, child: np.ndarray) -> list[float]:
	d = child - parent
	return [float(d[0]), float(d[1]), float(d[2])]


def inverse_bind(world_pos: np.ndarray) -> np.ndarray:
	m = np.eye(4, dtype=np.float32)
	m[0, 3] = -float(world_pos[0])
	m[1, 3] = -float(world_pos[1])
	m[2, 3] = -float(world_pos[2])
	return m.T.reshape(-1)


def loop_times(duration: float, frame_count: int) -> np.ndarray:
	times = np.linspace(0.0, duration, frame_count, endpoint=False, dtype=np.float32)
	return np.concatenate([times, np.array([duration], dtype=np.float32)])


def write_skinned_glb(
	path: Path,
	mesh: dict,
	nodes: list[dict],
	joint_indices: list[int],
	joint_world: list[np.ndarray],
	animations: list[dict],
	root_name: str,
) -> None:
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
		view = add_view(array.tobytes(), target)
		acc: dict = {
			"bufferView": view,
			"componentType": comp_type,
			"count": int(array.shape[0]),
			"type": type_name,
		}
		mn, mx = minmax(array)
		acc["min"] = mn
		acc["max"] = mx
		accessors.append(acc)
		return len(accessors) - 1

	idx_acc = add_accessor(mesh["indices"], "SCALAR", 5125, 34963)
	pos_acc = add_accessor(mesh["positions"], "VEC3", 5126, 34962)
	nrm_acc = add_accessor(mesh["normals"], "VEC3", 5126, 34962)
	uv_acc = add_accessor(mesh["uvs"], "VEC2", 5126, 34962)
	jnt_acc = add_accessor(mesh["joints"], "VEC4", 5121, 34962)
	wgt_acc = add_accessor(mesh["weights"], "VEC4", 5126, 34962)
	ibm = np.stack([inverse_bind(p) for p in joint_world]).astype(np.float32)
	ibm_acc = add_accessor(ibm, "MAT4", 5126)
	img_view_i = add_view(mesh["png"])

	out_anims = []
	for anim in animations:
		times_acc = add_accessor(anim["times"].astype(np.float32), "SCALAR", 5126)
		samplers = []
		channels = []
		for ch in anim["channels"]:
			values = ch["values"]
			if ch["path"] == "translation":
				out_acc = add_accessor(values.astype(np.float32), "VEC3", 5126)
			else:
				out_acc = add_accessor(values.astype(np.float32), "VEC4", 5126)
			samplers.append({"input": times_acc, "output": out_acc, "interpolation": "LINEAR"})
			channels.append(
				{"sampler": len(samplers) - 1, "target": {"node": ch["node"], "path": ch["path"]}}
			)
		out_anims.append({"name": anim["name"], "samplers": samplers, "channels": channels})

	mesh_node = len(nodes)
	nodes = list(nodes) + [{"name": root_name + "Mesh", "mesh": 0, "skin": 0}]
	if "children" in nodes[0]:
		nodes[0]["children"] = list(nodes[0]["children"]) + [mesh_node]
	else:
		nodes[0]["children"] = [mesh_node]

	doc = {
		"asset": {"version": "2.0", "generator": "unbox-fighters/tools/glb_rig_lib.py"},
		"scene": 0,
		"scenes": [{"nodes": [0], "name": root_name}],
		"nodes": nodes,
		"meshes": [
			{
				"name": root_name + "Mesh",
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
				"name": root_name + "Rig",
				"joints": joint_indices,
				"skeleton": joint_indices[0],
				"inverseBindMatrices": ibm_acc,
			}
		],
		"animations": out_anims,
		"materials": [
			{
				"name": root_name + "Material",
				"pbrMetallicRoughness": {
					"baseColorTexture": {"index": 0},
					"baseColorFactor": [1.0, 1.0, 1.0, 1.0],
					"metallicFactor": 0.0,
					"roughnessFactor": 0.85,
				},
			}
		],
		"textures": [{"source": 0}],
		"images": [{"bufferView": img_view_i, "mimeType": "image/png", "name": root_name + "Albedo"}],
		"accessors": accessors,
		"bufferViews": views,
		"buffers": [{"byteLength": len(blob)}],
	}
	json_bytes = pad4(json.dumps(doc, separators=(",", ":")).encode("utf-8"), b" ")
	bin_bytes = pad4(bytes(blob), b"\x00")
	length = 12 + 8 + len(json_bytes) + 8 + len(bin_bytes)
	out = bytearray()
	out += struct.pack("<III", 0x46546C67, 2, length)
	out += struct.pack("<II", len(json_bytes), 0x4E4F534A)
	out += json_bytes
	out += struct.pack("<II", len(bin_bytes), 0x004E4942)
	out += bin_bytes
	path.parent.mkdir(parents=True, exist_ok=True)
	path.write_bytes(out)
	print("Wrote", path, "bytes", path.stat().st_size)
