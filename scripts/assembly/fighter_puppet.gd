class_name FighterPuppet
extends Node2D

## Jointed on-stage fighter. Limbs rotate around magnet sockets.

signal stepped
signal hopped
signal struck

enum Pose { FRONT, PROFILE, STRIDE }

const TAG_OFFSETS := {
	PartSlotType.Value.HEAD: Vector2(78, -110),
	PartSlotType.Value.BODY: Vector2(78, -10),
	PartSlotType.Value.ARM_L: Vector2(-78, 8),
	PartSlotType.Value.ARM_R: Vector2(78, 48),
}
const _Spring := preload("res://scripts/data/spring_base.gd")
const HOP_HZ := 1.2
const HOP_HEIGHT := 86.0
const HOP_COMPRESS := 0.22
const HOP_LAND := 0.86
const ARM_SWING := 0.28
const IDLE_HZ := 1.35

var _parts: Dictionary = {}
var _pose: Pose = Pose.FRONT
var _dead: Dictionary = {}
var _detached: Dictionary = {}
var _tags: Dictionary = {}
var _sprites: Dictionary = {}
var _joints: Dictionary = {}
var _body_root: Node2D
var _hop_root: Node2D
var _spring: Sprite2D
var _shadow: Polygon2D
var _body_rest := CompositeResolver.BODY_ORIGIN
var _spring_rest := Vector2.ZERO
var _walking: bool = false
var _striking: bool = false
var _frozen: bool = false
var _gait: float = 0.0
var _life: float = 0.0
var _hop_y: float = 0.0
var _hop_squash: float = 1.0
var _hop_lean: float = 0.0
var _spring_pressed: bool = true
var _was_airborne: bool = false
var _motion: Tween

func _ready() -> void:
	_hop_root = Node2D.new()
	_hop_root.name = "HopRoot"
	add_child(_hop_root)
	_shadow = _Spring.make_shadow()
	add_child(_shadow)
	move_child(_shadow, 0)
	_spring = Sprite2D.new()
	_spring.name = "Spring"
	_spring.centered = true
	_spring.z_index = _Spring.Z_INDEX
	_hop_root.add_child(_spring)
	_body_root = Node2D.new()
	_body_root.name = "BodyRoot"
	_hop_root.add_child(_body_root)
	var body_sprite := Sprite2D.new()
	body_sprite.centered = true
	body_sprite.z_index = PartSlotType.fight_z_index(PartSlotType.Value.BODY)
	_body_root.add_child(body_sprite)
	_sprites[PartSlotType.Value.BODY] = body_sprite
	for slot in [
		PartSlotType.Value.LEG_L,
		PartSlotType.Value.LEG_R,
		PartSlotType.Value.ARM_L,
		PartSlotType.Value.ARM_R,
		PartSlotType.Value.HEAD,
	]:
		var joint := Node2D.new()
		joint.z_index = PartSlotType.fight_z_index(slot)
		_body_root.add_child(joint)
		_joints[slot] = joint
		var sprite := Sprite2D.new()
		sprite.centered = true
		joint.add_child(sprite)
		_sprites[slot] = sprite
	for slot in PartSlotType.shop_slots():
		var tag := StatTag.new()
		tag.position = TAG_OFFSETS[slot]
		add_child(tag)
		_tags[slot] = tag
	set_process(true)

func _process(delta: float) -> void:
	_life += delta
	if _striking or _frozen:
		return
	if _walking:
		_gait += delta * HOP_HZ * TAU
		_apply_hop(_gait)
	else:
		_apply_idle()

func setup_loadout(loadout: FighterLoadout, face_left: bool) -> void:
	_parts = PartKit.expand_loadout(loadout)
	_pose = Pose.FRONT
	_walking = false
	_striking = false
	_frozen = false
	_gait = 0.0
	_hop_y = 0.0
	_hop_squash = 1.0
	_hop_lean = 0.0
	_spring_pressed = true
	_was_airborne = false
	_dead.clear()
	_detached.clear()
	scale.x = -absf(scale.x) if face_left else absf(scale.x)
	_layout_rig()
	refresh_tags(loadout)

