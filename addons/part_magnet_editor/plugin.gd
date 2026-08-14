@tool
extends EditorPlugin

const MagnetInspectorPlugin := preload("res://addons/part_magnet_editor/magnet_inspector_plugin.gd")
const MagnetWindowScene := preload("res://addons/part_magnet_editor/magnet_window.gd")
const CharacterImporter := preload("res://addons/part_magnet_editor/character_importer.gd")

var _inspector_plugin: EditorInspectorPlugin
var _window: Window
var _window_part: PartDef
var _file_dialog: EditorFileDialog
var _form: AcceptDialog
var _id_edit: LineEdit
var _name_edit: LineEdit
var _head_spin: SpinBox
var _body_spin: SpinBox
var _legs_spin: SpinBox
var _pending_sheet := ""

func _enter_tree() -> void:
	_inspector_plugin = MagnetInspectorPlugin.new()
	_inspector_plugin.set_open_window(_open_magnet_window)
	add_inspector_plugin(_inspector_plugin)
	add_tool_menu_item("Ímãs das Peças", _open_magnet_window)
	add_tool_menu_item("Incluir personagem", _begin_import)
	set_process(false)

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

func _process(_delta: float) -> void:
	if _window == null or not is_instance_valid(_window) or not _window.visible:
		set_process(false)
		return
	var edited := EditorInterface.get_inspector().get_edited_object() as PartDef
	if edited != _window_part:
		_window_part = edited
		_window.set_part(edited)

func _open_magnet_window() -> void:
	if _window == null or not is_instance_valid(_window):
		_window = MagnetWindowScene.new()
		EditorInterface.get_base_control().add_child(_window)
	_window.popup_centered(Vector2i(480, 680))
	_window_part = EditorInterface.get_inspector().get_edited_object() as PartDef
	_window.set_part(_window_part)
	set_process(true)

func _begin_import() -> void:
	if _file_dialog == null or not is_instance_valid(_file_dialog):
		_file_dialog = EditorFileDialog.new()
		_file_dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
		_file_dialog.access = EditorFileDialog.ACCESS_FILESYSTEM
		_file_dialog.add_filter("*.png, *.webp", "Folha 3x3")
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
	_form.popup_centered()

func _build_form() -> void:
	_form = AcceptDialog.new()
	_form.title = "Incluir personagem"
	_form.ok_button_text = "Cortar e criar"
	_form.confirmed.connect(_on_form_confirmed)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	_form.add_child(box)
	box.add_child(_labeled_edit("Id interno (ex: zumbi)", true))
	box.add_child(_labeled_edit("Nome na carta (ex: Zumbi)", false))
	box.add_child(_labeled_spin("Ameaça (cabeça)", 0))
	box.add_child(_labeled_spin("Força (tronco)", 1))
	box.add_child(_labeled_spin("Agilidade (pernas)", 2))
	var hint := Label.new()
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.text = "A folha precisa ser uma grade 3×3 (de preferência 900×600). Depois marque os ímãs: Project → Tools → Ímãs das Peças."
	box.add_child(hint)
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

func _labeled_spin(caption: String, which: int) -> Control:
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
	match which:
		0:
			_head_spin = spin
		1:
			_body_spin = spin
		_:
			_legs_spin = spin
	return row

func _on_form_confirmed() -> void:
	_run_import()

func _run_import() -> void:
	var set_id := CharacterImporter.clean_id(_id_edit.text)
	var pngs := CharacterImporter.slice_sheet(_pending_sheet, set_id)
	if pngs.size() != 9:
		push_error("Não consegui cortar a folha em 9 peças.")
		return
	CharacterImporter.keep_source_sheet(_pending_sheet, set_id)
	var fs := EditorInterface.get_resource_filesystem()
	var err := ""
	for _attempt in 8:
		await _wait_filesystem(fs)
		err = CharacterImporter.write_defs(
			set_id,
			_name_edit.text,
			int(_head_spin.value),
			int(_body_spin.value),
			int(_legs_spin.value)
		)
		if err.is_empty():
			break
	if not err.is_empty():
		push_error(err)
		return
	await _wait_filesystem(fs)
	var part_path := "res://data/parts/%s_body.tres" % set_id
	var part := load(part_path) as PartDef
	if part != null:
		EditorInterface.inspect_object(part)
	EditorInterface.select_file(part_path)
	_open_magnet_window()

func _wait_filesystem(fs: EditorFileSystem) -> void:
	fs.scan()
	while fs.is_scanning():
		await get_tree().process_frame
	await get_tree().create_timer(0.35).timeout

func _free_node(node: Node) -> void:
	if node != null and is_instance_valid(node):
		node.queue_free()
