class_name CharacterSlot
extends Node2D

signal part_attached(slot: CharacterSlot, part: PartDef)
signal part_detached(slot: CharacterSlot, part: PartDef)

const HEAD_POS := Vector2(0, -138)
const BODY_POS := Vector2(0, -8)
const LEGS_POS := Vector2(0, 118)
const HEAD_SIZE_PX := 150.0
const BODY_SIZE_PX := 150.0
const LEGS_SIZE_PX := 150.0
const FULL_SIZE_PX := 350.0
const PAIR_SIZE_PX := 300.0
# Card art area roughly y=-180..160; align pair composites to top/bottom.
const BODY_HEAD_POS := Vector2(0, -95)
const BODY_LEGS_POS := Vector2(0, 55)
const FULL_POS := Vector2(0, -8)

@onready var _card_shadow: Sprite2D = $CardShadow
@onready var _card_frame: Sprite2D = $CardFrame
@onready var _empty_hint: Label = $EmptyHint
@onready var _display_root: Node2D = $Display
@onready var _sprite_composite: Sprite2D = $Display/Composite
@onready var _sprite_head: Sprite2D = $Display/Head
@onready var _sprite_body: Sprite2D = $Display/Body
@onready var _sprite_legs: Sprite2D = $Display/Legs
@onready var _zone_head: Area2D = $Zones/Head
@onready var _zone_body: Area2D = $Zones/Body
@onready var _zone_legs: Area2D = $Zones/Legs
@onready var _highlight: Line2D = $DropHighlight
@onready var _glow: Polygon2D = $CompleteGlow
@onready var _readout: StatReadout = $StatReadout

var character: CharacterDef
var _has_head: bool = false
var _has_body: bool = false
var _has_legs: bool = false
var _bound_parts: Dictionary = {}
var _crossfade_busy: bool = false
var _rest_y: float = 0.0

func setup(def: CharacterDef) -> void:
	character = def
	_rest_y = position.y
	_readout.set_display_name("???")
	_readout.set_stats(0, 0, 0)
	_readout.set_complete(false)
	_glow.visible = false
	_highlight.visible = false
	_build_visuals()
	_setup_zones()
	_refresh_display(false)

func can_accept(part: PartDef) -> bool:
	if part == null or character == null:
		return false
	match part.slot_type:
		PartSlotType.Value.HEAD:
			return not _has_head and character.head != null and part.id == character.head.id
		PartSlotType.Value.BODY:
			return not _has_body and character.body != null and part.id == character.body.id
		PartSlotType.Value.LEGS:
			return not _has_legs and character.legs != null and part.id == character.legs.id
		_:
			return false

func can_accept_at(part: PartDef, global_point: Vector2) -> bool:
	if not can_accept(part):
		return false
	return _zone_contains(part.slot_type, global_point) or _contains_point_expanded(global_point)

func _zone_contains(slot: PartSlotType.Value, global_point: Vector2) -> bool:
	var zone := _zone_for(slot)
	var rect: Rect2 = zone.get_meta("rect")
	return rect.has_point(to_local(global_point))

func try_attach(part_view: PartView) -> bool:
	if not can_accept(part_view.part_def):
		return false
	var slot := part_view.part_def.slot_type
	_set_flag(slot, true)
	_bound_parts[slot] = part_view
	part_view.set_attached_slot(self)
	part_view.snap_hide_for_slot()
	_refresh_display(true)
	_update_stats()
	_pulse_attach()
	part_attached.emit(self, part_view.part_def)
	return true

func detach_part(slot: PartSlotType.Value, refresh: bool = true) -> PartView:
	if not _bound_parts.has(slot):
		return null
	var part_view: PartView = _bound_parts[slot]
	_bound_parts.erase(slot)
	_set_flag(slot, false)
	part_view.set_attached_slot(null)
	if refresh:
		_refresh_display(true)
		_update_stats()
	part_detached.emit(self, part_view.part_def)
	return part_view

func set_drop_highlight(enabled: bool, slot: PartSlotType.Value) -> void:
	_highlight.visible = enabled
	if not enabled:
		return
	var zone := _zone_for(slot)
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

