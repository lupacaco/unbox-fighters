@tool
extends RefCounted

## Finds 6 front + 6 profile parts on a sheet and saves each in a 200×200 PNG.

const OUT := 200
const MIN_BLOB := 400
const SLOT_NAMES: PackedStringArray = ["head", "body", "arm_l", "arm_r", "leg_l", "leg_r"]

static func slice_to_folder(sheet_path: String, set_id: String) -> PackedStringArray:
	var img := Image.new()
	var err := img.load(sheet_path)
	if err != OK:
		push_error("Could not load sheet: %s (%s)" % [sheet_path, err])
		return PackedStringArray()
	img.convert(Image.FORMAT_RGBA8)
	var blobs := _find_blobs(img)
	var named := _classify(blobs, img.get_width())
	if named.is_empty():
		push_error("Need 6 parts on the left (front) and 6 on the right (profile).")
		return PackedStringArray()

	var out_dir := "res://assets/characters/%s" % set_id
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))
	var saved: PackedStringArray = []
	for pose in ["front", "profile"]:
		var suffix := "1" if pose == "front" else "2"
		var group: Dictionary = named[pose]
		for slot_name in SLOT_NAMES:
			var blob: Dictionary = group[slot_name]
			var box: Rect2i = blob["box"]
			var pad := 8
			var x0 := maxi(0, box.position.x - pad)
			var y0 := maxi(0, box.position.y - pad)
			var x1 := mini(img.get_width(), box.end.x + pad)
			var y1 := mini(img.get_height(), box.end.y + pad)
			var crop := img.get_region(Rect2i(x0, y0, x1 - x0, y1 - y0))
			_flood_edge_black(crop)
			var fitted := _fit_canvas(crop, OUT, OUT)
			var path := "%s/%s_%s-%s.png" % [out_dir, set_id, slot_name, suffix]
			fitted.save_png(ProjectSettings.globalize_path(path))
			saved.append(path)
	return saved

static func _find_blobs(img: Image) -> Array:
	var w := img.get_width()
	var h := img.get_height()
	var seen := PackedByteArray()
	seen.resize(w * h)
	var blobs: Array = []
	for y in h:
		for x in w:
			if seen[y * w + x] != 0 or not _is_ink(img.get_pixel(x, y)):
				continue
			var cells: Array[Vector2i] = []
			var q: Array[Vector2i] = [Vector2i(x, y)]
			seen[y * w + x] = 1
			var minx := x
			var maxx := x
			var miny := y
			var maxy := y
			var sx := 0
			var sy := 0
			while not q.is_empty():
				var p: Vector2i = q.pop_front()
				cells.append(p)
				sx += p.x
				sy += p.y
				minx = mini(minx, p.x)
				maxx = maxi(maxx, p.x)
				miny = mini(miny, p.y)
				maxy = maxi(maxy, p.y)
				for d in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
					var n: Vector2i = p + d
					if n.x < 0 or n.y < 0 or n.x >= w or n.y >= h:
						continue
					var i := n.y * w + n.x
					if seen[i] != 0:
						continue
					if not _is_ink(img.get_pixel(n.x, n.y)):
						continue
					seen[i] = 1
					q.append(n)
			var ncells := cells.size()
			if ncells < MIN_BLOB:
				continue
			blobs.append({
				"n": ncells,
				"cx": float(sx) / float(ncells),
				"cy": float(sy) / float(ncells),
				"box": Rect2i(minx, miny, maxx - minx + 1, maxy - miny + 1),
			})
	return blobs

static func _is_ink(c: Color) -> bool:
	if c.a < 0.03:
		return false
	return c.r > 0.07 or c.g > 0.07 or c.b > 0.07

static func _classify(blobs: Array, width: int) -> Dictionary:
	var front: Array = []
	var side: Array = []
	for blob in blobs:
		if float(blob["cx"]) < float(width) * 0.48:
			front.append(blob)
		else:
			side.append(blob)
	if front.size() != 6 or side.size() != 6:
		push_error("Expected 6+6 parts, got %d+%d" % [front.size(), side.size()])
		return {}
	return {
		"front": _name_group(front),
		"profile": _name_group(side),
	}

static func _name_group(group: Array) -> Dictionary:
	var ordered := group.duplicate()
	ordered.sort_custom(func(a, b): return a["cy"] < b["cy"])
	var head: Dictionary = ordered[0]
	var rest: Array = ordered.slice(1)
	var torso: Dictionary = rest[0]
	for blob in rest:
		if int(blob["n"]) > int(torso["n"]):
			torso = blob
	var limbs: Array = []
	for blob in rest:
		if blob != torso:
			limbs.append(blob)
	limbs.sort_custom(func(a, b): return a["cy"] < b["cy"])
	if limbs.size() != 4:
		return {}
	var arms: Array = [limbs[0], limbs[1]]
	var legs: Array = [limbs[2], limbs[3]]
	arms.sort_custom(func(a, b): return a["cx"] < b["cx"])
	legs.sort_custom(func(a, b): return a["cx"] < b["cx"])
	return {
		"head": head,
		"body": torso,
		"arm_l": arms[0],
		"arm_r": arms[1],
		"leg_l": legs[0],
		"leg_r": legs[1],
	}

static func _flood_edge_black(im: Image) -> void:
	var w := im.get_width()
	var h := im.get_height()
	var seen := {}
	var q: Array[Vector2i] = []
	for x in w:
		q.append(Vector2i(x, 0))
		q.append(Vector2i(x, h - 1))
	for y in h:
		q.append(Vector2i(0, y))
		q.append(Vector2i(w - 1, y))
	while not q.is_empty():
		var p: Vector2i = q.pop_front()
		var key := p.x * 100000 + p.y
		if seen.has(key):
			continue
		if p.x < 0 or p.y < 0 or p.x >= w or p.y >= h:
			continue
		seen[key] = true
		var c := im.get_pixel(p.x, p.y)
		if c.a >= 0.04 and not (c.r <= 0.05 and c.g <= 0.05 and c.b <= 0.05):
			continue
		im.set_pixel(p.x, p.y, Color(c.r, c.g, c.b, 0.0))
		q.append(Vector2i(p.x - 1, p.y))
		q.append(Vector2i(p.x + 1, p.y))
		q.append(Vector2i(p.x, p.y - 1))
		q.append(Vector2i(p.x, p.y + 1))

static func _fit_canvas(im: Image, width: int, height: int) -> Image:
	if im.get_width() == width and im.get_height() == height:
		return im
	var used := im.get_used_rect()
	if used.size.x <= 0 or used.size.y <= 0:
		var empty := Image.create(width, height, false, Image.FORMAT_RGBA8)
		empty.fill(Color(0, 0, 0, 0))
		return empty
	var cropped := im.get_region(used)
	var scale := minf(float(width) / float(cropped.get_width()), float(height) / float(cropped.get_height()))
	var nw := maxi(1, int(round(float(cropped.get_width()) * scale)))
	var nh := maxi(1, int(round(float(cropped.get_height()) * scale)))
	cropped.resize(nw, nh, Image.INTERPOLATE_LANCZOS)
	var canvas := Image.create(width, height, false, Image.FORMAT_RGBA8)
	canvas.fill(Color(0, 0, 0, 0))
	canvas.blit_rect(cropped, Rect2i(0, 0, nw, nh), Vector2i((width - nw) / 2, (height - nh) / 2))
	return canvas
