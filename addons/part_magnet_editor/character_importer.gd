@tool
extends RefCounted

## Turns a sliced sheet into the resources the game reads: four drawings, the
## arm kit that carries both arms, and the character card that ties them together.
##
## When the Python slicer left a `{id}_slice.json` next to the drawings, the
## magnets come from it. Otherwise every part starts on the safe default spot
## and you nudge them in Project → Tools → Ímãs das Peças.

const SheetSlicer := preload("res://addons/part_magnet_editor/sheet_slicer.gd")

const SLOT_NAMES: PackedStringArray = ["head", "body", "arm_l", "arm_r"]
const SLOT_LABELS: PackedStringArray = ["Cabeça", "Tronco", "Braço E", "Braço D"]
const SLOT_TYPES: Array[PartSlotType.Value] = [
	PartSlotType.Value.HEAD,
	PartSlotType.Value.BODY,
	PartSlotType.Value.ARM_L,
	PartSlotType.Value.ARM_R,
]
const ARMS_LABEL := "Braços"

static func slice_sheet(sheet_path: String, set_id: String) -> Dictionary:
	return SheetSlicer.slice_to_folder(sheet_path, set_id)


static func keep_source_sheet(sheet_path: String, set_id: String) -> void:
	set_id = clean_id(set_id)
	if set_id.is_empty() or sheet_path.is_empty():
		return
	var abs_sheet := ProjectSettings.globalize_path(sheet_path) if sheet_path.begins_with("res://") else sheet_path
	if not FileAccess.file_exists(abs_sheet):
		return
	var ext := abs_sheet.get_extension()
	if ext.is_empty():
		ext = "png"
	var keep := ProjectSettings.globalize_path("res://assets/characters/%s/%s.%s" % [set_id, set_id, ext])
	if abs_sheet != keep:
		DirAccess.copy_absolute(abs_sheet, keep)


## `values` is [Poder, Resistência, Agilidade]. Returns "" when everything saved.
static func write_defs(set_id: String, display_name: String, values: Array) -> String:
	set_id = clean_id(set_id)
	if set_id.is_empty():
		return "O id interno precisa ser minúsculo, sem acento. Exemplo: bruxa."
	if display_name.strip_edges().is_empty():
		display_name = set_id.capitalize()
	if values.size() < 3:
		return "Faltam os 3 números: Poder, Resistência e Agilidade."

	var magnets := read_slice_magnets(set_id)
	var stats := _stat_per_slot(values)
	var parts: Array[PartDef] = []
	for i in SLOT_NAMES.size():
		var slot_name: String = SLOT_NAMES[i]
		var slot_type: PartSlotType.Value = SLOT_TYPES[i]
		if load(_art_path(set_id, slot_name, 1)) == null:
			return "Ainda não achei as imagens de %s. Espere o Godot importar e tente de novo." % slot_name
		var part := _make_part(
			set_id, display_name, slot_name, slot_type, int(stats[slot_type]), magnets
		)
		var path := "res://data/parts/%s_%s.tres" % [set_id, slot_name]
		if ResourceSaver.save(part, path) != OK:
			return "Falha ao salvar %s" % path
		parts.append(load(path) as PartDef)

	var arms := _make_arms_kit(set_id, display_name, int(values[2]), parts[2], parts[3])
	var arms_path := "res://data/parts/%s_arms.tres" % set_id
	if ResourceSaver.save(arms, arms_path) != OK:
		return "Falha ao salvar %s" % arms_path

	var character := CharacterDef.new()
	character.id = StringName(set_id)
	character.display_name = display_name
	character.head = parts[0]
	character.body = parts[1]
	character.arm_l = parts[2]
	character.arm_r = parts[3]
	character.arms = load(arms_path) as PartDef
	var char_path := "res://data/parts/%s_character.tres" % set_id
	if ResourceSaver.save(character, char_path) != OK:
		return "Falha ao salvar %s" % char_path

	ShopPool.reload()
	return ""


## Magnets the slicer found, as {pose: {slot_name: {socket: Vector2}}}.
static func read_slice_magnets(set_id: String) -> Dictionary:
	var path := "res://assets/characters/%s/%s_slice.json" % [set_id, set_id]
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	var raw: Variant = (parsed as Dictionary).get("magnets", {})
	if typeof(raw) != TYPE_DICTIONARY:
		return {}
	var out := {}
	for pose_name in (raw as Dictionary).keys():
		var slots: Dictionary = (raw as Dictionary)[pose_name]
		var by_slot := {}
		for slot_name in slots.keys():
			var sockets: Dictionary = slots[slot_name]
			var points := {}
			for socket in sockets.keys():
				var pair: Array = sockets[socket]
				if pair.size() >= 2:
					points[socket] = Vector2(float(pair[0]), float(pair[1]))
			by_slot[slot_name] = points
		out[pose_name] = by_slot
	return out


static func _stat_per_slot(values: Array) -> Dictionary:
	return {
		PartSlotType.Value.HEAD: PartStats.clamp_for(PartSlotType.Value.HEAD, int(values[0])),
		PartSlotType.Value.BODY: PartStats.clamp_for(PartSlotType.Value.BODY, int(values[1])),
		PartSlotType.Value.ARM_L: PartStats.clamp_for(PartSlotType.Value.ARM_L, int(values[2])),
		PartSlotType.Value.ARM_R: PartStats.clamp_for(PartSlotType.Value.ARM_R, int(values[2])),
	}


