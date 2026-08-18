class_name Synergy
extends RefCounted

## Matching kits on the same card make the Freak stronger.
##
## Two of the same Freak: +25% on those two kits.
## Three of the same Freak: +50% on all three.
## Always rounds up, so a bonus is never worth nothing.

enum Level { NONE, PAIR, TRIPLE }

const PAIR_BONUS := 0.25
const TRIPLE_BONUS := 0.50

static func bonus_for(matching_kits: int) -> float:
	if matching_kits >= 3:
		return TRIPLE_BONUS
	if matching_kits == 2:
		return PAIR_BONUS
	return 0.0

static func level_for(matching_kits: int) -> Level:
	if matching_kits >= 3:
		return Level.TRIPLE
	if matching_kits == 2:
		return Level.PAIR
	return Level.NONE

static func level_name(level: Level) -> String:
	match level:
		Level.TRIPLE:
			return "SINERGIA TRIPLA"
		Level.PAIR:
			return "SINERGIA DUPLA"
		_:
			return ""

static func scaled_value(base: int, matching_kits: int) -> int:
	if base <= 0:
		return 0
	var bonus := bonus_for(matching_kits)
	if is_zero_approx(bonus):
		return base
	return ceili(float(base) * (1.0 + bonus))

static func set_count(parts: Array, set_id: StringName) -> int:
	if set_id == StringName():
		return 0
	var n := 0
	for item in parts:
		var part := item as PartDef
		if part != null and part.set_id == set_id:
			n += 1
	return n

## How many kits on this card share the part's Freak. 1 means no bonus.
static func matching_kits(part: PartDef, card_parts: Array) -> int:
	if part == null:
		return 0
	return set_count(card_parts, part.set_id)

static func value_for_part(part: PartDef, card_parts: Array) -> int:
	if part == null:
		return 0
	return scaled_value(part.stat_value, matching_kits(part, card_parts))

## The strongest synergy on the card, used for the banner and the gold glow.
static func best_level(card_parts: Array) -> Level:
	var best := 0
	for item in card_parts:
		var part := item as PartDef
		if part == null:
			continue
		best = maxi(best, set_count(card_parts, part.set_id))
	return level_for(best)
