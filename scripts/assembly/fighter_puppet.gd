class_name FighterPuppet
extends Node2D

## Jointed on-stage fighter. Limbs rotate around magnet sockets.

signal stepped
signal struck

enum Pose { FRONT, PROFILE, STRIDE }

const TAG_OFFSETS := {
	PartSlotType.Value.HEAD: Vector2(78, -110),
	PartSlotType.Value.BODY: Vector2(78, -10),
	PartSlotType.Value.LEGS: Vector2(78, 90),
}
const WALK_HZ := 2.15
const LEG_SWING := 0.42
const ARM_SWING := 0.28
const IDLE_HZ := 1.35

var _parts: Dictionary = {}
var _pose: Pose = Pose.FRONT
var _dead: Dictionary = {}
var _tags: Dictionary = {}
var _sprites: Dictionary = {}
var _joints: Dictionary = {}
var _body_root: Node2D
var _body_rest := CompositeResolver.BODY_ORIGIN
var _walking: bool = false
var _striking: bool = false
var _frozen: bool = false
var _gait: float = 0.0
var _life: float = 0.0
var _prev_gait_sin: float = 0.0
var _motion: Tween

func _ready() -> void:
	_body_root = Node2D.new()
	_body_root.name = "BodyRoot"
	add_child(_body_root)
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
		_gait += delta * WALK_HZ * TAU
		var s := sin(_gait)
		_apply_gait(_gait)
		if (_prev_gait_sin <= 0.0 and s > 0.0) or (_prev_gait_sin >= 0.0 and s < 0.0):
			stepped.emit()
		_prev_gait_sin = s
	else:
		_apply_idle()

func setup_loadout(loadout: FighterLoadout, face_left: bool) -> void:
	_parts = PartKit.expand_loadout(loadout)
	_pose = Pose.FRONT
	_walking = false
	_striking = false
	_frozen = false
	_gait = 0.0
	_dead.clear()
	scale.x = -absf(scale.x) if face_left else absf(scale.x)
	_layout_rig()
	refresh_tags(loadout)

func setup_parts(head: PartDef, body: PartDef, legs: PartDef) -> void:
	setup_loadout(FighterLoadout.from_parts(head, body, legs), scale.x < 0)

func set_pose(pose: Pose) -> void:
	_pose = pose
	_striking = false
	if pose != Pose.STRIDE:
		_walking = false
	_layout_rig()
	if pose == Pose.STRIDE:
		_apply_gait(_gait)

func start_walk() -> void:
	_pose = Pose.PROFILE
	_walking = true
	_striking = false
	_frozen = false
	_layout_rig()

func stop_walk() -> void:
	_walking = false
	_frozen = false

func freeze_motion(on: bool) -> void:
	_frozen = on
	if on:
		_walking = false
		_reset_joints()

func settle_idle() -> void:
	_walking = false
	_striking = true
	await _tween_rest(0.22)
	_striking = false

func set_stride_frame(left_forward: bool) -> void:
	_pose = Pose.PROFILE
	_walking = false
	_striking = true
	_layout_rig()
	_apply_gait(0.25 * TAU if left_forward else 0.75 * TAU)

func set_attacking(slot: Variant) -> void:
	_striking = slot != null
	_walking = false
	_layout_rig()
	if slot == null:
		_reset_joints()
		return
	_apply_strike_pose(int(slot))

func play_strike(slot: Variant) -> void:
	_striking = true
	_walking = false
	_kill_motion()
	_layout_rig()
	match int(slot) if slot != null else -1:
		int(PartSlotType.Value.HEAD):
			await _strike_head()
		int(PartSlotType.Value.LEGS):
			await _strike_kick()
		_:
			await _strike_punch()