func setup_parts(head: PartDef, body: PartDef, arm_l: PartDef = null, arm_r: PartDef = null) -> void:
	setup_loadout(FighterLoadout.from_parts(head, body, arm_l, arm_r), scale.x < 0)

func set_pose(pose: Pose) -> void:
	_pose = pose
	_striking = false
	if pose != Pose.STRIDE:
		_walking = false
	_layout_rig()
	if pose == Pose.STRIDE:
		_apply_hop(_gait)

func start_walk() -> void:
	_pose = Pose.PROFILE
	_walking = true
	_striking = false
	_frozen = false
	_gait = 0.0
	_was_airborne = false
	_layout_rig()

func stop_walk() -> void:
	_walking = false
	_frozen = false
	_reset_hop()

func freeze_motion(on: bool) -> void:
	_frozen = on
	if on:
		_walking = false
		_reset_hop()
		_reset_joints()

func settle_idle() -> void:
	_walking = false
	_striking = true
	_reset_hop()
	await _tween_rest(0.22)
	_striking = false

func set_stride_frame(_left_forward: bool) -> void:
	_pose = Pose.PROFILE
	_walking = false
	_striking = true
	_gait = 0.5 * TAU
	_layout_rig()
	_apply_hop(_gait)

func set_attacking(slot: Variant) -> void:
	_striking = slot != null
	_walking = false
	_reset_hop()
	_layout_rig()
	if slot == null:
		_reset_joints()
		return
	_apply_strike_pose(int(slot))

func play_strike(slot: Variant) -> void:
	_striking = true
	_walking = false
	_kill_motion()
	_reset_hop()
	_layout_rig()
	match int(slot) if slot != null else -1:
		int(PartSlotType.Value.HEAD):
			await _strike_head()
		int(PartSlotType.Value.LEGS):
			await _strike_kick()
		_:
			await _strike_punch()

func sprite_of(slot: PartSlotType.Value) -> Sprite2D:
	return _sprites.get(slot) as Sprite2D

func detach_kit(shop_slot: PartSlotType.Value) -> void:
	for visual in PartSlotType.visual_slots_for(shop_slot):
		_detached[visual] = true
		var sprite: Sprite2D = _sprites.get(visual)
		if sprite != null:
			sprite.visible = false

func attach_kit(shop_slot: PartSlotType.Value) -> void:
	for visual in PartSlotType.visual_slots_for(shop_slot):
		_detached.erase(visual)
	_layout_rig()

func snap_rest() -> void:
	_kill_motion()
	_reset_joints()
	_layout_rig()

func play_throw_windup(shop_slot: PartSlotType.Value) -> void:
	_striking = true
	_walking = false
	_kill_motion()
	_reset_hop()
	_layout_rig()
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_body_root, "position", _body_rest + Vector2(-26.0, 10.0), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_body_root, "rotation", 0.22, 0.2)
	match int(shop_slot):
		int(PartSlotType.Value.HEAD):
			_tween_joint(tw, PartSlotType.Value.HEAD, 0.42, 0.2)
			_tween_joint(tw, PartSlotType.Value.ARM_L, -0.28, 0.2)
			_tween_joint(tw, PartSlotType.Value.ARM_R, 0.28, 0.2)
		int(PartSlotType.Value.ARM_L):
			_tween_joint(tw, PartSlotType.Value.ARM_L, -0.95, 0.2)
			_tween_joint(tw, PartSlotType.Value.HEAD, 0.08, 0.2)
		int(PartSlotType.Value.ARM_R):
			_tween_joint(tw, PartSlotType.Value.ARM_R, 0.95, 0.2)
			_tween_joint(tw, PartSlotType.Value.HEAD, 0.08, 0.2)
		_:
			_tween_joint(tw, PartSlotType.Value.ARM_R, 0.85, 0.2)
			_tween_joint(tw, PartSlotType.Value.ARM_L, -0.55, 0.2)
			_tween_joint(tw, PartSlotType.Value.HEAD, 0.12, 0.2)
	await tw.finished
	await get_tree().create_timer(0.06).timeout

