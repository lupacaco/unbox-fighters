@tool
extends Window

const MagnetPreview := preload("res://addons/part_magnet_editor/magnet_preview.gd")

var _gui: Control
var _empty: Label
var _scroll: ScrollContainer

func _ready() -> void:
	title = "Ímãs"
	min_size = Vector2(440, 620)
	unresizable = false
	exclusive = false
	close_requested.connect(hide)
	var root := MarginContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("margin_left", 12)
	root.add_theme_constant_override("margin_top", 12)
	root.add_theme_constant_override("margin_right", 12)
	root.add_theme_constant_override("margin_bottom", 12)
	add_child(root)

	_scroll = ScrollContainer.new()
	_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(_scroll)

	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(column)

	_empty = Label.new()
	_empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_empty.text = "Clique numa peça na pasta FileSystem: data → parts.\nExemplo: cachorro_head ou medico_body."
	column.add_child(_empty)

	var open_folder := Button.new()
	open_folder.text = "Abrir pasta das peças"
	open_folder.custom_minimum_size.y = 28
	open_folder.pressed.connect(func() -> void:
		EditorInterface.select_file("res://data/parts/")
	)
	column.add_child(open_folder)

	_gui = MagnetPreview.new()
	_gui.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(_gui)
	_gui.visible = false

func set_part(part: PartDef) -> void:
	if _gui == null:
		return
	if part == null:
		_empty.visible = true
		_gui.visible = false
		return
	_empty.visible = false
	_gui.visible = true
	_gui.setup(part, true)