static func _art_path(set_id: String, slot_name: String, pose: int) -> String:
	return "res://assets/characters/%s/%s_%s-%d.png" % [set_id, set_id, slot_name, pose]


static func _make_part(
	set_id: String,
	display_name: String,
	slot_name: String,
	slot_type: PartSlotType.Value,
	stat_value: int,
	magnets: Dictionary
) -> PartDef:
	var part := PartDef.new()
	part.id = StringName("%s_%s" % [set_id, slot_name])
	part.display_name = "%s %s" % [display_name, SLOT_LABELS[SLOT_NAMES.find(slot_name)]]
	part.slot_type = slot_type
	part.set_id = StringName(set_id)
	part.stat_value = stat_value
	part.tier = PartStats.tier_for(slot_type, stat_value)
	part.sprite = load(_art_path(set_id, slot_name, 1)) as Texture2D
	part.sprite_profile = load(_art_path(set_id, slot_name, 2)) as Texture2D
	for pose in [0, 1]:
		var found: Dictionary = _magnets_for(magnets, pose, slot_name)
		for socket in part.socket_names():
			part.set_socket(socket, pose, _socket_value(found, socket))
	return part


static func _make_arms_kit(
	set_id: String, display_name: String, agility: int, arm_l: PartDef, arm_r: PartDef
) -> PartDef:
	var kit := PartDef.new()
	kit.id = StringName("%s_arms" % set_id)
	kit.display_name = "%s %s" % [display_name, ARMS_LABEL]
	kit.slot_type = PartSlotType.Value.ARMS
	kit.set_id = StringName(set_id)
	kit.stat_value = PartStats.clamp_for(PartSlotType.Value.ARMS, agility)
	kit.tier = PartStats.tier_for(PartSlotType.Value.ARMS, kit.stat_value)
	kit.kit_parts = [arm_l, arm_r]
	## Fallback drawing for anything that shows a kit as a single picture.
	kit.sprite = arm_r.sprite if arm_r != null else null
	kit.sprite_profile = arm_r.sprite_profile if arm_r != null else null
	return kit


static func _magnets_for(magnets: Dictionary, pose: int, slot_name: String) -> Dictionary:
	var pose_name := "profile" if pose == 1 else "front"
	var by_slot: Dictionary = magnets.get(pose_name, {})
	return by_slot.get(slot_name, {})


## The slicer calls the head and arm joint "join"; the game calls it down/up.
static func _socket_value(found: Dictionary, socket: String) -> Vector2:
	var key := socket
	if socket == "down" or socket == "up":
		key = "join"
	if found.has(key):
		return found[key]
	return CompositeResolver.default_socket(socket)


static func to_project_path(source_path: String) -> String:
	var path := source_path.strip_edges().replace("\\", "/")
	if path.is_empty():
		return ""
	if path.begins_with("res://"):
		return path
	var root := ProjectSettings.globalize_path("res://").replace("\\", "/").trim_suffix("/")
	if path.to_lower().begins_with(root.to_lower()):
		var rel := path.substr(root.length()).trim_prefix("/")
		if rel.is_empty():
			return ""
		return "res://" + rel
	return ""


static func character_art_folder(set_id: String) -> String:
	var id := String(set_id)
	if id.is_empty():
		return "res://assets/characters"
	return "res://assets/characters/%s" % id


static func fit_to_square(img: Image, side: int) -> Image:
	if img == null or side < 1:
		return img
	if img.get_format() != Image.FORMAT_RGBA8:
		img.convert(Image.FORMAT_RGBA8)
	var w := img.get_width()
	var h := img.get_height()
	if w == side and h == side:
		return img
	var scale := minf(float(side) / float(maxi(w, 1)), float(side) / float(maxi(h, 1)))
	var nw := maxi(1, int(round(float(w) * scale)))
	var nh := maxi(1, int(round(float(h) * scale)))
	img.resize(nw, nh, Image.INTERPOLATE_LANCZOS)
	var canvas := Image.create(side, side, false, Image.FORMAT_RGBA8)
	canvas.fill(Color(0, 0, 0, 0))
	canvas.blit_rect(img, Rect2i(0, 0, nw, nh), Vector2i(int((side - nw) / 2.0), int((side - nh) / 2.0)))
	return canvas


static func part_image_path(part: PartDef, pose: int) -> String:
	if part == null:
		return ""
	var tex := part.texture_for_pose(pose)
	if tex != null and not tex.resource_path.is_empty():
		return tex.resource_path
	var set_id := String(part.set_id)
	var slot := String(PartSlotType.to_string_name(part.slot_type))
	if set_id.is_empty() or slot == "unknown" or slot == "arms":
		return ""
	return _art_path(set_id, slot, 2 if pose == 1 else 1)


static func clean_id(raw: String) -> String:
	var s := raw.strip_edges().to_lower()
	s = s.replace("á", "a").replace("à", "a").replace("ã", "a").replace("â", "a")
	s = s.replace("é", "e").replace("ê", "e")
	s = s.replace("í", "i")
	s = s.replace("ó", "o").replace("ô", "o").replace("õ", "o")
	s = s.replace("ú", "u").replace("ü", "u")
	s = s.replace("ç", "c")
	var out := ""
	for i in s.length():
		var ch := s[i]
		if (ch >= "a" and ch <= "z") or (ch >= "0" and ch <= "9") or ch == "_":
			out += ch
	return out
