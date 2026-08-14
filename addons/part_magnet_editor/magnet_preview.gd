@tool
extends VBoxContainer

## Drag the metal-sphere magnets on the part image.

const POSE_LABELS: PackedStringArray = ["Frente", "De lado"]
const DISC_RADIUS := 8.0
const HIT_RADIUS := 18.0
const MIX_HEIGHT := 320.0
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
	"shoulder_l": "OMBRO E",
	"shoulder_r": "OMBRO D",
	"hip_l": "QUADRIL E",
	"hip_r": "QUADRIL D",
}

var show_mix: bool = false

var _part: PartDef
var _pose: int = 0
var _preview_parts: Dictionary = {}
var _undo: EditorUndoRedoManager

var _help: Label
var _pose_row: HBoxContainer
var _canvas: Control
var _coords: Label
var _mix_box: VBoxContainer
var _pickers: Dictionary = {}
var _mix_canvas: Control

var _drag_socket := ""
var _grab_offset := Vector2.ZERO
var _undo_prop := ""
var _undo_old := Vector2.ZERO

func setup(part: PartDef, with_mix: bool = false) -> void:
	_part = part
	show_mix = with_mix
	_undo = EditorInterface.get_editor_undo_redo()
	if _help == null:
		_build_ui()
	_fill_preview_from_set()
	_refresh_all()

func set_part(part: PartDef) -> void:
	setup(part, show_mix)

func _build_ui() -> void:
	add_theme_constant_override("separation", 8)

	var title := Label.new()
	title.text = "Ímãs — arraste as bolinhas até as esferas de metal"
	title.add_theme_font_size_override("font_size", 15)
	add_child(title)

	_help = Label.new()
	_help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_help.modulate = Color(0.78, 0.8, 0.84, 1)
	add_child(_help)

	_pose_row = HBoxContainer.new()
	_pose_row.add_theme_constant_override("separation", 6)
	add_child(_pose_row)
	var group := ButtonGroup.new()
	for i in POSE_LABELS.size():
		_add_pose_button(i, group)

	_canvas = Control.new()
	_canvas.custom_minimum_size = Vector2(200, 200)
	_canvas.mouse_filter = Control.MOUSE_FILTER_STOP
	_canvas.draw.connect(_on_canvas_draw)
	_canvas.gui_input.connect(_on_canvas_gui_input)
	_canvas.mouse_default_cursor_shape = Control.CURSOR_MOVE
	add_child(_canvas)

	_coords = Label.new()
	_coords.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_coords)

	if not show_mix:
		return

	_mix_box = VBoxContainer.new()
	_mix_box.add_theme_constant_override("separation", 6)
	add_child(_mix_box)

	var mix_title := Label.new()
	mix_title.text = "Prévia do encaixe (mistura)"
	_mix_box.add_child(mix_title)

	var mix_help := Label.new()
	mix_help.text = "Troque as 6 peças para ver se pescoço, ombros e quadris batem nas esferas."
	mix_help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mix_help.modulate = Color(0.78, 0.8, 0.84, 1)
	_mix_box.add_child(mix_help)

	for slot in PartSlotType.all_slots():
		_pickers[slot] = _make_picker(slot)

	_mix_canvas = Control.new()
	_mix_canvas.custom_minimum_size = Vector2(0, MIX_HEIGHT)
	_mix_canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_mix_canvas.draw.connect(_on_mix_draw)
	_mix_box.add_child(_mix_canvas)

func _add_pose_button(pose_i: int, group: ButtonGroup) -> void:
	var btn := Button.new()
	btn.text = POSE_LABELS[pose_i]
	btn.toggle_mode = true
	btn.button_group = group
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.pressed.connect(func() -> void:
		_pose = pose_i
		_refresh_all()
	)
	_pose_row.add_child(btn)

func _make_picker(slot: PartSlotType.Value) -> EditorResourcePicker:
	var row := HBoxContainer.new()
	_mix_box.add_child(row)
	var lab := Label.new()
	lab.text = PartSlotType.display_label(slot)
	lab.custom_minimum_size.x = 78
	row.add_child(lab)
	var picker := EditorResourcePicker.new()
	picker.base_type = "PartDef"
	picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	picker.resource_changed.connect(func(res: Resource) -> void:
		_preview_parts[slot] = res as PartDef
		if _mix_canvas != null:
			_mix_canvas.queue_redraw()
	)
	row.add_child(picker)
	return picker

func _fill_preview_from_set() -> void:
	if _part == null:
		return
	_preview_parts[_part.slot_type] = _part
	var filled := _preview_complete()
	if filled:
		_apply_pickers()
		return
	for character in _load_characters():
		if character == null:
			continue
		var owns := false
		for slot in PartSlotType.all_slots():
			if character.get_part(slot) == _part:
				owns = true
				break
		if not owns:
			continue
		for slot in PartSlotType.all_slots():
			if not _preview_parts.has(slot) or _preview_parts[slot] == null:
				_preview_parts[slot] = character.get_part(slot)
		break
	_apply_pickers()

