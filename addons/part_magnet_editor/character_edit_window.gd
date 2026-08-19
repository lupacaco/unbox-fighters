@tool
extends AcceptDialog

## Pick an existing Freak and change the card: name, type, power, Attack, HP.

const CharacterEditor := preload("res://addons/part_magnet_editor/character_editor.gd")
const ToolChrome := preload("res://addons/part_magnet_editor/tool_chrome.gd")

signal roster_changed
signal open_magnets(set_id: String)

var _picker: OptionButton
var _preview: TextureRect
var _id_label: Label
var _name_edit: LineEdit
var _attack_spin: SpinBox
var _hp_spin: SpinBox
var _kind_option: OptionButton
var _ability_option: OptionButton
var _price: Label
var _hint: Label
var _status: Label
var _magnets_btn: Button
var _sets: Array[Dictionary] = []
var _syncing := false
var _busy := false


func _ready() -> void:
	title = "Editar personagem"
	ok_button_text = "Salvar"
	dialog_hide_on_ok = false
	ToolChrome.apply(self)
	confirmed.connect(_on_save_pressed)
	add_cancel_button("Fechar")
	_build_body()
	about_to_popup.connect(_refresh)


func present() -> void:
	_refresh()
	ToolChrome.popup(self)


func _build_body() -> void:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	add_child(ToolChrome.scrolled_body(box))

	var pick_lab := Label.new()
	pick_lab.text = "Escolha o Freak"
	box.add_child(pick_lab)

	_picker = OptionButton.new()
	_picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_picker.item_selected.connect(_on_set_chosen)
	box.add_child(_picker)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 12)
	box.add_child(top)

	_preview = TextureRect.new()
	_preview.custom_minimum_size = Vector2(96, 96)
	_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	top.add_child(_preview)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(info)

	_id_label = Label.new()
	_id_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_child(_id_label)

	info.add_child(_labeled_name())

	box.add_child(_labeled_spin("Ataque (cabeça, 1 a 10)", true))
	box.add_child(_labeled_spin("HP (corpo, 10 a 20)", false))
	box.add_child(_labeled_kind())
	box.add_child(_labeled_ability())

	_price = Label.new()
	box.add_child(_price)

	_magnets_btn = Button.new()
	_magnets_btn.text = "Abrir ímãs deste Freak"
	_magnets_btn.pressed.connect(_on_magnets_pressed)
	box.add_child(_magnets_btn)

	_hint = Label.new()
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hint.text = "O nome da pasta (id) não muda por aqui. Desenhos entram em Incluir; ímãs têm a ferramenta própria."
	box.add_child(_hint)

	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(_status)

	_name_edit.text_changed.connect(_on_fields_changed)
	_attack_spin.value_changed.connect(_on_spin_changed)
	_hp_spin.value_changed.connect(_on_spin_changed)
	_kind_option.item_selected.connect(_on_option_changed)
	_ability_option.item_selected.connect(_on_option_changed)


func _labeled_name() -> Control:
	var row := VBoxContainer.new()
	var lab := Label.new()
	lab.text = "Nome na carta"
	row.add_child(lab)
	_name_edit = LineEdit.new()
	_name_edit.placeholder_text = "Ex: Bruxa"
	row.add_child(_name_edit)
	return row


func _labeled_spin(caption: String, is_attack: bool) -> Control:
	var row := HBoxContainer.new()
	var lab := Label.new()
	lab.text = caption
	lab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(lab)
	var spin := SpinBox.new()
	if is_attack:
		spin.min_value = PartStats.ATTACK_MIN
		spin.max_value = PartStats.ATTACK_MAX
		_attack_spin = spin
	else:
		spin.min_value = PartStats.HP_MIN
		spin.max_value = PartStats.HP_MAX
		_hp_spin = spin
	row.add_child(spin)
	return row


func _labeled_kind() -> Control:
	var row := VBoxContainer.new()
	var lab := Label.new()
	lab.text = "Tipo"
	row.add_child(lab)
	_kind_option = OptionButton.new()
	_kind_option.add_item("Humano", int(FreakKind.Value.HUMAN))
	_kind_option.add_item("Sobrenatural", int(FreakKind.Value.SUPERNATURAL))
	_kind_option.add_item("Animal", int(FreakKind.Value.ANIMAL))
	row.add_child(_kind_option)
	return row


func _labeled_ability() -> Control:
	var row := VBoxContainer.new()
	var lab := Label.new()
	lab.text = "Poder (só no set completo)"
	row.add_child(lab)
	_ability_option = OptionButton.new()
	_ability_option.add_item("Nenhum", int(FreakAbility.Value.NONE))
	_ability_option.add_item("Controle de Mente", int(FreakAbility.Value.MIND_CONTROL))
	_ability_option.add_item("Recurso", int(FreakAbility.Value.APPEAL))
	row.add_child(_ability_option)
	return row


