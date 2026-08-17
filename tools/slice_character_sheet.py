"""Cut a 4+4 character sheet into eight 200x200 PNGs (edge-black to transparent).

The sheet has front parts on the left and profile parts on the right,
or front on top and profile on the bottom.
Each half must contain 4 separate drawings: head, torso, two arms.
"""

from __future__ import annotations

import argparse
from collections import deque
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
CANVAS = 200
SLOTS = ("head", "body", "arm_l", "arm_r")
SLOT_LABELS = {
	"head": "Cabeça",
	"body": "Tronco",
	"arm_l": "Braço E",
	"arm_r": "Braço D",
}
SLOT_TYPES = {"head": 0, "body": 1, "arm_l": 2, "arm_r": 3}


def uses_alpha_background(im: Image.Image) -> bool:
	w, h = im.size
	px = im.load()
	samples = [(0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1), (w // 2, 0), (0, h // 2)]
	return sum(1 for x, y in samples if px[x, y][3] < 10) >= 4


def is_ink(px, x: int, y: int, opaque_is_ink: bool) -> bool:
	r, g, b, a = px[x, y]
	if a < 8:
		return False
	if opaque_is_ink:
		return True
	return r > 18 or g > 18 or b > 18


def find_blobs(im: Image.Image, opaque_is_ink: bool) -> list[dict]:
	w, h = im.size
	px = im.load()
	seen = [[False] * w for _ in range(h)]
	blobs: list[dict] = []
	for y in range(h):
		for x in range(w):
			if seen[y][x] or not is_ink(px, x, y, opaque_is_ink):
				continue
			q = deque([(x, y)])
			seen[y][x] = True
			n = 0
			minx = maxx = x
			miny = maxy = y
			sx = sy = 0
			while q:
				cx, cy = q.popleft()
				n += 1
				sx += cx
				sy += cy
				minx = min(minx, cx)
				maxx = max(maxx, cx)
				miny = min(miny, cy)
				maxy = max(maxy, cy)
				for dx, dy in ((-1, 0), (1, 0), (0, -1), (0, 1)):
					nx, ny = cx + dx, cy + dy
					if 0 <= nx < w and 0 <= ny < h and not seen[ny][nx] and is_ink(px, nx, ny, opaque_is_ink):
						seen[ny][nx] = True
						q.append((nx, ny))
			if n < 400:
				continue
			blobs.append(
				{
					"n": n,
					"cx": sx / n,
					"cy": sy / n,
					"box": (minx, miny, maxx + 1, maxy + 1),
				}
			)
	return blobs


def classify(blobs: list[dict], width: int, height: int) -> dict[str, dict]:
	left = [b for b in blobs if b["cx"] < width * 0.48]
	right = [b for b in blobs if b["cx"] >= width * 0.48]
	top = [b for b in blobs if b["cy"] < height * 0.48]
	bottom = [b for b in blobs if b["cy"] >= height * 0.48]
	if len(left) == 4 and len(right) == 4:
		return {"front": _name_group(left), "profile": _name_group(right)}
	if len(top) == 4 and len(bottom) == 4:
		return {"front": _name_group(top), "profile": _name_group(bottom)}
	if len(left) == 6 and len(right) == 6:
		return {"front": _name_group(left), "profile": _name_group(right)}
	if len(top) == 6 and len(bottom) == 6:
		return {"front": _name_group(top), "profile": _name_group(bottom)}
	raise RuntimeError(
		"A folha precisa de 4 desenhos de frente e 4 de perfil, separados. "
		f"Achei {len(left)} à esquerda, {len(right)} à direita, {len(top)} em cima e {len(bottom)} embaixo. "
		"Se o Freak tem roupa preta, use PNG com fundo transparente (não JPG)."
	)


def _name_group(group: list[dict]) -> dict[str, dict]:
	if len(group) == 4:
		return _name_four(group)
	if len(group) == 6:
		return _name_six(group)
	raise RuntimeError("Could not name the drawings")


def _name_four(group: list[dict]) -> dict[str, dict]:
	ordered = sorted(group, key=lambda b: b["cy"])
	head = ordered[0]
	rest = ordered[1:]
	torso = max(rest, key=lambda b: b["n"])
	arms = [b for b in rest if b is not torso]
	if len(arms) != 2:
		raise RuntimeError("Could not split the two arms")
	arms = sorted(arms, key=lambda b: b["cx"])
	return {
		"head": head,
		"body": torso,
		"arm_l": arms[0],
		"arm_r": arms[1],
	}


def _name_six(group: list[dict]) -> dict[str, dict]:
	ordered = sorted(group, key=lambda b: b["cy"])
	head = ordered[0]
	rest = ordered[1:]
	torso = max(rest, key=lambda b: b["n"])
	limbs = [b for b in rest if b is not torso]
	if len(limbs) != 4:
		raise RuntimeError("Could not split arms and legs")
	xs = [b["cx"] for b in limbs]
	ys = [b["cy"] for b in limbs]
	if max(xs) - min(xs) > (max(ys) - min(ys)) * 1.4:
		by_x = sorted(limbs, key=lambda b: b["cx"])
		arms = by_x[:2]
		legs = by_x[2:]
	else:
		limbs_by_y = sorted(limbs, key=lambda b: b["cy"])
		arms = sorted(limbs_by_y[:2], key=lambda b: b["cx"])
		legs = sorted(limbs_by_y[2:], key=lambda b: b["cx"])
	return {
		"head": head,
		"body": torso,
		"arm_l": arms[0],
		"arm_r": arms[1],
		"leg_l": legs[0],
		"leg_r": legs[1],
	}


def flood_edge_black(im: Image.Image, keep_dark_clothes: bool = False) -> None:
	w, h = im.size
	px = im.load()
	seen = set()
	q = deque()

	def floodable(x: int, y: int) -> bool:
		r, g, b, a = px[x, y]
		if a < 10:
			return True
		if keep_dark_clothes:
			return False
		return r <= 13 and g <= 13 and b <= 13

	def try_add(x: int, y: int) -> None:
		if x < 0 or y < 0 or x >= w or y >= h or (x, y) in seen:
			return
		if not floodable(x, y):
			return
		seen.add((x, y))
		q.append((x, y))

	for x in range(w):
		try_add(x, 0)
		try_add(x, h - 1)
	for y in range(h):
		try_add(0, y)
		try_add(w - 1, y)
	while q:
		x, y = q.popleft()
		r, g, b, _ = px[x, y]
		px[x, y] = (r, g, b, 0)
		try_add(x - 1, y)
		try_add(x + 1, y)
		try_add(x, y - 1)
		try_add(x, y + 1)


def fit_canvas(im: Image.Image, keep_dark_clothes: bool = False) -> tuple[Image.Image, float, tuple[int, int]]:
	flood_edge_black(im, keep_dark_clothes)
	bbox = im.getbbox()
	if not bbox:
		empty = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
		return empty, 1.0, (0, 0)
	cropped = im.crop(bbox)
	cw, ch = cropped.size
	scale = min(CANVAS / cw, CANVAS / ch)
	nw = max(1, int(round(cw * scale)))
	nh = max(1, int(round(ch * scale)))
	resized = cropped.resize((nw, nh), Image.Resampling.LANCZOS)
	canvas = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
	ox = (CANVAS - nw) // 2
	oy = (CANVAS - nh) // 2
	canvas.paste(resized, (ox, oy), resized)
	return canvas, scale, (ox, oy)


def is_silver(r: int, g: int, b: int, a: int) -> bool:
	if a < 80:
		return False
	mx = max(r, g, b)
	mn = min(r, g, b)
	if mx < 150:
		return False
	if mx - mn > 45:
		return False
	if r > 230 and g > 230 and b > 230:
		return False
	return True


def find_silver_clusters(im: Image.Image, origin: tuple[int, int]) -> list[tuple[float, float]]:
	w, h = im.size
	px = im.load()
	ox, oy = origin
	seen = [[False] * w for _ in range(h)]
	centers: list[tuple[float, float, int]] = []
	for y in range(h):
		for x in range(w):
			if seen[y][x]:
				continue
			r, g, b, a = px[x, y]
			if not is_silver(r, g, b, a):
				continue
			q = deque([(x, y)])
			seen[y][x] = True
			pts: list[tuple[int, int]] = []
			while q:
				cx, cy = q.popleft()
				pts.append((cx, cy))
				for dx, dy in ((-1, 0), (1, 0), (0, -1), (0, 1)):
					nx, ny = cx + dx, cy + dy
					if 0 <= nx < w and 0 <= ny < h and not seen[ny][nx]:
						nr, ng, nb, na = px[nx, ny]
						if is_silver(nr, ng, nb, na):
							seen[ny][nx] = True
							q.append((nx, ny))
			if len(pts) < 80:
				continue
			sx = ox + sum(p[0] for p in pts) / len(pts)
			sy = oy + sum(p[1] for p in pts) / len(pts)
			centers.append((sx, sy, len(pts)))
	centers.sort(key=lambda c: c[2], reverse=True)
	return [(c[0], c[1]) for c in centers]


def to_magnet(px: float, py: float) -> tuple[int, int]:
	return (int(round(px - CANVAS * 0.5)), int(round(py - CANVAS * 0.5)))


def name_body_sockets(points: list[tuple[float, float]]) -> dict[str, tuple[int, int]]:
	if not points:
		return {}
	pts = points[:5] if len(points) > 5 else points
	if len(pts) == 1:
		return {"neck": to_magnet(*pts[0])}
	by_y = sorted(pts, key=lambda p: p[1])
	named: dict[str, tuple[int, int]] = {"neck": to_magnet(*by_y[0])}
	rest = by_y[1:]
	if len(rest) >= 4:
		hips = sorted(rest, key=lambda p: p[1])[-2:]
		hips = sorted(hips, key=lambda p: p[0])
		shoulders = [p for p in rest if p not in hips]
		shoulders = sorted(shoulders, key=lambda p: p[0])
		named["shoulder_l"] = to_magnet(*shoulders[0])
		named["shoulder_r"] = to_magnet(*shoulders[-1])
		named["hip_l"] = to_magnet(*hips[0])
		named["hip_r"] = to_magnet(*hips[-1])
	elif len(rest) >= 2:
		high, low = sorted(rest, key=lambda p: p[1])[0], sorted(rest, key=lambda p: p[1])[-1]
		named["shoulder_r"] = to_magnet(*high)
		named["shoulder_l"] = named["shoulder_r"]
		named["hip_r"] = to_magnet(*low)
		named["hip_l"] = named["hip_r"]
	elif len(rest) == 1:
		named["hip_r"] = to_magnet(*rest[0])
		named["hip_l"] = named["hip_r"]
	return named


def name_single_socket(points: list[tuple[float, float]], slot: str) -> dict[str, tuple[int, int]]:
	if not points:
		return {}
	if slot == "head":
		pt = max(points, key=lambda p: p[1])
		return {"join": to_magnet(*pt)}
	pt = min(points, key=lambda p: p[1])
	return {"join": to_magnet(*pt)}


def write_part_tres(
	parts_dir: Path,
	set_id: str,
	display_name: str,
	slot: str,
	combat: int,
	magnets_front: dict,
	magnets_profile: dict,
) -> None:
	path = parts_dir / f"{set_id}_{slot}.tres"
	lines = [
		'[gd_resource type="Resource" script_class="PartDef" load_steps=4 format=3]',
		"",
		'[ext_resource type="Script" path="res://scripts/data/part_def.gd" id="1"]',
		f'[ext_resource type="Texture2D" path="res://assets/characters/{set_id}/{set_id}_{slot}-1.png" id="2"]',
		f'[ext_resource type="Texture2D" path="res://assets/characters/{set_id}/{set_id}_{slot}-2.png" id="3"]',
		"",
		"[resource]",
		'script = ExtResource("1")',
		f'id = &"{set_id}_{slot}"',
		f'display_name = "{display_name} {SLOT_LABELS[slot]}"',
		f"slot_type = {SLOT_TYPES[slot]}",
		'sprite = ExtResource("2")',
		'sprite_profile = ExtResource("3")',
		f'set_id = &"{set_id}"',
		f"combat_value = {combat}",
		"tier = 1" if combat <= 5 else f"tier = {1 if combat <= 5 else (2 if combat == 6 else (3 if combat == 7 else (4 if combat == 8 else 5)))}",
	]
	if slot == "body":
		for key, val in magnets_front.items():
			lines.append(f"magnet_{key} = Vector2({val[0]}, {val[1]})")
		for key, val in magnets_profile.items():
			lines.append(f"magnet_{key}_profile = Vector2({val[0]}, {val[1]})")
	else:
		prop = "magnet_down" if slot == "head" else "magnet_up"
		if "join" in magnets_front:
			x, y = magnets_front["join"]
			lines.append(f"{prop} = Vector2({x}, {y})")
		if "join" in magnets_profile:
			x, y = magnets_profile["join"]
			lines.append(f"{prop}_profile = Vector2({x}, {y})")
	path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def write_character(parts_dir: Path, set_id: str, display_name: str) -> None:
	path = parts_dir / f"{set_id}_character.tres"
	path.write_text(
		"\n".join(
			[
				'[gd_resource type="Resource" script_class="CharacterDef" load_steps=6 format=3]',
				"",
				'[ext_resource type="Script" path="res://scripts/data/character_def.gd" id="1"]',
				f'[ext_resource type="Resource" path="res://data/parts/{set_id}_head.tres" id="2"]',
				f'[ext_resource type="Resource" path="res://data/parts/{set_id}_body.tres" id="3"]',
				f'[ext_resource type="Resource" path="res://data/parts/{set_id}_arm_l.tres" id="4"]',
				f'[ext_resource type="Resource" path="res://data/parts/{set_id}_arm_r.tres" id="5"]',
				"",
				"[resource]",
				'script = ExtResource("1")',
				f'id = &"{set_id}"',
				f'display_name = "{display_name}"',
				'head = ExtResource("2")',
				'body = ExtResource("3")',
				'arm_l = ExtResource("4")',
				'arm_r = ExtResource("5")',
				"",
			]
		),
		encoding="utf-8",
	)


def slice_sheet(sheet_path: Path, set_id: str, out_dir: Path) -> dict:
	sheet = Image.open(sheet_path).convert("RGBA")
	keep_dark = uses_alpha_background(sheet)
	try:
		named = classify(find_blobs(sheet, keep_dark), sheet.width, sheet.height)
	except RuntimeError:
		keep_dark = not keep_dark
		named = classify(find_blobs(sheet, keep_dark), sheet.width, sheet.height)
	out_dir.mkdir(parents=True, exist_ok=True)
	report: dict = {}
	for pose, suffix in (("front", "1"), ("profile", "2")):
		report[pose] = {}
		for slot in SLOTS:
			blob = named[pose][slot]
			box = blob["box"]
			pad = 8
			x0 = max(0, box[0] - pad)
			y0 = max(0, box[1] - pad)
			x1 = min(sheet.width, box[2] + pad)
			y1 = min(sheet.height, box[3] + pad)
			crop = sheet.crop((x0, y0, x1, y1)).convert("RGBA")
			raw = crop.copy()
			flood_edge_black(raw, keep_dark)
			bbox = raw.getbbox()
			canvas, scale, origin = fit_canvas(crop, keep_dark)
			dest = out_dir / f"{set_id}_{slot}-{suffix}.png"
			canvas.save(dest, "PNG")
			points = []
			if bbox:
				local = find_silver_clusters(raw.crop(bbox), (0, 0))
				points = [(origin[0] + px * scale, origin[1] + py * scale) for px, py in local]
			mags = name_body_sockets(points) if slot == "body" else name_single_socket(points, slot)
			report[pose][slot] = mags
			print(pose, slot, dest.name, "magnets", mags)
	return report


def main() -> None:
	parser = argparse.ArgumentParser(description="Cut a 4+4 Freak sheet into eight 200x200 parts.")
	parser.add_argument("sheet", help="Path to the PNG/WEBP sheet")
	parser.add_argument("--id", required=True, help="Internal id, e.g. vampiro")
	parser.add_argument("--name", default="", help="Display name, e.g. Vampiro")
	parser.add_argument("--value", type=int, default=4, help="Combat number if --head/--body are omitted")
	parser.add_argument("--head", type=int, default=0, help="Shop number for the head kit")
	parser.add_argument("--body", type=int, default=0, help="Shop number for the torso kit")
	parser.add_argument("--write-defs", action="store_true", help="Also write data/parts/*.tres")
	args = parser.parse_args()
	set_id = args.id.strip().lower()
	display_name = args.name.strip() or set_id.capitalize()
	head_v = args.head or args.value
	body_v = args.body or args.value
	slot_values = {
		"head": head_v,
		"body": body_v,
		"arm_l": body_v,
		"arm_r": body_v,
	}
	out_dir = ROOT / "assets" / "characters" / set_id
	report = slice_sheet(Path(args.sheet), set_id, out_dir)
	if args.write_defs:
		parts_dir = ROOT / "data" / "parts"
		for slot in SLOTS:
			write_part_tres(
				parts_dir,
				set_id,
				display_name,
				slot,
				slot_values[slot],
				report["front"][slot],
				report["profile"][slot],
			)
		write_character(parts_dir, set_id, display_name)
	print("done")


if __name__ == "__main__":
	main()
