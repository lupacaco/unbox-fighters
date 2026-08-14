class_name PartKit
extends RefCounted

## Turns a shop kit into the drawing used on screen.
## Legs stay in the files for the magnet editor; the game draws a spring instead.

static func expand_shop_part(part: PartDef) -> Dictionary:
	var visual := {}
	if part == null:
		return visual
	if PartSlotType.is_shop_slot(part.slot_type):
		visual[part.slot_type] = part
	return visual

static func expand_shop_parts(shop_parts: Dictionary) -> Dictionary:
	var visual := {}
	for slot in shop_parts.keys():
		var expanded := expand_shop_part(shop_parts[slot] as PartDef)
		for visual_slot in expanded.keys():
			visual[visual_slot] = expanded[visual_slot]
	return visual

static func expand_loadout(loadout: FighterLoadout) -> Dictionary:
	if loadout == null:
		return {}
	var shop := {}
	for slot in PartSlotType.shop_slots():
		shop[slot] = loadout.get_part(slot)
	return expand_shop_parts(shop)
