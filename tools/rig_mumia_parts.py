"""Rig mummy head / body / legs GLBs and bake idle, walk, punch, kick, jump, look."""
from __future__ import annotations

import math
import sys
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(Path(__file__).resolve().parent))
import glb_rig_lib as rig  # noqa: E402

SRC = Path(r"C:\dev\3D\mumia-3d")
OUT = ROOT / "assets" / "characters" / "mumia" / "3d"

WALK_SEC = 0.85
IDLE_SEC = 1.2
PUNCH_SEC = 0.48
KICK_SEC = 0.55
JUMP_SEC = 0.62
LOOK_SEC = 0.8
FRAMES = 24


def _repeat_first(values: list[np.ndarray]) -> np.ndarray:
	return np.stack(values + [values[0]])


def _paint_chain(positions: np.ndarray, bones: list[tuple[np.ndarray, np.ndarray, float]], side_axis: int | None = None) -> tuple[np.ndarray, np.ndarray]:
	w = np.zeros((len(positions), len(bones)), dtype=np.float64)
	x = positions[:, 0]
	left = 1.0 - rig.smoothstep(-0.04, 0.04, x)
	right = rig.smoothstep(-0.04, 0.04, x)
	for i, (a, b, radius) in enumerate(bones):
		mask = 1.0
		if side_axis is not None:
			mid = 0.5 * (a[0] + b[0])
			mask = left if mid < 0 else right
		w[:, i] = rig.envelope(rig.segment_distance(positions, a, b), radius) * mask
	row = np.maximum(w.sum(axis=1, keepdims=True), 1e-8)
	return rig.top4_weights(w / row)


