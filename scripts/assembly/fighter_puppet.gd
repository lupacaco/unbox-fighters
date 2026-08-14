class_name FighterPuppet
extends Node2D

## On-stage fighter used during a real queue fight.

enum Pose { FRONT, PROFILE, STRIDE }

const TAG_OFFSETS := {
	PartSlotType.Value.HEAD: Vector2(78, -110),
	PartSlotType.Value.BODY: Vector2(78, -10),
	PartSlotType.Value.ARM_L: Vector2(-78, -40),
	PartSlotType.Value.ARM_R: Vector2(78, -40),
	PartSlotType.Value.LEG_L: Vector2(-78, 80),
	PartSlotType.Value.LEG_R: Vector2(78, 80),
}

var _parts: Dictionary = {}
var _pose: Pose = Pose.FRONT
var _stride_attack: bool = false
var _attack_slot: Variant = null
var _dead: Dictionary = {}
var _tags: Dictionary = {}
var _sprites: Dictionary = {}

func _ready() -> void:
	for slot in PartSlotType.draw_order():
		var sprite := Sprite2D.new()
		sprite.centered = true
		add_child(sprite)
		_sprites[slot] = sprite
	for slot in PartSlotType.all_slots():
		var tag := StatTag.new()
		tag.position = TAG_OFFSETS[slot]
		add_child(tag)
		_tags[slot] = tag

func setup_loadout(loadout: FighterLoadout, face_left: bool) -> void:
	_parts.clear()
	for slot in PartSlotType.all_slots():
		_parts[slot] = loadout.get_part(slot) if loadout != null else null
	_pose = Pose.FRONT
	_stride_attack = false
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
	if pose != Pose.STRIDE:
		_stride_attack = false
	_refresh()

func set_stride_frame(use_attack: bool) -> void:
	_pose = Pose.STRIDE
	_stride_attack = use_attack
	_attack_slot = null
	_refresh()

func set_attacking(slot: Variant) -> void:
	_attack_slot = slot
	_refresh()

func set_part_dead(slot: PartSlotType.Value, dead: bool) -> void:
	_dead[slot] = dead
	_refresh()
	if _tags.has(slot) and dead:
		(_tags[slot] as StatTag).visible = false

func refresh_tags(loadout: FighterLoadout) -> void:
	for slot in _tags.keys():
		var tag: StatTag = _tags[slot]
		if _dead.get(slot, false) or loadout == null or loadout.get_part(slot) == null:
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
	for slot in PartSlotType.all_slots():
		if _part_def(slot) != null and not _dead.get(slot, false):
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
	return _sprites.get(slot) as Sprite2D

func _part_def(slot: PartSlotType.Value) -> PartDef:
	return _parts.get(slot) as PartDef

func _refresh() -> void:
	var textures := {}
	for slot in PartSlotType.all_slots():
		textures[slot] = _texture_for(slot)
	var plan := CompositeResolver.resolve_slots(_parts, textures)
	var positions: Dictionary = plan.get("positions", {})
	for slot in PartSlotType.draw_order():
		_place(_sprites[slot], textures.get(slot), positions.get(slot, Vector2.ZERO), slot)

func _texture_for(slot: PartSlotType.Value) -> Texture2D:
	if _dead.get(slot, false):
		return null
	var part := _part_def(slot)
	if part == null:
		return null
	if _attack_slot != null and int(_attack_slot) == int(slot) and part.sprite_attack != null:
		return part.sprite_attack
	if _pose == Pose.STRIDE:
		if _stride_attack and part.sprite_attack != null:
			return part.sprite_attack
		if part.sprite_profile != null:
			return part.sprite_profile
	if _pose == Pose.PROFILE and part.sprite_profile != null:
		return part.sprite_profile
	return part.sprite

func _place(sprite: Sprite2D, texture: Texture2D, pos: Vector2, slot: PartSlotType.Value) -> void:
	if sprite == null:
		return
	if texture == null:
		sprite.visible = false
		sprite.texture = null
		return
	sprite.visible = not _dead.get(slot, false)
	sprite.texture = texture
	sprite.position = pos
	sprite.scale = Vector2.ONE * CompositeResolver.display_scale()
