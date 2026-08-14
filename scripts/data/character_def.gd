@tool
class_name CharacterDef
extends Resource

## @tool lets the magnet editor (Project → Tools) read these six drawings.

@export var id: StringName
@export var display_name: String = "???"
@export var head: PartDef
@export var body: PartDef
@export var arm_l: PartDef
@export var arm_r: PartDef
@export var leg_l: PartDef
@export var leg_r: PartDef
## Shop kit: both legs together. Old 3-part sets used this as the only legs drawing.
@export var legs: PartDef

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
		PartSlotType.Value.LEG_L:
			return leg_l if leg_l != null else legs
		PartSlotType.Value.LEG_R:
			return leg_r if leg_r != null else legs
		PartSlotType.Value.LEGS:
			return legs
		_:
			return null

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
	for slot in PartSlotType.visual_slots():
		var part := get_part(slot)
		if part == null:
			continue
		if part.sprite_profile == null:
			return false
	return true