def rig_legs(mesh: dict) -> None:
	hips = np.array([0.0, 0.22, -0.02])
	thigh_l = np.array([-0.20, 0.10, -0.03])
	calf_l = np.array([-0.22, -0.16, -0.02])
	foot_l = np.array([-0.26, -0.40, 0.00])
	thigh_r = np.array([0.18, 0.10, -0.02])
	calf_r = np.array([0.19, -0.16, -0.01])
	foot_r = np.array([0.24, -0.40, 0.03])
	world = [hips, thigh_l, calf_l, foot_l, thigh_r, calf_r, foot_r]
	names = ["Hips", "Thigh_L", "Calf_L", "Foot_L", "Thigh_R", "Calf_R", "Foot_R"]
	toe_l = foot_l + np.array([0.0, -0.02, 0.14])
	toe_r = foot_r + np.array([0.0, -0.02, 0.14])
	segments = [
		(hips, hips + np.array([0.0, 0.24, 0.0]), 0.30),
		(thigh_l, calf_l, 0.16),
		(calf_l, foot_l, 0.13),
		(foot_l, toe_l, 0.13),
		(thigh_r, calf_r, 0.16),
		(calf_r, foot_r, 0.13),
		(foot_r, toe_r, 0.13),
	]
	mesh["joints"], mesh["weights"] = _paint_chain(mesh["positions"].astype(np.float64), segments, side_axis=0)

	nodes = [
		{"name": "Legs", "children": [1]},
		{"name": "Hips", "translation": rig.local_translation(np.zeros(3), hips), "children": [2, 5]},
		{"name": "Thigh_L", "translation": rig.local_translation(hips, thigh_l), "children": [3]},
		{"name": "Calf_L", "translation": rig.local_translation(thigh_l, calf_l), "children": [4]},
		{"name": "Foot_L", "translation": rig.local_translation(calf_l, foot_l)},
		{"name": "Thigh_R", "translation": rig.local_translation(hips, thigh_r), "children": [6]},
		{"name": "Calf_R", "translation": rig.local_translation(thigh_r, calf_r), "children": [7]},
		{"name": "Foot_R", "translation": rig.local_translation(calf_r, foot_r)},
	]
	# node indices: 0 Legs, 1 Hips ... 7 Foot_R. joints = 1..7
	thigh_len_l = float(np.linalg.norm(calf_l - thigh_l))
	calf_len_l = float(np.linalg.norm(foot_l - calf_l))
	thigh_len_r = float(np.linalg.norm(calf_r - thigh_r))
	calf_len_r = float(np.linalg.norm(foot_r - calf_r))

	def bake_walk(duration: float, step_len: float, step_h: float, kick_side: str | None, crouch: float) -> dict:
		times = rig.loop_times(duration, FRAMES)
		n = len(times)
		rot = {name: [] for name in names}
		hips_t = []
		for i in range(FRAMES):
			u = i / float(FRAMES)
			if kick_side:
				# One-shot kick: plant other leg, swing this one forward.
				t = u
				bob = 0.01
				hips_q = rig.euler_xyz(0.06, 0.0, 0.0)
				hips_p = hips + np.array([0.0, bob, 0.0])
			elif crouch > 0.0:
				dip = crouch * math.sin(math.pi * min(u * 1.15, 1.0))
				hips_q = rig.euler_xyz(0.08, 0.0, 0.0)
				hips_p = hips + np.array([0.0, -dip, 0.0])
			else:
				bob = 0.014 * (0.5 - 0.5 * math.cos(4.0 * math.pi * u))
				hips_q = rig.euler_xyz(0.04, 0.07 * math.sin(2.0 * math.pi * u), 0.04 * math.sin(2.0 * math.pi * u))
				hips_p = hips + np.array([0.01 * math.sin(2.0 * math.pi * u), bob, 0.0])
			hips_t.append(hips_p.astype(np.float32))
			rot["Hips"].append(hips_q.astype(np.float32))

			def one_leg(side: str, phase: float, thigh_len: float, calf_len: float, bind_hip: np.ndarray, bind_foot: np.ndarray) -> None:
				offset = bind_hip - hips
				hip_joint = hips_p + rig.quat_rotate(hips_q, offset)
				if kick_side == side:
					# Swing forward and up, then back.
					arc = math.sin(math.pi * min(phase * 1.05, 1.0))
					foot = np.array([bind_foot[0], bind_foot[1] + 0.16 * arc, bind_foot[2] + 0.34 * arc])
					pitch = 0.25 * arc
				elif crouch > 0.0:
					foot = bind_foot.copy()
					pitch = 0.1 * math.sin(math.pi * min(phase, 1.0))
				else:
					duty = 0.62
					ph = phase % 1.0
					if ph < duty:
						tt = ph / duty
						z = (0.5 - tt) * step_len + bind_foot[2]
						y = bind_foot[1]
						pitch = 0.2 * (1.0 - tt / 0.18) if tt < 0.18 else (-0.28 * ((tt - 0.78) / 0.22) if tt > 0.78 else 0.0)
					else:
						tt = (ph - duty) / (1.0 - duty)
						ease = tt * tt * (3.0 - 2.0 * tt)
						z = (-0.5 + ease) * step_len + bind_foot[2]
						y = bind_foot[1] + step_h * math.sin(math.pi * tt)
						pitch = 0.35 * math.sin(math.pi * tt)
					foot = np.array([bind_foot[0], y, z])
				pole = hip_joint + np.array([0.0, 0.0, 0.42])
				knee = rig.two_bone_ik(hip_joint, foot, thigh_len, calf_len, pole)
				thigh_q = rig.bone_quat(hip_joint, knee, pole)
				calf_q = rig.bone_quat(knee, foot, pole)
				foot_q = rig.quat_norm(rig.quat_mul(calf_q, rig.quat_from_axis_angle(np.array([1.0, 0.0, 0.0]), pitch)))
				rot["Thigh_%s" % side].append(rig.local_from_world(hips_q, thigh_q).astype(np.float32))
				rot["Calf_%s" % side].append(rig.local_from_world(thigh_q, calf_q).astype(np.float32))
				rot["Foot_%s" % side].append(rig.local_from_world(calf_q, foot_q).astype(np.float32))

			one_leg("L", u if not kick_side else (u if kick_side == "L" else 0.0), thigh_len_l, calf_len_l, thigh_l, foot_l)
			one_leg("R", (u + 0.5) if not kick_side else (u if kick_side == "R" else 0.0), thigh_len_r, calf_len_r, thigh_r, foot_r)

		channels = [{"node": 1, "path": "translation", "values": _repeat_first(hips_t)}]
		for i, name in enumerate(names):
			channels.append({"node": i + 1, "path": "rotation", "values": _repeat_first(rot[name])})
		return {"times": times, "channels": channels}

	idle = bake_walk(IDLE_SEC, 0.02, 0.008, None, 0.0)
	idle["name"] = "idle"
	walk = bake_walk(WALK_SEC, 0.18, 0.06, None, 0.0)
	walk["name"] = "walk"
	punch = bake_walk(PUNCH_SEC, 0.03, 0.01, None, 0.0)
	punch["name"] = "punch"
	kick = bake_walk(KICK_SEC, 0.04, 0.02, "R", 0.0)
	kick["name"] = "kick"
	jump = bake_walk(JUMP_SEC, 0.0, 0.0, None, 0.07)
	jump["name"] = "jump"
	look = bake_walk(LOOK_SEC, 0.02, 0.008, None, 0.0)
	look["name"] = "look"
	rig.write_skinned_glb(
		OUT / "mumia-legs-rig.glb",
		mesh,
		nodes,
		[1, 2, 3, 4, 5, 6, 7],
		world,
		[idle, walk, punch, kick, jump, look],
		"MumiaLegs",
	)


