class_name FighterPuppet
extends Node2D

## Temporary on-stage fighter used by the fight animation (not a card).

enum Pose { FRONT, PROFILE, STRIDE }

const PART_SIZE_PX := 170.0

var _head_def: PartDef
var _body_def: PartDef
var _legs_def: PartDef
var _pose: Pose = Pose.FRONT
var _stride_attack: bool = false
var _attack_slot: Variant = null

var _legs: Sprite2D
var _body: Sprite2D
var _head: Sprite2D

func _ready() -> void:
	_legs = Sprite2D.new()
	_body = Sprite2D.new()
	_head = Sprite2D.new()
	for sprite in [_legs, _body, _head]:
		sprite.centered = true
		add_child(sprite)

func setup_parts(head: PartDef, body: PartDef, legs: PartDef) -> void:
	_head_def = head
	_body_def = body
	_legs_def = legs
	_pose = Pose.FRONT
	_stride_attack = false
	_attack_slot = null
	_refresh()

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

func get_part_node(slot: PartSlotType.Value) -> Sprite2D:
	match slot:
		PartSlotType.Value.HEAD:
			return _head
		PartSlotType.Value.BODY:
			return _body
		_:
			return _legs

func _part_def(slot: PartSlotType.Value) -> PartDef:
	match slot:
		PartSlotType.Value.HEAD:
			return _head_def
		PartSlotType.Value.BODY:
			return _body_def
		_:
			return _legs_def

func _refresh() -> void:
	var plan := CompositeResolver.resolve_parts(_head_def, _body_def, _legs_def)
	_place(_legs, _texture_for(PartSlotType.Value.LEGS), plan["legs_pos"])
	_place(_body, _texture_for(PartSlotType.Value.BODY), plan["body_pos"])
	_place(_head, _texture_for(PartSlotType.Value.HEAD), plan["head_pos"])

func _texture_for(slot: PartSlotType.Value) -> Texture2D:
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

func _place(sprite: Sprite2D, texture: Texture2D, pos: Vector2) -> void:
	if texture == null:
		sprite.visible = false
		sprite.texture = null
		return
	sprite.visible = true
	sprite.texture = texture
	sprite.position = pos
	var tex_size := texture.get_size()
	var s := PART_SIZE_PX / maxf(maxf(tex_size.x, tex_size.y), 1.0)
	sprite.scale = Vector2.ONE * s