func _preview_complete() -> bool:
	for slot in PartSlotType.all_slots():
		if not _preview_parts.has(slot) or _preview_parts[slot] == null:
			return false
	return true

func _load_characters() -> Array[CharacterDef]:
	var list := ShopPool.roster()
	if not list.is_empty():
		return list
	var found: Array[CharacterDef] = []
	var dir := DirAccess.open("res://data/parts")
	if dir == null:
		return found
	dir.list_dir_begin()
	var fname := dir.get_next()
	while fname != "":
		if not dir.current_is_dir() and fname.ends_with("_character.tres"):
			var character := load("res://data/parts/%s" % fname) as CharacterDef
			if character != null:
				found.append(character)
		fname = dir.get_next()
	return found

func _apply_pickers() -> void:
	for slot in _pickers.keys():
		var picker := _pickers[slot] as EditorResourcePicker
		if picker != null:
			picker.edited_resource = _preview_parts.get(slot) as Resource

func _refresh_all() -> void:
	_help.text = _help_for(_part)
	if _pose_row != null:
		for i in _pose_row.get_child_count():
			var btn := _pose_row.get_child(i) as Button
			if btn != null:
				btn.button_pressed = i == _pose
	_refresh_coords()
	if _canvas != null:
		var tex := _current_texture()
		if tex != null:
			var size := tex.get_size()
			var max_w := 360.0
			var s := max_w / maxf(size.x, 1.0)
			_canvas.custom_minimum_size = Vector2(size.x * s, size.y * s)
		_canvas.queue_redraw()
	if _mix_canvas != null:
		_mix_canvas.queue_redraw()

func _help_for(part: PartDef) -> String:
	if part == null:
		return "Clique numa peça na pasta FileSystem: data → parts.\nExemplo: leao_head ou leao_body."
	if part.is_torso():
		return "Tronco: 5 ímãs. PESCOÇO no topo, OMBRO E/D nas laterais, QUADRIL E/D embaixo. Arraste cada bolinha até a esfera de metal."
	if part.slot_type == PartSlotType.Value.HEAD:
		return "Cabeça: arraste a bolinha vermelha BAIXO até a esfera na base do pescoço."
	return "Braço ou perna: arraste a bolinha azul CIMA até a esfera no topo."

func _current_texture() -> Texture2D:
	if _part == null:
		return null
	return _part.texture_for_pose(_pose)

func _sockets() -> PackedStringArray:
	if _part == null:
		return PackedStringArray()
	return _part.socket_names()

func _refresh_coords() -> void:
	if _coords == null:
		return
	if _part == null:
		_coords.text = ""
		return
	var bits: PackedStringArray = []
	for socket in _sockets():
		var magnet := _part.socket_for(socket, _current_texture())
		bits.append("%s: %.0f, %.0f" % [_socket_label(socket), magnet.x, magnet.y])
	_coords.text = "   |   ".join(bits)

func _socket_label(socket: String) -> String:
	if SOCKET_LABELS.has(socket):
		return str(SOCKET_LABELS[socket])
	return socket

func _socket_color(socket: String) -> Color:
	if SOCKET_COLORS.has(socket):
		return Color(SOCKET_COLORS[socket])
	return Color.WHITE

func _image_rect() -> Rect2:
	return Rect2(Vector2.ZERO, _canvas.size)

func _on_canvas_draw() -> void:
	var rect := _image_rect()
	_canvas.draw_rect(rect, Color(0.04, 0.04, 0.05, 1), true)
	var tex := _current_texture()
	if _part == null:
		_canvas.draw_string(ThemeDB.fallback_font, Vector2(16, 28), "Clique numa peça em data/parts", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.8, 0.8, 0.8))
		return
	if tex == null:
		_canvas.draw_string(ThemeDB.fallback_font, Vector2(16, 28), "Esta pose ainda não tem desenho.", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.95, 0.7, 0.3))
		return
	_canvas.draw_texture_rect(tex, rect, false)
	for socket in _sockets():
		_draw_marker(_part.socket_for(socket, tex), _socket_label(socket), _socket_color(socket), _drag_socket == socket)

func _draw_marker(magnet: Vector2, label: String, color: Color, active: bool) -> void:
	var p := _magnet_to_canvas(magnet)
	var radius := DISC_RADIUS + 3.0 if active else DISC_RADIUS
	_canvas.draw_circle(p, radius + 2.0, Color(0, 0, 0, 0.65))
	_canvas.draw_circle(p, radius, color)
	_canvas.draw_arc(p, radius, 0.0, TAU, 24, Color.WHITE, 1.2, true)
	_canvas.draw_string(ThemeDB.fallback_font, p + Vector2(10, 4), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, color)