def rig_body(mesh: dict) -> None:
	chest = np.array([0.0, 0.10, -0.01])
	sh_l = np.array([-0.16, 0.20, -0.03])
	el_l = np.array([-0.29, -0.05, 0.02])
	hd_l = np.array([-0.42, -0.29, 0.06])
	sh_r = np.array([0.15, 0.20, -0.03])
	el_r = np.array([0.28, -0.05, 0.01])
	hd_r = np.array([0.41, -0.29, 0.04])
	world = [chest, sh_l, el_l, hd_l, sh_r, el_r, hd_r]
	names = ["Chest", "UpperArm_L", "LowerArm_L", "Hand_L", "UpperArm_R", "LowerArm_R", "Hand_R"]
	segments = [
		(chest, chest + np.array([0.0, 0.18, 0.0]), 0.22),
		(sh_l, el_l, 0.12),
		(el_l, hd_l, 0.11),
		(hd_l, hd_l + np.array([-0.04, -0.04, 0.02]), 0.10),
		(sh_r, el_r, 0.12),
		(el_r, hd_r, 0.11),
		(hd_r, hd_r + np.array([0.04, -0.04, 0.02]), 0.10),
	]
	mesh["joints"], mesh["weights"] = _paint_chain(mesh["positions"].astype(np.float64), segments, side_axis=0)
	nodes = [
		{"name": "Body", "children": [1]},
		{"name": "Chest", "translation": rig.local_translation(np.zeros(3), chest), "children": [2, 5]},
		{"name": "UpperArm_L", "translation": rig.local_translation(chest, sh_l), "children": [3]},
		{"name": "LowerArm_L", "translation": rig.local_translation(sh_l, el_l), "children": [4]},
		{"name": "Hand_L", "translation": rig.local_translation(el_l, hd_l)},
		{"name": "UpperArm_R", "translation": rig.local_translation(chest, sh_r), "children": [6]},
		{"name": "LowerArm_R", "translation": rig.local_translation(sh_r, el_r), "children": [7]},
		{"name": "Hand_R", "translation": rig.local_translation(el_r, hd_r)},
	]
	len_u_l = float(np.linalg.norm(el_l - sh_l))
	len_l_l = float(np.linalg.norm(hd_l - el_l))
	len_u_r = float(np.linalg.norm(el_r - sh_r))
	len_l_r = float(np.linalg.norm(hd_r - el_r))

	def bake(duration: float, mode: str) -> dict:
		times = rig.loop_times(duration, FRAMES)
		rot = {name: [] for name in names}
		chest_t = []
		for i in range(FRAMES):
			u = i / float(FRAMES)
			if mode == "walk":
				chest_q = rig.euler_xyz(0.03, 0.05 * math.sin(2.0 * math.pi * u), 0.0)
				chest_p = chest + np.array([0.0, 0.008 * math.sin(4.0 * math.pi * u), 0.0])
			elif mode == "punch":
				chest_q = rig.euler_xyz(0.05, -0.12 * math.sin(math.pi * u), 0.0)
				chest_p = chest + np.array([0.0, 0.0, 0.02 * math.sin(math.pi * u)])
			elif mode == "kick":
				chest_q = rig.euler_xyz(0.08, 0.1 * math.sin(math.pi * u), 0.0)
				chest_p = chest
			elif mode == "jump":
				chest_q = rig.euler_xyz(0.1 * math.sin(math.pi * u), 0.0, 0.0)
				chest_p = chest + np.array([0.0, -0.02 * math.sin(math.pi * u), 0.0])
			elif mode == "look":
				chest_q = rig.euler_xyz(0.02, 0.08 * math.sin(2.0 * math.pi * u), 0.0)
				chest_p = chest
			else:
				chest_q = rig.euler_xyz(0.02 * math.sin(2.0 * math.pi * u), 0.0, 0.0)
				chest_p = chest + np.array([0.0, 0.006 * math.sin(2.0 * math.pi * u), 0.0])
			chest_t.append(chest_p.astype(np.float32))
			rot["Chest"].append(chest_q.astype(np.float32))

			def arm(side: str, sh: np.ndarray, hd: np.ndarray, ul: float, ll: float, phase: float) -> None:
				offset = sh - chest
				shoulder = chest_p + rig.quat_rotate(chest_q, offset)
				if mode == "punch" and side == "R":
					arc = math.sin(math.pi * min(phase * 1.05, 1.0))
					target = np.array([hd[0] * 0.25, 0.06, 0.38 * arc + 0.04])
					pole = shoulder + np.array([0.12 if side == "R" else -0.12, 0.15, 0.2])
				elif mode == "punch" and side == "L":
					target = hd + np.array([0.0, 0.02, -0.08])
					pole = shoulder + np.array([-0.12, 0.1, 0.1])
				elif mode == "walk":
					swing = 0.42 * math.sin(2.0 * math.pi * phase)
					# phase 0 left arm forward when right leg forward
					target = np.array([hd[0], hd[1] + 0.04 * abs(swing), hd[2] + 0.22 * swing])
					pole = shoulder + np.array([0.1 if side == "R" else -0.1, 0.05, 0.25])
				elif mode == "jump":
					target = np.array([hd[0] * 0.7, hd[1] + 0.18, hd[2] + 0.05])
					pole = shoulder + np.array([0.0, 0.2, 0.2])
				elif mode == "kick":
					target = hd + np.array([0.0, 0.04, 0.06])
					pole = shoulder + np.array([0.0, 0.1, 0.2])
				else:
					target = hd.copy()
					pole = shoulder + np.array([0.08 if side == "R" else -0.08, 0.05, 0.2])
				elbow = rig.two_bone_ik(shoulder, target, ul, ll, pole)
				uq = rig.bone_quat(shoulder, elbow, pole)
				lq = rig.bone_quat(elbow, target, pole)
				hq = lq.copy()
				rot["UpperArm_%s" % side].append(rig.local_from_world(chest_q, uq).astype(np.float32))
				rot["LowerArm_%s" % side].append(rig.local_from_world(uq, lq).astype(np.float32))
				rot["Hand_%s" % side].append(rig.local_from_world(lq, hq).astype(np.float32))

			# Walk: left arm opposite to a left-leg-forward phase.
			arm("L", sh_l, hd_l, len_u_l, len_l_l, u + 0.5 if mode == "walk" else u)
			arm("R", sh_r, hd_r, len_u_r, len_l_r, u if mode == "walk" else u)

		channels = [{"node": 1, "path": "translation", "values": _repeat_first(chest_t)}]
		for i, name in enumerate(names):
			channels.append({"node": i + 1, "path": "rotation", "values": _repeat_first(rot[name])})
		return {"times": times, "channels": channels}

	clips = []
	for name, dur, mode in [
		("idle", IDLE_SEC, "idle"),
		("walk", WALK_SEC, "walk"),
		("punch", PUNCH_SEC, "punch"),
		("kick", KICK_SEC, "kick"),
		("jump", JUMP_SEC, "jump"),
		("look", LOOK_SEC, "look"),
	]:
		clip = bake(dur, mode)
		clip["name"] = name
		clips.append(clip)
	rig.write_skinned_glb(OUT / "mumia-body-rig.glb", mesh, nodes, [1, 2, 3, 4, 5, 6, 7], world, clips, "MumiaBody")


