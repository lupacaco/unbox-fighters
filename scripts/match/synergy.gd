class_name Synergy
extends RefCounted

## Combat value on a card: 2 matching kits = full, 1 = 50%.
## Always rounds up. The spring base has no number. Arms count as their own kits.

static func scaled_value(base: int, same_set_count: int) -> int:
	if base <= 0 or same_set_count <= 0:
		return 0
	if same_set_count >= 2:
		return base
	return ceili(float(base) * 0.5)

static func set_count(parts: Array, set_id: StringName) -> int:
	if set_id == StringName():
		return 0
	var n := 0
	for item in parts:
		var part := item as PartDef
		if part != null and part.set_id == set_id:
			n += 1
	return n

static func value_for_part(part: PartDef, card_parts: Array) -> int:
	if part == null:
		return 0
	return scaled_value(part.combat_value, set_count(card_parts, part.set_id))
