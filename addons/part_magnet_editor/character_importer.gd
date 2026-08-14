@tool
extends RefCounted

const SheetSlicer := preload("res://addons/part_magnet_editor/sheet_slicer.gd")

const SLOT_NAMES: PackedStringArray = ["head", "body", "arm_l", "arm_r"]
const SLOT_LABELS: PackedStringArray = ["Cabeça", "Tronco", "Braço E", "Braço D"]
const SLOT_TYPES: Array[PartSlotType.Value] = [
	PartSlotType.Value.HEAD,
	PartSlotType.Value.BODY,
	PartSlotType.Value.ARM_L,
	PartSlotType.Value.ARM_R,
]

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


static func write_defs(set_id: String, display_name: String, values: Array) -> String:
	set_id = clean_id(set_id)
	if set_id.is_empty():
		return "O id interno precisa ser minúsculo, sem acento. Exemplo: leao."
	if display_name.strip_edges().is_empty():
		display_name = set_id.capitalize()
	if values.size() < 2:
		return "Faltam os 2 números da loja (cabeça, tronco)."

	var visual_values: Array = _visual_values(values)
	var parts: Array[PartDef] = []
	for i in SLOT_NAMES.size():
		var slot_name: String = SLOT_NAMES[i]
		var tex1 := load("res://assets/characters/%s/%s_%s-1.png" % [set_id, set_id, slot_name]) as Texture2D
		if tex1 == null:
			return "Ainda não achei as imagens de %s. Espere o Godot importar e tente de novo." % slot_name
		var part := _make_part(set_id, display_name, slot_name, SLOT_TYPES[i], int(visual_values[i]))
		var path := "res://data/parts/%s_%s.tres" % [set_id, slot_name]
		var save_err := ResourceSaver.save(part, path)
		if save_err != OK:
			return "Falha ao salvar %s" % path
		parts.append(load(path) as PartDef)

	var character := CharacterDef.new()
	character.id = StringName(set_id)
	character.display_name = display_name
	character.head = parts[0]
	character.body = parts[1]
	character.arm_l = parts[2]
	character.arm_r = parts[3]
	var char_path := "res://data/parts/%s_character.tres" % set_id
	var char_err := ResourceSaver.save(character, char_path)
	if char_err != OK:
		return "Falha ao salvar %s" % char_path

	ShopPool.reload()
	return ""

static func _visual_values(values: Array) -> Array:
	if values.size() >= 4:
		return [int(values[0]), int(values[1]), int(values[2]), int(values[3])]
	return [int(values[0]), int(values[1]), int(values[1]), int(values[1])]

static func _make_part(
	set_id: String,
	display_name: String,
	slot_name: String,
	slot_type: PartSlotType.Value,
	combat_value: int
) -> PartDef:
	var part := PartDef.new()
	part.id = StringName("%s_%s" % [set_id, slot_name])
	part.display_name = "%s %s" % [display_name, SLOT_LABELS[SLOT_NAMES.find(slot_name)]]
	part.slot_type = slot_type
	part.set_id = StringName(set_id)
	part.combat_value = combat_value
	part.tier = PartDef.tier_for(combat_value)
	part.sprite = load("res://assets/characters/%s/%s_%s-1.png" % [set_id, set_id, slot_name]) as Texture2D
	part.sprite_profile = load("res://assets/characters/%s/%s_%s-2.png" % [set_id, set_id, slot_name]) as Texture2D
	match slot_type:
		PartSlotType.Value.HEAD:
			part.magnet_down = CompositeResolver.DEFAULT_HEAD_DOWN
			part.magnet_down_profile = CompositeResolver.DEFAULT_HEAD_DOWN
		PartSlotType.Value.BODY:
			part.magnet_neck = CompositeResolver.DEFAULT_NECK
			part.magnet_shoulder_l = CompositeResolver.DEFAULT_SHOULDER_L
			part.magnet_shoulder_r = CompositeResolver.DEFAULT_SHOULDER_R
			part.magnet_hip_l = CompositeResolver.DEFAULT_HIP_L
			part.magnet_hip_r = CompositeResolver.DEFAULT_HIP_R
			part.magnet_neck_profile = CompositeResolver.DEFAULT_NECK
			part.magnet_shoulder_l_profile = CompositeResolver.DEFAULT_SHOULDER_L
			part.magnet_shoulder_r_profile = CompositeResolver.DEFAULT_SHOULDER_R
			part.magnet_hip_l_profile = CompositeResolver.DEFAULT_HIP_L
			part.magnet_hip_r_profile = CompositeResolver.DEFAULT_HIP_R
		_:
			part.magnet_up = CompositeResolver.DEFAULT_LIMB_UP
			part.magnet_up_profile = CompositeResolver.DEFAULT_LIMB_UP
	return part

static func replace_part_image(source_path: String, dest_res: String) -> String:
	if source_path.is_empty() or dest_res.is_empty():
		return "Escolha um arquivo de imagem."
	var img := Image.new()
	var err := img.load(source_path)
	if err != OK:
		err = _load_image_bytes(img, source_path)
	if err != OK:
		return "Não consegui ler essa imagem. Use PNG ou WEBP."
	img = fit_to_square(img, int(CompositeResolver.PART_SIZE_PX))
	var abs_dest := ProjectSettings.globalize_path(dest_res) if dest_res.begins_with("res://") else dest_res
	var folder := abs_dest.get_base_dir()
	if not DirAccess.dir_exists_absolute(folder):
		DirAccess.make_dir_recursive_absolute(folder)
	if abs_dest.get_extension().to_lower() == "webp":
		err = img.save_webp(abs_dest)
	else:
		err = img.save_png(abs_dest)
	if err != OK:
		return "Não consegui gravar a imagem no projeto."
	return ""


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


static func _load_image_bytes(img: Image, source_path: String) -> Error:
	var bytes := FileAccess.get_file_as_bytes(source_path)
	if bytes.is_empty():
		return ERR_CANT_OPEN
	var ext := source_path.get_extension().to_lower()
	if ext == "webp":
		return img.load_webp_from_buffer(bytes)
	return img.load_png_from_buffer(bytes)


static func part_image_path(part: PartDef, pose: int) -> String:
	if part == null:
		return ""
	var tex := part.texture_for_pose(pose)
	if tex != null and not tex.resource_path.is_empty():
		return tex.resource_path
	var set_id := String(part.set_id)
	var slot := String(PartSlotType.to_string_name(part.slot_type))
	if set_id.is_empty() or slot.is_empty() or slot == "unknown" or slot == "legs":
		return ""
	var suffix := "2" if pose == 1 else "1"
	return "res://assets/characters/%s/%s_%s-%s.png" % [set_id, set_id, slot, suffix]


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
