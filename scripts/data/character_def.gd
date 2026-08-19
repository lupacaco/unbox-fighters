@tool
class_name CharacterDef
extends Resource

## @tool lets the magnet editor (Project → Tools) read these drawings.
## The shop sells head and body; the body draws as the torso plus both arms.
## The wooden crate is a shared base on the card, not a kit.

@export var id: StringName
@export var display_name: String = "???"
@export var kind: FreakKind.Value = FreakKind.Value.HUMAN
@export var ability: FreakAbility.Value = FreakAbility.Value.NONE
@export var head: PartDef
@export var body: PartDef
@export var arm_l: PartDef
@export var arm_r: PartDef
## Leftover grouping of the two arm drawings. Not sold in the shop.
@export var arms: PartDef

func get_part(slot: PartSlotType.Value) -> PartDef:
	match slot:
		PartSlotType.Value.HEAD:
			return head
		PartSlotType.Value.BODY:
			return body
		PartSlotType.Value.ARM_L:
			return arm_l
		PartSlotType.Value.ARM_R:
			return arm_r
		PartSlotType.Value.ARMS:
			return arms
		_:
			return null

func set_part(slot: PartSlotType.Value, part: PartDef) -> void:
	match slot:
		PartSlotType.Value.HEAD:
			head = part
		PartSlotType.Value.BODY:
			body = part
		PartSlotType.Value.ARM_L:
			arm_l = part
		PartSlotType.Value.ARM_R:
			arm_r = part
		PartSlotType.Value.ARMS:
			arms = part

func shop_parts() -> Array[PartDef]:
	var list: Array[PartDef] = []
	for slot in PartSlotType.shop_slots():
		var part := get_part(slot)
		if part != null:
			list.append(part)
	return list

func visual_parts() -> Array[PartDef]:
	var list: Array[PartDef] = []
	for slot in PartSlotType.visual_slots():
		var part := get_part(slot)
		if part != null and part not in list:
			list.append(part)
	return list

func all_parts() -> Array[PartDef]:
	return shop_parts()

func can_fight() -> bool:
	for slot in PartSlotType.shop_slots():
		if get_part(slot) == null:
			return false
	for part in visual_parts():
		if part.sprite_profile == null:
			return false
	return true
