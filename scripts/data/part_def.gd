@tool
class_name PartDef
extends Resource

@export var id: StringName
@export var display_name: String = ""
@export var slot_type: PartSlotType.Value = PartSlotType.Value.HEAD
@export var set_id: StringName
@export var sprite: Texture2D
## Side view used on the fight stage (pose "-2").
@export var sprite_profile: Texture2D
## Attack pose used when the part flies forward (pose "-3").
@export var sprite_attack: Texture2D
@export var combat_value: int = 0
@export var tier: int = 1

## Magnet points in texture pixels, from the sprite CENTER.
## Y negative = up on the image. Y positive = down on the image.
## Head: only magnet_down. Legs: only magnet_up. Body: both + weapon.
@export var magnet_up: Vector2 = Vector2.ZERO
@export var magnet_down: Vector2 = Vector2.ZERO
## Where a future weapon sits on the body (hand). Unused on head and legs.
@export var magnet_weapon: Vector2 = Vector2.ZERO
@export var magnet_up_profile: Vector2 = Vector2.ZERO
@export var magnet_down_profile: Vector2 = Vector2.ZERO
@export var magnet_weapon_profile: Vector2 = Vector2.ZERO
@export var magnet_up_attack: Vector2 = Vector2.ZERO
@export var magnet_down_attack: Vector2 = Vector2.ZERO
@export var magnet_weapon_attack: Vector2 = Vector2.ZERO

static func tier_for(value: int) -> int:
	if value <= 5:
		return 1
	if value == 6:
		return 2
	if value == 7:
		return 3
	if value == 8:
		return 4
	return 5

func uses_magnet_up() -> bool:
	return slot_type != PartSlotType.Value.HEAD

func uses_magnet_down() -> bool:
	return slot_type != PartSlotType.Value.LEGS

func uses_weapon_magnet() -> bool:
	return slot_type == PartSlotType.Value.BODY

func has_fight_poses() -> bool:
	return sprite_profile != null and sprite_attack != null

func profile_magnets_marked() -> bool:
	return magnet_up_profile.length_squared() > 0.01 or magnet_down_profile.length_squared() > 0.01

func attack_magnets_marked() -> bool:
	return magnet_up_attack.length_squared() > 0.01 or magnet_down_attack.length_squared() > 0.01

func weapon_profile_marked() -> bool:
	return magnet_weapon_profile.length_squared() > 0.01

func weapon_attack_marked() -> bool:
	return magnet_weapon_attack.length_squared() > 0.01

func magnet_up_for(shown: Texture2D) -> Vector2:
	if uses_magnet_up() and shown != null:
		if shown == sprite_attack and attack_magnets_marked():
			return magnet_up_attack
		if shown == sprite_profile and profile_magnets_marked():
			return magnet_up_profile
	return magnet_up

func magnet_down_for(shown: Texture2D) -> Vector2:
	if uses_magnet_down() and shown != null:
		if shown == sprite_attack and attack_magnets_marked():
			return magnet_down_attack
		if shown == sprite_profile and profile_magnets_marked():
			return magnet_down_profile
	return magnet_down

func magnet_weapon_for(shown: Texture2D) -> Vector2:
	if uses_weapon_magnet() and shown != null:
		if shown == sprite_attack and weapon_attack_marked():
			return magnet_weapon_attack
		if shown == sprite_profile and weapon_profile_marked():
			return magnet_weapon_profile
	return magnet_weapon

func texture_for_pose(pose: int) -> Texture2D:
	if pose == 1:
		return sprite_profile
	if pose == 2:
		return sprite_attack
	return sprite

func _validate_property(property: Dictionary) -> void:
	match String(property.name):
		"magnet_up":
			if slot_type == PartSlotType.Value.HEAD:
				property.usage = PROPERTY_USAGE_NO_EDITOR
		"magnet_down":
			if slot_type == PartSlotType.Value.LEGS:
				property.usage = PROPERTY_USAGE_NO_EDITOR
		"magnet_weapon":
			if slot_type != PartSlotType.Value.BODY:
				property.usage = PROPERTY_USAGE_NO_EDITOR
		"magnet_up_profile", "magnet_down_profile", "magnet_weapon_profile", "magnet_up_attack", "magnet_down_attack", "magnet_weapon_attack":
			property.usage = PROPERTY_USAGE_NO_EDITOR
