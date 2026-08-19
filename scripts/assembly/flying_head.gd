class_name FlyingHead
extends Node2D

## The head that jumps off the torso, flies crown-first, cracks the other
## Freak and comes home. No barrel rolls — only the tilt that puts the top
## of the head on the target.

const AFTERIMAGE_EVERY := 0.045
const GHOST_TINT := Color(1.0, 0.92, 0.62, 0.36)

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
	_trail.amount = 12
	_trail.lifetime = 0.18
	_trail.local_coords = false
	_trail.direction = Vector2.ZERO
	_trail.spread = 14.0
	_trail.initial_velocity_min = 8.0
	_trail.initial_velocity_max = 22.0
	_trail.gravity = Vector2.ZERO
	_trail.scale_amount_min = 0.22 * sprite_scale
	_trail.scale_amount_max = 0.7 * sprite_scale
	_trail.color = Color(1.0, 0.93, 0.72, 0.42)
	_trail.z_index = -1
	add_child(_trail)

## Whip across to the target. `crown_angle` is how far to tilt so the top
## of the head leads (about a quarter turn toward the enemy).
func strike(target: Callable, out_time: float, arc: float, crown_angle: float) -> void:
	_begin_streak()
	var start := global_position
	var start_rot := rotation
	var tween := create_tween()
	tween.tween_method(
		func(t: float) -> void:
			var to: Vector2 = target.call()
			var p := start.lerp(to, t)
			p.y -= sin(t * PI) * absf(arc)
			global_position = p
			rotation = lerp_angle(start_rot, crown_angle, _smooth(t)),
		0.0, 1.0, out_time
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	await tween.finished
	rotation = crown_angle
	_end_streak()

## The one-frame freeze and flash on contact. Keeps the crown-first angle.
func land_hit() -> void:
	modulate = Color(1.8, 1.6, 1.3)
	var rest := scale
	scale = rest * Vector2(1.22, 0.78)
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.16)
	tween.parallel().tween_property(self, "scale", rest, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func fly_home(home: Callable, back_time: float, arc: float) -> void:
	_begin_streak()
	if _trail != null:
		_trail.color = Color(1.0, 0.84, 0.38, 0.5)
	var start := global_position
	var start_rot := rotation
	var tween := create_tween()
	tween.tween_method(
		func(t: float) -> void:
			var to: Vector2 = home.call()
			var p := start.lerp(to, t)
			p.y -= sin(t * PI) * absf(arc) * 0.55
			global_position = p
			rotation = lerp_angle(start_rot, 0.0, _smooth(t)),
		0.0, 1.0, back_time
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await tween.finished
	_end_streak()
	rotation = 0.0
	scale = Vector2.ONE

func _smooth(t: float) -> float:
	var u := clampf(t, 0.0, 1.0)
	return u * u * (3.0 - 2.0 * u)

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
	fade.tween_property(ghost, "modulate:a", 0.0, 0.12)
	fade.tween_callback(ghost.queue_free)
