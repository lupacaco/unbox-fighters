@tool
extends VBoxContainer

const PREVIEW_SIZE := 300.0
const MARKER_RADIUS := 10.0

enum EditTarget { UP, DOWN }

var _part: PartDef
var _target: EditTarget = EditTarget.UP
var _canvas: Control
var _btn_up: Button
var _btn_down: Button
var _label_coords: Label
var _undo: EditorUndoRedoManager

func setup(part: PartDef) -> void:
	_part = part
	_undo = EditorInterface.get_editor_undo_redo()
	_build_ui()
	_refresh_buttons()
	_refresh_coords()
	if _part.slot_type == PartSlotType.Value.HEAD:
		_set_target(EditTarget.DOWN)
	elif _part.slot_type == PartSlotType.Value.LEGS:
		_set_target(EditTarget.UP)
	else:
		_set_target(EditTarget.UP)

func _build_ui() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	add_child(row)

	_btn_up = Button.new()
	_btn_up.text = "Marcar Ímã de Cima"
	_btn_up.toggle_mode = true
	_btn_up.pressed.connect(func() -> void: _set_target(EditTarget.UP))
	row.add_child(_btn_up)

	_btn_down = Button.new()
	_btn_down.text = "Marcar Ímã de Baixo"
	_btn_down.toggle_mode = true
	_btn_down.pressed.connect(func() -> void: _set_target(EditTarget.DOWN))
	row.add_child(_btn_down)

	_canvas = Control.new()
	_canvas.custom_minimum_size = Vector2(PREVIEW_SIZE, PREVIEW_SIZE)
	_canvas.mouse_filter = Control.MOUSE_FILTER_STOP
	_canvas.draw.connect(_on_canvas_draw)
	_canvas.gui_input.connect(_on_canvas_gui_input)
	add_child(_canvas)

	_label_coords = Label.new()
	_label_coords.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_label_coords)

func _set_target(target: EditTarget) -> void:
	_target = target
	_refresh_buttons()
	_canvas.queue_redraw()

func _refresh_buttons() -> void:
	if _btn_up == null or _btn_down == null:
		return
	_btn_up.button_pressed = _target == EditTarget.UP
	_btn_down.button_pressed = _target == EditTarget.DOWN

func _refresh_coords() -> void:
	if _part == null or _label_coords == null:
		return
	_label_coords.text = "Cima: %s   |   Baixo: %s" % [_part.magnet_up, _part.magnet_down]

func _texture_draw_rect() -> Rect2:
	return Rect2(Vector2.ZERO, Vector2(PREVIEW_SIZE, PREVIEW_SIZE))

func _on_canvas_draw() -> void:
	var rect := _texture_draw_rect()
	_canvas.draw_rect(rect, Color(0.08, 0.09, 0.11, 1), true)

	if _part == null or _part.sprite == null:
		_canvas.draw_string(ThemeDB.fallback_font, Vector2(16, 28), "Sem sprite nesta peça", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.8, 0.8, 0.8))
		return

	_canvas.draw_texture_rect(_part.sprite, rect, false)
	_draw_marker(_part.magnet_up, Color(0.25, 0.85, 1.0, 1.0), "CIMA")
	_draw_marker(_part.magnet_down, Color(1.0, 0.35, 0.35, 1.0), "BAIXO")

func _draw_marker(magnet: Vector2, color: Color, label: String) -> void:
	var pos := _magnet_to_canvas(magnet)
	_canvas.draw_circle(pos, MARKER_RADIUS + 2.0, Color(0, 0, 0, 0.65))
	_canvas.draw_circle(pos, MARKER_RADIUS, color)
	_canvas.draw_circle(pos, 2.5, Color.WHITE)
	_canvas.draw_string(
		ThemeDB.fallback_font,
		pos + Vector2(12, 4),
		label,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		12,
		color
	)

func _on_canvas_gui_input(event: InputEvent) -> void:
	if _part == null or _part.sprite == null:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var magnet := _canvas_to_magnet(event.position)
		_apply_magnet(magnet)
		_canvas.accept_event()

func _apply_magnet(magnet: Vector2) -> void:
	var rounded := Vector2(roundf(magnet.x), roundf(magnet.y))
	var prop := "magnet_up" if _target == EditTarget.UP else "magnet_down"
	var old_value: Vector2 = _part.get(prop)
	if old_value == rounded:
		return

	if _undo != null:
		_undo.create_action("Set part %s" % prop)
		_undo.add_do_property(_part, prop, rounded)
		_undo.add_undo_property(_part, prop, old_value)
		_undo.add_do_method(self, "_after_magnet_changed")
		_undo.add_undo_method(self, "_after_magnet_changed")
		_undo.commit_action()
	else:
		_part.set(prop, rounded)
		_after_magnet_changed()

func _after_magnet_changed() -> void:
	_refresh_coords()
	_canvas.queue_redraw()
	# Keep the resource dirty so Godot asks to save / writes the .tres.
	if _part != null:
		_part.emit_changed()

func _magnet_to_canvas(magnet: Vector2) -> Vector2:
	var tex_size := _part.sprite.get_size()
	var rect := _texture_draw_rect()
	var pixel := magnet + tex_size * 0.5
	var nx := pixel.x / maxf(tex_size.x, 1.0)
	var ny := pixel.y / maxf(tex_size.y, 1.0)
	return rect.position + Vector2(nx * rect.size.x, ny * rect.size.y)

func _canvas_to_magnet(canvas_pos: Vector2) -> Vector2:
	var tex_size := _part.sprite.get_size()
	var rect := _texture_draw_rect()
	var local := canvas_pos - rect.position
	local.x = clampf(local.x, 0.0, rect.size.x)
	local.y = clampf(local.y, 0.0, rect.size.y)
	var nx := local.x / maxf(rect.size.x, 1.0)
	var ny := local.y / maxf(rect.size.y, 1.0)
	var pixel := Vector2(nx * tex_size.x, ny * tex_size.y)
	return pixel - tex_size * 0.5
