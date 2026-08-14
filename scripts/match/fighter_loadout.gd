class_name FighterLoadout
extends RefCounted

## One card: head + torso kits on a spring base. Missing kits are allowed.

var head: PartDef
var body: PartDef
var legs: PartDef

static func from_parts(head_part: PartDef, body_part: PartDef, legs_part: PartDef) -> FighterLoadout:
	var loadout := FighterLoadout.new()
	loadout.head = head_part
	loadout.body = body_part
	loadout.legs = legs_part
	return loadout

static func from_character(character: CharacterDef) -> FighterLoadout:
	if character == null:
		return FighterLoadout.new()
	return from_parts(character.head, character.body, character.legs)

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
		PartSlotType.Value.LEGS:
			return legs
		_:
			return null

func set_part(slot: PartSlotType.Value, part: PartDef) -> void:
	match slot:
		PartSlotType.Value.HEAD:
			head = part
		PartSlotType.Value.BODY:
			body = part
		PartSlotType.Value.LEGS:
			legs = part

func combat_value_of(slot: PartSlotType.Value) -> int:
	return Synergy.value_for_part(get_part(slot), parts_array())

func total_power() -> int:
	var total := 0
	for slot in PartSlotType.shop_slots():
		total += combat_value_of(slot)
	return total

func duplicate_loadout() -> FighterLoadout:
	return from_parts(head, body, legs)
