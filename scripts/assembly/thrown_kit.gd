class_name ThrownKit
extends RigidBody2D

## One shop kit flying on the shelf: collides with physics, then flies off or returns.

signal collided

const LAYER_KIT := 8
const AFTERIMAGE_SEC := 0.032
const OFFSCREEN := Rect2(-160.0, -160.0, 2240.0, 1400.0)

var slot: PartSlotType.Value = PartSlotType.Value.HEAD
var face_left: bool = false

var _visual: Node2D
var _trail: CPUParticles2D
var _shape: CollisionShape2D
var _flying: bool = false
var _returning: bool = false
var _hit: bool = false
var _ghost_wait: float = 0.0
var _ghost_tint := Color(1.0, 0.96, 0.82, 0.42)
var _sprite_count: int = 0

func _ready() -> void:
	contact_monitor = true
	max_contacts_reported = 6
	continuous_cd = RigidBody2D.CCD_MODE_CAST_SHAPE
	collision_layer = LAYER_KIT
	collision_mask = LAYER_KIT
	can_sleep = false
	gravity_scale = 0.0
	input_pickable = false
	z_as_relative = false
	z_index = 80
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func sprite_count() -> int:
	return _sprite_count

func setup_from_puppet(puppet: FighterPuppet, shop_slot: PartSlotType.Value, opponent: bool) -> void:
	slot = shop_slot
	face_left = opponent
	mass = _mass_for(shop_slot)
	var mat := PhysicsMaterial.new()
	mat.bounce = 0.38
	mat.friction = 0.62
	physics_material_override = mat
	_visual = Node2D.new()
	_visual.name = "Visual"
	add_child(_visual)
	var origin := puppet.kit_anchor(shop_slot)
	global_position = origin
	for visual_slot in PartSlotType.visual_slots_for(shop_slot):
		var src := puppet.sprite_of(visual_slot)
		if src == null or src.texture == null:
			continue
		var clone := Sprite2D.new()
		clone.centered = src.centered
		clone.texture = src.texture
		clone.flip_h = src.flip_h
		clone.flip_v = src.flip_v
		clone.modulate = src.modulate
		clone.z_index = src.z_index
		_visual.add_child(clone)
		clone.global_transform = src.global_transform
		_sprite_count += 1
	_shape = CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = _radius_for(shop_slot)
	_shape.shape = circle
	add_child(_shape)
	Feel.hide_collision_debug(_shape)
	_trail = CPUParticles2D.new()
	_trail.emitting = false
	_trail.amount = 16
	_trail.lifetime = 0.28
	_trail.local_coords = false
	_trail.direction = Vector2.ZERO
	_trail.spread = 18.0
	_trail.initial_velocity_min = 8.0
	_trail.initial_velocity_max = 28.0
	_trail.gravity = Vector2.ZERO
	_trail.scale_amount_min = 0.35
	_trail.scale_amount_max = 0.9
	_trail.color = Color(1.0, 0.93, 0.72, 0.55)
	_trail.z_index = -1
	add_child(_trail)

func launch_toward(target: Vector2, duration: float) -> void:
	_hit = false
	_flying = true
	_returning = false
	freeze = false
	gravity_scale = 0.0
	linear_damp = 0.0
	angular_damp = 0.0
	collision_layer = LAYER_KIT
	collision_mask = LAYER_KIT
	var travel := target - global_position
	linear_velocity = travel / maxf(duration, 0.08)
	angular_velocity = 11.0 if linear_velocity.x >= 0.0 else -11.0
	if _trail != null:
		_trail.emitting = true

func begin_wreck(away_x: float) -> void:
	_stop_flight_fx()
	_hit = true
	freeze = false
	can_sleep = false
	sleeping = false
	gravity_scale = 1.55
	linear_damp = 0.12
	angular_damp = 0.08
	collision_layer = 0
	collision_mask = 0
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	apply_central_impulse(Vector2(away_x, -920.0))
	apply_torque_impulse(away_x * 28.0)
	modulate = Color(0.62, 0.54, 0.5)
	if _visual != null:
		Feel.punch(_visual, Vector2(1.28, 0.68), Vector2.ONE)

