@tool
extends Window

## One large board: pick a Freak, then mark magnets on all 12 drawings.

const MagnetTile := preload("res://addons/part_magnet_editor/magnet_tile.gd")
const MagnetMix := preload("res://addons/part_magnet_editor/magnet_mix.gd")

var _picker: OptionButton
var _help: Label
var _status: Label
var _front_tiles: Array[Control] = []
var _profile_tiles: Array[Control] = []
var _front_mix: Control
var _profile_mix: Control

var _characters: Array[CharacterDef] = []
var _character: CharacterDef
var _pending_part: PartDef
var _pending_set_id: String = ""

func _ready() -> void:
	title = "Ímãs — todas as partes"
	min_size = Vector2i(1100, 720)
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
	root.add_theme_constant_override("margin_left", 14)
	root.add_theme_constant_override("margin_top", 12)
	root.add_theme_constant_override("margin_right", 14)
	root.add_theme_constant_override("margin_bottom", 12)
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
	_help.text = "Escolha o Freak. Arraste as bolinhas até o centro das esferas de metal. Em cima: frente. Embaixo: de lado. O tronco tem 5 ímãs (pescoço, ombros, quadris)."
	column.add_child(_help)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)

	var board := VBoxContainer.new()
	board.add_theme_constant_override("separation", 8)
	board.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	board.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(board)

	board.add_child(_section_label("Frente"))
	board.add_child(_make_part_row(0))

	board.add_child(_section_label("De lado"))
	board.add_child(_make_part_row(1))

	board.add_child(_section_label("Prévia do encaixe"))
	var mix_row := HBoxContainer.new()
	mix_row.add_theme_constant_override("separation", 10)
	mix_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mix_row.custom_minimum_size.y = 280
	board.add_child(mix_row)
	_front_mix = MagnetMix.new()
	_profile_mix = MagnetMix.new()
	mix_row.add_child(_front_mix)
	mix_row.add_child(_profile_mix)

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
	save_btn.text = "Salvar ímãs"
	save_btn.custom_minimum_size = Vector2(140, 32)
	save_btn.pressed.connect(_save_all)
	bar.add_child(save_btn)
	_status = Label.new()
	_status.modulate = Color(0.7, 0.86, 0.62, 1)
	bar.add_child(_status)
	return bar

func _section_label(text: String) -> Label:
	var lab := Label.new()
	lab.text = text
	lab.add_theme_font_size_override("font_size", 15)
	return lab

func _make_part_row(pose: int) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.custom_minimum_size.y = 236
	var tiles: Array[Control] = []
	for _i in PartSlotType.visual_slots().size():
		var tile := MagnetTile.new()
		tile.magnets_changed.connect(_refresh_mix)
		row.add_child(tile)
		tiles.append(tile)
	if pose == 0:
		_front_tiles = tiles
	else:
		_profile_tiles = tiles
	return row

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
		var part := character.get_part(slots[i]) if character != null else null
		(_front_tiles[i] as MagnetTile).set_target(part, 0)
		(_profile_tiles[i] as MagnetTile).set_target(part, 1)
	_refresh_mix()

func _refresh_mix() -> void:
	var parts := {}
	if _character != null:
		for slot in PartSlotType.visual_slots():
			parts[slot] = _character.get_part(slot)
	if _front_mix != null:
		(_front_mix as MagnetMix).set_mix(parts, 0, "Frente")
	if _profile_mix != null:
		(_profile_mix as MagnetMix).set_mix(parts, 1, "De lado")

func _save_all() -> void:
	if _character == null:
		_status.text = "Escolha um Freak."
		return
	var saved := 0
	for part in _character.visual_parts():
		if part == null or part.resource_path.is_empty():
			continue
		var err := ResourceSaver.save(part, part.resource_path)
		if err != OK:
			_status.text = "Não consegui salvar %s." % part.resource_path.get_file()
			_status.modulate = Color(0.95, 0.55, 0.4, 1)
			return
		saved += 1
	_status.modulate = Color(0.7, 0.86, 0.62, 1)
	_status.text = "Salvei %d fichas." % saved
	var fs := EditorInterface.get_resource_filesystem()
	if fs != null:
		fs.scan()

func _character_for_part(part: PartDef) -> CharacterDef:
	if part == null:
		return null
	var by_id := _character_by_id(String(part.set_id))
	if by_id != null:
		return by_id
	for character in _characters:
		for slot in PartSlotType.visual_slots():
			if character.get_part(slot) == part:
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

func _load_all_characters() -> Array[CharacterDef]:
	var found: Array[CharacterDef] = []
	var dir := DirAccess.open("res://data/parts")
	if dir == null:
		return found
	dir.list_dir_begin()
	var fname := dir.get_next()
	while fname != "":
		if not dir.current_is_dir() and fname.ends_with("_character.tres"):
			var character := load("res://data/parts/%s" % fname) as CharacterDef
			if character != null:
				found.append(character)
		fname = dir.get_next()
	found.sort_custom(func(a: CharacterDef, b: CharacterDef) -> bool:
		return String(a.display_name) < String(b.display_name)
	)
	return found
