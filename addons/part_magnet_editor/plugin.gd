@tool
extends EditorPlugin

const MagnetInspectorPlugin := preload("res://addons/part_magnet_editor/magnet_inspector_plugin.gd")
const MagnetWindowScene := preload("res://addons/part_magnet_editor/magnet_window.gd")
const CharacterImporter := preload("res://addons/part_magnet_editor/character_importer.gd")

var _inspector_plugin: EditorInspectorPlugin
var _window
var _file_dialog: EditorFileDialog
var _form: AcceptDialog
var _id_edit: LineEdit
var _name_edit: LineEdit
var _value_spins: Array[SpinBox] = []
var _pending_sheet := ""
var _form_status: Label
var _importing := false

func _enter_tree() -> void:
	_inspector_plugin = MagnetInspectorPlugin.new()
	_inspector_plugin.set_open_window(_open_magnet_window)
	add_inspector_plugin(_inspector_plugin)
	add_tool_menu_item("Ímãs das Peças", _open_magnet_window)
	add_tool_menu_item("Incluir personagem", _begin_import)

func _exit_tree() -> void:
	remove_tool_menu_item("Ímãs das Peças")
	remove_tool_menu_item("Incluir personagem")
	if _inspector_plugin != null:
		remove_inspector_plugin(_inspector_plugin)
		_inspector_plugin = null
	_free_node(_window)
	_window = null
	_free_node(_file_dialog)
	_file_dialog = null
	_free_node(_form)
	_form = null

func _ensure_window() -> void:
	if _window == null or not is_instance_valid(_window):
		_window = MagnetWindowScene.new()
		EditorInterface.get_base_control().add_child(_window)

func _open_magnet_window() -> void:
	_ensure_window()
	var part := EditorInterface.get_inspector().get_edited_object() as PartDef
	_window.present(part)
	_popup_magnet()

func _open_magnet_window_for_set(set_id: String) -> void:
	_ensure_window()
	_window.present_character_id(set_id)
	_popup_magnet()

func _popup_magnet() -> void:
	var host := EditorInterface.get_base_control().size
	var w := clampi(int(host.x * 0.62), 840, 980)
	var h := clampi(int(host.y * 0.62), 500, 620)
	_window.popup_centered(Vector2i(w, h))

func _begin_import() -> void:
	if _file_dialog == null or not is_instance_valid(_file_dialog):
		_file_dialog = EditorFileDialog.new()
		_file_dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
		_file_dialog.access = EditorFileDialog.ACCESS_FILESYSTEM
		_file_dialog.add_filter("*.png, *.webp", "Folha com 6 desenhos de frente e 6 de perfil")
		_file_dialog.file_selected.connect(_on_sheet_chosen)
		EditorInterface.get_base_control().add_child(_file_dialog)
	_file_dialog.popup_file_dialog()

func _on_sheet_chosen(path: String) -> void:
	_pending_sheet = path
	if _form == null or not is_instance_valid(_form):
		_build_form()
	var stem := path.get_file().get_basename().to_lower()
	_id_edit.text = CharacterImporter.clean_id(stem)
	_name_edit.text = stem.capitalize()
	_set_form_status("Ao clicar, a janela fica aberta e mostra o que está acontecendo. Costuma levar poucos segundos.", false)
	_form.popup_centered(Vector2i(440, 420))

func _build_form() -> void:
	_form = AcceptDialog.new()
	_form.title = "Incluir personagem"
	_form.ok_button_text = "Cortar e criar"
	_form.min_size = Vector2i(420, 400)
	_form.dialog_hide_on_ok = false
	_form.confirmed.connect(_on_form_confirmed)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	box.custom_minimum_size = Vector2(400, 300)
	_form.add_child(box)
	box.add_child(_labeled_edit("Id interno (ex: leao)", true))
	box.add_child(_labeled_edit("Nome na carta (ex: Leão)", false))
	var labels: PackedStringArray = ["Cabeça", "Tronco"]
	_value_spins.clear()
	for i in labels.size():
		box.add_child(_labeled_spin(labels[i]))
	var hint := Label.new()
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.custom_minimum_size.x = 380
	hint.text = "Folha com 6 desenhos de frente e 6 de perfil. A loja ganha 4 kits (cabeça, tronco, braço E, braço D). A base-mola já vem na carta. Depois marque os ímãs em Ampliar."
	box.add_child(hint)
	_form_status = Label.new()
	_form_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_form_status.custom_minimum_size.x = 380
	_form_status.text = "Ao clicar, a janela fica aberta e mostra o que está acontecendo. Costuma levar poucos segundos."
	box.add_child(_form_status)
	EditorInterface.get_base_control().add_child(_form)

