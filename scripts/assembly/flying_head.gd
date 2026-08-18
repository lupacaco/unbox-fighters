class_name FlyingHead
extends Node2D

## The head that jumps off the torso, flies across the gap, cracks the other
## Freak and boomerangs home. Driven by tweens so the fight stays predictable.

const AFTERIMAGE_EVERY := 0.03
const GHOST_TINT := Color(1.0, 0.92, 0.62, 0.42)

var _sprite: Sprite2D
var _trail: CPUParticles2D
var _ghost_wait: float = 0.0
var _streaking: bool = false

func setup(texture: Texture2D, flip: bool, sprite_scale: float) -> void:
	z_as_relative = false
	z_index = 90
	_sprite = Sprite2D.new()
	_sprite.centered = true
	_sprite.texture = texture
	_sprite.flip_h = flip
	_sprite.scale = Vector2.ONE * sprite_scale
	add_child(_sprite)

	_trail = CPUParticles2D.new()
	_trail.emitting = false
	_trail.amount = 18
	_trail.lifetime = 0.26
	_trail.local_coords = false
	_trail.direction = Vector2.ZERO
	_trail.spread = 20.0
	_trail.initial_velocity_min = 10.0
	_trail.initial_velocity_max = 34.0
	_trail.gravity = Vector2.ZERO
	_trail.scale_amount_min = 0.3 * sprite_scale
	_trail.scale_amount_max = 0.9 * sprite_scale
	_trail.color = Color(1.0, 0.93, 0.72, 0.5)
	_trail.z_index = -1
	add_child(_trail)

## Crouch, then rip across to the target in an arc.
func strike(target: Callable, out_time: float, arc: float) -> void:
	_begin_streak()
	var start := global_position
	var spin := signf(arc) * TAU * 0.9
	var tween := create_tween()
	tween.tween_method(
		func(t: float) -> void:
			var to: Vector2 = target.call()
			var p := start.lerp(to, t)
			p.y -= sin(t * PI) * absf(arc)
			global_position = p
			rotation = spin * t
			var swell := 1.0 + sin(t * PI) * 0.14
			scale = Vector2(swell, swell),
		0.0, 1.0, out_time
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	await tween.finished
	_end_streak()

## The one-frame freeze and flash on contact.
func land_hit() -> void:
	modulate = Color(1.8, 1.6, 1.3)
	scale = Vector2(1.3, 0.78)
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.16)
	tween.parallel().tween_property(self, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func fly_home(home: Callable, back_time: float, arc: float) -> void:
	_begin_streak()
	if _trail != null:
		_trail.color = Color(1.0, 0.84, 0.38, 0.6)
	var start := global_position
	var start_rot := rotation
	var spin := -signf(arc) * TAU * 0.6
	var tween := create_tween()
	tween.tween_method(
		func(t: float) -> void:
			var to: Vector2 = home.call()
			var p := start.lerp(to, t)
			p.y -= sin(t * PI) * absf(arc) * 0.8
			global_position = p
			rotation = lerp_angle(start_rot, 0.0, t) + spin * (1.0 - t) * t * 2.0,
		0.0, 1.0, back_time
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await tween.finished
	_end_streak()
	rotation = 0.0
	scale = Vector2.ONE

func _process(delta: float) -> void:
	if not _streaking:
		return
	_ghost_wait += delta
	if _ghost_wait < AFTERIMAGE_EVERY:
		return
	_ghost_wait = 0.0
	_spawn_afterimage()

func _begin_streak() -> void:
	_streaking = true
	set_process(true)
	if _trail != null:
		_trail.emitting = true

func _end_streak() -> void:
	_streaking = false
	set_process(false)
	if _trail != null:
		_trail.emitting = false

func _spawn_afterimage() -> void:
	var parent := get_parent()
	if parent == null or _sprite == null or _sprite.texture == null:
		return
	var ghost := Sprite2D.new()
	ghost.centered = true
	ghost.texture = _sprite.texture
	ghost.flip_h = _sprite.flip_h
	ghost.z_as_relative = false
	ghost.z_index = z_index - 2
	ghost.modulate = GHOST_TINT
	parent.add_child(ghost)
	ghost.global_transform = _sprite.global_transform
	var fade := ghost.create_tween()
	fade.tween_property(ghost, "modulate:a", 0.0, 0.17)
	fade.tween_callback(ghost.queue_free)
