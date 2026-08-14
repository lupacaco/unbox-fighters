@tool
extends Window

## Two tabs (front / profile): six parts on the left, a large mix preview on the right.

const MagnetPartCard := preload("res://addons/part_magnet_editor/magnet_part_card.gd")
const MagnetMix := preload("res://addons/part_magnet_editor/magnet_mix.gd")

var _picker: OptionButton
var _help: Label
var _status: Label
var _front_cards: Array[Control] = []
var _profile_cards: Array[Control] = []
var _front_mix: Control
var _profile_mix: Control
var _tabs: TabContainer

var _characters: Array[CharacterDef] = []
var _character: CharacterDef
var _pending_part: PartDef
var _pending_set_id: String = ""

func _ready() -> void:
	title = "Ímãs das peças"
	min_size = Vector2i(880, 560)
	unresizable = false
	exclusive = false
	close_requested.connect(hide)
	_build_ui()
	_apply_pending()

func present(part: PartDef) -> void:
	_pending_part = part
	_pending_set_id = ""
	if is_node_ready():
		_apply_pending()

func present_character_id(set_id: String) -> void:
	_pending_part = null
	_pending_set_id = set_id
	if is_node_ready():
		_apply_pending()

func _apply_pending() -> void:
	_refresh_roster()
	if _characters.is_empty():
		_show_character(null)
		return
	var chosen: CharacterDef = null
	if not _pending_set_id.is_empty():
		chosen = _character_by_id(_pending_set_id)
	if chosen == null and _pending_part != null:
		chosen = _character_for_part(_pending_part)
	if chosen == null:
		chosen = _character_by_id("leao")
	if chosen == null:
		chosen = _characters[0]
	_select_character(chosen)

func _build_ui() -> void:
	var root := MarginContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("margin_left", 12)
	root.add_theme_constant_override("margin_top", 10)
	root.add_theme_constant_override("margin_right", 12)
	root.add_theme_constant_override("margin_bottom", 10)
	add_child(root)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(column)

	column.add_child(_build_toolbar())

	_help = Label.new()
	_help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_help.modulate = Color(0.78, 0.8, 0.84, 1)
	_help.text = "Frente e perfil em abas. À esquerda: as 6 partes (tipo, virar, girar, Z). Z 1 fica na frente. Arraste as bolinhas até as esferas de metal."
	column.add_child(_help)

	_tabs = TabContainer.new()
	_tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(_tabs)

	_tabs.add_child(_make_tab(0, "Frente"))
	_tabs.add_child(_make_tab(1, "Perfil"))

func _build_toolbar() -> Control:
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 10)
	var lab := Label.new()
	lab.text = "Freak"
	bar.add_child(lab)
	_picker = OptionButton.new()
	_picker.custom_minimum_size.x = 220
	_picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_picker.item_selected.connect(_on_freak_selected)
	bar.add_child(_picker)
	var save_btn := Button.new()
	save_btn.text = "Salvar"
	save_btn.custom_minimum_size = Vector2(110, 32)
	save_btn.pressed.connect(_save_all)
	bar.add_child(save_btn)
	_status = Label.new()
	_status.modulate = Color(0.7, 0.86, 0.62, 1)
	bar.add_child(_status)
	return bar

func _make_tab(pose: int, caption: String) -> Control:
	var tab := MarginContainer.new()
	tab.name = caption
	tab.add_theme_constant_override("margin_left", 6)
	tab.add_theme_constant_override("margin_top", 8)
	tab.add_theme_constant_override("margin_right", 6)
	tab.add_theme_constant_override("margin_bottom", 6)

	var row := HSplitContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.split_offset = 300
	tab.add_child(row)

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size.x = 280
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_stretch_ratio = 0.42
	row.add_child(scroll)

	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 8)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)

	var cards: Array[Control] = []
	for _i in PartSlotType.visual_slots().size():
		var card := MagnetPartCard.new()
		card.magnets_changed.connect(_refresh_mix)
		card.transform_changed.connect(_on_transform_changed)
		card.slot_chosen.connect(_on_slot_chosen)
		list.add_child(card)
		cards.append(card)
	if pose == 0:
		_front_cards = cards
	else:
		_profile_cards = cards

	var mix := MagnetMix.new()
	mix.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mix.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mix.size_flags_stretch_ratio = 0.58
	row.add_child(mix)
	if pose == 0:
		_front_mix = mix
	else:
		_profile_mix = mix
	return tab

func _refresh_roster() -> void:
	_characters = _load_all_characters()
	_picker.clear()
	if _characters.is_empty():
		_picker.add_item("Nenhum Freak em data/parts")
		_picker.disabled = true
		return
	_picker.disabled = false
	for character in _characters:
		_picker.add_item(character.display_name)

func _on_freak_selected(index: int) -> void:
	if index < 0 or index >= _characters.size():
		return
	_show_character(_characters[index])