func play_throw_recoil(shop_slot: PartSlotType.Value) -> void:
	_striking = true
	var tw := create_tween()
	tw.set_parallel(true)
	var hop := Vector2(22.0, -8.0)
	if shop_slot == PartSlotType.Value.LEGS:
		hop = Vector2(16.0, -28.0)
	tw.tween_property(_body_root, "position", _body_rest + hop, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.tween_property(_body_root, "rotation", -0.2, 0.12)
	await tw.finished
	await _tween_rest(0.22)
	_striking = false

func play_catch_kit() -> void:
	_striking = true
	Feel.punch(self, Vector2(1.16, 0.84), Vector2.ONE)
	modulate = Color(1.35, 1.22, 0.95)
	var tw := create_tween()
	tw.tween_property(self, "modulate", Color.WHITE, 0.2)
	await _tween_rest(0.16)
	_striking = false

func play_flinch(away: float) -> void:
	_striking = true
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_body_root, "position", _body_rest + Vector2(away * 18.0, 6.0), 0.08)
	tw.tween_property(_body_root, "rotation", away * 0.16, 0.08)
	await tw.finished
	await _tween_rest(0.18)
	_striking = false

func set_part_dead(slot: PartSlotType.Value, dead: bool) -> void:
	for visual in PartSlotType.visual_slots_for(slot):
		_dead[visual] = dead
		_detached.erase(visual)
	_layout_rig()
	if _tags.has(slot) and dead:
		(_tags[slot] as StatTag).visible = false

func is_visual_dead(slot: PartSlotType.Value) -> bool:
	return bool(_dead.get(slot, false))

func refresh_tags(loadout: FighterLoadout) -> void:
	for slot in _tags.keys():
		var tag: StatTag = _tags[slot]
		if _kit_dead(slot) or loadout == null or loadout.get_part(slot) == null:
			tag.visible = false
			continue
		tag.visible = true
		tag.setup(loadout.combat_value_of(slot), ThemeTokens.color_for_slot(slot))

func set_tag_value(slot: PartSlotType.Value, value: int) -> void:
	if not _tags.has(slot):
		return
	(_tags[slot] as StatTag).setup(value, ThemeTokens.color_for_slot(slot))

func has_living_part() -> bool:
	for slot in PartSlotType.visual_slots():
		if _part_def(slot) != null and not is_visual_dead(slot):
			return true
	return false

func feet_position() -> Vector2:
	return Vector2(global_position.x, visual_bottom_y())

func visual_bottom_y() -> float:
	var lowest := -INF
	if _spring != null and _spring.visible and _spring.texture != null:
		var half_h := float(_spring.texture.get_height()) * absf(_spring.global_scale.y) * 0.5
		lowest = maxf(lowest, _spring.global_position.y + half_h)
	for slot in _sprites.keys():
		var sprite: Sprite2D = _sprites[slot]
		if sprite == null or not sprite.visible or sprite.texture == null:
			continue
		var half_h := float(sprite.texture.get_height()) * absf(sprite.global_scale.y) * 0.5
		lowest = maxf(lowest, sprite.global_position.y + half_h)
	if lowest == -INF:
		return global_position.y + _Spring.GROUND_Y
	return lowest

func is_spring_pressed() -> bool:
	return _spring_pressed

func hop_lift() -> float:
	return -_hop_y

func spring_is_airborne() -> bool:
	return _hop_y < -8.0

func _place_spring() -> void:
	if _spring == null:
		return
	_spring.texture = _Spring.texture(_spring_pressed)
	_spring.visible = true
	_spring.scale = Vector2.ONE * _Spring.SCALE
	_spring.z_index = _Spring.Z_INDEX
	_spring.position = _spring_rest

func _update_shadow() -> void:
	if _shadow == null:
		return
	_shadow.position = _Spring.shadow_position()
	var look: Dictionary = _Spring.hop_shadow_look(maxf(0.0, -_hop_y), HOP_HEIGHT)
	_shadow.scale = look["scale"]
	_shadow.modulate.a = float(look["alpha"])

func _reset_hop() -> void:
	_hop_y = 0.0
	_hop_squash = 1.0
	_hop_lean = 0.0
	_apply_hop_transform()

