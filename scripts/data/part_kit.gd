class_name PartKit
extends RefCounted

## Turns a shop kit into the drawings that go on screen.
## The body kit is one box in the shop but the torso plus both arms on the Freak.

static func expand_shop_part(part: PartDef) -> Dictionary:
	var visual := {}
	if part == null:
		return visual
	if part.slot_type == PartSlotType.Value.BODY:
		visual[PartSlotType.Value.BODY] = part
		var character := ShopPool.character_by_id(part.set_id)
		if character != null:
			if character.arm_l != null:
				visual[PartSlotType.Value.ARM_L] = character.arm_l
			if character.arm_r != null:
				visual[PartSlotType.Value.ARM_R] = character.arm_r
		return visual
	if part.is_bundle():
		for piece in part.kit_parts:
			if piece != null:
				visual[piece.slot_type] = piece
		return visual
	if PartSlotType.is_shop_slot(part.slot_type) or PartSlotType.is_arm(part.slot_type):
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