func _setup_zones() -> void:
	_configure_zone(_zone_head, Rect2(-95, -190, 190, 110))
	_configure_zone(_zone_body, Rect2(-105, -85, 210, 130))
	_configure_zone(_zone_legs, Rect2(-95, 45, 190, 120))

func _configure_zone(zone: Area2D, rect: Rect2) -> void:
	zone.set_meta("rect", rect)
	zone.monitoring = false
	zone.monitorable = false
	zone.input_pickable = true
	var shape_owner := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	shape_owner.shape = shape
	shape_owner.position = rect.position + rect.size * 0.5
	zone.add_child(shape_owner)
	zone.input_event.connect(_on_zone_input.bind(zone))

func _on_zone_input(_viewport: Node, event: InputEvent, _shape_idx: int, zone: Area2D) -> void:
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
	if zone == _zone_head:
		return PartSlotType.Value.HEAD
	if zone == _zone_body:
		return PartSlotType.Value.BODY
	return PartSlotType.Value.LEGS

func _zone_for(slot: PartSlotType.Value) -> Area2D:
	match slot:
		PartSlotType.Value.HEAD:
			return _zone_head
		PartSlotType.Value.BODY:
			return _zone_body
		_:
			return _zone_legs

func _contains_point_expanded(global_point: Vector2) -> bool:
	var local := to_local(global_point)
	return Rect2(Vector2(-135, -205), Vector2(270, 400)).has_point(local)

func _set_flag(slot: PartSlotType.Value, value: bool) -> void:
	match slot:
		PartSlotType.Value.HEAD:
			_has_head = value
		PartSlotType.Value.BODY:
			_has_body = value
		PartSlotType.Value.LEGS:
			_has_legs = value

func _refresh_display(animate: bool) -> void:
	var plan := CompositeResolver.resolve(character, _has_head, _has_body, _has_legs)
	var complete := _has_head and _has_body and _has_legs
	_glow.visible = complete
	_readout.set_complete(complete)
	_empty_hint.visible = plan["mode"] == "empty" or (
		plan["mode"] == "layered"
		and plan["head"] == null
		and plan["body"] == null
		and plan["legs"] == null
	)

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
	_sprite_head.visible = false
	_sprite_body.visible = false
	_sprite_legs.visible = false

	if plan["mode"] == "composite":
		var kind: String = str(plan.get("composite_kind", "full"))
		match kind:
			"body_head":
				_place_sprite(_sprite_composite, plan["composite"], BODY_HEAD_POS, PAIR_SIZE_PX)
			"body_legs":
				_place_sprite(_sprite_composite, plan["composite"], BODY_LEGS_POS, PAIR_SIZE_PX)
			_:
				_place_sprite(_sprite_composite, plan["composite"], FULL_POS, FULL_SIZE_PX)
		return

	if plan["mode"] == "layered":
		_place_sprite(_sprite_legs, plan["legs"], LEGS_POS, LEGS_SIZE_PX)
		_place_sprite(_sprite_body, plan["body"], BODY_POS, BODY_SIZE_PX)
		_place_sprite(_sprite_head, plan["head"], HEAD_POS, HEAD_SIZE_PX)

func _place_sprite(sprite: Sprite2D, texture: Texture2D, pos: Vector2, target_px: float) -> void:
	if texture == null:
		sprite.texture = null
		sprite.visible = false
		return
	sprite.texture = texture
	sprite.visible = true
	sprite.centered = true
	sprite.position = pos
	var tex_size := texture.get_size()
	var s := target_px / maxf(maxf(tex_size.x, tex_size.y), 1.0)
	sprite.scale = Vector2.ONE * s

func _update_stats() -> void:
	var brain := 0
	var power := 0
	var speed := 0
	for slot in _bound_parts.keys():
		var view: PartView = _bound_parts[slot]
		brain += view.part_def.brain
		power += view.part_def.power
		speed += view.part_def.speed
	_readout.set_stats(brain, power, speed)
	_readout.set_display_name("???" if not (_has_head and _has_body and _has_legs) else character.display_name)

func _pulse_attach() -> void:
	var tween := create_tween()
	tween.tween_property(_card_frame, "modulate", Color(1.12, 1.1, 1.08, 1), 0.08)
	tween.tween_property(_card_frame, "modulate", Color.WHITE, 0.28).set_trans(Tween.TRANS_SINE)
