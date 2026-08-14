@tool
extends VBoxContainer

## Drag CIMA / BAIXO / ARMA discs on the part image, matching the Unity magnet tool.

const POSE_LABELS: PackedStringArray = ["Frente", "De lado", "Golpe"]
const UP_COLOR := Color(0.35, 0.82, 0.95, 1)
const DOWN_COLOR := Color(0.95, 0.28, 0.32, 1)
const WEAPON_COLOR := Color(0.95, 0.78, 0.18, 1)
const DISC_RADIUS := 8.0
const HIT_RADIUS := 18.0
const MIX_HEIGHT := 280.0

enum DragMagnet { NONE, UP, DOWN, WEAPON }

var show_mix: bool = false

var _part: PartDef
var _pose: int = 0
var _preview_head: PartDef
var _preview_body: PartDef
var _preview_legs: PartDef
var _undo: EditorUndoRedoManager

var _help: Label
var _pose_row: HBoxContainer
var _canvas: Control
var _coords: Label
var _mix_box: VBoxContainer
var _head_pick: EditorResourcePicker
var _body_pick: EditorResourcePicker
var _legs_pick: EditorResourcePicker
var _mix_canvas: Control

var _drag: DragMagnet = DragMagnet.NONE
var _grab_offset := Vector2.ZERO
var _undo_props: PackedStringArray = []
var _undo_olds: Array[Vector2] = []

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
	title.text = "Ímãs — arraste as bolinhas no desenho"
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
	_canvas.custom_minimum_size = Vector2(300, 200)
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
	mix_help.text = "Troque cabeça, tronco ou pernas para ver se o pescoço, a cintura e a arma batem."
	mix_help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mix_help.modulate = Color(0.78, 0.8, 0.84, 1)
	_mix_box.add_child(mix_help)

	_head_pick = _make_picker("Cabeça")
	_body_pick = _make_picker("Tronco")
	_legs_pick = _make_picker("Pernas")

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

func _make_picker(label_text: String) -> EditorResourcePicker:
	var row := HBoxContainer.new()
	_mix_box.add_child(row)
	var lab := Label.new()
	lab.text = label_text
	lab.custom_minimum_size.x = 72
	row.add_child(lab)
	var picker := EditorResourcePicker.new()
	picker.base_type = "PartDef"
	picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	picker.resource_changed.connect(func(res: Resource) -> void:
		_on_mix_resource_changed(label_text, res)
	)
	row.add_child(picker)
	return picker

func _on_mix_resource_changed(which: String, res: Resource) -> void:
	var part := res as PartDef
	match which:
		"Cabeça":
			_preview_head = part
		"Tronco":
			_preview_body = part
		_:
			_preview_legs = part
	if _mix_canvas != null:
		_mix_canvas.queue_redraw()

func _fill_preview_from_set() -> void:
	if _part == null:
		return
	match _part.slot_type:
		PartSlotType.Value.HEAD:
			_preview_head = _part
		PartSlotType.Value.BODY:
			_preview_body = _part
		_:
			_preview_legs = _part
	if _preview_head != null and _preview_body != null and _preview_legs != null:
		_apply_pickers()
		return
	for character in _load_characters():
		if character == null:
			continue
		if character.head != _part and character.body != _part and character.legs != _part:
			continue
		if _preview_head == null:
			_preview_head = character.head
		if _preview_body == null:
			_preview_body = character.body
		if _preview_legs == null:
			_preview_legs = character.legs
		break
	_apply_pickers()

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
	if _head_pick != null:
		_head_pick.edited_resource = _preview_head
	if _body_pick != null:
		_body_pick.edited_resource = _preview_body
	if _legs_pick != null:
		_legs_pick.edited_resource = _preview_legs

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
		return "Clique numa peça na pasta FileSystem: data → parts.\nExemplo: cachorro_head ou medico_body."
	match part.slot_type:
		PartSlotType.Value.HEAD:
			return "Cabeça: arraste a bolinha vermelha BAIXO até a base do pescoço."
		PartSlotType.Value.LEGS:
			return "Pernas: arraste a bolinha azul CIMA até o topo da cintura."
		_:
			return "Tronco: CIMA no pescoço, BAIXO na cintura, ARMA (dourada) na mão que vai segurar a arma."

