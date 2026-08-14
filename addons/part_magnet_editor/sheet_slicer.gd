@tool
extends RefCounted

## Finds 4 front + 4 profile parts on a sheet and saves each in a 200×200 PNG.

const OUT := 200
const MIN_BLOB := 400
const SLOT_NAMES: PackedStringArray = ["head", "body", "arm_l", "arm_r"]

static func slice_to_folder(sheet_path: String, set_id: String) -> Dictionary:
	if set_id.is_empty():
		return _fail("O id interno precisa ser minúsculo, sem acento. Exemplo: leao.")
	var img := Image.new()
	var err := img.load(sheet_path)
	if err != OK:
		var abs_path := ProjectSettings.globalize_path(sheet_path) if sheet_path.begins_with("res://") else sheet_path
		err = img.load(abs_path)
	if err != OK:
		return _fail("Não consegui abrir essa imagem. Use PNG ou WEBP.")
	if img.get_format() != Image.FORMAT_RGBA8:
		img.convert(Image.FORMAT_RGBA8)
	var keep_dark := _uses_alpha_background(img)
	var blobs := _find_blobs(img, keep_dark)
	var named := _classify(blobs, img.get_width(), img.get_height())
	if not _named_ok(named):
		keep_dark = not keep_dark
		blobs = _find_blobs(img, keep_dark)
		named = _classify(blobs, img.get_width(), img.get_height())
	var classify_err := String(named.get("error", ""))
	if not classify_err.is_empty():
		return _fail(classify_err)
	if not _group_complete(named.get("front", {})) or not _group_complete(named.get("profile", {})):
		return _fail("Achei os recortes, mas não soube o que é cabeça, tronco e braço. Separe bem as 4 peças de frente e as 4 de perfil.")

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
			_flood_edge_black(crop, keep_dark)
			var fitted := _fit_canvas(crop, OUT, OUT)
			var path := "%s/%s_%s-%s.png" % [out_dir, set_id, slot_name, suffix]
			fitted.save_png(ProjectSettings.globalize_path(path))
			saved.append(path)
	if saved.size() != 8:
		return _fail("O corte não gerou as 8 imagens.")
	return {"saved": saved, "error": ""}

static func _fail(message: String) -> Dictionary:
	return {"saved": PackedStringArray(), "error": message}

static func _group_complete(group: Dictionary) -> bool:
	if group.is_empty():
		return false
	for slot_name in SLOT_NAMES:
		if not group.has(slot_name):
			return false
	return true

static func _named_ok(named: Dictionary) -> bool:
	if not String(named.get("error", "")).is_empty():
		return false
	return _group_complete(named.get("front", {})) and _group_complete(named.get("profile", {}))

static func _uses_alpha_background(img: Image) -> bool:
	var w := img.get_width()
	var h := img.get_height()
	var hits := 0
	for p in [
		Vector2i(0, 0),
		Vector2i(w - 1, 0),
		Vector2i(0, h - 1),
		Vector2i(w - 1, h - 1),
		Vector2i(int(w / 2.0), 0),
		Vector2i(0, int(h / 2.0)),
	]:
		if img.get_pixel(p.x, p.y).a < 0.04:
			hits += 1
	return hits >= 4

static func _find_blobs(img: Image, opaque_is_ink: bool) -> Array:
	var w := img.get_width()
	var h := img.get_height()
	var data := img.get_data()
	var seen := PackedByteArray()
	seen.resize(w * h)
	var blobs: Array = []
	for y in h:
		for x in w:
			var idx := y * w + x
			if seen[idx] != 0 or not _is_ink_at(data, idx, opaque_is_ink):
				continue
			var q: Array[Vector2i] = [Vector2i(x, y)]
			var qi := 0
			seen[idx] = 1
			var minx := x
			var maxx := x
			var miny := y
			var maxy := y
			var sx := 0
			var sy := 0
			var ncells := 0
			while qi < q.size():
				var p: Vector2i = q[qi]
				qi += 1
				ncells += 1
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
					var ni := n.y * w + n.x
					if seen[ni] != 0:
						continue
					if not _is_ink_at(data, ni, opaque_is_ink):
						continue
					seen[ni] = 1
					q.append(n)
			if ncells < MIN_BLOB:
				continue
			blobs.append({
				"n": ncells,
				"cx": float(sx) / float(ncells),
				"cy": float(sy) / float(ncells),
				"box": Rect2i(minx, miny, maxx - minx + 1, maxy - miny + 1),
			})
	return blobs

