class_name FighterLoadout
extends RefCounted

## One card: up to six parts. Missing parts are allowed.

var head: PartDef
var body: PartDef
var arm_l: PartDef
var arm_r: PartDef
var leg_l: PartDef
var leg_r: PartDef

static func from_parts(
	head_part: PartDef,
	body_part: PartDef,
	legs_part: PartDef,
	arm_l_part: PartDef = null,
	arm_r_part: PartDef = null,
	leg_l_part: PartDef = null,
	leg_r_part: PartDef = null
) -> FighterLoadout:
	var loadout := FighterLoadout.new()
	loadout.head = head_part
	loadout.body = body_part
	loadout.arm_l = arm_l_part
	loadout.arm_r = arm_r_part
	loadout.leg_l = leg_l_part if leg_l_part != null else legs_part
	loadout.leg_r = leg_r_part
	return loadout

static func from_character(character: CharacterDef) -> FighterLoadout:
	if character == null:
		return FighterLoadout.new()
	var loadout := FighterLoadout.new()
	for slot in PartSlotType.all_slots():
		loadout.set_part(slot, character.get_part(slot))
	return loadout

func is_empty() -> bool:
	for slot in PartSlotType.all_slots():
		if get_part(slot) != null:
			return false
	return true

func parts_array() -> Array:
	var list: Array = []
	for slot in PartSlotType.all_slots():
		list.append(get_part(slot))
	return list

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
			return leg_l
		PartSlotType.Value.LEG_R:
			return leg_r
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
		PartSlotType.Value.LEG_L:
			leg_l = part
		PartSlotType.Value.LEG_R:
			leg_r = part

func combat_value_of(slot: PartSlotType.Value) -> int:
	return Synergy.value_for_part(get_part(slot), parts_array())

func total_power() -> int:
	var total := 0
	for slot in PartSlotType.all_slots():
		total += combat_value_of(slot)
	return total

func duplicate_loadout() -> FighterLoadout:
	return from_parts(head, body, null, arm_l, arm_r, leg_l, leg_r)
