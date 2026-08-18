class_name BeltFreak
extends Node2D

## A finished Freak riding its conveyor. It has no legs, so it drags itself
## along with its hands: the arms swing back, the body rocks, dust puffs at the
## rollers. At the tip it brakes and turns to face the enemy.

const HP_BAR := Vector2(96, 10)
const SLIDE_CYCLE := 0.62
const ARM_SWING := 0.55
const HEAD_ARC := 210.0

var runner: BeltLane.Runner
var player_side: bool = true
## Set once the Freak has braked at the fighting tip.
var arrived: bool = false

var _body: Node2D
var _overlay: Node2D
var _shadow: Polygon2D
var _dust: CPUParticles2D
var _hp_fill: Polygon2D
var _sprites: Dictionary = {}
var _arm_rest: Dictionary = {}
var _head_home := Vector2.ZERO
var _phase: float = 0.0
var _display_scale: float = AssemblyLayout.BELT_FREAK_SCALE
var _moving: bool = true
var _max_hp: int = 1
var _dead: bool = false

func setup(loadout: FighterLoadout, lane_runner: BeltLane.Runner, is_player: bool) -> void:
	runner = lane_runner
	player_side = is_player
	_max_hp = maxi(1, lane_runner.stats.toughness)
	_build_body(loadout)
	_build_overlay()
	set_progress(lane_runner.progress)

# ---------------------------------------------------------------- movement

func set_progress(progress: float) -> void:
	position.x = AssemblyLayout.belt_x_at(player_side, progress)
	position.y = AssemblyLayout.belt_floor_y()

func set_moving(moving: bool) -> void:
	if _moving == moving:
		return
	_moving = moving
	if _dust != null:
		_dust.emitting = moving
	if not moving:
		_settle()

## Hard stop at the tip: squash, dust puff, then face the enemy.
func play_arrive() -> void:
	set_moving(false)
	Feel.punch(_body, Vector2(1.16, 0.84), Vector2.ONE)
	if _dust != null:
		_dust.emitting = true
		var stop := create_tween()
		stop.tween_interval(0.3)
		stop.tween_callback(func() -> void:
			if is_instance_valid(_dust):
				_dust.emitting = false
		)

func play_land() -> void:
	_body.position.y = -240.0
	_body.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(_body, "modulate:a", 1.0, 0.12)
	tween.parallel().tween_property(_body, "position:y", 0.0, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(func() -> void: Feel.punch(_body, Vector2(1.2, 0.8), Vector2.ONE))
	tween.parallel().tween_callback(GameAudio.part_place)

func _process(delta: float) -> void:
	if _dead or not _moving:
		return
	_phase += delta / SLIDE_CYCLE
	var wave := sin(_phase * TAU)
	var lead: Sprite2D = _sprites.get(PartSlotType.Value.ARM_R)
	var trail: Sprite2D = _sprites.get(PartSlotType.Value.ARM_L)
	_swing(lead, wave * ARM_SWING)
	_swing(trail, -wave * ARM_SWING * 0.8)
	_body.position.y = -absf(wave) * 5.0
	_body.rotation = wave * 0.045
	var head: Sprite2D = _sprites.get(PartSlotType.Value.HEAD)
	if head != null:
		head.position = _head_home + Vector2(wave * 3.0, absf(wave) * -2.0)

func _settle() -> void:
	_body.rotation = 0.0
	_body.position.y = 0.0
	for slot in [PartSlotType.Value.ARM_L, PartSlotType.Value.ARM_R]:
		_swing(_sprites.get(slot), 0.0)
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

# ---------------------------------------------------------------- fighting

func head_global_position() -> Vector2:
	var head: Sprite2D = _sprites.get(PartSlotType.Value.HEAD)
	return head.global_position if head != null else global_position

## Wind up, throw the head at the target, land the hit, bring it back.
func attack(target: Callable, on_impact: Callable) -> void:
	var head: Sprite2D = _sprites.get(PartSlotType.Value.HEAD)
	if head == null or head.texture == null:
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
	set_process(false)
	if _dust != null:
		_dust.emitting = false
	if _overlay != null:
		_overlay.visible = false
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
	_body = Node2D.new()
	_body.name = "Body"
	add_child(_body)
	if not player_side:
		_body.scale.x = -1.0

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
	_dust.emitting = true
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
