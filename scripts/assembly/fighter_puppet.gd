class_name FighterPuppet
extends Node2D

## On-stage fighter. Six drawings move like a marionette; shop kits stay three.

enum Pose { FRONT, PROFILE, STRIDE }

const TAG_OFFSETS := {
	PartSlotType.Value.HEAD: Vector2(78, -110),
	PartSlotType.Value.BODY: Vector2(78, -10),
	PartSlotType.Value.LEGS: Vector2(78, 90),
}

var _parts: Dictionary = {}
var _pose: Pose = Pose.FRONT
var _walk_step: int = 0
var _attack_slot: Variant = null
var _dead: Dictionary = {}
var _tags: Dictionary = {}
var _sprites: Dictionary = {}
var _rest_pos: Dictionary = {}

func _ready() -> void:
	for slot in PartSlotType.draw_order():
		var sprite := Sprite2D.new()
		sprite.centered = true
		add_child(sprite)
		_sprites[slot] = sprite
	for slot in PartSlotType.shop_slots():
		var tag := StatTag.new()
		tag.position = TAG_OFFSETS[slot]
		add_child(tag)
		_tags[slot] = tag

func setup_loadout(loadout: FighterLoadout, face_left: bool) -> void:
	_parts = PartKit.expand_loadout(loadout)
	_pose = Pose.FRONT
	_walk_step = 0
	_attack_slot = null
	_dead.clear()
	scale.x = -absf(scale.x) if face_left else absf(scale.x)
	_refresh()
	refresh_tags(loadout)

func setup_parts(head: PartDef, body: PartDef, legs: PartDef) -> void:
	setup_loadout(FighterLoadout.from_parts(head, body, legs), scale.x < 0)

func set_pose(pose: Pose) -> void:
	_pose = pose
	_attack_slot = null
	_refresh()

func set_stride_frame(left_forward: bool) -> void:
	_pose = Pose.STRIDE
	_walk_step = 0 if left_forward else 1
	_attack_slot = null
	_refresh()

func set_attacking(slot: Variant) -> void:
	_attack_slot = slot
	_refresh()

func set_part_dead(slot: PartSlotType.Value, dead: bool) -> void:
	for visual in PartSlotType.visual_slots_for(slot):
		_dead[visual] = dead
	_refresh()
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
	var tag: StatTag = _tags[slot]
	tag.setup(value, ThemeTokens.color_for_slot(slot))

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

func kit_anchor(shop_slot: PartSlotType.Value) -> Vector2:
	var acc := Vector2.ZERO
	var count := 0
	for visual in PartSlotType.visual_slots_for(shop_slot):
		var sprite: Sprite2D = _sprites.get(visual)
		if sprite == null or sprite.texture == null:
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

func _refresh() -> void:
	var textures := {}
	for slot in PartSlotType.visual_slots():
		textures[slot] = _texture_for(slot)
	var plan := CompositeResolver.resolve_slots(_parts, textures)
	var positions: Dictionary = plan.get("positions", {})
	for slot in PartSlotType.draw_order():
		_place(_sprites[slot], textures.get(slot), positions.get(slot, Vector2.ZERO), slot)
	_apply_marionette()

func _texture_for(slot: PartSlotType.Value) -> Texture2D:
	if is_visual_dead(slot):
		return null
	var part := _part_def(slot)
	if part == null:
		return null
	if (_pose == Pose.STRIDE or _pose == Pose.PROFILE) and part.sprite_profile != null:
		return part.sprite_profile
	return part.sprite

func _place(sprite: Sprite2D, texture: Texture2D, pos: Vector2, slot: PartSlotType.Value) -> void:
	if sprite == null:
		return
	sprite.rotation = 0.0
	if texture == null:
		sprite.visible = false
		sprite.texture = null
		_rest_pos[slot] = pos
		return
	sprite.visible = not is_visual_dead(slot)
	sprite.texture = texture
	sprite.position = pos
	sprite.scale = Vector2.ONE * CompositeResolver.display_scale()
	_rest_pos[slot] = pos

func _apply_marionette() -> void:
	if _pose == Pose.STRIDE:
		var dir := 1.0 if _walk_step == 0 else -1.0
		_rotate_limb(PartSlotType.Value.LEG_L, -24.0 * dir)
		_rotate_limb(PartSlotType.Value.LEG_R, 20.0 * dir)
		_rotate_limb(PartSlotType.Value.ARM_L, 12.0 * dir)
		_rotate_limb(PartSlotType.Value.ARM_R, -12.0 * dir)
	if _attack_slot == null:
		return
	match int(_attack_slot):
		int(PartSlotType.Value.HEAD):
			_nudge(PartSlotType.Value.HEAD, Vector2(18, -8))
			_nudge(PartSlotType.Value.BODY, Vector2(10, -2))
		int(PartSlotType.Value.BODY):
			_rotate_limb(PartSlotType.Value.ARM_R, -58.0)
		int(PartSlotType.Value.LEGS):
			_rotate_limb(PartSlotType.Value.LEG_R, -50.0)

func _rotate_limb(slot: PartSlotType.Value, angle_deg: float) -> void:
	var sprite: Sprite2D = _sprites.get(slot)
	var part := _part_def(slot)
	if sprite == null or part == null or not sprite.visible:
		return
	var rest: Vector2 = _rest_pos.get(slot, sprite.position)
	var magnet := part.magnet_up_for(sprite.texture) * CompositeResolver.display_scale()
	var rad := deg_to_rad(angle_deg)
	sprite.position = rest + magnet - magnet.rotated(rad)
	sprite.rotation = rad

func _nudge(slot: PartSlotType.Value, offset: Vector2) -> void:
	var sprite: Sprite2D = _sprites.get(slot)
	if sprite == null or not sprite.visible:
		return
	var rest: Vector2 = _rest_pos.get(slot, sprite.position)
	sprite.position = rest + offset