func _apply_hop_transform() -> void:
	if _hop_root == null:
		return
	var squash := _hop_squash
	_hop_root.scale = Vector2(2.0 - squash, squash)
	_hop_root.rotation = _hop_lean
	_hop_root.position = Vector2(0.0, _Spring.GROUND_Y * (1.0 - squash) + _hop_y)
	_update_shadow()
	if _body_root != null and not _walking:
		_body_root.position.x = _body_rest.x
		if not _striking:
			_body_root.position.y = _body_rest.y

func _set_spring_pressed(pressed: bool) -> void:
	if _spring_pressed == pressed:
		_place_spring()
		return
	_spring_pressed = pressed
	_layout_rig()

func _apply_hop(phase: float) -> void:
	var cycle := fposmod(phase, TAU) / TAU
	var airborne := false
	if cycle < HOP_COMPRESS:
		var u := _smooth(cycle / HOP_COMPRESS)
		_hop_squash = lerpf(1.0, 0.74, u)
		_hop_y = 0.0
		_hop_lean = 0.05 * u
		_set_spring_pressed(true)
	elif cycle < HOP_LAND:
		airborne = true
		var span := HOP_LAND - HOP_COMPRESS
		var u := (cycle - HOP_COMPRESS) / span
		# Ballistic arc: leave the ground, peak, fall. Whole toy rides this.
		_hop_y = -4.0 * u * (1.0 - u) * HOP_HEIGHT
		_hop_squash = 1.0
		_hop_lean = 0.18 * (1.0 - 2.0 * u)
		_set_spring_pressed(false)
	else:
		var u := _smooth((cycle - HOP_LAND) / (1.0 - HOP_LAND))
		_hop_squash = lerpf(0.7, 1.0, u)
		_hop_y = 0.0
		_hop_lean = 0.0
		_set_spring_pressed(true)
	_apply_hop_transform()
	var swing := sin(phase)
	_set_joint(PartSlotType.Value.ARM_L, swing * ARM_SWING)
	_set_joint(PartSlotType.Value.ARM_R, sin(phase + PI) * ARM_SWING)
	_set_joint(PartSlotType.Value.HEAD, swing * -0.12)
	if _body_root != null:
		_body_root.rotation = swing * 0.08
		_body_root.position = Vector2(_body_rest.x, _body_rest.y)
	if not _was_airborne and airborne:
		hopped.emit()
	if _was_airborne and not airborne:
		stepped.emit()
	_was_airborne = airborne

func _apply_idle() -> void:
	_reset_hop()
	var want_pressed := _has_visible_part()
	if _spring_pressed != want_pressed:
		_spring_pressed = want_pressed
		_layout_rig()
	else:
		_place_spring()
	var b := sin(_life * IDLE_HZ * TAU)
	var arm_l := CompositeResolver.front_arm_spread(PartSlotType.Value.ARM_L) if _pose == Pose.FRONT else 0.0
	var arm_r := CompositeResolver.front_arm_spread(PartSlotType.Value.ARM_R) if _pose == Pose.FRONT else 0.0
	_set_joint(PartSlotType.Value.ARM_L, arm_l + b * 0.07)
	_set_joint(PartSlotType.Value.ARM_R, arm_r - b * 0.07)
	_set_joint(PartSlotType.Value.HEAD, b * 0.04)
	_set_joint(PartSlotType.Value.LEG_L, 0.0)
	_set_joint(PartSlotType.Value.LEG_R, 0.0)
	if _body_root != null:
		_body_root.rotation = b * 0.02
		_body_root.position.y = _body_rest.y + b * 1.8

func _smooth(t: float) -> float:
	var u := clampf(t, 0.0, 1.0)
	return u * u * (3.0 - 2.0 * u)

func get_part_node(slot: PartSlotType.Value) -> Sprite2D:
	return _sprites.get(slot) as Sprite2D

func joint_rotation(slot: PartSlotType.Value) -> float:
	if slot == PartSlotType.Value.BODY:
		return _body_root.rotation if _body_root != null else 0.0
	var joint: Node2D = _joints.get(slot)
	return joint.rotation if joint != null else 0.0