static func _is_ink_at(data: PackedByteArray, pixel: int, opaque_is_ink: bool) -> bool:
	var i := pixel * 4
	if data[i + 3] < 8:
		return false
	if opaque_is_ink:
		return true
	return data[i] > 18 or data[i + 1] > 18 or data[i + 2] > 18

static func _classify(blobs: Array, width: int, height: int) -> Dictionary:
	var left: Array = []
	var right: Array = []
	var top: Array = []
	var bottom: Array = []
	for blob in blobs:
		if float(blob["cx"]) < float(width) * 0.48:
			left.append(blob)
		else:
			right.append(blob)
		if float(blob["cy"]) < float(height) * 0.48:
			top.append(blob)
		else:
			bottom.append(blob)
	if left.size() == 4 and right.size() == 4:
		return {"front": _name_group(left), "profile": _name_group(right), "error": ""}
	if top.size() == 4 and bottom.size() == 4:
		return {"front": _name_group(top), "profile": _name_group(bottom), "error": ""}
	if left.size() == 6 and right.size() == 6:
		return {"front": _name_group(left), "profile": _name_group(right), "error": ""}
	if top.size() == 6 and bottom.size() == 6:
		return {"front": _name_group(top), "profile": _name_group(bottom), "error": ""}
	return {
		"front": {},
		"profile": {},
		"error": "A folha precisa de 4 desenhos de frente e 4 de perfil, separados. Achei %d à esquerda, %d à direita, %d em cima e %d embaixo. Se o Freak tem roupa preta, use PNG com fundo transparente (não JPG)." % [left.size(), right.size(), top.size(), bottom.size()],
	}

static func _name_group(group: Array) -> Dictionary:
	if group.size() == 4:
		return _name_four(group)
	if group.size() == 6:
		return _name_six(group)
	return {}

static func _name_four(group: Array) -> Dictionary:
	var ordered := group.duplicate()
	ordered.sort_custom(func(a, b): return a["cy"] < b["cy"])
	var head: Dictionary = ordered[0]
	var rest: Array = ordered.slice(1)
	var torso: Dictionary = rest[0]
	for blob in rest:
		if int(blob["n"]) > int(torso["n"]):
			torso = blob
	var arms: Array = []
	for blob in rest:
		if blob != torso:
			arms.append(blob)
	if arms.size() != 2:
		return {}
	arms.sort_custom(func(a, b): return a["cx"] < b["cx"])
	return {
		"head": head,
		"body": torso,
		"arm_l": arms[0],
		"arm_r": arms[1],
	}

static func _name_six(group: Array) -> Dictionary:
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
	if limbs.size() != 4:
		return {}
	var xs: Array[float] = []
	var ys: Array[float] = []
	for blob in limbs:
		xs.append(float(blob["cx"]))
		ys.append(float(blob["cy"]))
	var arms: Array
	var legs: Array
	if xs.max() - xs.min() > (ys.max() - ys.min()) * 1.4:
		limbs.sort_custom(func(a, b): return a["cx"] < b["cx"])
		arms = [limbs[0], limbs[1]]
		legs = [limbs[2], limbs[3]]
	else:
		limbs.sort_custom(func(a, b): return a["cy"] < b["cy"])
		arms = [limbs[0], limbs[1]]
		legs = [limbs[2], limbs[3]]
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

static func _flood_edge_black(im: Image, keep_dark_clothes: bool = false) -> void:
	var w := im.get_width()
	var h := im.get_height()
	var seen := PackedByteArray()
	seen.resize(w * h)
	var q: Array[Vector2i] = []
	for x in w:
		q.append(Vector2i(x, 0))
		q.append(Vector2i(x, h - 1))
	for y in h:
		q.append(Vector2i(0, y))
		q.append(Vector2i(w - 1, y))
	var qi := 0
	while qi < q.size():
		var p: Vector2i = q[qi]
		qi += 1
		if p.x < 0 or p.y < 0 or p.x >= w or p.y >= h:
			continue
		var idx := p.y * w + p.x
		if seen[idx] != 0:
			continue
		seen[idx] = 1
		var c := im.get_pixel(p.x, p.y)
		if not _is_sheet_background(c, keep_dark_clothes):
			continue
		im.set_pixel(p.x, p.y, Color(c.r, c.g, c.b, 0.0))
		q.append(Vector2i(p.x - 1, p.y))
		q.append(Vector2i(p.x + 1, p.y))
		q.append(Vector2i(p.x, p.y - 1))
		q.append(Vector2i(p.x, p.y + 1))

static func _is_sheet_background(c: Color, keep_dark_clothes: bool) -> bool:
	if c.a < 0.04:
		return true
	if keep_dark_clothes:
		return false
	return c.r <= 0.05 and c.g <= 0.05 and c.b <= 0.05

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
