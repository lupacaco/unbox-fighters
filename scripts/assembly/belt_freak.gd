class_name BeltFreak
extends Node2D

## A finished Freak riding its conveyor. It has no legs, so it rows itself
## along with both hands. At the tip it brakes and turns to face the enemy.

const HP_BAR := Vector2(96, 10)
const HEAD_ARC := 210.0
const TAG_SCALE := 0.72
const REACH_ANGLE := 0.7
const PULL_ANGLE := -0.85
const JUMP_PEAK := 280.0
const JUMP_TIME := 0.52

var runner: BeltLane.Runner
var player_side: bool = true
## Set once the Freak has braked at the fighting tip.
var arrived: bool = false

var _facing: Node2D
var _body: Node2D
var _overlay: Node2D
var _shadow: Polygon2D
var _dust: CPUParticles2D
var _hp_fill: Polygon2D
var _power_tag: StatTag
var _tough_tag: StatTag
var _sprites: Dictionary = {}
var _arm_rest: Dictionary = {}
var _head_home := Vector2.ZERO
var _display_scale: float = AssemblyLayout.BELT_FREAK_SCALE
var _max_hp: int = 1
var _dead: bool = false
var _jumping: bool = false
var _stroking: bool = false
var _stroke_from_x: float = 0.0
var _stroke_to_x: float = 0.0

func setup(loadout: FighterLoadout, lane_runner: BeltLane.Runner, is_player: bool) -> void:
	runner = lane_runner
	player_side = is_player
	_max_hp = maxi(1, lane_runner.stats.toughness)
	_build_body(loadout)
	_build_overlay()
	_build_stat_tags(loadout)
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
	_stroke_from_x = position.x
	_stroke_to_x = AssemblyLayout.belt_x_at(player_side, to_progress)
	GameAudio.step()
	if _dust != null:
		_dust.emitting = true
	var tween := create_tween()
	tween.tween_method(_row_at, 0.0, 1.0, 0.52)
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
	if runner != null and runner.at_tip() and not arrived:
		arrived = true
		play_arrive()

## 0..1 of one paddle: both hands reach forward, then pull the crate along.
func _row_at(t: float) -> void:
	var angle := 0.0
	var lean := 0.0
	var bob := 0.0
	if t < 0.22:
		var u := t / 0.22
		angle = lerpf(0.0, REACH_ANGLE, u)
		lean = lerpf(0.0, 0.09, u)
		bob = -u * 7.0
	elif t < 0.72:
		var u := (t - 0.22) / 0.50
		angle = lerpf(REACH_ANGLE, PULL_ANGLE, u)
		lean = lerpf(0.09, -0.07, u)
		bob = lerpf(-7.0, 0.0, u)
		position.x = lerpf(_stroke_from_x, _stroke_to_x, u)
	else:
		var u := (t - 0.72) / 0.28
		angle = lerpf(PULL_ANGLE, 0.0, u)
		lean = lerpf(-0.07, 0.0, u)
		position.x = _stroke_to_x
	_swing(_sprites.get(PartSlotType.Value.ARM_R) as Sprite2D, angle)
	_swing(_sprites.get(PartSlotType.Value.ARM_L) as Sprite2D, angle * 0.92)
	_body.rotation = lean
	_body.position.y = bob
	var head: Sprite2D = _sprites.get(PartSlotType.Value.HEAD)
	if head != null:
		head.position = _head_home + Vector2(angle * 4.0, bob * 0.15)

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
	if _hp_fill == null or runner == null:
		return
	var ratio := clampf(float(runner.hp) / float(_max_hp), 0.0, 1.0)
	var tween := create_tween()
	tween.tween_method(
		func(t: float) -> void: _hp_fill.polygon = _hp_shape(t),
		_hp_ratio(), ratio, 0.22
	).set_trans(Tween.TRANS_SINE)
	_hp_fill.color = ThemeTokens.BELT_PLAYER.lerp(ThemeTokens.X_RED, 1.0 - ratio)

