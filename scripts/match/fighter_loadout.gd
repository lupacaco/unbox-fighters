class_name FighterLoadout
extends RefCounted

## One card: head, torso and the arm kit. Missing kits are allowed while building.

var head: PartDef
var body: PartDef
var arms: PartDef

static func from_parts(head_part: PartDef, body_part: PartDef, arms_part: PartDef = null) -> FighterLoadout:
	var loadout := FighterLoadout.new()
	loadout.head = head_part
	loadout.body = body_part
	loadout.arms = arms_part
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

func is_complete() -> bool:
	for slot in PartSlotType.shop_slots():
		if get_part(slot) == null:
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
		PartSlotType.Value.ARMS:
			arms = part

## The kit number with the synergy bonus already in it.
func stat_of(slot: PartSlotType.Value) -> int:
	return Synergy.value_for_part(get_part(slot), parts_array())

func base_stat_of(slot: PartSlotType.Value) -> int:
	var part := get_part(slot)
	return part.stat_value if part != null else 0

func stats() -> FreakStats:
	return FreakStats.from_loadout(self)

func duplicate_loadout() -> FighterLoadout:
	return from_parts(head, body, arms)
