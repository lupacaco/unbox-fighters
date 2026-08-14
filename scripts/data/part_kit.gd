class_name PartKit
extends RefCounted

## Turns a shop kit (head / torso) into the drawings used on screen.
## Legs stay in the files for the magnet editor; the game draws a spring instead.

static func character_for(part: PartDef) -> CharacterDef:
	if part == null:
		return null
	for character in ShopPool.roster():
		if character != null and character.id == part.set_id:
			return character
	return null

static func expand_shop_part(part: PartDef) -> Dictionary:
	var visual := {}
	if part == null:
		return visual
	match part.slot_type:
		PartSlotType.Value.HEAD:
			visual[PartSlotType.Value.HEAD] = part
		PartSlotType.Value.BODY:
			visual[PartSlotType.Value.BODY] = part
			var character := character_for(part)
			if character != null:
				if character.arm_l != null:
					visual[PartSlotType.Value.ARM_L] = character.arm_l
				if character.arm_r != null:
					visual[PartSlotType.Value.ARM_R] = character.arm_r
		PartSlotType.Value.LEGS:
			var character := character_for(part)
			if character != null and (character.leg_l != null or character.leg_r != null):
				if character.leg_l != null:
					visual[PartSlotType.Value.LEG_L] = character.leg_l
				if character.leg_r != null:
					visual[PartSlotType.Value.LEG_R] = character.leg_r
			else:
				visual[PartSlotType.Value.LEG_L] = part
		_:
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
