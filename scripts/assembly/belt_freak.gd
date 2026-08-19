class_name BeltFreak
extends Node2D

## A finished Freak riding its conveyor. It has no legs, so it rows itself
## along with both hands. At the tip it brakes and turns to face the enemy.

const HEAD_ARC := 210.0
const JUMP_PEAK := 280.0
const JUMP_TIME := 0.52
## One paddle: lift both arms forward, throw them back in a half-moon, then slide.
const STROKE_TIME := 0.88
const LIFT_END := 0.24
const SWEEP_END := 0.50
const SLIDE_END := 0.82
## Extra arm rotation from hanging down, in radians, sweeping over the top.
const ARM_FRONT := -2.05
const ARM_BACK := -4.55
const ARM_DOWN := -TAU

var runner: BeltLane.Runner
var player_side: bool = true
## Set once the Freak has braked at the fighting tip.
var arrived: bool = false

var _facing: Node2D
var _body: Node2D
var _shadow: Polygon2D
var _dust: CPUParticles2D
var _plaque: CratePlaque
var _sprites: Dictionary = {}
var _arm_rest: Dictionary = {}
var _head_home := Vector2.ZERO
var _display_scale: float = AssemblyLayout.BELT_FREAK_SCALE
var _dead: bool = false
var _jumping: bool = false
var _stroking: bool = false
var _stroke_from_x: float = 0.0
var _stroke_to_x: float = 0.0
var _slide_started: bool = false

func setup(loadout: FighterLoadout, lane_runner: BeltLane.Runner, is_player: bool) -> void:
	runner = lane_runner
	player_side = is_player
	_build_body(loadout)
	_build_plaque(loadout)
	set_progress(lane_runner.progress)

# ---------------------------------------------------------------- movement

func set_progress(progress: float) -> void:
	position.x = AssemblyLayout.belt_x_at(player_side, progress)
	position.y = AssemblyLayout.belt_floor_y()

func follow_runner() -> void:
	if runner == null or _dead or _jumping:
		return
	if runner.pending_stroke:
		runner.pending_stroke = false
		play_stroke(runner.progress)
		return
	if _stroking:
		return
	if runner.at_tip() and not arrived:
		arrived = true
		play_arrive()

