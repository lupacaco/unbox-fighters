@tool
extends EditorInspectorPlugin

const MagnetPreview := preload("res://addons/part_magnet_editor/magnet_preview.gd")

var _open_window: Callable = Callable()

func set_open_window(cb: Callable) -> void:
	_open_window = cb

func _can_handle(object: Object) -> bool:
	return object is PartDef

func _parse_begin(object: Object) -> void:
	var part := object as PartDef
	if part == null:
		return

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)

	var open_btn := Button.new()
	open_btn.text = "Abrir ferramenta de ímãs (imagem grande)"
	open_btn.custom_minimum_size.y = 26
	open_btn.pressed.connect(func() -> void:
		if _open_window.is_valid():
			_open_window.call()
	)
	box.add_child(open_btn)

	var preview := MagnetPreview.new()
	preview.setup(part, false)
	box.add_child(preview)

	add_custom_control(box)
