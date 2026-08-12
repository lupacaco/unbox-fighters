class_name FighterPuppet
extends Node2D

## Temporary on-stage fighter used by the fight animation (not a card).

enum Pose { FRONT, PROFILE }

const PART_SIZE_PX := 170.0

var _character: CharacterDef
var _pose: Pose = Pose.FRONT
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

func setup(character: CharacterDef) -> void:
	_character = character
	_pose = Pose.FRONT
	_attack_slot = null
	_refresh()

func set_pose(pose: Pose) -> void:
	_pose = pose
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

func _refresh() -> void:
	if _character == null:
		return
	var plan := CompositeResolver.resolve(_character, true, true, true)
	_place(_legs, _texture_for(PartSlotType.Value.LEGS), plan["legs_pos"])
	_place(_body, _texture_for(PartSlotType.Value.BODY), plan["body_pos"])
	_place(_head, _texture_for(PartSlotType.Value.HEAD), plan["head_pos"])

func _texture_for(slot: PartSlotType.Value) -> Texture2D:
	var part := _character.get_part(slot)
	if part == null:
		return null
	if _attack_slot != null and int(_attack_slot) == int(slot) and part.sprite_attack != null:
		return part.sprite_attack
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
