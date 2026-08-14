@tool
extends EditorInspectorPlugin

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
	box.add_theme_constant_override("separation", 6)
	var open_btn := Button.new()
	open_btn.text = "Abrir as 12 partes deste Freak"
	open_btn.custom_minimum_size.y = 28
	open_btn.pressed.connect(func() -> void:
		if _open_window.is_valid():
			_open_window.call()
	)
	box.add_child(open_btn)
	var hint := Label.new()
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.modulate = Color(0.78, 0.8, 0.84, 1)
	hint.text = "A ferramenta mostra as 12 imagens (frente e de lado) na mesma tela. Arraste as bolinhas até as esferas de metal."
	box.add_child(hint)
	add_custom_control(box)
