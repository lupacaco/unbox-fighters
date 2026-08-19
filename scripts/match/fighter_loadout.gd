class_name FighterLoadout
extends RefCounted

## One card: head and body. Missing kits are allowed while building.

var head: PartDef
var body: PartDef

static func from_parts(head_part: PartDef, body_part: PartDef) -> FighterLoadout:
	var loadout := FighterLoadout.new()
	loadout.head = head_part
	loadout.body = body_part
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

## Head and body of the same Freak. That is what turns the unique power on.
func is_complete_set() -> bool:
	if not is_complete() or head == null or body == null:
		return false
	return head.set_id != StringName() and head.set_id == body.set_id

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
		_:
			return null

func set_part(slot: PartSlotType.Value, part: PartDef) -> void:
	match slot:
		PartSlotType.Value.HEAD:
			head = part
		PartSlotType.Value.BODY:
			body = part

## The kit number with the type bonus already in it.
func stat_of(slot: PartSlotType.Value) -> int:
	return Synergy.value_for_part(get_part(slot), parts_array())

func base_stat_of(slot: PartSlotType.Value) -> int:
	var part := get_part(slot)
	return part.stat_value if part != null else 0

func stats() -> FreakStats:
	return FreakStats.from_loadout(self)

## Incomplete mix stays generic. Same Freak on both kits uses that Freak's name.
func crate_title() -> String:
	if is_complete_set():
		var character := ShopPool.character_by_id(head.set_id)
		if character != null:
			var named := character.display_name.strip_edges()
			if not named.is_empty():
				return named.to_upper()
	return "FREAK"

func duplicate_loadout() -> FighterLoadout:
	return from_parts(head, body)