## Grey out, slide toward the gap and drop through with a spin.
func play_death() -> void:
	_dead = true
	_stroking = false
	if _dust != null:
		_dust.emitting = false
	if _overlay != null:
		_overlay.visible = false
	if _power_tag != null:
		_power_tag.visible = false
	if _tough_tag != null:
		_tough_tag.visible = false
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
	var head: Sprite2D = _sprites.get(PartSlotType.Value.HEAD)
	_head_home = head.position if head != null else Vector2.ZERO

	_dust = CPUParticles2D.new()
	_dust.amount = 14
	_dust.lifetime = 0.5
	_dust.local_coords = false
	_dust.direction = Vector2(-1.0, -0.5)
	_dust.spread = 24.0
	_dust.initial_velocity_min = 30.0
	_dust.initial_velocity_max = 90.0
	_dust.gravity = Vector2(0, 120)
	_dust.scale_amount_min = 1.5
	_dust.scale_amount_max = 4.0
	_dust.color = Color(0.72, 0.68, 0.6, 0.28)
	_dust.position = Vector2(-40.0 * _display_scale, -4.0)
	_dust.z_index = -1
	_dust.emitting = false
	_body.add_child(_dust)

func _build_overlay() -> void:
	_overlay = Node2D.new()
	_overlay.name = "Overlay"
	_overlay.position = Vector2(0.0, -330.0 * _display_scale)
	_overlay.z_index = 12
	add_child(_overlay)

	var back := Polygon2D.new()
	back.polygon = _hp_frame(HP_BAR * 0.5 + Vector2(3, 3))
	back.color = Color(0.05, 0.05, 0.07, 0.9)
	_overlay.add_child(back)

	_hp_fill = Polygon2D.new()
	_hp_fill.color = ThemeTokens.BELT_PLAYER if player_side else ThemeTokens.BELT_OPPONENT
	_hp_fill.polygon = _hp_shape(1.0)
	_overlay.add_child(_hp_fill)

func _build_stat_tags(loadout: FighterLoadout) -> void:
	if runner == null or runner.stats == null:
		return
	var stats := runner.stats
	_power_tag = _make_tag(
		PartSlotType.Value.HEAD,
		stats.power,
		stats.power > stats.base_of(loadout, PartSlotType.Value.HEAD)
	)
	_tough_tag = _make_tag(
		PartSlotType.Value.BODY,
		stats.toughness,
		stats.toughness > stats.base_of(loadout, PartSlotType.Value.BODY)
	)

func _make_tag(slot: PartSlotType.Value, value: int, boosted: bool) -> StatTag:
	var tag := StatTag.new()
	tag.z_index = 11
	tag.scale = Vector2.ONE * TAG_SCALE
	add_child(tag)
	tag.setup(value, ThemeTokens.color_for_slot(slot), boosted)
	var sprite: Sprite2D = _sprites.get(slot)
	if sprite != null:
		var bump := Vector2(0.0, -42.0 * _display_scale) if slot == PartSlotType.Value.HEAD else Vector2(0.0, 8.0)
		tag.position = to_local(sprite.global_position) + bump
	return tag

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

func _hp_ratio() -> float:
	var poly := _hp_fill.polygon
	if poly.size() < 3:
		return 0.0
	return clampf((poly[1].x + HP_BAR.x * 0.5) / HP_BAR.x, 0.0, 1.0)

func _hp_shape(ratio: float) -> PackedVector2Array:
	var half := HP_BAR * 0.5
	var w := HP_BAR.x * clampf(ratio, 0.0, 1.0)
	if w <= 1.0:
		return PackedVector2Array()
	return PackedVector2Array([
		Vector2(-half.x, -half.y), Vector2(-half.x + w, -half.y),
		Vector2(-half.x + w, half.y), Vector2(-half.x, half.y),
	])

func _hp_frame(half: Vector2) -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(-half.x, -half.y), Vector2(half.x, -half.y),
		Vector2(half.x, half.y), Vector2(-half.x, half.y),
	])

func _oval(rx: float, ry: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	const SEGMENTS := 22
	for i in SEGMENTS:
		var angle := TAU * float(i) / float(SEGMENTS)
		points.append(Vector2(cos(angle) * rx, sin(angle) * ry))
	return points
