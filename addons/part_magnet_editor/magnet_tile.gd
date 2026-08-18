@tool
extends Control

## One part + one pose. Drag the colored dots onto the metal spheres.
## Mouse wheel zooms. Right-drag (or left-drag on empty space) pans.

signal magnets_changed
signal expand_requested

const TITLE_H := 0.0
const DISC_RADIUS := 7.0
const HIT_RADIUS := 16.0
const ZOOM_MIN := 1.0
const ZOOM_MAX := 8.0
const SOCKET_COLORS := {
	"neck": Color(0.35, 0.82, 0.95, 1),
	"up": Color(0.35, 0.82, 0.95, 1),
	"down": Color(0.95, 0.28, 0.32, 1),
	"shoulder_l": Color(0.96, 0.55, 0.22, 1),
	"shoulder_r": Color(0.95, 0.35, 0.28, 1),
	"ground": Color(0.38, 0.86, 0.52, 1),
}
const SOCKET_LABELS := {
	"neck": "PESCOÇO",
	"up": "CIMA",
	"down": "BAIXO",
	"shoulder_l": "OE",
	"shoulder_r": "OD",
	"ground": "CHÃO",
}

var part: PartDef
var pose: int = 0
var start_zoom := 1.0
var can_expand := true

var _undo: EditorUndoRedoManager
var _drag_socket := ""
var _grab_offset := Vector2.ZERO
var _undo_prop := ""
var _undo_old := Vector2.ZERO
var _zoom := 1.0
var _pan := Vector2.ZERO
var _panning := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_MOVE
	clip_contents = true
	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = Vector2(260, 260)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	resized.connect(_on_resized)
	_undo = EditorInterface.get_editor_undo_redo()

func set_target(next_part: PartDef, next_pose: int) -> void:
	var changed := part != next_part or pose != next_pose
	part = next_part
	pose = next_pose
	if changed:
		reset_view()
	queue_redraw()

func reset_view() -> void:
	_zoom = start_zoom
	var view := _view_rect()
	var side := view.size.x * _zoom
	_pan = Vector2((view.size.x - side) * 0.5, (view.size.y - side) * 0.5)
	_clamp_pan()
	queue_redraw()

func zoom_by(factor: float, pivot: Vector2 = Vector2.ZERO) -> void:
	if pivot == Vector2.ZERO:
		pivot = _view_rect().get_center()
	_adjust_zoom(pivot, factor)

func _on_resized() -> void:
	_clamp_pan()
	queue_redraw()

func _draw() -> void:
	var view := _view_rect()
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.04, 0.04, 0.05, 1), true)
	draw_rect(view, Color(0.04, 0.04, 0.05, 1), true)
	var rect := _image_rect()
	var tex := _texture()
	if part == null:
		draw_string(
			ThemeDB.fallback_font,
			rect.position + Vector2(8, 22),
			"sem peça",
			HORIZONTAL_ALIGNMENT_LEFT,
			rect.size.x - 16,
			12,
			Color(0.7, 0.7, 0.72)
		)
		return
	if tex == null:
		draw_string(
			ThemeDB.fallback_font,
			rect.position + Vector2(8, 22),
			"sem desenho",
			HORIZONTAL_ALIGNMENT_LEFT,
			rect.size.x - 16,
			12,
			Color(0.95, 0.7, 0.3)
		)
		return
	part.draw_transformed(self, tex, rect, pose)
	for socket in part.socket_names():
		_draw_marker(part.socket_for(socket, tex), _socket_label(socket), _socket_color(socket), _drag_socket == socket)
	if _zoom > 1.01:
		draw_string(
			ThemeDB.fallback_font,
			_view_rect().position + Vector2(6, 16),
			"%d%%" % int(round(_zoom * 100.0)),
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			12,
			Color(0.86, 0.88, 0.92, 0.85)
		)

func _gui_input(event: InputEvent) -> void:
	if part == null or _texture() == null:
		return
	if event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.button_index == MOUSE_BUTTON_WHEEL_UP and mouse.pressed:
			_adjust_zoom(mouse.position, 1.18)
			accept_event()
			return
		if mouse.button_index == MOUSE_BUTTON_WHEEL_DOWN and mouse.pressed:
			_adjust_zoom(mouse.position, 1.0 / 1.18)
			accept_event()
			return
		if mouse.button_index == MOUSE_BUTTON_LEFT and mouse.double_click:
			if can_expand:
				expand_requested.emit()
			accept_event()
			return
		if mouse.button_index == MOUSE_BUTTON_RIGHT:
			_panning = mouse.pressed
			accept_event()
			return
		if mouse.button_index == MOUSE_BUTTON_LEFT:
			if mouse.pressed:
				if not _begin_drag(mouse.position) and _zoom > 1.01:
					_panning = true
			else:
				_panning = false
				_end_drag()
			accept_event()
			return
	elif event is InputEventMouseMotion:
		var motion := event as InputEventMouseMotion
		if _panning:
			_pan += motion.relative
			_clamp_pan()
			queue_redraw()
			accept_event()
		elif _drag_socket != "":
			_update_drag(motion.position)
			accept_event()

func _begin_drag(mouse: Vector2) -> bool:
	if not _image_rect().has_point(mouse):
		return false
	var pick := ""
	var pick_screen := Vector2.ZERO
	var best := HIT_RADIUS * HIT_RADIUS
	var tex := _texture()
	for socket in part.socket_names():
		var screen := _visual_to_canvas(part.magnet_to_visual(part.socket_for(socket, tex), pose))
		var d := mouse.distance_squared_to(screen)
		if d <= best:
			best = d
			pick = socket
			pick_screen = screen
	if pick == "":
		return false
	_drag_socket = pick
	_grab_offset = mouse - pick_screen
	_undo_prop = _property_for(pick)
	_undo_old = part.get(_undo_prop) as Vector2
	_ensure_pose_copied()
	queue_redraw()
	return true