## Leap from a world point (the card, or above the red belt) onto the entry.
func play_jump_from(from_global: Vector2) -> void:
	_jumping = true
	if runner != null:
		runner.landed = false
	var dest := Vector2(AssemblyLayout.belt_x_at(player_side, 0.0), AssemblyLayout.belt_floor_y())
	global_position = from_global
	var start_s := AssemblyLayout.CARD_FREAK_SCALE / maxf(AssemblyLayout.BELT_FREAK_SCALE, 0.01)
	scale = Vector2(start_s, start_s)
	Feel.punch(_body, Vector2(1.18, 0.82), Vector2.ONE)
	GameAudio.step()
	var tween := create_tween()
	tween.tween_method(
		func(t: float) -> void:
			var p := from_global.lerp(dest, t)
			p.y -= sin(t * PI) * JUMP_PEAK
			global_position = p
			var s := lerpf(start_s, 1.0, t)
			scale = Vector2(s, s),
		0.0,
		1.0,
		JUMP_TIME
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(_finish_jump.bind(dest))

func play_stroke(to_progress: float) -> void:
	if _dead or _stroking:
		return
	_stroking = true
	_slide_started = false
	_stroke_from_x = position.x
	_stroke_to_x = AssemblyLayout.belt_x_at(player_side, to_progress)
	var tween := create_tween()
	tween.tween_method(_row_at, 0.0, 1.0, STROKE_TIME)
	tween.tween_callback(_finish_stroke)

## Hard stop at the tip: squash, dust puff.
func play_arrive() -> void:
	_settle()
	Feel.punch(_body, Vector2(1.16, 0.84), Vector2.ONE)
	_puff_dust(0.3)
	GameAudio.step()

func _finish_jump(dest: Vector2) -> void:
	if not is_instance_valid(self):
		return
	global_position = dest
	scale = Vector2.ONE
	Feel.punch(_body, Vector2(1.22, 0.78), Vector2.ONE)
	GameAudio.part_place()
	_puff_dust(0.22)
	if runner != null:
		runner.landed = true
	_jumping = false

func _finish_stroke() -> void:
	if not is_instance_valid(self):
		return
	position.x = _stroke_to_x
	_settle()
	if _dust != null:
		_dust.emitting = false
	_stroking = false
	_slide_started = false
	if runner != null and runner.at_tip() and not arrived:
		arrived = true
		play_arrive()

## Lift both arms forward, throw them back in a half-moon, then the crate slides.
func _row_at(t: float) -> void:
	var angle := 0.0
	var lean := 0.0
	var bob := 0.0
	if t < LIFT_END:
		var u := t / LIFT_END
		u = _smooth(u)
		angle = lerpf(0.0, ARM_FRONT, u)
		lean = lerpf(0.0, 0.1, u)
		bob = lerpf(0.0, -8.0, u)
		position.x = _stroke_from_x
	elif t < SWEEP_END:
		var u := (t - LIFT_END) / (SWEEP_END - LIFT_END)
		u = _smooth(u)
		angle = lerpf(ARM_FRONT, ARM_BACK, u)
		lean = lerpf(0.1, -0.08, u)
		bob = lerpf(-8.0, -2.0, u)
		position.x = _stroke_from_x
	elif t < SLIDE_END:
		_begin_slide()
		var u := (t - SWEEP_END) / (SLIDE_END - SWEEP_END)
		u = 1.0 - (1.0 - u) * (1.0 - u)
		angle = ARM_BACK
		lean = lerpf(-0.08, 0.02, u)
		bob = 0.0
		position.x = lerpf(_stroke_from_x, _stroke_to_x, u)
	else:
		if _dust != null:
			_dust.emitting = false
		var u := (t - SLIDE_END) / maxf(0.001, 1.0 - SLIDE_END)
		u = _smooth(u)
		angle = lerpf(ARM_BACK, ARM_DOWN, u)
		lean = lerpf(0.02, 0.0, u)
		bob = 0.0
		position.x = _stroke_to_x
	_swing(_sprites.get(PartSlotType.Value.ARM_R) as Sprite2D, angle)
	_swing(_sprites.get(PartSlotType.Value.ARM_L) as Sprite2D, angle)
	_body.rotation = lean
	_body.position.y = bob
	var head: Sprite2D = _sprites.get(PartSlotType.Value.HEAD)
	if head != null:
		head.position = _head_home + Vector2(-sin(angle) * 3.0, bob * 0.12)

func _begin_slide() -> void:
	if _slide_started:
		return
	_slide_started = true
	GameAudio.wood_slide()
	if _dust != null:
		_dust.emitting = false
		_dust.emitting = true
	Feel.punch(_body, Vector2(1.12, 0.88), Vector2.ONE)

func _smooth(u: float) -> float:
	var x := clampf(u, 0.0, 1.0)
	return x * x * (3.0 - 2.0 * x)

func _settle() -> void:
	_body.rotation = 0.0
	_body.position.y = 0.0
	for slot in [PartSlotType.Value.ARM_L, PartSlotType.Value.ARM_R]:
		_swing(_sprites.get(slot) as Sprite2D, 0.0)
	var head: Sprite2D = _sprites.get(PartSlotType.Value.HEAD)
	if head != null:
		head.position = _head_home

## Rotates an arm around its shoulder magnet instead of its own middle.
func _swing(arm: Sprite2D, angle: float) -> void:
	if arm == null or not arm.visible:
		return
	var rest: Dictionary = _arm_rest.get(arm.get_instance_id(), {})
	if rest.is_empty():
		return
	arm.rotation = float(rest["rotation"]) + angle
	arm.position = CompositeResolver.center_after_pivot(rest["position"], rest["pivot"], angle)

func _puff_dust(seconds: float) -> void:
	if _dust == null:
		return
	_dust.emitting = true
	var stop := create_tween()
	stop.tween_interval(seconds)
	stop.tween_callback(func() -> void:
		if is_instance_valid(_dust):
			_dust.emitting = false
	)

# ---------------------------------------------------------------- fighting

func head_global_position() -> Vector2:
	var head: Sprite2D = _sprites.get(PartSlotType.Value.HEAD)
	return head.global_position if head != null else global_position

## Wind up, throw the head at the target, land the hit, bring it back.
func attack(target: Callable, on_impact: Callable) -> void:
	var head: Sprite2D = _sprites.get(PartSlotType.Value.HEAD)
	if head == null or head.texture == null:
		if on_impact.is_valid():
			on_impact.call()
		return
	var crouch := create_tween()
	crouch.tween_property(_body, "scale", Vector2(1.1, 0.88), 0.1).set_trans(Tween.TRANS_SINE)
	crouch.tween_property(_body, "scale", Vector2.ONE, 0.08)
	await crouch.finished

	var bullet := FlyingHead.new()
	get_parent().add_child(bullet)
	bullet.global_position = head.global_position
	bullet.setup(head.texture, head.flip_h != player_side, _display_scale)
	bullet.scale.x = -1.0 if not player_side else 1.0
	head.visible = false

	var arc := HEAD_ARC if player_side else -HEAD_ARC
	await bullet.strike(target, 0.26, arc)
	bullet.land_hit()
	if on_impact.is_valid():
		on_impact.call()
	await get_tree().create_timer(0.09).timeout
	await bullet.fly_home(func() -> Vector2: return head.global_position, 0.3, arc)
	if is_instance_valid(bullet):
		bullet.queue_free()
	if is_instance_valid(self):
		head.visible = true
		Feel.punch(_body, Vector2(0.92, 1.1), Vector2.ONE)

func flash_hit(damage: int) -> void:
	if _dead:
		return
	GameAudio.impact()
	var flash := create_tween()
	flash.tween_property(_body, "modulate", Color(2.0, 1.5, 1.5), 0.05)
	flash.tween_property(_body, "modulate", Color.WHITE, 0.2)
	var shove := -26.0 if player_side else 26.0
	var kick := create_tween()
	kick.tween_property(_body, "position:x", shove, 0.06).set_trans(Tween.TRANS_SINE)
	kick.tween_property(_body, "position:x", 0.0, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_pop_damage(damage)
	refresh_hp()

func refresh_hp() -> void:
	if _plaque == null or runner == null or runner.loadout == null:
		return
	_plaque.set_hp(runner.hp, runner.loadout.base_stat_of(PartSlotType.Value.BODY))

## Grey out, slide toward the gap and drop through with a spin.
func play_death() -> void:
	_dead = true
	_stroking = false
	if _dust != null:
		_dust.emitting = false
	if _plaque != null:
		_plaque.visible = false
	var fall_x := AssemblyLayout.gap_center_x()
	var tween := create_tween()
	tween.tween_property(_body, "modulate", Color(0.42, 0.4, 0.44, 1), 0.18)
	tween.parallel().tween_property(self, "position:x", fall_x, 0.36).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(_body, "rotation", 0.5 if player_side else -0.5, 0.36)
	tween.tween_property(self, "position:y", AssemblyLayout.HEIGHT + 260.0, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(_body, "rotation", 3.4 if player_side else -3.4, 0.55)
	tween.parallel().tween_property(_body, "modulate:a", 0.25, 0.55)
	await tween.finished
	queue_free()

# ---------------------------------------------------------------- build

func _build_body(loadout: FighterLoadout) -> void:
	_facing = Node2D.new()
	_facing.name = "Facing"
	add_child(_facing)
	## Flip the whole toy, not each sprite: squash and punches live on Body,
	## so they cannot wipe the opponent's left-facing scale.
	if not player_side:
		_facing.scale.x = -1.0

	_body = Node2D.new()
	_body.name = "Body"
	_facing.add_child(_body)

	_shadow = Polygon2D.new()
	_shadow.color = Color(0.02, 0.02, 0.04, 0.4)
	_shadow.polygon = _oval(74.0 * _display_scale, 11.0)
	_body.add_child(_shadow)

	var expanded := PartKit.expand_shop_parts(_shop_map(loadout))
	var profile := {}
	for slot in expanded.keys():
		var part := expanded[slot] as PartDef
		profile[slot] = part.sprite_profile if part.sprite_profile != null else part.sprite
	var plan := CompositeResolver.resolve_slots(expanded, profile)
	var textures: Dictionary = plan["textures"]
	var positions: Dictionary = plan["positions"]
	for slot in PartSlotType.draw_order_for(expanded):
		var texture: Texture2D = textures.get(slot)
		if texture == null:
			continue
		var sprite := Sprite2D.new()
		sprite.name = String(PartSlotType.to_string_name(slot))
		sprite.centered = true
		sprite.texture = texture
		sprite.position = positions.get(slot, Vector2.ZERO) * _display_scale
		sprite.scale = Vector2.ONE * CompositeResolver.display_scale() * _display_scale
		sprite.z_index = PartSlotType.fight_z_index(slot, true)
		var part := expanded.get(slot) as PartDef
		if part != null:
			sprite.flip_h = part.flip_h_for(1)
			sprite.rotation_degrees = float(part.rotation_for(1))
		_body.add_child(sprite)
		_sprites[slot] = sprite
		if PartSlotType.is_arm(slot):
			_arm_rest[sprite.get_instance_id()] = {
				"position": sprite.position,
				"rotation": sprite.rotation,
				"pivot": CompositeResolver.socket_of(part, "up", texture) * CompositeResolver.display_scale() * _display_scale,
			}
		if slot == PartSlotType.Value.BODY:
			var body_z := sprite.z_index
			var back := Sprite2D.new()
			back.name = "CrateBack"
			back.z_index = CompositeResolver.crate_back_z(body_z)
			_body.add_child(back)
			CompositeResolver.apply_crate_back_to(back, _display_scale)
			var front := Sprite2D.new()
			front.name = "CrateFront"
			front.z_index = CompositeResolver.crate_front_z(body_z)
			_body.add_child(front)
			CompositeResolver.apply_crate_front_to(front, _display_scale)
	var head: Sprite2D = _sprites.get(PartSlotType.Value.HEAD)
	_head_home = head.position if head != null else Vector2.ZERO

	_dust = CPUParticles2D.new()
	_dust.amount = 28
	_dust.lifetime = 0.7
	_dust.explosiveness = 0.35
	_dust.local_coords = false
	_dust.direction = Vector2(-1.0, -0.35)
	_dust.spread = 28.0
	_dust.initial_velocity_min = 18.0
	_dust.initial_velocity_max = 55.0
	_dust.gravity = Vector2(0, 50)
	_dust.scale_amount_min = 2.0
	_dust.scale_amount_max = 6.0
	_dust.color = Color(0.84, 0.80, 0.74, 0.42)
	_dust.position = Vector2(-52.0 * _display_scale, -6.0)
	_dust.z_index = -1
	_dust.emitting = false
	_body.add_child(_dust)

func _build_plaque(loadout: FighterLoadout) -> void:
	_plaque = CratePlaque.new()
	_plaque.name = "CratePlaque"
	_plaque.position = CompositeResolver.crate_front_position() * _display_scale
	_plaque.z_index = 8
	## Opponent Freaks are flipped; flip the plaque back so the name stays readable.
	if not player_side:
		_plaque.scale.x = -1.0
	_body.add_child(_plaque)
	var hp := runner.hp if runner != null else -1
	_plaque.show_loadout(loadout, hp)

func _shop_map(loadout: FighterLoadout) -> Dictionary:
	var shop := {}
	for slot in PartSlotType.shop_slots():
		var part := loadout.get_part(slot)
		if part != null:
			shop[slot] = part
	return shop

func _pop_damage(damage: int) -> void:
	if damage <= 0:
		return
	var label := GameTheme.make_label("-%d" % damage, 40, Vector2.ZERO, Vector2(120, 48), ThemeTokens.X_RED)
	label.position = Vector2(-60.0, -400.0 * _display_scale)
	label.z_index = 14
	add_child(label)
	var tween := label.create_tween()
	tween.tween_property(label, "position:y", label.position.y - 58.0, 0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.6)
	tween.tween_callback(label.queue_free)

func _oval(rx: float, ry: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	const SEGMENTS := 22
	for i in SEGMENTS:
		var angle := TAU * float(i) / float(SEGMENTS)
		points.append(Vector2(cos(angle) * rx, sin(angle) * ry))
	return points