func fly_off_and_free() -> void:
	var fade := create_tween()
	fade.tween_interval(0.16)
	fade.tween_property(self, "modulate:a", 0.0, 0.32)
	var waited := 0.0
	while waited < 1.2 and is_inside_tree():
		await get_tree().physics_frame
		waited += get_physics_process_delta_time()
		if not OFFSCREEN.has_point(global_position):
			break
	if is_instance_valid(self):
		queue_free()

func fly_boomerang_to(dest: Callable, duration: float) -> void:
	_hit = true
	_returning = true
	_ghost_tint = Color(1.0, 0.86, 0.42, 0.5)
	collision_layer = 0
	collision_mask = 0
	freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC
	freeze = true
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	gravity_scale = 0.0
	if _trail != null:
		_trail.color = Color(1.0, 0.84, 0.38, 0.7)
		_trail.emitting = true
	var start := global_position
	var start_rot := rotation
	var spin := -1.6 if face_left else 1.6
	var tween := create_tween()
	tween.tween_method(
		func(t: float) -> void:
			var target: Vector2 = dest.call()
			var p := start.lerp(target, t)
			p.y -= sin(t * PI) * 190.0
			global_position = p
			rotation = start_rot + spin * t * TAU
			var swell := 1.0 + sin(t * PI) * 0.16
			scale = Vector2(swell, swell),
		0.0,
		1.0,
		duration
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	_stop_flight_fx()
	_returning = false
	scale = Vector2.ONE
	rotation = 0.0

func flash_hit() -> void:
	modulate = Color(1.55, 1.4, 1.15)
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.16)

func _process(delta: float) -> void:
	if not _flying and not _returning:
		return
	_ghost_wait += delta
	if _ghost_wait < AFTERIMAGE_SEC:
		return
	_ghost_wait = 0.0
	_spawn_afterimage()

func _spawn_afterimage() -> void:
	if _visual == null or not is_instance_valid(_visual):
		return
	var parent := get_parent()
	if parent == null:
		return
	var ghost := Node2D.new()
	ghost.z_as_relative = false
	ghost.z_index = z_index - 2
	ghost.modulate = _ghost_tint
	parent.add_child(ghost)
	ghost.global_transform = _visual.global_transform
	for child in _visual.get_children():
		var src := child as Sprite2D
		if src == null or src.texture == null:
			continue
		var copy := Sprite2D.new()
		copy.centered = src.centered
		copy.texture = src.texture
		copy.flip_h = src.flip_h
		copy.flip_v = src.flip_v
		copy.z_index = src.z_index
		ghost.add_child(copy)
		copy.global_transform = src.global_transform
	var fade := ghost.create_tween()
	fade.tween_property(ghost, "modulate:a", 0.0, 0.18)
	fade.tween_callback(ghost.queue_free)

func _stop_flight_fx() -> void:
	_flying = false
	if _trail != null:
		_trail.emitting = false

func _on_body_entered(body: Node) -> void:
	if _hit or _returning:
		return
	if body == self:
		return
	if body is RigidBody2D and body.collision_layer == LAYER_KIT:
		_hit = true
		_flying = false
		collided.emit()

func _mass_for(shop_slot: PartSlotType.Value) -> float:
	match shop_slot:
		PartSlotType.Value.BODY:
			return 1.5
		PartSlotType.Value.LEGS:
			return 1.15
		_:
			return 0.85

func _radius_for(shop_slot: PartSlotType.Value) -> float:
	match shop_slot:
		PartSlotType.Value.BODY:
			return 78.0
		PartSlotType.Value.LEGS:
			return 64.0
		_:
			return 52.0
