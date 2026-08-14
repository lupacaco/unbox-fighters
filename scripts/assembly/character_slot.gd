class_name CharacterSlot
extends Node2D

signal part_attached(slot: CharacterSlot, part: PartDef)
signal part_detached(slot: CharacterSlot, part: PartDef)
signal card_drag_requested(slot: CharacterSlot)
signal assembly_changed(slot: CharacterSlot)

const TAG_OFFSETS := {
	PartSlotType.Value.HEAD: Vector2(108, -150),
	PartSlotType.Value.BODY: Vector2(108, -20),
	PartSlotType.Value.LEGS: Vector2(108, 110),
}

@onready var _card_shadow: Sprite2D = $CardShadow
@onready var _card_frame: Sprite2D = $CardFrame
@onready var _empty_hint: Label = $EmptyHint
@onready var _display_root: Node2D = $Display
@onready var _sprite_composite: Sprite2D = $Display/Composite
@onready var _highlight: Line2D = $DropHighlight
@onready var _glow: Polygon2D = $CompleteGlow
@onready var _readout: StatReadout = $StatReadout
@onready var _fight_button: Button = $FightButton

var character: CharacterDef
var queue_rank: int = 3
var _roster: Array[CharacterDef] = []
var _bound_parts: Dictionary = {}
var _layer_sprites: Dictionary = {}
var _zones: Dictionary = {}
var _crossfade_busy: bool = false
var _rest_y: float = 0.0
var _fight_locked: bool = false
var _lifted: bool = false
var _rank_label: Label
var _tags: Dictionary = {}
var _grip: Area2D
var _card_motion: Tween

func setup(def: CharacterDef = null, roster: Array[CharacterDef] = []) -> void:
	character = def
	_roster = roster
	_rest_y = position.y
	_lifted = false
	visible = true
	scale = Vector2.ONE
	modulate.a = 1.0
	_readout.set_display_name("???")
	_readout.set_from_loadout(FighterLoadout.new())
	_readout.set_complete(false)
	_glow.visible = false
	_highlight.visible = false
	_build_visuals()
	_setup_zones()
	_hide_fight_button()
	_ensure_rank_label()
	_ensure_tags()
	_ensure_grip()
	_refresh_display(false)
	_refresh_tags()

func set_queue_rank(rank: int) -> void:
	queue_rank = rank
	_ensure_rank_label()
	_rank_label.text = "%dº" % rank

func to_loadout() -> FighterLoadout:
	var loadout := FighterLoadout.new()
	for slot in PartSlotType.shop_slots():
		loadout.set_part(slot, get_attached_part(slot))
	return loadout

func steal_all_parts() -> Dictionary:
	var stolen := {}
	for slot in PartSlotType.shop_slots():
		var view := detach_part(slot, false)
		if view != null:
			stolen[slot] = view
	_refresh_display(false)
	_update_stats()
	return stolen

func receive_parts(parts: Dictionary) -> void:
	for slot in parts.keys():
		var view: PartView = parts[slot]
		if view != null:
			try_attach(view)

func find_part_at(global_point: Vector2) -> PartView:
	if _fight_locked:
		return null
	for slot in PartSlotType.shop_slots():
		if not _bound_parts.has(slot):
			continue
		if _zone_contains(slot, global_point):
			var view: PartView = _bound_parts[slot]
			if view != null and is_instance_valid(view):
				return view
	return null