func _labeled_edit(caption: String, is_id: bool) -> Control:
	var row := VBoxContainer.new()
	var lab := Label.new()
	lab.text = caption
	row.add_child(lab)
	var edit := LineEdit.new()
	row.add_child(edit)
	if is_id:
		_id_edit = edit
	else:
		_name_edit = edit
	return row

func _labeled_spin(caption: String) -> Control:
	var row := HBoxContainer.new()
	var lab := Label.new()
	lab.text = caption
	lab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(lab)
	var spin := SpinBox.new()
	spin.min_value = 3
	spin.max_value = 9
	spin.value = 4
	row.add_child(spin)
	_value_spins.append(spin)
	return row

func _on_form_confirmed() -> void:
	if _importing:
		return
	await _run_import()

func _set_form_status(text: String, is_error: bool) -> void:
	if _form_status == null:
		return
	_form_status.text = text
	_form_status.modulate = Color(0.95, 0.55, 0.4, 1) if is_error else Color(0.78, 0.86, 0.72, 1)

func _set_form_busy(busy: bool) -> void:
	_importing = busy
	if _form == null or not is_instance_valid(_form):
		return
	var ok := _form.get_ok_button()
	if ok != null:
		ok.disabled = busy
	if _id_edit != null:
		_id_edit.editable = not busy
	if _name_edit != null:
		_name_edit.editable = not busy
	for spin in _value_spins:
		spin.editable = not busy

func _editor_tree() -> SceneTree:
	var host := EditorInterface.get_base_control()
	if host != null and host.get_tree() != null:
		return host.get_tree()
	return get_tree()

func _run_import() -> void:
	var set_id := CharacterImporter.clean_id(_id_edit.text)
	if set_id.is_empty():
		_set_form_status("O id interno precisa ser minúsculo, sem acento. Exemplo: leao.", true)
		return
	if _pending_sheet.is_empty():
		_set_form_status("Escolha de novo a folha PNG ou WEBP.", true)
		return
	_set_form_busy(true)
	_set_form_status("Cortando a folha… a janela fica aberta. Espere uns segundos.", false)
	var tree := _editor_tree()
	if tree != null:
		await tree.process_frame
		await tree.process_frame
	var result: Dictionary = CharacterImporter.slice_sheet(_pending_sheet, set_id)
	var slice_err := String(result.get("error", ""))
	if not slice_err.is_empty():
		_set_form_busy(false)
		_set_form_status(slice_err, true)
		push_error(slice_err)
		return
	CharacterImporter.keep_source_sheet(_pending_sheet, set_id)
	_set_form_status("Esperando o Godot ler as 12 imagens…", false)
	var fs := EditorInterface.get_resource_filesystem()
	var err := ""
	var values: Array = []
	for spin in _value_spins:
		values.append(int(spin.value))
	for _attempt in 8:
		await _wait_filesystem(fs)
		err = CharacterImporter.write_defs(set_id, _name_edit.text, values)
		if err.is_empty():
			break
	if not err.is_empty():
		_set_form_busy(false)
		_set_form_status(err, true)
		push_error(err)
		return
	await _wait_filesystem(fs)
	_set_form_status("Pronto. O Freak já entra nas caixas no próximo Play. Abrindo os ímãs…", false)
	var part_path := "res://data/parts/%s_body.tres" % set_id
	var part := load(part_path) as PartDef
	if part != null:
		EditorInterface.inspect_object(part)
	EditorInterface.select_file(part_path)
	_set_form_busy(false)
	_form.hide()
	_open_magnet_window_for_set(set_id)

func _wait_filesystem(fs: EditorFileSystem) -> void:
	if fs == null:
		return
	fs.scan()
	var tree := _editor_tree()
	var frames := 0
	while fs.is_scanning() and frames < 240:
		if tree != null:
			await tree.process_frame
		frames += 1
	if tree != null:
		await tree.create_timer(0.25).timeout

func _free_node(node: Node) -> void:
	if node != null and is_instance_valid(node):
		node.queue_free()
