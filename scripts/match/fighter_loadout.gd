class_name FighterLoadout
extends RefCounted

## One card: up to a head, body and legs. Missing parts are allowed.

var head: PartDef
var body: PartDef
var legs: PartDef

static func from_parts(head_part: PartDef, body_part: PartDef, legs_part: PartDef) -> FighterLoadout:
	var loadout := FighterLoadout.new()
	loadout.head = head_part
	loadout.body = body_part
	loadout.legs = legs_part
	return loadout

func is_empty() -> bool:
	return head == null and body == null and legs == null

func parts_array() -> Array:
	return [head, body, legs]

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
	for slot in [PartSlotType.Value.HEAD, PartSlotType.Value.BODY, PartSlotType.Value.LEGS]:
		total += combat_value_of(slot)
	return total

func duplicate_loadout() -> FighterLoadout:
	return from_parts(head, body, legs)
