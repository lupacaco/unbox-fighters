class_name CharacterDef
extends Resource

@export var id: StringName
@export var display_name: String = "???"
@export var head: PartDef
@export var body: PartDef
@export var arm_l: PartDef
@export var arm_r: PartDef
@export var leg_l: PartDef
@export var leg_r: PartDef
## Old 3-part sets used a single legs piece. Kept so those files still load.
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
		_:
			return null

func all_parts() -> Array[PartDef]:
	var list: Array[PartDef] = []
	for slot in PartSlotType.all_slots():
		list.append(get_part(slot))
	return list

func can_fight() -> bool:
	for slot in PartSlotType.all_slots():
		var part := get_part(slot)
		if part == null or not part.has_fight_poses():
			return false
	return true