func drop_kit(slot: PartSlotType.Value) -> void:
	_striking = true
	_kill_motion()
	for visual in PartSlotType.visual_slots_for(slot):
		var sprite: Sprite2D = _sprites.get(visual)
		if sprite == null or not sprite.visible:
			continue
		var tw := create_tween()
		tw.set_parallel(true)
		tw.tween_property(sprite, "modulate:a", 0.0, 0.42).set_trans(Tween.TRANS_SINE)
		tw.tween_property(sprite, "position:y", sprite.position.y + 58.0, 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_property(sprite, "rotation", sprite.rotation + deg_to_rad(48.0), 0.42)
		tw.tween_property(sprite, "scale", sprite.scale * 0.72, 0.42)
	await get_tree().create_timer(0.42).timeout
	set_part_dead(slot, true)
	_striking = false

func set_part_dead(slot: PartSlotType.Value, dead: bool) -> void:
	for visual in PartSlotType.visual_slots_for(slot):
		_dead[visual] = dead
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
	for slot in _sprites.keys():
		var sprite: Sprite2D = _sprites[slot]
		if sprite == null or not sprite.visible or sprite.texture == null:
			continue
		var half_h := float(sprite.texture.get_height()) * absf(sprite.global_scale.y) * 0.5
		lowest = maxf(lowest, sprite.global_position.y + half_h)
	if lowest == -INF:
		return global_position.y + CompositeResolver.FEET_DROP_PX
	return lowest

func get_part_node(slot: PartSlotType.Value) -> Sprite2D:
	if PartSlotType.is_shop_slot(slot) and slot != PartSlotType.Value.HEAD and slot != PartSlotType.Value.BODY:
		var visuals := PartSlotType.visual_slots_for(slot)
		if not visuals.is_empty():
			return _sprites.get(visuals[0]) as Sprite2D
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
		if sprite == null or sprite.texture == null or not sprite.visible:
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
	var plan := CompositeResolver.resolve_slots(_parts, textures)
	var positions: Dictionary = plan.get("positions", {})
	var part_scale := CompositeResolver.display_scale()
	_body_rest = positions.get(PartSlotType.Value.BODY, CompositeResolver.BODY_ORIGIN)
	_body_root.position = _body_rest
	if not _walking and not _striking:
		_body_root.rotation = 0.0
	var body: PartDef = _parts.get(PartSlotType.Value.BODY)
	var body_tex: Texture2D = textures.get(PartSlotType.Value.BODY)
	_place_sprite(_sprites[PartSlotType.Value.BODY], body_tex, Vector2.ZERO, body)
	_sprites[PartSlotType.Value.BODY].z_index = PartSlotType.fight_z_index(PartSlotType.Value.BODY)
	_place_joint(
		PartSlotType.Value.HEAD,
		_socket(body, "neck", body_tex) * part_scale,
		textures.get(PartSlotType.Value.HEAD),
		_socket(_part_def(PartSlotType.Value.HEAD), "down", textures.get(PartSlotType.Value.HEAD)) * part_scale
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
	_place_joint(
		PartSlotType.Value.LEG_L,
		_socket(body, "hip_l", body_tex) * part_scale,
		textures.get(PartSlotType.Value.LEG_L),
		_socket(_part_def(PartSlotType.Value.LEG_L), "up", textures.get(PartSlotType.Value.LEG_L)) * part_scale
	)
	_place_joint(
		PartSlotType.Value.LEG_R,
		_socket(body, "hip_r", body_tex) * part_scale,
		textures.get(PartSlotType.Value.LEG_R),
		_socket(_part_def(PartSlotType.Value.LEG_R), "up", textures.get(PartSlotType.Value.LEG_R)) * part_scale
	)

func _place_joint(slot: PartSlotType.Value, joint_pos: Vector2, texture: Texture2D, magnet: Vector2) -> void:
	var joint: Node2D = _joints.get(slot)
	var sprite: Sprite2D = _sprites.get(slot)
	if joint == null or sprite == null:
		return
	var part := _part_def(slot)
	joint.position = joint_pos
	joint.z_index = PartSlotType.fight_z_index(slot)
	_place_sprite(sprite, texture, -magnet, part)
	joint.visible = texture != null

func _place_sprite(sprite: Sprite2D, texture: Texture2D, pos: Vector2, part: PartDef = null) -> void:
	if sprite == null:
		return
	if texture == null:
		sprite.visible = false
		sprite.texture = null
		return
	sprite.visible = true
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

func _apply_gait(phase: float) -> void:
	var s := sin(phase)
	var opp := sin(phase + PI)
	_set_joint(PartSlotType.Value.LEG_L, s * -LEG_SWING)
	_set_joint(PartSlotType.Value.LEG_R, opp * -LEG_SWING)
	_set_joint(PartSlotType.Value.ARM_L, s * ARM_SWING)
	_set_joint(PartSlotType.Value.ARM_R, opp * ARM_SWING)
	_set_joint(PartSlotType.Value.HEAD, s * -0.12)
	if _body_root != null:
		_body_root.rotation = s * 0.08
		_body_root.position.y = _body_rest.y - absf(s) * 5.5

func _apply_idle() -> void:
	var b := sin(_life * IDLE_HZ * TAU)
	_set_joint(PartSlotType.Value.ARM_L, b * 0.07)
	_set_joint(PartSlotType.Value.ARM_R, -b * 0.07)
	_set_joint(PartSlotType.Value.HEAD, b * 0.04)
	_set_joint(PartSlotType.Value.LEG_L, 0.0)
	_set_joint(PartSlotType.Value.LEG_R, 0.0)
	if _body_root != null:
		_body_root.rotation = b * 0.02
		_body_root.position.y = _body_rest.y + b * 1.8

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
	GameAudio.whoosh()
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
	GameAudio.whoosh()
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
	GameAudio.whoosh()
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
			_motion.tween_property(joint, "rotation", 0.0, duration).set_trans(Tween.TRANS_SINE)
	await _motion.finished
	_reset_joints()

func _reset_joints() -> void:
	for slot in _joints.keys():
		_set_joint(slot, 0.0)
	if _body_root != null:
		_body_root.rotation = 0.0
		_body_root.position = _body_rest

func _set_joint(slot: Variant, radians: float) -> void:
	var joint: Node2D = _joints.get(slot)
	if joint != null:
		joint.rotation = radians

func _kill_motion() -> void:
	if _motion != null and _motion.is_valid():
		_motion.kill()
	_motion = null