func _current_texture() -> Texture2D:
	if _part == null:
		return null
	return _part.texture_for_pose(_pose)

func _refresh_coords() -> void:
	if _coords == null:
		return
	if _part == null:
		_coords.text = ""
		return
	var bits: PackedStringArray = []
	if _part.uses_magnet_up():
		var up := _magnet_up()
		bits.append("Cima: %.0f, %.0f" % [up.x, up.y])
	if _part.uses_magnet_down():
		var down := _magnet_down()
		bits.append("Baixo: %.0f, %.0f" % [down.x, down.y])
	if _part.uses_weapon_magnet():
		var weapon := _magnet_weapon()
		bits.append("Arma: %.0f, %.0f" % [weapon.x, weapon.y])
	_coords.text = "   |   ".join(bits)

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
	if _part.uses_magnet_up():
		_draw_marker(_magnet_up(), "CIMA", UP_COLOR, _drag == DragMagnet.UP)
	if _part.uses_magnet_down():
		_draw_marker(_magnet_down(), "BAIXO", DOWN_COLOR, _drag == DragMagnet.DOWN)
	if _part.uses_weapon_magnet():
		_draw_marker(_magnet_weapon(), "ARMA", WEAPON_COLOR, _drag == DragMagnet.WEAPON)

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
	elif event is InputEventMouseMotion and _drag != DragMagnet.NONE:
		_update_drag(event.position)
		_canvas.accept_event()

func _begin_drag(mouse: Vector2) -> void:
	var pick := DragMagnet.NONE
	var pick_screen := Vector2.ZERO
	var best := HIT_RADIUS * HIT_RADIUS
	var candidates: Array = []
	if _part.uses_magnet_up():
		candidates.append([DragMagnet.UP, _magnet_to_canvas(_magnet_up())])
	if _part.uses_magnet_down():
		candidates.append([DragMagnet.DOWN, _magnet_to_canvas(_magnet_down())])
	if _part.uses_weapon_magnet():
		candidates.append([DragMagnet.WEAPON, _magnet_to_canvas(_magnet_weapon())])
	for item in candidates:
		var d: float = mouse.distance_squared_to(item[1])
		if d <= best:
			best = d
			pick = item[0]
			pick_screen = item[1]
	if pick == DragMagnet.NONE:
		return
	_drag = pick
	_grab_offset = mouse - pick_screen
	_capture_undo(pick)
	_ensure_pose_copied(pick)

func _update_drag(mouse: Vector2) -> void:
	var magnet := _canvas_to_magnet(mouse - _grab_offset)
	_set_magnet(_drag, magnet)
	_part.emit_changed()
	_refresh_coords()
	_canvas.queue_redraw()
	if _mix_canvas != null:
		_mix_canvas.queue_redraw()

func _capture_undo(kind: DragMagnet) -> void:
	_undo_props = PackedStringArray()
	_undo_olds.clear()
	for prop in _affected_props(kind):
		_undo_props.append(prop)
		_undo_olds.append(_part.get(prop) as Vector2)

func _affected_props(kind: DragMagnet) -> PackedStringArray:
	if kind == DragMagnet.WEAPON:
		return _props_for(kind)
	if _pose == 1:
		return PackedStringArray(["magnet_up_profile", "magnet_down_profile"])
	if _pose == 2:
		return PackedStringArray(["magnet_up_attack", "magnet_down_attack"])
	return _props_for(kind)

func _end_drag() -> void:
	if _drag == DragMagnet.NONE:
		return
	_drag = DragMagnet.NONE
	if _undo == null or _part == null:
		return
	_undo.create_action("Mover ímã")
	for i in _undo_props.size():
		var prop := _undo_props[i]
		_undo.add_do_property(_part, prop, _part.get(prop))
		_undo.add_undo_property(_part, prop, _undo_olds[i])
	_undo.add_do_method(self, "_after_magnet_changed")
	_undo.add_undo_method(self, "_after_magnet_changed")
	_undo.commit_action()
	_canvas.queue_redraw()