func _select_character(character: CharacterDef) -> void:
	var idx := _characters.find(character)
	if idx >= 0:
		_picker.select(idx)
	_show_character(character)

func _show_character(character: CharacterDef) -> void:
	_character = character
	_status.text = ""
	var slots := PartSlotType.visual_slots()
	for i in slots.size():
		var part := _visual_part(character, slots[i])
		(_front_cards[i] as MagnetPartCard).set_target(part, 0)
		(_profile_cards[i] as MagnetPartCard).set_target(part, 1)
	_refresh_mix()

func _on_transform_changed() -> void:
	_refresh_mix()
	_sync_shared_fields()

func _sync_shared_fields() -> void:
	if _character == null:
		return
	var slots := PartSlotType.visual_slots()
	for i in slots.size():
		var part := _visual_part(_character, slots[i])
		(_front_cards[i] as MagnetPartCard).set_target(part, 0)
		(_profile_cards[i] as MagnetPartCard).set_target(part, 1)

func _on_slot_chosen(part: PartDef, new_slot: PartSlotType.Value) -> void:
	if _character == null or part == null:
		return
	var old_slot := part.slot_type
	if old_slot == new_slot:
		return
	var occupant := _visual_part(_character, new_slot)
	_character.set_part(old_slot, occupant)
	_character.set_part(new_slot, part)
	part.slot_type = new_slot
	if occupant != null:
		occupant.slot_type = old_slot
		_save_resource(occupant)
	_save_resource(part)
	_save_resource(_character)
	_status.modulate = Color(0.7, 0.86, 0.62, 1)
	_status.text = "Troquei %s ↔ %s." % [
		PartSlotType.display_label(old_slot),
		PartSlotType.display_label(new_slot),
	]
	_show_character(_character)

func _refresh_mix() -> void:
	var parts := {}
	if _character != null:
		for slot in PartSlotType.visual_slots():
			parts[slot] = _visual_part(_character, slot)
	if _front_mix != null:
		(_front_mix as MagnetMix).set_mix(parts, 0, "Prévia")
	if _profile_mix != null:
		(_profile_mix as MagnetMix).set_mix(parts, 1, "Prévia")

func _save_all() -> void:
	if _character == null:
		_status.text = "Escolha um Freak."
		return
	var saved := 0
	var seen: Dictionary = {}
	for slot in PartSlotType.visual_slots():
		var part := _visual_part(_character, slot)
		if part == null or part.resource_path.is_empty() or seen.has(part.resource_path):
			continue
		seen[part.resource_path] = true
		if not _save_resource(part):
			_status.text = "Não consegui salvar %s." % part.resource_path.get_file()
			_status.modulate = Color(0.95, 0.55, 0.4, 1)
			return
		saved += 1
	if not _character.resource_path.is_empty():
		_save_resource(_character)
	_status.modulate = Color(0.7, 0.86, 0.62, 1)
	_status.text = "Salvei %d fichas." % saved
	var fs := EditorInterface.get_resource_filesystem()
	if fs != null:
		fs.scan()

func _save_resource(resource: Resource) -> bool:
	if resource == null or resource.resource_path.is_empty():
		return false
	return ResourceSaver.save(resource, resource.resource_path) == OK

func _character_for_part(part: PartDef) -> CharacterDef:
	if part == null:
		return null
	var by_id := _character_by_id(String(part.set_id))
	if by_id != null:
		return by_id
	for character in _characters:
		for slot in PartSlotType.visual_slots():
			if _visual_part(character, slot) == part:
				return character
		if character.legs == part:
			return character
	return null

func _character_by_id(set_id: String) -> CharacterDef:
	if set_id.is_empty():
		return null
	for character in _characters:
		if String(character.id) == set_id:
			return character
	return null

func _visual_part(character: CharacterDef, slot: PartSlotType.Value) -> PartDef:
	if character == null:
		return null
	var key := String(PartSlotType.to_string_name(slot))
	var part := character.get(key) as PartDef
	if part != null:
		return part
	if character.has_method("get_part"):
		part = character.get_part(slot)
		if part != null:
			return part
	var set_id := String(character.id)
	if set_id.is_empty():
		return null
	var path := "res://data/parts/%s_%s.tres" % [set_id, key]
	if ResourceLoader.exists(path):
		return ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REPLACE) as PartDef
	return null

func _load_all_characters() -> Array[CharacterDef]:
	var found: Array[CharacterDef] = []
	var dir := DirAccess.open("res://data/parts")
	if dir == null:
		return found
	dir.list_dir_begin()
	var fname := dir.get_next()
	while fname != "":
		if not dir.current_is_dir() and fname.ends_with("_character.tres"):
			var path := "res://data/parts/%s" % fname
			var character := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REPLACE) as CharacterDef
			if character != null:
				found.append(character)
		fname = dir.get_next()
	found.sort_custom(func(a: CharacterDef, b: CharacterDef) -> bool:
		return String(a.display_name) < String(b.display_name)
	)
	return found
