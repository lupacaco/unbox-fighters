@tool
extends Control

## One part + one pose. Drag the colored dots onto the metal spheres.

signal magnets_changed

const TITLE_H := 0.0
const DISC_RADIUS := 7.0
const HIT_RADIUS := 16.0
const SOCKET_COLORS := {
	"neck": Color(0.35, 0.82, 0.95, 1),
	"up": Color(0.35, 0.82, 0.95, 1),
	"down": Color(0.95, 0.28, 0.32, 1),
	"shoulder_l": Color(0.96, 0.55, 0.22, 1),
	"shoulder_r": Color(0.95, 0.35, 0.28, 1),
	"hip_l": Color(0.38, 0.86, 0.52, 1),
	"hip_r": Color(0.22, 0.78, 0.72, 1),
}
const SOCKET_LABELS := {
	"neck": "PESCOÇO",
	"up": "CIMA",
	"down": "BAIXO",
	"shoulder_l": "OE",
	"shoulder_r": "OD",
	"hip_l": "QE",
	"hip_r": "QD",
}

var part: PartDef
var pose: int = 0

var _undo: EditorUndoRedoManager
var _drag_socket := ""
var _grab_offset := Vector2.ZERO
var _undo_prop := ""
var _undo_old := Vector2.ZERO

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_MOVE
	custom_minimum_size = Vector2(220, 220)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	resized.connect(queue_redraw)
	_undo = EditorInterface.get_editor_undo_redo()

func set_target(next_part: PartDef, next_pose: int) -> void:
	part = next_part
	pose = next_pose
	queue_redraw()

func _draw() -> void:
	var rect := _image_rect()
	draw_rect(rect, Color(0.04, 0.04, 0.05, 1), true)
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

func _gui_input(event: InputEvent) -> void:
	if part == null or _texture() == null:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_begin_drag(event.position)
		else:
			_end_drag()
		accept_event()
	elif event is InputEventMouseMotion and _drag_socket != "":
		_update_drag(event.position)
		accept_event()

func _begin_drag(mouse: Vector2) -> void:
	if not _image_rect().has_point(mouse):
		return
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
		return
	_drag_socket = pick
	_grab_offset = mouse - pick_screen
	_undo_prop = _property_for(pick)
	_undo_old = part.get(_undo_prop) as Vector2
	_ensure_pose_copied()
	queue_redraw()

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
		"hip_l":
			return "magnet_hip_l_profile" if profile else "magnet_hip_l"
		"hip_r":
			return "magnet_hip_r_profile" if profile else "magnet_hip_r"
		_:
			return "magnet_up"

func _texture() -> Texture2D:
	if part == null:
		return null
	return part.texture_for_pose(pose)

func _image_rect() -> Rect2:
	var avail := Vector2(size.x, maxf(size.y - TITLE_H, 1.0))
	var side := minf(avail.x, avail.y)
	var origin := Vector2((size.x - side) * 0.5, TITLE_H + (avail.y - side) * 0.5)
	return Rect2(origin, Vector2(side, side))

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