func play_leave_for_fight() -> void:
	if _lifted:
		return
	_lifted = true
	set_fight_locked(true)
	_kill_card_motion()
	_card_motion = create_tween()
	_card_motion.tween_property(self, "position:y", _rest_y - AssemblyLayout.CARD_LIFT, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_card_motion.parallel().tween_property(self, "scale", Vector2(0.78, 0.78), 0.4)
	_card_motion.parallel().tween_property(self, "modulate:a", 0.0, 0.38).set_trans(Tween.TRANS_SINE)
	_card_motion.tween_callback(func() -> void:
		position.y = _rest_y
		scale = Vector2.ONE
		modulate.a = 1.0
		visible = false
	)

func play_return_from_fight() -> void:
	_kill_card_motion()
	visible = true
	position.y = _rest_y - AssemblyLayout.CARD_SETTLE
	scale = Vector2(0.84, 0.84)
	modulate.a = 1.0
	_card_motion = create_tween()
	_card_motion.tween_property(self, "position:y", _rest_y, 0.42).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_card_motion.parallel().tween_property(self, "scale", Vector2.ONE, 0.42)
	_card_motion.tween_callback(func() -> void:
		_lifted = false
		set_fight_locked(false)
	)

func _kill_card_motion() -> void:
	if _card_motion != null and _card_motion.is_valid():
		_card_motion.kill()
	_card_motion = null

func contains_card_point(global_point: Vector2) -> bool:
	return Rect2(Vector2(-135, -205), Vector2(270, 400)).has_point(to_local(global_point))

func is_complete() -> bool:
	for slot in PartSlotType.shop_slots():
		if get_attached_part(slot) == null:
			return false
	return true

func get_attached_part(slot: PartSlotType.Value) -> PartDef:
	if not _bound_parts.has(slot):
		return null
	var view = _bound_parts[slot]
	if view == null or not is_instance_valid(view):
		_bound_parts.erase(slot)
		return null
	return (view as PartView).part_def

func set_fight_locked(locked: bool) -> void:
	_fight_locked = locked
	for key in _bound_parts.keys():
		var view = _bound_parts[key]
		if view != null and is_instance_valid(view):
			(view as PartView).lock_interaction(locked)

func attached_parts_can_fight() -> bool:
	if not is_complete():
		return false
	var visual := PartKit.expand_shop_parts(_shop_parts_map())
	for slot in PartSlotType.visual_slots():
		var part: PartDef = visual.get(slot)
		if part != null and part.sprite_profile == null:
			return false
	return true

func can_fight() -> bool:
	return attached_parts_can_fight() and not _fight_locked

func set_fighter_visible(visible_flag: bool) -> void:
	_display_root.visible = visible_flag

func get_fighter_global_position() -> Vector2:
	return _display_root.global_position

func has_any_part() -> bool:
	for slot in PartSlotType.shop_slots():
		if get_attached_part(slot) != null:
			return true
	return false

func can_accept(part: PartDef) -> bool:
	if _fight_locked or part == null:
		return false
	return PartSlotType.is_shop_slot(part.slot_type)

func can_accept_at(part: PartDef, global_point: Vector2) -> bool:
	if not can_accept(part):
		return false
	return _zone_contains(part.slot_type, global_point) or _contains_point_expanded(global_point)

func _zone_contains(slot: PartSlotType.Value, global_point: Vector2) -> bool:
	var zone := _zone_for(slot)
	if zone == null or not zone.has_meta("rect"):
		return false
	var rect: Rect2 = zone.get_meta("rect")
	return rect.has_point(to_local(global_point))

func try_attach(part_view: PartView) -> bool:
	if _fight_locked or part_view == null or part_view.part_def == null:
		return false
	if not can_accept(part_view.part_def):
		return false
	var slot := part_view.part_def.slot_type
	var displaced: PartView = null
	if _bound_parts.has(slot):
		displaced = detach_part(slot, false)
	var was_complete := is_complete()
	_bound_parts[slot] = part_view
	part_view.set_attached_slot(self)
	part_view.snap_hide_for_slot()
	_refresh_display(true)
	_update_stats()
	_pulse_attach()
	GameAudio.part_place()
	var now_complete := is_complete()
	if now_complete and not was_complete:
		GameAudio.fighter_complete()
	part_attached.emit(self, part_view.part_def)
	assembly_changed.emit(self)
	if displaced != null:
		displaced.return_to_tray()
	return true

func detach_part(slot: PartSlotType.Value, refresh: bool = true) -> PartView:
	if _fight_locked:
		return null
	if not _bound_parts.has(slot):
		return null
	var part_view: PartView = _bound_parts[slot]
	_bound_parts.erase(slot)
	part_view.set_attached_slot(null)
	if refresh:
		_refresh_display(true)
		_update_stats()
	part_detached.emit(self, part_view.part_def)
	assembly_changed.emit(self)
	return part_view

func set_drop_highlight(enabled: bool, slot: PartSlotType.Value) -> void:
	_highlight.visible = enabled
	if not enabled:
		return
	var zone := _zone_for(slot)
	if zone == null or not zone.has_meta("rect"):
		return
	var rect: Rect2 = zone.get_meta("rect")
	_highlight.points = PackedVector2Array([
		rect.position,
		rect.position + Vector2(rect.size.x, 0),
		rect.position + rect.size,
		rect.position + Vector2(0, rect.size.y),
		rect.position
	])
	_highlight.default_color = Color(0.77, 0.12, 0.23, 0.85)
	_highlight.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(_highlight, "modulate:a", 1.0, 0.16).set_trans(Tween.TRANS_SINE)

func play_intro(delay: float) -> void:
	modulate.a = 0.0
	position.y = _rest_y + 28.0
	var tween := create_tween()
	tween.tween_interval(delay)
	tween.tween_property(self, "modulate:a", 1.0, 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "position:y", _rest_y, 0.55).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _build_visuals() -> void:
	var frame_tex: Texture2D = load("res://assets/ui/frame_premium.png")
	_card_frame.texture = frame_tex
	_card_shadow.texture = frame_tex
	_card_frame.centered = true
	_card_shadow.centered = true
	var tex_size := frame_tex.get_size()
	var s := 450.0 / maxf(tex_size.y, 1.0)
	_card_frame.scale = Vector2.ONE * s
	_card_shadow.scale = Vector2.ONE * s
	_glow.polygon = PackedVector2Array([
		Vector2(-130, -200), Vector2(130, -200), Vector2(130, 180), Vector2(-130, 180)
	])
	_glow.color = Color(0.79, 0.7, 0.49, 0.1)
	_ensure_layers()

func _layer_name(slot: PartSlotType.Value) -> String:
	match slot:
		PartSlotType.Value.HEAD:
			return "Head"
		PartSlotType.Value.BODY:
			return "Body"
		PartSlotType.Value.ARM_L:
			return "ArmL"
		PartSlotType.Value.ARM_R:
			return "ArmR"
		PartSlotType.Value.LEG_L:
			return "LegL"
		PartSlotType.Value.LEGS:
			return "Legs"
		_:
			return "LegR"

func _ensure_layers() -> void:
	for slot in PartSlotType.draw_order():
		var node_name := _layer_name(slot)
		var sprite := _display_root.get_node_or_null(node_name) as Sprite2D
		if sprite == null:
			sprite = Sprite2D.new()
			sprite.name = node_name
			sprite.centered = true
			_display_root.add_child(sprite)
		_layer_sprites[slot] = sprite

func _setup_zones() -> void:
	var zones_root: Node2D = $Zones
	var rects := {
		PartSlotType.Value.HEAD: Rect2(-95, -190, 190, 110),
		PartSlotType.Value.BODY: Rect2(-105, -85, 210, 130),
		PartSlotType.Value.LEGS: Rect2(-95, 45, 190, 120),
	}
	for slot in PartSlotType.shop_slots():
		var node_name := _layer_name(slot)
		var zone := zones_root.get_node_or_null(node_name) as Area2D
		if zone == null:
			zone = Area2D.new()
			zone.name = node_name
			zone.collision_layer = 2
			zone.collision_mask = 0
			zones_root.add_child(zone)
		_configure_zone(zone, rects[slot])
		_zones[slot] = zone

func _configure_zone(zone: Area2D, rect: Rect2) -> void:
	zone.set_meta("rect", rect)
	zone.monitoring = false
	zone.monitorable = false
	zone.input_pickable = true
	if zone.get_meta("wired", false):
		for child in zone.get_children():
			var shape_node := child as CollisionShape2D
			if shape_node != null and shape_node.shape is RectangleShape2D:
				(shape_node.shape as RectangleShape2D).size = rect.size
				shape_node.position = rect.position + rect.size * 0.5
		return
	zone.set_meta("wired", true)
	var shape_owner := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	shape_owner.shape = shape
	shape_owner.position = rect.position + rect.size * 0.5
	zone.add_child(shape_owner)
	zone.input_event.connect(_on_zone_input.bind(zone))

func _on_zone_input(_viewport: Node, event: InputEvent, _shape_idx: int, zone: Area2D) -> void:
	if _fight_locked:
		return
	if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
		return
	var slot := _slot_for_zone(zone)
	if not _bound_parts.has(slot):
		return
	var part_view: PartView = detach_part(slot, true)
	if part_view == null:
		return
	part_view.visible = true
	part_view.global_position = get_viewport().get_mouse_position()
	var drag: DragDropService = get_tree().get_first_node_in_group("drag_drop_service") as DragDropService
	if drag != null:
		drag.begin_drag(part_view)
	get_viewport().set_input_as_handled()

func _slot_for_zone(zone: Area2D) -> PartSlotType.Value:
	for slot in _zones.keys():
		if _zones[slot] == zone:
			return slot
	return PartSlotType.Value.BODY

func _zone_for(slot: PartSlotType.Value) -> Area2D:
	return _zones.get(slot) as Area2D

func _contains_point_expanded(global_point: Vector2) -> bool:
	var local := to_local(global_point)
	return Rect2(Vector2(-135, -205), Vector2(270, 400)).has_point(local)

func _shop_parts_map() -> Dictionary:
	var shop := {}
	for slot in PartSlotType.shop_slots():
		shop[slot] = get_attached_part(slot)
	return shop

func _refresh_display(animate: bool) -> void:
	var plan := CompositeResolver.resolve_slots(PartKit.expand_shop_parts(_shop_parts_map()))
	var complete := is_complete()
	_glow.visible = complete
	_readout.set_complete(complete)
	_empty_hint.visible = plan["mode"] == "empty"

	if not animate or _crossfade_busy:
		_apply_plan(plan)
		return

	_crossfade_busy = true
	var tween := create_tween()
	tween.tween_property(_display_root, "modulate:a", 0.0, 0.1).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(_apply_plan.bind(plan))
	tween.tween_property(_display_root, "modulate:a", 1.0, 0.18).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(func() -> void: _crossfade_busy = false)

func _apply_plan(plan: Dictionary) -> void:
	_sprite_composite.visible = false
	var textures: Dictionary = plan.get("textures", {})
	var positions: Dictionary = plan.get("positions", {})
	for slot in PartSlotType.draw_order():
		var sprite: Sprite2D = _layer_sprites.get(slot)
		if sprite == null:
			continue
		_place_sprite(sprite, textures.get(slot), positions.get(slot, Vector2.ZERO))

func _place_sprite(sprite: Sprite2D, texture: Texture2D, pos: Vector2) -> void:
	if texture == null:
		sprite.texture = null
		sprite.visible = false
		return
	sprite.texture = texture
	sprite.visible = true
	sprite.centered = true
	sprite.position = pos
	sprite.scale = Vector2.ONE * CompositeResolver.display_scale()

func _update_stats() -> void:
	var loadout := to_loadout()
	_readout.set_from_loadout(loadout)
	_readout.set_display_name(_resolve_display_name())
	_refresh_tags()

func _resolve_display_name() -> String:
	if not is_complete():
		if to_loadout().is_empty():
			return "—"
		return "???"
	for def in _roster:
		if def == null:
			continue
		var same := true
		for slot in PartSlotType.shop_slots():
			var attached := get_attached_part(slot)
			var expected := def.get_part(slot)
			if attached == null or expected == null or attached.id != expected.id:
				same = false
				break
		if same:
			return def.display_name
	return "MIX"

func _pulse_attach() -> void:
	var tween := create_tween()
	tween.tween_property(_card_frame, "modulate", Color(1.12, 1.1, 1.08, 1), 0.08)
	tween.tween_property(_card_frame, "modulate", Color.WHITE, 0.28).set_trans(Tween.TRANS_SINE)

func _hide_fight_button() -> void:
	if _fight_button == null:
		return
	_fight_button.visible = false
	_fight_button.disabled = true
	_fight_button.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _ensure_rank_label() -> void:
	if _rank_label != null:
		return
	_rank_label = Label.new()
	_rank_label.position = Vector2(-40, -248)
	_rank_label.size = Vector2(80, 40)
	_rank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_rank_label.add_theme_font_size_override("font_size", 28)
	_rank_label.add_theme_color_override("font_color", Color.WHITE)
	add_child(_rank_label)

func _ensure_tags() -> void:
	if not _tags.is_empty():
		return
	for slot in PartSlotType.shop_slots():
		var tag := StatTag.new()
		tag.position = TAG_OFFSETS[slot]
		add_child(tag)
		_tags[slot] = tag

func _refresh_tags() -> void:
	_ensure_tags()
	var loadout := to_loadout()
	for slot in _tags.keys():
		var tag: StatTag = _tags[slot]
		var value := loadout.combat_value_of(slot)
		tag.setup(value, ThemeTokens.color_for_slot(slot))

func _ensure_grip() -> void:
	if _grip != null:
		return
	_grip = Area2D.new()
	_grip.name = "CardGrip"
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(220, 48)
	shape.shape = rect
	shape.position = Vector2(0, -226)
	_grip.add_child(shape)
	_grip.input_pickable = true
	_grip.input_event.connect(_on_grip_input)
	add_child(_grip)

func _on_grip_input(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if _fight_locked:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		card_drag_requested.emit(self)
		get_viewport().set_input_as_handled()