func kit_anchor(shop_slot: PartSlotType.Value) -> Vector2:
	var acc := Vector2.ZERO
	var count := 0
	for visual in PartSlotType.visual_slots_for(shop_slot):
		var sprite: Sprite2D = _sprites.get(visual)
		if sprite == null or sprite.texture == null or is_visual_dead(visual):
			continue
		acc += sprite.global_position
		count += 1
	if count == 0:
		return global_position
	return acc / float(count)

func _kit_dead(shop_slot: PartSlotType.Value) -> bool:
	for visual in PartSlotType.visual_slots_for(shop_slot):
		if is_visual_dead(visual):
			return true
	return false

func _part_def(slot: PartSlotType.Value) -> PartDef:
	return _parts.get(slot) as PartDef

func _texture_for(slot: PartSlotType.Value) -> Texture2D:
	if is_visual_dead(slot):
		return null
	var part := _part_def(slot)
	if part == null:
		return null
	if _pose != Pose.FRONT and part.sprite_profile != null:
		return part.sprite_profile
	return part.sprite

func _layout_rig() -> void:
	if _body_root == null:
		return
	var textures := {}
	for slot in PartSlotType.visual_slots():
		textures[slot] = _texture_for(slot)
	# Body sits on the sphere of the current spring drawing.
	var pose_pressed := _spring_pressed
	if not _walking and not _striking:
		pose_pressed = _has_visible_part()
		_spring_pressed = pose_pressed
	var plan := CompositeResolver.resolve_slots(_parts, textures, pose_pressed)
	var positions: Dictionary = plan.get("positions", {})
	var part_scale := CompositeResolver.display_scale()
	var body: PartDef = _parts.get(PartSlotType.Value.BODY)
	var body_tex: Texture2D = textures.get(PartSlotType.Value.BODY)
	var head_tex: Texture2D = textures.get(PartSlotType.Value.HEAD)
	if body_tex != null:
		_body_rest = positions.get(PartSlotType.Value.BODY, CompositeResolver.BODY_ORIGIN)
	else:
		_body_rest = Vector2.ZERO
	_spring_rest = _Spring.center_on_ground(_spring_pressed)
	_place_spring()
	_apply_hop_transform()
	if not _walking and not _striking:
		_body_root.rotation = 0.0
	_place_sprite(PartSlotType.Value.BODY, _sprites[PartSlotType.Value.BODY], body_tex, Vector2.ZERO, body)
	_sprites[PartSlotType.Value.BODY].z_index = PartSlotType.fight_z_index(PartSlotType.Value.BODY)
	if body_tex != null:
		_place_joint(
			PartSlotType.Value.HEAD,
			_socket(body, "neck", body_tex) * part_scale,
			head_tex,
			_socket(_part_def(PartSlotType.Value.HEAD), "down", head_tex) * part_scale
		)
		_place_joint(
			PartSlotType.Value.ARM_L,
			_socket(body, "shoulder_l", body_tex) * part_scale,
			textures.get(PartSlotType.Value.ARM_L),
			_socket(_part_def(PartSlotType.Value.ARM_L), "up", textures.get(PartSlotType.Value.ARM_L)) * part_scale
		)
		_place_joint(
			PartSlotType.Value.ARM_R,
			_socket(body, "shoulder_r", body_tex) * part_scale,
			textures.get(PartSlotType.Value.ARM_R),
			_socket(_part_def(PartSlotType.Value.ARM_R), "up", textures.get(PartSlotType.Value.ARM_R)) * part_scale
		)
	else:
		var magnet := _Spring.magnet_world(pose_pressed)
		_place_joint(
			PartSlotType.Value.HEAD,
			magnet,
			head_tex,
			_socket(_part_def(PartSlotType.Value.HEAD), "down", head_tex) * part_scale
		)
		_place_joint(
			PartSlotType.Value.ARM_L,
			magnet + Vector2(-40.0, 8.0),
			textures.get(PartSlotType.Value.ARM_L),
			_socket(_part_def(PartSlotType.Value.ARM_L), "up", textures.get(PartSlotType.Value.ARM_L)) * part_scale
		)
		_place_joint(
			PartSlotType.Value.ARM_R,
			magnet + Vector2(40.0, 8.0),
			textures.get(PartSlotType.Value.ARM_R),
			_socket(_part_def(PartSlotType.Value.ARM_R), "up", textures.get(PartSlotType.Value.ARM_R)) * part_scale
		)
	_place_joint(PartSlotType.Value.LEG_L, Vector2.ZERO, null, Vector2.ZERO)
	_place_joint(PartSlotType.Value.LEG_R, Vector2.ZERO, null, Vector2.ZERO)

