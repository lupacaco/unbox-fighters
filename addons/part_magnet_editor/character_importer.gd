@tool
extends RefCounted

const SheetSlicer := preload("res://addons/part_magnet_editor/sheet_slicer.gd")

const SLOT_NAMES: PackedStringArray = ["head", "body", "arm_l", "arm_r", "leg_l", "leg_r"]
const SLOT_LABELS: PackedStringArray = ["Cabeça", "Tronco", "Braço E", "Braço D", "Perna E", "Perna D"]
const SLOT_TYPES: Array[PartSlotType.Value] = [
	PartSlotType.Value.HEAD,
	PartSlotType.Value.BODY,
	PartSlotType.Value.ARM_L,
	PartSlotType.Value.ARM_R,
	PartSlotType.Value.LEG_L,
	PartSlotType.Value.LEG_R,
]

static func slice_sheet(sheet_path: String, set_id: String) -> PackedStringArray:
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
	if values.size() < 3:
		return "Faltam os 3 números da loja (cabeça, tronco, pernas)."

	var visual_values: Array = _visual_values(values)
	var legs_value := int(values[2]) if values.size() == 3 else int(values[4])
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

	var legs_kit := _make_legs_kit(set_id, display_name, legs_value)
	var legs_path := "res://data/parts/%s_legs.tres" % set_id
	var legs_err := ResourceSaver.save(legs_kit, legs_path)
	if legs_err != OK:
		return "Falha ao salvar %s" % legs_path

	var character := CharacterDef.new()
	character.id = StringName(set_id)
	character.display_name = display_name
	character.head = parts[0]
	character.body = parts[1]
	character.arm_l = parts[2]
	character.arm_r = parts[3]
	character.leg_l = parts[4]
	character.leg_r = parts[5]
	character.legs = load(legs_path) as PartDef
	var char_path := "res://data/parts/%s_character.tres" % set_id
	var char_err := ResourceSaver.save(character, char_path)
	if char_err != OK:
		return "Falha ao salvar %s" % char_path

	ShopPool.reload()
	return ""

static func _visual_values(values: Array) -> Array:
	if values.size() >= 6:
		return values
	return [int(values[0]), int(values[1]), int(values[1]), int(values[1]), int(values[2]), int(values[2])]

static func _make_legs_kit(set_id: String, display_name: String, combat_value: int) -> PartDef:
	var part := PartDef.new()
	part.id = StringName("%s_legs" % set_id)
	part.display_name = "%s Pernas" % display_name
	part.slot_type = PartSlotType.Value.LEGS
	part.set_id = StringName(set_id)
	part.combat_value = combat_value
	part.tier = PartDef.tier_for(combat_value)
	return part

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
