@tool
extends RefCounted

## Cuts a 3×3 character sheet into nine 300×200 PNGs with edge-black made transparent.

const OUT_W := 300
const OUT_H := 200
const SLOTS: PackedStringArray = ["head", "body", "legs"]
const POSES: PackedStringArray = ["1", "2", "3"]

static func slice_to_folder(sheet_path: String, set_id: String) -> PackedStringArray:
	var img := Image.new()
	var err := img.load(sheet_path)
	if err != OK:
		push_error("Could not load sheet: %s (%s)" % [sheet_path, err])
		return PackedStringArray()
	img.convert(Image.FORMAT_RGBA8)
	if img.get_width() < 3 or img.get_height() < 3:
		push_error("Sheet too small: %s" % sheet_path)
		return PackedStringArray()

	var cell_w := int(img.get_width() / 3)
	var cell_h := int(img.get_height() / 3)
	var out_dir := "res://assets/characters/%s" % set_id
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))

	var saved: PackedStringArray = []
	for row in 3:
		for col in 3:
			var cell := img.get_region(Rect2i(col * cell_w, row * cell_h, cell_w, cell_h))
			_flood_edge_black(cell)
			var fitted := _fit_canvas(cell, OUT_W, OUT_H)
			var path := "%s/%s_%s-%s.png" % [out_dir, set_id, SLOTS[row], POSES[col]]
			fitted.save_png(ProjectSettings.globalize_path(path))
			saved.append(path)
	return saved

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
		var key := p.x * 10000 + p.y
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
