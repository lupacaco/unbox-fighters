"""Cut a 4+4 character sheet into eight 200x200 PNGs (edge-black to transparent).

The sheet holds four drawings of the same Freak twice: head, torso and two arms,
front pose and profile pose. Front may be the top row or the left column.

It also writes <id>_slice.json next to the PNGs with the three fight numbers and
the joints it could find, so Godot can build data/parts/*.tres with the magnets
already close to right:

* head and arms carry a metal ball, always the tip that sticks out
* the torso carries recessed metal cups (neck and shoulders) and a crate base

Use --overlay to save a check image with every joint drawn on top of the part.
"""

from __future__ import annotations

import argparse
import json
from collections import deque
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
## Outside assets/ so Godot never imports the check images as game art.
CHECK_DIR = ROOT / "tools" / "checks"
CANVAS = 200
SLOTS = ("head", "body", "arm_l", "arm_r")
MIN_BLOB = 400
INK_ALPHA = 40


# --------------------------------------------------------------------------- sheet

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
			while q:
				cx, cy = q.popleft()
				n += 1
				minx = min(minx, cx)
				maxx = max(maxx, cx)
				miny = min(miny, cy)
				maxy = max(maxy, cy)
				for dx, dy in ((-1, 0), (1, 0), (0, -1), (0, 1)):
					nx, ny = cx + dx, cy + dy
					if 0 <= nx < w and 0 <= ny < h and not seen[ny][nx] and is_ink(px, nx, ny, opaque_is_ink):
						seen[ny][nx] = True
						q.append((nx, ny))
			if n < MIN_BLOB:
				continue
			blobs.append({"n": n, "box": (minx, miny, maxx + 1, maxy + 1)})
	return blobs


def _bands(blobs: list[dict], axis: int) -> list[list[dict]]:
	"""Group drawings that share the same row (axis 1) or the same column (axis 0)."""
	lo_i, hi_i = (0, 2) if axis == 0 else (1, 3)
	bands: list[list[dict]] = []
	edge = -1
	for blob in sorted(blobs, key=lambda b: b["box"][lo_i]):
		if bands and blob["box"][lo_i] < edge:
			bands[-1].append(blob)
			edge = max(edge, blob["box"][hi_i])
		else:
			bands.append([blob])
			edge = blob["box"][hi_i]
	return bands


def classify(blobs: list[dict]) -> dict[str, dict]:
	rows = _bands(blobs, 1)
	if len(rows) == 2 and all(len(r) == 4 for r in rows):
		return {"front": _name_four(rows[0]), "profile": _name_four(rows[1])}
	cols = _bands(blobs, 0)
	if len(cols) == 2 and all(len(c) == 4 for c in cols):
		return {"front": _name_four(cols[0]), "profile": _name_four(cols[1])}
	raise RuntimeError(
		"A folha precisa de 4 desenhos de frente e 4 de perfil, separados. "
		f"Achei {len(blobs)} desenhos, em {len(rows)} linhas e {len(cols)} colunas. "
		"Se o Freak tem roupa preta, use PNG com fundo transparente (não JPG)."
	)


def _name_four(group: list[dict]) -> dict[str, dict]:
	"""Torso is the biggest drawing; the two arms are the closest pair in size."""
	torso = max(group, key=lambda b: b["n"])
	rest = [b for b in group if b is not torso]
	if len(rest) != 3:
		raise RuntimeError("Não consegui separar cabeça e braços")
	pairs = [(a, b) for i, a in enumerate(rest) for b in rest[i + 1:]]
	arms = min(pairs, key=lambda p: abs(p[0]["n"] - p[1]["n"]))
	head = next(b for b in rest if b is not arms[0] and b is not arms[1])
	left, right = sorted(arms, key=lambda b: b["box"][0])
	return {"head": head, "body": torso, "arm_l": left, "arm_r": right}


# --------------------------------------------------------------------------- canvas

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


