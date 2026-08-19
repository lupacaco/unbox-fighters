@tool
extends AcceptDialog

## Pick an existing Freak and delete every file the include tool created.

const CharacterRemover := preload("res://addons/part_magnet_editor/character_remover.gd")
const ToolChrome := preload("res://addons/part_magnet_editor/tool_chrome.gd")

signal roster_changed
signal release_set(set_id: String)

var _picker: OptionButton
var _preview: TextureRect
var _summary: Label
var _files: ItemList
var _hint: Label
var _status: Label
var _sure: ConfirmationDialog
var _sets: Array[Dictionary] = []
var _busy := false


func _ready() -> void:
	title = "Remover personagem"
	ok_button_text = "Apagar este Freak"
	dialog_hide_on_ok = false
	ToolChrome.apply(self)
	confirmed.connect(_on_delete_pressed)
	add_cancel_button("Fechar")
	_build_body()
	_build_sure()
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

	_summary = Label.new()
	_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(_summary)

	var files_lab := Label.new()
	files_lab.text = "Arquivos que vão sumir"
	box.add_child(files_lab)

	_files = ItemList.new()
	_files.custom_minimum_size = Vector2(0, 180)
	_files.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_files.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(_files)

	_hint = Label.new()
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hint.text = "Isso apaga de vez: desenhos, pasta e fichas da loja. Não dá para desfazer no Godot."
	box.add_child(_hint)

	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(_status)


func _build_sure() -> void:
	_sure = ConfirmationDialog.new()
	_sure.title = "Apagar de vez?"
	_sure.ok_button_text = "Apagar de vez"
	_sure.cancel_button_text = "Não"
	_sure.confirmed.connect(_do_remove)
	add_child(_sure)


func _refresh() -> void:
	_sets = CharacterRemover.list_sets()
	_picker.clear()
	if _sets.is_empty():
		_picker.add_item("Nenhum Freak no projeto")
		_picker.disabled = true
		_show_set(-1)
		_set_ok_enabled(false)
		_set_status("Não achei nenhum Freak para apagar.", false)
		return
	_picker.disabled = false
	for row in _sets:
		var label := String(row["display_name"])
		var set_id := String(row["id"])
		if label.to_lower() != set_id:
			label = "%s (%s)" % [label, set_id]
		_picker.add_item(label)
	_picker.select(0)
	_show_set(0)
	_set_status("Escolha o Freak e clique em Apagar. Vai pedir confirmação.", false)


func _on_set_chosen(index: int) -> void:
	_show_set(index)


func _show_set(index: int) -> void:
	_files.clear()
	_preview.texture = null
	if index < 0 or index >= _sets.size():
		_summary.text = ""
		_hint.text = "Isso apaga de vez: desenhos, pasta e fichas da loja. Não dá para desfazer no Godot."
		_set_ok_enabled(false)
		return
	var row: Dictionary = _sets[index]
	var set_id := String(row["id"])
	var kind := String(row["kind_label"])
	var shop_line := "Já entra nas caixas." if bool(row["in_shop"]) else "Ainda não tem ficha na loja."
	var kind_line := ("Tipo: %s\n" % kind) if not kind.is_empty() else ""
	_summary.text = "%s\n%s%s\n%s" % [
		String(row["display_name"]),
		kind_line,
		shop_line,
		CharacterRemover.summarize(set_id),
	]
	var paths := CharacterRemover.collect_paths(set_id)
	for path in paths:
		_files.add_item(path.replace("res://", ""))
	_preview.texture = _preview_texture(set_id)
	var mentions := CharacterRemover.scripts_that_mention(set_id)
	if _sets.size() == 1:
		_hint.text = "Este é o último Freak do projeto. Se apagar, a loja fica vazia no próximo Play."
	elif not mentions.is_empty():
		_hint.text = "Alguns testes do projeto ainda citam este Freak. Apagar pode fazer as checagens falharem."
	else:
		_hint.text = "Isso apaga de vez: desenhos, pasta e fichas da loja. Não dá para desfazer no Godot."
	_set_ok_enabled(not paths.is_empty() and not _busy)


func _preview_texture(set_id: String) -> Texture2D:
	var character := load("res://data/parts/%s_character.tres" % set_id) as CharacterDef
	if character != null and character.head != null and character.head.sprite != null:
		return character.head.sprite
	var art := "res://assets/characters/%s/%s_head-1.png" % [set_id, set_id]
	if ResourceLoader.exists(art):
		return load(art) as Texture2D
	return null


func _on_delete_pressed() -> void:
	if _busy:
		return
	var set_id := _selected_id()
	if set_id.is_empty():
		_set_status("Escolha um Freak da lista.", true)
		return
	var row := _selected_row()
	var name := String(row.get("display_name", set_id))
	var count := CharacterRemover.collect_paths(set_id).size()
	_sure.dialog_text = (
		"Apagar %s de vez?\n\n" % name
		+ "Sumam os desenhos, a pasta e as fichas da loja (%d arquivo(s)).\n" % count
		+ "Não dá para desfazer no Godot."
	)
	_sure.popup_centered()


func _do_remove() -> void:
	if _busy:
		return
	var set_id := _selected_id()
	if set_id.is_empty():
		_set_status("Escolha um Freak da lista.", true)
		return
	_busy = true
	_set_ok_enabled(false)
	_preview.texture = null
	_files.clear()
	_set_status("Apagando… a janela fica aberta.", false)
	release_set.emit(set_id)
	var err := CharacterRemover.remove(set_id)
	_scan_filesystem()
	roster_changed.emit()
	_busy = false
	_refresh()
	if not err.is_empty():
		_set_status(err, true)
		return
	_set_status("Pronto. %s saiu do jogo. No próximo Play a loja já não vende este Freak." % set_id.capitalize(), false)


func _selected_id() -> String:
	var row := _selected_row()
	if row.is_empty():
		return ""
	return String(row["id"])


func _selected_row() -> Dictionary:
	if _picker == null or _sets.is_empty():
		return {}
	var index := _picker.selected
	if index < 0 or index >= _sets.size():
		return {}
	return _sets[index]


func _set_ok_enabled(enabled: bool) -> void:
	var ok := get_ok_button()
	if ok != null:
		ok.disabled = not enabled
		ok.modulate = Color(0.95, 0.5, 0.42, 1) if enabled else Color(0.7, 0.7, 0.7, 1)


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