func _on_canvas_gui_input(event: InputEvent) -> void:
	if _part == null or _current_texture() == null:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_begin_drag(event.position)
		else:
			_end_drag()
		_canvas.accept_event()
	elif event is InputEventMouseMotion and _drag_socket != "":
		_update_drag(event.position)
		_canvas.accept_event()

func _begin_drag(mouse: Vector2) -> void:
	var pick := ""
	var pick_screen := Vector2.ZERO
	var best := HIT_RADIUS * HIT_RADIUS
	for socket in _sockets():
		var screen := _magnet_to_canvas(_part.socket_for(socket, _current_texture()))
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
	_undo_old = _part.get(_undo_prop) as Vector2
	_ensure_pose_copied()

func _update_drag(mouse: Vector2) -> void:
	var magnet := _canvas_to_magnet(mouse - _grab_offset)
	_part.set_socket(_drag_socket, _pose, magnet)
	_part.emit_changed()
	_refresh_coords()
	_canvas.queue_redraw()
	if _mix_canvas != null:
		_mix_canvas.queue_redraw()

func _end_drag() -> void:
	if _drag_socket == "":
		return
	if _undo == null or _part == null or _undo_prop == "":
		_drag_socket = ""
		return
	_drag_socket = ""
	_undo.create_action("Mover ímã")
	_undo.add_do_property(_part, _undo_prop, _part.get(_undo_prop))
	_undo.add_undo_property(_part, _undo_prop, _undo_old)
	_undo.add_do_method(self, "_after_magnet_changed")
	_undo.add_undo_method(self, "_after_magnet_changed")
	_undo.commit_action()
	_canvas.queue_redraw()

func _property_for(socket: String) -> String:
	var profile := _pose == 1
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

func _after_magnet_changed() -> void:
	if _part != null:
		_part.emit_changed()
	_refresh_coords()
	if _canvas != null:
		_canvas.queue_redraw()
	if _mix_canvas != null:
		_mix_canvas.queue_redraw()

func _ensure_pose_copied() -> void:
	if _pose != 1 or _part.profile_magnets_marked():
		return
	for socket in _sockets():
		_part.set_socket(socket, 1, _part.socket_for(socket, _part.sprite))

func _magnet_to_canvas(magnet: Vector2) -> Vector2:
	var tex := _current_texture()
	var tex_size := tex.get_size() if tex != null else Vector2(200, 200)
	var rect := _image_rect()
	var pixel := magnet + tex_size * 0.5
	var nx := pixel.x / maxf(tex_size.x, 1.0)
	var ny := pixel.y / maxf(tex_size.y, 1.0)
	return rect.position + Vector2(nx * rect.size.x, ny * rect.size.y)

func _canvas_to_magnet(canvas_pos: Vector2) -> Vector2:
	var tex := _current_texture()
	var tex_size := tex.get_size() if tex != null else Vector2(200, 200)
	var rect := _image_rect()
	var local := canvas_pos - rect.position
	local.x = clampf(local.x, 0.0, rect.size.x)
	local.y = clampf(local.y, 0.0, rect.size.y)
	var nx := local.x / maxf(rect.size.x, 1.0)
	var ny := local.y / maxf(rect.size.y, 1.0)
	var pixel := Vector2(nx * tex_size.x, ny * tex_size.y)
	return Vector2(roundf(pixel.x - tex_size.x * 0.5), roundf(pixel.y - tex_size.y * 0.5))

func _on_mix_draw() -> void:
	var box := Rect2(Vector2.ZERO, _mix_canvas.size)
	_mix_canvas.draw_rect(box, Color(0.07, 0.07, 0.09, 1), true)
	var textures := {}
	for slot in PartSlotType.all_slots():
		textures[slot] = _tex_or_front(_preview_parts.get(slot) as PartDef)
	var any := false
	for slot in textures.keys():
		if textures[slot] != null:
			any = true
			break
	if not any:
		return
	var plan := CompositeResolver.resolve_slots(_preview_parts, textures)
	var s := 0.62
	var origin := box.get_center() + Vector2(0, 12)
	var positions: Dictionary = plan.get("positions", {})
	for slot in PartSlotType.draw_order():
		_draw_mix_part(textures.get(slot), positions.get(slot, Vector2.ZERO), s, origin, box)

func _tex_or_front(part: PartDef) -> Texture2D:
	if part == null:
		return null
	var tex := part.texture_for_pose(_pose)
	return tex if tex != null else part.sprite

func _draw_mix_part(tex: Texture2D, image_pos: Vector2, scale: float, origin: Vector2, box: Rect2) -> void:
	if tex == null:
		return
	var size := tex.get_size() * scale
	var r := Rect2(origin + image_pos * scale - size * 0.5, size)
	if not box.intersects(r):
		return
	_mix_canvas.draw_texture_rect(tex, r, false)