func _place_joint(slot: PartSlotType.Value, joint_pos: Vector2, texture: Texture2D, magnet: Vector2) -> void:
	var joint: Node2D = _joints.get(slot)
	var sprite: Sprite2D = _sprites.get(slot)
	if joint == null or sprite == null:
		return
	var part := _part_def(slot)
	joint.position = joint_pos
	joint.z_index = PartSlotType.fight_z_index(slot)
	_place_sprite(slot, sprite, texture, -magnet, part)
	joint.visible = texture != null

func _place_sprite(slot: PartSlotType.Value, sprite: Sprite2D, texture: Texture2D, pos: Vector2, part: PartDef = null) -> void:
	if sprite == null:
		return
	if texture == null:
		sprite.visible = false
		sprite.texture = null
		return
	sprite.visible = not bool(_detached.get(slot, false))
	sprite.texture = texture
	sprite.position = pos
	sprite.scale = Vector2.ONE * CompositeResolver.display_scale()
	sprite.modulate = Color.WHITE
	sprite.rotation = 0.0
	sprite.flip_h = false
	if part != null:
		part.apply_to_sprite(sprite, texture, false)

func _socket(part: PartDef, socket: String, shown: Texture2D) -> Vector2:
	return CompositeResolver.socket_of(part, socket, shown)

func _has_visible_part() -> bool:
	for slot in PartSlotType.visual_slots():
		if slot == PartSlotType.Value.LEG_L or slot == PartSlotType.Value.LEG_R:
			continue
		if _texture_for(slot) != null:
			return true
	return false

func _apply_strike_pose(shop_slot: int) -> void:
	match shop_slot:
		int(PartSlotType.Value.HEAD):
			_set_joint(PartSlotType.Value.HEAD, -0.22)
			if _body_root != null:
				_body_root.position.x = _body_rest.x + 16.0
				_body_root.rotation = -0.12
		int(PartSlotType.Value.LEGS):
			_set_joint(PartSlotType.Value.LEG_R, -0.85)
			_set_joint(PartSlotType.Value.LEG_L, 0.18)
			_set_joint(PartSlotType.Value.ARM_L, 0.2)
			_set_joint(PartSlotType.Value.ARM_R, -0.2)
		_:
			_set_joint(PartSlotType.Value.ARM_R, -1.05)
			_set_joint(PartSlotType.Value.ARM_L, 0.35)
			_set_joint(PartSlotType.Value.HEAD, -0.08)
			if _body_root != null:
				_body_root.position.x = _body_rest.x + 12.0
				_body_root.rotation = -0.14

