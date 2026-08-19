@tool
extends RefCounted

## Edits the card of an existing Freak: name, type, power, Attack, and HP.
## Drawings and magnets stay as they are. The folder id does not change.

const CharacterImporter := preload("res://addons/part_magnet_editor/character_importer.gd")

const PARTS_DIR := "res://data/parts"


static func list_sets() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for set_id in _ids_on_disk():
		var snap := read(set_id)
		if not String(snap.get("error", "")).is_empty():
			continue
		rows.append(snap)
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return String(a["display_name"]) < String(b["display_name"])
	)
	return rows


static func read(set_id: String) -> Dictionary:
	set_id = CharacterImporter.clean_id(set_id)
	var empty := {
		"id": set_id,
		"display_name": "",
		"attack": PartStats.ATTACK_MIN,
		"hp": PartStats.HP_MIN,
		"kind": int(FreakKind.Value.HUMAN),
		"ability": int(FreakAbility.Value.NONE),
		"kind_label": "",
		"ability_label": "",
		"head_price": 0,
		"body_price": 0,
		"error": "",
	}
	if set_id.is_empty():
		empty["error"] = "Escolha um Freak da lista."
		return empty
	var character := _load_character(set_id)
	if character == null:
		empty["error"] = "Não achei a ficha deste Freak. Inclua ele antes de editar."
		return empty
	if character.head == null or character.body == null:
		empty["error"] = "Este Freak está incompleto. Falta cabeça ou corpo."
		return empty
	var attack := PartStats.clamp_for(PartSlotType.Value.HEAD, character.head.stat_value)
	var hp := PartStats.clamp_for(PartSlotType.Value.BODY, character.body.stat_value)
	var kind: FreakKind.Value = character.kind
	var ability: FreakAbility.Value = character.ability
	var display := character.display_name.strip_edges()
	if display.is_empty():
		display = set_id.capitalize()
	return {
		"id": set_id,
		"display_name": display,
		"attack": attack,
		"hp": hp,
		"kind": int(kind),
		"ability": int(ability),
		"kind_label": FreakKind.label(kind),
		"ability_label": FreakAbility.display_name(ability),
		"head_price": PartStats.price_for(PartSlotType.Value.HEAD, attack),
		"body_price": PartStats.price_for(PartSlotType.Value.BODY, hp),
		"error": "",
	}


static func save(
	set_id: String,
	display_name: String,
	attack: int,
	hp: int,
	kind: FreakKind.Value,
	ability: FreakAbility.Value
) -> String:
	set_id = CharacterImporter.clean_id(set_id)
	if set_id.is_empty():
		return "Escolha um Freak da lista."
	display_name = display_name.strip_edges()
	if display_name.is_empty():
		return "O nome na carta não pode ficar vazio."
	attack = PartStats.clamp_for(PartSlotType.Value.HEAD, attack)
	hp = PartStats.clamp_for(PartSlotType.Value.BODY, hp)
	var character := _load_character(set_id)
	if character == null:
		return "Não achei a ficha deste Freak. Inclua ele antes de editar."
	if character.head == null or character.body == null:
		return "Este Freak está incompleto. Falta cabeça ou corpo."

	character.display_name = display_name
	character.kind = kind
	character.ability = ability
	_apply_part(character.head, display_name, PartSlotType.Value.HEAD, attack)
	_apply_part(character.body, display_name, PartSlotType.Value.BODY, hp)
	_apply_part(character.arm_l, display_name, PartSlotType.Value.ARM_L, hp)
	_apply_part(character.arm_r, display_name, PartSlotType.Value.ARM_R, hp)
	if character.arms != null:
		character.arms.display_name = "%s %s" % [display_name, CharacterImporter.ARMS_LABEL]

	var err := _save_part(character.head)
	if not err.is_empty():
		return err
	err = _save_part(character.body)
	if not err.is_empty():
		return err
	err = _save_part(character.arm_l)
	if not err.is_empty():
		return err
	err = _save_part(character.arm_r)
	if not err.is_empty():
		return err
	err = _save_part(character.arms)
	if not err.is_empty():
		return err
	var char_path := character.resource_path
	if char_path.is_empty():
		char_path = "%s/%s_character.tres" % [PARTS_DIR, set_id]
	if ResourceSaver.save(character, char_path) != OK:
		return "Não consegui gravar a ficha %s." % char_path.get_file()

	err = _update_slice_report(set_id, display_name, attack, hp, kind, ability)
	if not err.is_empty():
		return err
	ShopPool.reload()
	return ""


static func price_line(attack: int, hp: int) -> String:
	attack = PartStats.clamp_for(PartSlotType.Value.HEAD, attack)
	hp = PartStats.clamp_for(PartSlotType.Value.BODY, hp)
	return "Na loja: cabeça $%d · corpo $%d" % [
		PartStats.price_for(PartSlotType.Value.HEAD, attack),
		PartStats.price_for(PartSlotType.Value.BODY, hp),
	]


static func _apply_part(
	part: PartDef, display_name: String, slot: PartSlotType.Value, value: int
) -> void:
	if part == null:
		return
	var label := _slot_label(slot)
	if not label.is_empty():
		part.display_name = "%s %s" % [display_name, label]
	part.stat_value = value
	part.tier = PartStats.tier_for(slot, value)


static func _slot_label(slot: PartSlotType.Value) -> String:
	var idx := CharacterImporter.SLOT_TYPES.find(slot)
	if idx < 0:
		return ""
	return CharacterImporter.SLOT_LABELS[idx]


static func _save_part(part: PartDef) -> String:
	if part == null:
		return ""
	var path := part.resource_path
	if path.is_empty():
		return ""
	if ResourceSaver.save(part, path) != OK:
		return "Não consegui gravar %s." % path.get_file()
	return ""


static func _load_character(set_id: String) -> CharacterDef:
	var path := "%s/%s_character.tres" % [PARTS_DIR, set_id]
	if not ResourceLoader.exists(path):
		return null
	return ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REPLACE) as CharacterDef


static func _ids_on_disk() -> PackedStringArray:
	var ids: PackedStringArray = []
	var dir := DirAccess.open(PARTS_DIR)
	if dir == null:
		return ids
	dir.list_dir_begin()
	var fname := dir.get_next()
	while fname != "":
		if not dir.current_is_dir() and fname.ends_with("_character.tres"):
			var set_id := CharacterImporter.clean_id(fname.trim_suffix("_character.tres"))
			if not set_id.is_empty() and set_id not in ids:
				ids.append(set_id)
		fname = dir.get_next()
	return ids


static func _update_slice_report(
	set_id: String,
	display_name: String,
	attack: int,
	hp: int,
	kind: FreakKind.Value,
	ability: FreakAbility.Value
) -> String:
	var path := "res://assets/characters/%s/%s_slice.json" % [set_id, set_id]
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return "Não consegui ler %s." % path.get_file()
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return "O arquivo %s está ilegível." % path.get_file()
	var report: Dictionary = parsed
	report["display_name"] = display_name
	report["stats"] = {"attack": attack, "hp": hp}
	report["kind"] = FreakKind.storage_key(kind)
	report["ability"] = FreakAbility.storage_key(ability)
	var out := FileAccess.open(path, FileAccess.WRITE)
	if out == null:
		return "Não consegui gravar %s." % path.get_file()
	out.store_string(JSON.stringify(report, "\t"))
	out.store_string("\n")
	return ""