func _update_drag(mouse: Vector2) -> void:
	var magnet := part.visual_to_magnet(_canvas_to_visual(mouse - _grab_offset), pose)
	part.set_socket(_drag_socket, pose, magnet)
	part.emit_changed()
	queue_redraw()
	magnets_changed.emit()

func _end_drag() -> void:
	if _drag_socket == "":
		return
	if _undo == null or part == null or _undo_prop == "":
		_drag_socket = ""
		_save_part()
		queue_redraw()
		return
	_drag_socket = ""
	_undo.create_action("Mover ímã")
	_undo.add_do_property(part, _undo_prop, part.get(_undo_prop))
	_undo.add_undo_property(part, _undo_prop, _undo_old)
	_undo.add_do_method(self, "_after_magnet_changed")
	_undo.add_undo_method(self, "_after_magnet_changed")
	_undo.commit_action()
	queue_redraw()

func _after_magnet_changed() -> void:
	if part != null:
		part.emit_changed()
	_save_part()
	queue_redraw()
	magnets_changed.emit()

func _save_part() -> void:
	if part == null or part.resource_path.is_empty():
		return
	ResourceSaver.save(part, part.resource_path)

func _ensure_pose_copied() -> void:
	if pose != 1 or part.profile_magnets_marked():
		return
	for socket in part.socket_names():
		part.set_socket(socket, 1, part.socket_for(socket, part.sprite))

func _property_for(socket: String) -> String:
	var profile := pose == 1
	match socket:
		"up":
			return "magnet_up_profile" if profile else "magnet_up"
		"down":
			return "magnet_down_profile" if profile else "magnet_down"
		"neck":
			return "magnet_neck_profile" if profile else "magnet_neck"
		"shoulder_l":
			return "magnet_shoulder_l_profile" if profile else "magnet_shoulder_l"
		"shoulder_r":
			return "magnet_shoulder_r_profile" if profile else "magnet_shoulder_r"
		"ground":
			return "magnet_ground_profile" if profile else "magnet_ground"
		_:
			return "magnet_up"

func _texture() -> Texture2D:
	if part == null:
		return null
	return part.texture_for_pose(pose)

func _view_rect() -> Rect2:
	var side := minf(size.x, maxf(size.y - TITLE_H, 1.0))
	return Rect2(Vector2(0.0, TITLE_H), Vector2(side, side))

func _image_rect() -> Rect2:
	var view := _view_rect()
	var side := view.size.x * _zoom
	return Rect2(view.position + _pan, Vector2(side, side))

func _adjust_zoom(pivot: Vector2, factor: float) -> void:
	var view := _view_rect()
	var old_rect := _image_rect()
	var uv := (pivot - old_rect.position) / maxf(old_rect.size.x, 1.0)
	_zoom = clampf(_zoom * factor, ZOOM_MIN, ZOOM_MAX)
	var new_side := view.size.x * _zoom
	_pan = (pivot - view.position) - uv * new_side
	_clamp_pan()
	queue_redraw()

func _clamp_pan() -> void:
	var view := _view_rect()
	var side := view.size.x * _zoom
	var min_pan := view.size.x - side
	if _zoom <= 1.001:
		_pan = Vector2.ZERO
		return
	_pan.x = clampf(_pan.x, min_pan, 0.0)
	_pan.y = clampf(_pan.y, min_pan, 0.0)

func _draw_marker(magnet: Vector2, label: String, color: Color, active: bool) -> void:
	var p := _visual_to_canvas(part.magnet_to_visual(magnet, pose))
	var radius := DISC_RADIUS + 3.0 if active else DISC_RADIUS
	draw_circle(p, radius + 2.0, Color(0, 0, 0, 0.65))
	draw_circle(p, radius, color)
	draw_arc(p, radius, 0.0, TAU, 24, Color.WHITE, 1.2, true)
	draw_string(ThemeDB.fallback_font, p + Vector2(8, 4), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, color)

func _visual_to_canvas(visual: Vector2) -> Vector2:
	var tex := _texture()
	var tex_size := tex.get_size() if tex != null else Vector2(200, 200)
	var rect := _image_rect()
	var pixel := visual + tex_size * 0.5
	var nx := pixel.x / maxf(tex_size.x, 1.0)
	var ny := pixel.y / maxf(tex_size.y, 1.0)
	return rect.position + Vector2(nx * rect.size.x, ny * rect.size.y)

func _canvas_to_visual(canvas_pos: Vector2) -> Vector2:
	var tex := _texture()
	var tex_size := tex.get_size() if tex != null else Vector2(200, 200)
	var rect := _image_rect()
	var local := canvas_pos - rect.position
	local.x = clampf(local.x, 0.0, rect.size.x)
	local.y = clampf(local.y, 0.0, rect.size.y)
	var nx := local.x / maxf(rect.size.x, 1.0)
	var ny := local.y / maxf(rect.size.y, 1.0)
	var pixel := Vector2(nx * tex_size.x, ny * tex_size.y)
	return Vector2(roundf(pixel.x - tex_size.x * 0.5), roundf(pixel.y - tex_size.y * 0.5))

func _socket_label(socket: String) -> String:
	if SOCKET_LABELS.has(socket):
		return str(SOCKET_LABELS[socket])
	return socket

func _socket_color(socket: String) -> Color:
	if SOCKET_COLORS.has(socket):
		return Color(SOCKET_COLORS[socket])
	return Color.WHITE