func _refresh() -> void:
	var keep := _selected_id()
	_sets = CharacterEditor.list_sets()
	_picker.clear()
	if _sets.is_empty():
		_picker.add_item("Nenhum Freak no projeto")
		_picker.disabled = true
		_fill(-1)
		_set_ok_enabled(false)
		_set_status("Não achei nenhum Freak para editar. Inclua um primeiro.", false)
		return
	_picker.disabled = false
	var select := 0
	for i in _sets.size():
		var row: Dictionary = _sets[i]
		_picker.add_item(_picker_label(row))
		if String(row["id"]) == keep:
			select = i
	_picker.select(select)
	_fill(select)
	_set_status("Mude o que quiser e clique em Salvar. Vale no próximo Play.", false)


func _picker_label(row: Dictionary) -> String:
	var label := String(row["display_name"])
	var set_id := String(row["id"])
	if label.to_lower() != set_id:
		return "%s (%s)" % [label, set_id]
	return label


func _on_set_chosen(index: int) -> void:
	_fill(index)


func _fill(index: int) -> void:
	_syncing = true
	if index < 0 or index >= _sets.size():
		_preview.texture = null
		_id_label.text = "Id interno: —"
		_name_edit.text = ""
		_attack_spin.value = PartStats.ATTACK_MIN
		_hp_spin.value = PartStats.HP_MIN
		_kind_option.select(0)
		_ability_option.select(0)
		_price.text = ""
		_set_fields_enabled(false)
		_set_ok_enabled(false)
		_syncing = false
		return
	var row: Dictionary = _sets[index]
	var set_id := String(row["id"])
	_id_label.text = "Id interno: %s (a pasta não muda)" % set_id
	_name_edit.text = String(row["display_name"])
	_attack_spin.value = int(row["attack"])
	_hp_spin.value = int(row["hp"])
	_select_item_id(_kind_option, int(row["kind"]))
	_select_item_id(_ability_option, int(row["ability"]))
	_preview.texture = _preview_texture(set_id)
	_refresh_price()
	_set_fields_enabled(true)
	_set_ok_enabled(not _busy)
	_syncing = false


func _select_item_id(option: OptionButton, id: int) -> void:
	for i in option.item_count:
		if option.get_item_id(i) == id:
			option.select(i)
			return
	option.select(0)


func _preview_texture(set_id: String) -> Texture2D:
	var character := load("res://data/parts/%s_character.tres" % set_id) as CharacterDef
	if character != null and character.head != null and character.head.sprite != null:
		return character.head.sprite
	var art := "res://assets/characters/%s/%s_head-1.png" % [set_id, set_id]
	if ResourceLoader.exists(art):
		return load(art) as Texture2D
	return null


func _on_fields_changed(_text: String) -> void:
	if _syncing:
		return


func _on_spin_changed(_value: float) -> void:
	if _syncing:
		return
	_refresh_price()


func _on_option_changed(_index: int) -> void:
	if _syncing:
		return


func _refresh_price() -> void:
	if _price == null:
		return
	_price.text = CharacterEditor.price_line(int(_attack_spin.value), int(_hp_spin.value))


func _on_save_pressed() -> void:
	if _busy:
		return
	var set_id := _selected_id()
	if set_id.is_empty():
		_set_status("Escolha um Freak da lista.", true)
		return
	_busy = true
	_set_ok_enabled(false)
	_set_status("Gravando…", false)
	var err := CharacterEditor.save(
		set_id,
		_name_edit.text,
		int(_attack_spin.value),
		int(_hp_spin.value),
		_kind_option.get_item_id(_kind_option.selected) as FreakKind.Value,
		_ability_option.get_item_id(_ability_option.selected) as FreakAbility.Value
	)
	_busy = false
	if not err.is_empty():
		_set_ok_enabled(true)
		_set_status(err, true)
		return
	var saved_name := _name_edit.text.strip_edges()
	_scan_filesystem()
	roster_changed.emit()
	_refresh()
	_set_status("Pronto. %s gravado. No próximo Play a loja e a luta já usam estes números." % saved_name, false)


func _on_magnets_pressed() -> void:
	var set_id := _selected_id()
	if set_id.is_empty():
		_set_status("Escolha um Freak da lista.", true)
		return
	open_magnets.emit(set_id)


func _selected_id() -> String:
	if _picker == null or _sets.is_empty():
		return ""
	var index := _picker.selected
	if index < 0 or index >= _sets.size():
		return ""
	return String(_sets[index]["id"])


func _set_fields_enabled(enabled: bool) -> void:
	_name_edit.editable = enabled
	_attack_spin.editable = enabled
	_hp_spin.editable = enabled
	_kind_option.disabled = not enabled
	_ability_option.disabled = not enabled
	if _magnets_btn != null:
		_magnets_btn.disabled = not enabled


func _set_ok_enabled(enabled: bool) -> void:
	var ok := get_ok_button()
	if ok != null:
		ok.disabled = not enabled


func _set_status(text: String, is_error: bool) -> void:
	if _status == null:
		return
	_status.text = text
	_status.modulate = Color(0.95, 0.55, 0.4, 1) if is_error else Color(0.78, 0.86, 0.72, 1)


func _scan_filesystem() -> void:
	if not Engine.is_editor_hint():
		return
	var fs := EditorInterface.get_resource_filesystem()
	if fs != null:
		fs.scan()