func _strike_punch() -> void:
	var arm: Node2D = _joints.get(PartSlotType.Value.ARM_R)
	var other: Node2D = _joints.get(PartSlotType.Value.ARM_L)
	if arm == null:
		struck.emit()
		await get_tree().create_timer(0.28).timeout
		return
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(arm, "rotation", 0.92, 0.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if other != null:
		tw.tween_property(other, "rotation", -0.28, 0.18)
	tw.tween_property(_body_root, "rotation", 0.2, 0.18)
	tw.tween_property(_body_root, "position", _body_rest + Vector2(-10.0, 8.0), 0.18)
	_set_joint(PartSlotType.Value.HEAD, 0.12)
	await tw.finished
	tw = create_tween()
	tw.set_parallel(true)
	tw.tween_property(arm, "rotation", -1.48, 0.09).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	if other != null:
		tw.tween_property(other, "rotation", 0.48, 0.09)
	tw.tween_property(_body_root, "rotation", -0.24, 0.09)
	tw.tween_property(_body_root, "position", _body_rest + Vector2(26.0, -4.0), 0.09)
	_set_joint(PartSlotType.Value.HEAD, -0.16)
	await tw.finished
	struck.emit()
	await get_tree().create_timer(0.08).timeout

func _strike_kick() -> void:
	var kick: Node2D = _joints.get(PartSlotType.Value.LEG_R)
	var plant: Node2D = _joints.get(PartSlotType.Value.LEG_L)
	if kick == null:
		struck.emit()
		await get_tree().create_timer(0.28).timeout
		return
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(kick, "rotation", 0.62, 0.16).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if plant != null:
		tw.tween_property(plant, "rotation", 0.18, 0.16)
	tw.tween_property(_body_root, "rotation", 0.16, 0.16)
	tw.tween_property(_body_root, "position", _body_rest + Vector2(-6.0, -22.0), 0.16)
	_set_joint(PartSlotType.Value.ARM_L, 0.28)
	_set_joint(PartSlotType.Value.ARM_R, -0.22)
	await tw.finished
	tw = create_tween()
	tw.set_parallel(true)
	tw.tween_property(kick, "rotation", -1.22, 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	if plant != null:
		tw.tween_property(plant, "rotation", 0.28, 0.1)
	tw.tween_property(_body_root, "position", _body_rest + Vector2(18.0, 6.0), 0.1)
	tw.tween_property(_body_root, "rotation", -0.2, 0.1)
	await tw.finished
	struck.emit()
	await get_tree().create_timer(0.08).timeout

func _strike_head() -> void:
	var head: Node2D = _joints.get(PartSlotType.Value.HEAD)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_body_root, "position", _body_rest + Vector2(-16.0, 6.0), 0.16).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(_body_root, "rotation", 0.2, 0.16)
	if head != null:
		tw.tween_property(head, "rotation", 0.32, 0.16)
	_set_joint(PartSlotType.Value.ARM_L, -0.18)
	_set_joint(PartSlotType.Value.ARM_R, 0.18)
	await tw.finished
	tw = create_tween()
	tw.set_parallel(true)
	tw.tween_property(_body_root, "position", _body_rest + Vector2(28.0, -2.0), 0.09).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.tween_property(_body_root, "rotation", -0.22, 0.09)
	if head != null:
		tw.tween_property(head, "rotation", -0.38, 0.09)
	await tw.finished
	struck.emit()
	await get_tree().create_timer(0.08).timeout

func _tween_rest(duration: float) -> void:
	_kill_motion()
	if _body_root == null or not is_inside_tree():
		_reset_joints()
		return
	_motion = create_tween()
	_motion.set_parallel(true)
	_motion.tween_property(_body_root, "rotation", 0.0, duration).set_trans(Tween.TRANS_SINE)
	_motion.tween_property(_body_root, "position", _body_rest, duration).set_trans(Tween.TRANS_SINE)
	for slot in _joints.keys():
		var joint: Node2D = _joints[slot]
		if joint != null:
			_motion.tween_property(joint, "rotation", _rest_joint(slot), duration).set_trans(Tween.TRANS_SINE)
	await _motion.finished
	_reset_joints()

func _reset_joints() -> void:
	for slot in _joints.keys():
		_set_joint(slot, _rest_joint(slot))
	if _body_root != null:
		_body_root.rotation = 0.0
		_body_root.position = _body_rest

func _rest_joint(slot: Variant) -> float:
	if _pose != Pose.FRONT:
		return 0.0
	return CompositeResolver.front_arm_spread(slot as PartSlotType.Value)

func _set_joint(slot: Variant, radians: float) -> void:
	var joint: Node2D = _joints.get(slot)
	if joint != null:
		joint.rotation = radians

func _tween_joint(tw: Tween, slot: PartSlotType.Value, radians: float, duration: float) -> void:
	var joint: Node2D = _joints.get(slot)
	if joint != null:
		tw.tween_property(joint, "rotation", radians, duration)

func _kill_motion() -> void:
	if _motion != null and _motion.is_valid():
		_motion.kill()
	_motion = null