func _props_for(kind: DragMagnet) -> PackedStringArray:
	if kind == DragMagnet.WEAPON:
		if _pose == 1:
			return PackedStringArray(["magnet_weapon_profile"])
		if _pose == 2:
			return PackedStringArray(["magnet_weapon_attack"])
		return PackedStringArray(["magnet_weapon"])
	var up := "magnet_up"
	var down := "magnet_down"
	if _pose == 1:
		up = "magnet_up_profile"
		down = "magnet_down_profile"
	elif _pose == 2:
		up = "magnet_up_attack"
		down = "magnet_down_attack"
	if kind == DragMagnet.UP:
		return PackedStringArray([up])
	return PackedStringArray([down])

func _after_magnet_changed() -> void:
	if _part != null:
		_part.emit_changed()
	_refresh_coords()
	if _canvas != null:
		_canvas.queue_redraw()
	if _mix_canvas != null:
		_mix_canvas.queue_redraw()

func _magnet_up() -> Vector2:
	return _part.magnet_up_for(_current_texture())

func _magnet_down() -> Vector2:
	return _part.magnet_down_for(_current_texture())

func _magnet_weapon() -> Vector2:
	return _part.magnet_weapon_for(_current_texture())

func _ensure_pose_copied(kind: DragMagnet) -> void:
	if kind == DragMagnet.WEAPON:
		if _pose == 1 and not _part.weapon_profile_marked():
			_part.magnet_weapon_profile = _part.magnet_weapon
		if _pose == 2 and not _part.weapon_attack_marked():
			_part.magnet_weapon_attack = _part.magnet_weapon
		return
	if _pose == 1 and not _part.profile_magnets_marked():
		_part.magnet_up_profile = _part.magnet_up
		_part.magnet_down_profile = _part.magnet_down
	if _pose == 2 and not _part.attack_magnets_marked():
		_part.magnet_up_attack = _part.magnet_up
		_part.magnet_down_attack = _part.magnet_down

func _set_magnet(kind: DragMagnet, magnet: Vector2) -> void:
	if kind == DragMagnet.UP:
		if _pose == 1:
			_part.magnet_up_profile = magnet
		elif _pose == 2:
			_part.magnet_up_attack = magnet
		else:
			_part.magnet_up = magnet
		return
	if kind == DragMagnet.DOWN:
		if _pose == 1:
			_part.magnet_down_profile = magnet
		elif _pose == 2:
			_part.magnet_down_attack = magnet
		else:
			_part.magnet_down = magnet
		return
	if _pose == 1:
		_part.magnet_weapon_profile = magnet
	elif _pose == 2:
		_part.magnet_weapon_attack = magnet
	else:
		_part.magnet_weapon = magnet

func _magnet_to_canvas(magnet: Vector2) -> Vector2:
	var tex := _current_texture()
	var tex_size := tex.get_size() if tex != null else Vector2(300, 200)
	var rect := _image_rect()
	var pixel := magnet + tex_size * 0.5
	var nx := pixel.x / maxf(tex_size.x, 1.0)
	var ny := pixel.y / maxf(tex_size.y, 1.0)
	return rect.position + Vector2(nx * rect.size.x, ny * rect.size.y)

func _canvas_to_magnet(canvas_pos: Vector2) -> Vector2:
	var tex := _current_texture()
	var tex_size := tex.get_size() if tex != null else Vector2(300, 200)
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
	var hs := _tex_or_front(_preview_head)
	var bs := _tex_or_front(_preview_body)
	var ls := _tex_or_front(_preview_legs)
	if hs == null and bs == null and ls == null:
		return
	var plan := CompositeResolver.resolve_parts(_preview_head, _preview_body, _preview_legs, hs, bs, ls)
	var s := 0.55
	var origin := box.get_center()
	_draw_mix_part(ls, plan["legs_pos"], s, origin, box)
	_draw_mix_part(bs, plan["body_pos"], s, origin, box)
	_draw_mix_part(hs, plan["head_pos"], s, origin, box)
	if _preview_body != null and _preview_body.uses_weapon_magnet():
		var p: Vector2 = origin + plan["weapon_pos"] * s
		_mix_canvas.draw_circle(p, 6.0, WEAPON_COLOR)
		_mix_canvas.draw_arc(p, 6.0, 0.0, TAU, 16, Color.WHITE, 1.0, true)

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
