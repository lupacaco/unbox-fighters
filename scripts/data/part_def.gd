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
## Head: only magnet_down. Legs: only magnet_up. Body: both.
@export var magnet_up: Vector2 = Vector2.ZERO
@export var magnet_down: Vector2 = Vector2.ZERO

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

func has_fight_poses() -> bool:
	return sprite_profile != null and sprite_attack != null

func _validate_property(property: Dictionary) -> void:
	match String(property.name):
		"magnet_up":
			if slot_type == PartSlotType.Value.HEAD:
				property.usage = PROPERTY_USAGE_NO_EDITOR
		"magnet_down":
			if slot_type == PartSlotType.Value.LEGS:
				property.usage = PROPERTY_USAGE_NO_EDITOR