def fit_canvas(im: Image.Image, keep_dark_clothes: bool = False) -> Image.Image:
	flood_edge_black(im, keep_dark_clothes)
	canvas = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
	bbox = im.getbbox()
	if not bbox:
		return canvas
	cropped = im.crop(bbox)
	cw, ch = cropped.size
	scale = min(CANVAS / cw, CANVAS / ch)
	nw = max(1, int(round(cw * scale)))
	nh = max(1, int(round(ch * scale)))
	resized = cropped.resize((nw, nh), Image.Resampling.LANCZOS)
	canvas.paste(resized, ((CANVAS - nw) // 2, (CANVAS - nh) // 2), resized)
	return canvas


# --------------------------------------------------------------------------- joints

def ink_rows(canvas: Image.Image) -> list[list[tuple[int, int]]]:
	"""For every row, the spans of drawn pixels, left to right."""
	px = canvas.load()
	rows: list[list[tuple[int, int]]] = []
	for y in range(CANVAS):
		spans: list[tuple[int, int]] = []
		start = -1
		for x in range(CANVAS):
			if px[x, y][3] >= INK_ALPHA:
				if start < 0:
					start = x
			elif start >= 0:
				spans.append((start, x - 1))
				start = -1
		if start >= 0:
			spans.append((start, CANVAS - 1))
		rows.append(spans)
	return rows


def _span_at(spans: list[tuple[int, int]], x: float) -> tuple[int, int] | None:
	if not spans:
		return None
	for lo, hi in spans:
		if lo - 2 <= x <= hi + 2:
			return (lo, hi)
	return max(spans, key=lambda s: s[1] - s[0])


def ball_joint(rows: list[list[tuple[int, int]]], at_bottom: bool) -> tuple[int, int] | None:
	"""The connector ball is the round tip at the end of a head or an arm.

	Walking inward from the tip, the silhouette widens to the ball equator and
	then narrows at the wrist or the neck. That first peak is the ball center.
	"""
	order = range(CANVAS - 1, -1, -1) if at_bottom else range(CANVAS)
	tip = next((y for y in order if rows[y]), -1)
	if tip < 0:
		return None
	step = -1 if at_bottom else 1
	track = sum(_span_at(rows[tip], CANVAS * 0.5)) * 0.5
	widths: list[tuple[int, float, int]] = []
	for i in range(int(CANVAS * 0.5)):
		y = tip + step * i
		if y < 0 or y >= CANVAS:
			break
		span = _span_at(rows[y], track)
		if span is None:
			break
		track = (span[0] + span[1]) * 0.5
		widths.append((span[1] - span[0] + 1, track, y))
	peak = _first_peak(widths)
	if peak is None:
		return None
	return (int(round(peak[1])), peak[2])


def _first_peak(widths: list[tuple[int, float, int]], drop_rows: int = 4) -> tuple[int, float, int] | None:
	for i in range(2, len(widths) - drop_rows):
		here = widths[i][0]
		if here < 10 or here > CANVAS * 0.75:
			continue
		if widths[i - 1][0] > here:
			continue
		if all(widths[i + k][0] < here for k in range(1, drop_rows + 1)):
			return widths[i]
	return None


def _metal(r: int, g: int, b: int, a: int) -> bool:
	if a < 120:
		return False
	mx = max(r, g, b)
	mn = min(r, g, b)
	if mx < 105 or mx > 250:
		return False
	return (mx - mn) <= mx * 0.33


def metal_blobs(canvas: Image.Image) -> list[dict]:
	px = canvas.load()
	seen = [[False] * CANVAS for _ in range(CANVAS)]
	found: list[dict] = []
	for y in range(CANVAS):
		for x in range(CANVAS):
			if seen[y][x] or not _metal(*px[x, y]):
				continue
			q = deque([(x, y)])
			seen[y][x] = True
			pts: list[tuple[int, int]] = []
			while q:
				cx, cy = q.popleft()
				pts.append((cx, cy))
				for dx, dy in ((-1, 0), (1, 0), (0, -1), (0, 1), (-1, -1), (1, 1), (-1, 1), (1, -1)):
					nx, ny = cx + dx, cy + dy
					if 0 <= nx < CANVAS and 0 <= ny < CANVAS and not seen[ny][nx] and _metal(*px[nx, ny]):
						seen[ny][nx] = True
						q.append((nx, ny))
			if len(pts) < 45:
				continue
			xs = [p[0] for p in pts]
			ys = [p[1] for p in pts]
			w = max(xs) - min(xs) + 1
			h = max(ys) - min(ys) + 1
			if w < 6 or h < 6:
				continue
			if not 0.30 <= w / h <= 3.2:
				continue
			if len(pts) < w * h * 0.34:
				continue
			found.append({"n": len(pts), "cx": sum(xs) / len(pts), "cy": sum(ys) / len(pts)})
	found.sort(key=lambda c: c["n"], reverse=True)
	return found


## A shoulder cup found this close to the neck is really something else on the chest.
MIN_SHOULDER_SPREAD = 22
## Sockets live on the torso, never down in the crate.
SOCKET_CEILING = int(CANVAS * 0.62)


def torso_joints(
	canvas: Image.Image, rows: list[list[tuple[int, int]]], profile: bool
) -> dict[str, tuple[int, int]]:
	"""Neck and shoulder cups, plus the crate base the Freak stands on."""
	joints: dict[str, tuple[int, int]] = {}
	floor = next((y for y in range(CANVAS - 1, -1, -1) if rows[y]), CANVAS - 1)
	mid = _span_at(rows[floor], CANVAS * 0.5)
	joints["ground"] = (int(round((mid[0] + mid[1]) * 0.5)) if mid else CANVAS // 2, floor)

	cups = [c for c in metal_blobs(canvas) if c["cy"] < SOCKET_CEILING]
	if profile:
		# Turned sideways only one shoulder cup faces us, and the neck cup hides
		# behind the collar, so the neck starts at the top of the silhouette.
		joints["neck"] = _silhouette_top(rows)
		if cups:
			only = (int(round(cups[0]["cx"])), int(round(cups[0]["cy"])))
			joints["shoulder_l"] = only
			joints["shoulder_r"] = only
		return joints

	if not cups:
		return joints
	cups.sort(key=lambda c: c["cy"])
	neck = (int(round(cups[0]["cx"])), int(round(cups[0]["cy"])))
	joints["neck"] = neck
	sides = [c for c in cups[1:] if abs(c["cx"] - neck[0]) >= MIN_SHOULDER_SPREAD]
	if not sides:
		return joints
	# The cups sit either side of the neck, so one good find gives the other.
	far = max(sides, key=lambda c: abs(c["cx"] - neck[0]))
	spread = abs(far["cx"] - neck[0])
	pair = [(int(round(far["cx"])), int(round(far["cy"])))]
	twin = next(
		(
			c
			for c in sides
			if (c["cx"] - neck[0]) * (far["cx"] - neck[0]) < 0
			and abs(c["cx"] - neck[0]) >= spread * 0.6
		),
		None,
	)
	if twin is not None:
		pair.append((int(round(twin["cx"])), int(round(twin["cy"]))))
	else:
		pair.append((2 * neck[0] - pair[0][0], pair[0][1]))
	pair.sort(key=lambda p: p[0])
	joints["shoulder_l"] = pair[0]
	joints["shoulder_r"] = pair[1]
	return joints


def _silhouette_top(rows: list[list[tuple[int, int]]]) -> tuple[int, int]:
	top = next((y for y in range(CANVAS) if rows[y]), 0)
	band = [s for y in range(top, min(CANVAS, top + 14)) for s in rows[y]]
	if not band:
		return (CANVAS // 2, top)
	lo = min(s[0] for s in band)
	hi = max(s[1] for s in band)
	return (int(round((lo + hi) * 0.5)), top + 4)


def find_joints(canvas: Image.Image, slot: str, profile: bool) -> dict[str, tuple[int, int]]:
	rows = ink_rows(canvas)
	if slot == "body":
		return torso_joints(canvas, rows, profile)
	point = ball_joint(rows, at_bottom=slot == "head")
	return {"join": point} if point else {}


def to_magnet(point: tuple[int, int]) -> list[int]:
	return [point[0] - CANVAS // 2, point[1] - CANVAS // 2]


# --------------------------------------------------------------------------- run

def save_overlay(canvas: Image.Image, joints: dict, dest: Path) -> None:
	shot = Image.new("RGBA", (CANVAS, CANVAS), (24, 20, 34, 255))
	shot.alpha_composite(canvas)
	pen = ImageDraw.Draw(shot)
	for name, (x, y) in joints.items():
		colour = (255, 90, 90, 255) if name == "ground" else (90, 230, 255, 255)
		pen.ellipse((x - 6, y - 6, x + 6, y + 6), outline=colour, width=2)
		pen.line((x - 9, y, x + 9, y), fill=colour)
		pen.line((x, y - 9, x, y + 9), fill=colour)
		pen.text((x + 8, y - 12), name, fill=colour)
	shot.save(dest, "PNG")


def slice_sheet(sheet_path: Path, set_id: str, out_dir: Path, overlay: bool) -> dict:
	sheet = Image.open(sheet_path).convert("RGBA")
	keep_dark = uses_alpha_background(sheet)
	try:
		named = classify(find_blobs(sheet, keep_dark))
	except RuntimeError:
		keep_dark = not keep_dark
		named = classify(find_blobs(sheet, keep_dark))
	out_dir.mkdir(parents=True, exist_ok=True)
	report: dict = {}
	for pose, suffix in (("front", "1"), ("profile", "2")):
		report[pose] = {}
		for slot in SLOTS:
			box = named[pose][slot]["box"]
			pad = 8
			crop = sheet.crop(
				(
					max(0, box[0] - pad),
					max(0, box[1] - pad),
					min(sheet.width, box[2] + pad),
					min(sheet.height, box[3] + pad),
				)
			).convert("RGBA")
			canvas = fit_canvas(crop, keep_dark)
			canvas.save(out_dir / f"{set_id}_{slot}-{suffix}.png", "PNG")
			joints = find_joints(canvas, slot, pose == "profile")
			report[pose][slot] = {name: to_magnet(pt) for name, pt in joints.items()}
			if overlay:
				CHECK_DIR.mkdir(parents=True, exist_ok=True)
				save_overlay(canvas, joints, CHECK_DIR / f"{set_id}_{slot}-{suffix}.png")
			print(pose, slot, report[pose][slot])
	return report


def main() -> None:
	parser = argparse.ArgumentParser(description="Cut a 4+4 Freak sheet into eight 200x200 parts.")
	parser.add_argument("sheet", help="Path to the PNG/WEBP sheet")
	parser.add_argument("--id", required=True, help="Internal id, e.g. bruxa")
	parser.add_argument("--name", default="", help="Display name, e.g. Bruxa")
	parser.add_argument("--attack", type=int, default=5, help="Cabeca: Ataque, 1 a 10")
	parser.add_argument("--hp", type=int, default=15, help="Corpo: HP, 10 a 20")
	parser.add_argument("--kind", default="human", help="humano, sobrenatural ou animal")
	parser.add_argument("--ability", default="", help="mind_control, appeal, or empty")
	parser.add_argument("--overlay", action="store_true", help="Save a check image with the joints drawn")
	args = parser.parse_args()
	set_id = args.id.strip().lower()
	out_dir = ROOT / "assets" / "characters" / set_id
	report = slice_sheet(Path(args.sheet), set_id, out_dir, args.overlay)
	payload = {
		"id": set_id,
		"display_name": args.name.strip() or set_id.capitalize(),
		"stats": {
			"attack": max(1, min(10, args.attack)),
			"hp": max(10, min(20, args.hp)),
		},
		"kind": args.kind.strip().lower() or "human",
		"ability": args.ability.strip().lower(),
		"magnets": report,
	}
	(out_dir / f"{set_id}_slice.json").write_text(
		json.dumps(payload, ensure_ascii=False, indent="\t") + "\n", encoding="utf-8"
	)
	print("done")


if __name__ == "__main__":
	main()
