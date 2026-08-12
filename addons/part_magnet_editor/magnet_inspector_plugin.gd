@tool
extends EditorInspectorPlugin

const MagnetPreview := preload("res://addons/part_magnet_editor/magnet_preview.gd")

func _can_handle(object: Object) -> bool:
	return object is PartDef

func _parse_begin(object: Object) -> void:
	var part := object as PartDef
	if part == null:
		return

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)

	var title := Label.new()
	title.text = "Ímãs — clique na imagem para marcar o ponto"
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(title)

	var hint := Label.new()
	hint.text = "Escolha qual ímã editar, depois clique no círculo da peça (pescoço / cintura)."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.modulate = Color(0.75, 0.78, 0.82, 1)
	box.add_child(hint)

	var preview := MagnetPreview.new()
	preview.setup(part)
	box.add_child(preview)

	add_custom_control(box)
