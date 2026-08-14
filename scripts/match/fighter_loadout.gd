class_name FighterLoadout
extends RefCounted

## One card: head, torso, and both arms on a spring base. Missing kits are allowed.

var head: PartDef
var body: PartDef
var arm_l: PartDef
var arm_r: PartDef

static func from_parts(
	head_part: PartDef,
	body_part: PartDef,
	arm_l_part: PartDef = null,
	arm_r_part: PartDef = null
) -> FighterLoadout:
	var loadout := FighterLoadout.new()
	loadout.head = head_part
	loadout.body = body_part
	loadout.arm_l = arm_l_part
	loadout.arm_r = arm_r_part
	return loadout

static func from_character(character: CharacterDef) -> FighterLoadout:
	var loadout := FighterLoadout.new()
	if character == null:
		return loadout
	for slot in PartSlotType.shop_slots():
		loadout.set_part(slot, character.get_part(slot))
	return loadout

func is_empty() -> bool:
	for slot in PartSlotType.shop_slots():
		if get_part(slot) != null:
			return false
	return true

func parts_array() -> Array:
	var list: Array = []
	for slot in PartSlotType.shop_slots():
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

func combat_value_of(slot: PartSlotType.Value) -> int:
	return Synergy.value_for_part(get_part(slot), parts_array())

func total_power() -> int:
	var total := 0
	for slot in PartSlotType.shop_slots():
		total += combat_value_of(slot)
	return total

func duplicate_loadout() -> FighterLoadout:
	return from_parts(head, body, arm_l, arm_r)