def rig_head(mesh: dict) -> None:
	neck = np.array([0.0, -0.32, 0.02])
	head = np.array([0.0, 0.08, 0.08])
	world = [neck, head]
	segments = [
		(neck, neck + np.array([0.0, 0.12, 0.0]), 0.22),
		(head, head + np.array([0.0, 0.28, 0.04]), 0.36),
	]
	w = np.zeros((len(mesh["positions"]), 2), dtype=np.float64)
	pos = mesh["positions"].astype(np.float64)
	w[:, 0] = rig.envelope(rig.segment_distance(pos, *segments[0][:2]), segments[0][2])
	w[:, 0] += (1.0 - rig.smoothstep(-0.20, 0.00, pos[:, 1])) * 0.8
	w[:, 1] = rig.envelope(np.linalg.norm(pos - head, axis=1), 0.42)
	w[:, 1] += rig.smoothstep(-0.10, 0.10, pos[:, 1]) * 0.9
	row = np.maximum(w.sum(axis=1, keepdims=True), 1e-8)
	mesh["joints"], mesh["weights"] = rig.top4_weights(w / row)
	nodes = [
		{"name": "HeadRoot", "children": [1]},
		{"name": "Neck", "translation": rig.local_translation(np.zeros(3), neck), "children": [2]},
		{"name": "Head", "translation": rig.local_translation(neck, head)},
	]

	def bake(duration: float, mode: str) -> dict:
		times = rig.loop_times(duration, FRAMES)
		neck_r = []
		head_r = []
		for i in range(FRAMES):
			u = i / float(FRAMES)
			if mode == "walk":
				nq = rig.euler_xyz(0.04 * math.sin(4.0 * math.pi * u), 0.06 * math.sin(2.0 * math.pi * u), 0.0)
				hq = rig.euler_xyz(0.03 * math.sin(4.0 * math.pi * u + 0.4), 0.0, 0.0)
			elif mode == "punch":
				nq = rig.euler_xyz(0.12 * math.sin(math.pi * u), -0.1 * math.sin(math.pi * u), 0.0)
				hq = rig.euler_xyz(0.08 * math.sin(math.pi * u), 0.0, 0.0)
			elif mode == "kick":
				nq = rig.euler_xyz(0.1 * math.sin(math.pi * u), 0.08, 0.0)
				hq = rig.euler_xyz(0.05, 0.0, 0.0)
			elif mode == "jump":
				nq = rig.euler_xyz(-0.08 * math.sin(math.pi * u), 0.0, 0.0)
				hq = rig.euler_xyz(-0.06 * math.sin(math.pi * u), 0.0, 0.0)
			elif mode == "look":
				nq = rig.euler_xyz(0.12 * math.sin(2.0 * math.pi * u), 0.35 * math.sin(2.0 * math.pi * u), 0.0)
				hq = rig.euler_xyz(0.18 * math.sin(2.0 * math.pi * u + 0.5), 0.15 * math.sin(2.0 * math.pi * u), 0.0)
			else:
				nq = rig.euler_xyz(0.03 * math.sin(2.0 * math.pi * u), 0.0, 0.0)
				hq = rig.euler_xyz(0.02 * math.sin(2.0 * math.pi * u + 0.3), 0.0, 0.0)
			neck_r.append(nq.astype(np.float32))
			head_r.append(rig.local_from_world(nq, rig.quat_mul(nq, hq)).astype(np.float32))
		return {
			"times": times,
			"channels": [
				{"node": 1, "path": "rotation", "values": _repeat_first(neck_r)},
				{"node": 2, "path": "rotation", "values": _repeat_first(head_r)},
			],
		}

	clips = []
	for name, dur, mode in [
		("idle", IDLE_SEC, "idle"),
		("walk", WALK_SEC, "walk"),
		("punch", PUNCH_SEC, "punch"),
		("kick", KICK_SEC, "kick"),
		("jump", JUMP_SEC, "jump"),
		("look", LOOK_SEC, "look"),
	]:
		clip = bake(dur, mode)
		clip["name"] = name
		clips.append(clip)
	rig.write_skinned_glb(OUT / "mumia-head-rig.glb", mesh, nodes, [1, 2], world, clips, "MumiaHead")


def main() -> None:
	OUT.mkdir(parents=True, exist_ok=True)
	import shutil

	for part in ("head", "body", "legs"):
		src = SRC / ("mumia-%s.glb" % part)
		if not src.is_file():
			raise SystemExit("Missing %s" % src)
		shutil.copy2(src, OUT / ("mumia-%s.glb" % part))
		mesh = rig.load_mesh(src)
		if part == "legs":
			rig_legs(mesh)
		elif part == "body":
			rig_body(mesh)
		else:
			rig_head(mesh)


if __name__ == "__main__":
	main()
