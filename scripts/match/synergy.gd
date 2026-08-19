class_name Synergy
extends RefCounted

## Two kits of the same family (Humano, Sobrenatural or Animal) raise both
## numbers by half, rounded up. The Freak's unique power is separate: it only
## turns on when head and body belong to the same character.

enum Level { NONE, KIND }

const KIND_BONUS := 0.50

static func kinds_match(parts: Array) -> bool:
	var kinds: Array[FreakKind.Value] = []
	for item in parts:
		var part := item as PartDef
		if part == null:
			continue
		kinds.append(kind_of(part))
	if kinds.size() < 2:
		return false
	return kinds[0] == kinds[1]

static func kind_of(part: PartDef) -> FreakKind.Value:
	if part == null:
		return FreakKind.Value.HUMAN
	var character := ShopPool.character_by_id(part.set_id)
	if character == null:
		return FreakKind.Value.HUMAN
	return character.kind

static func bonus_for(parts: Array) -> float:
	return KIND_BONUS if kinds_match(parts) else 0.0

static func level_for(parts: Array) -> Level:
	return Level.KIND if kinds_match(parts) else Level.NONE

static func level_name(level: Level, kind: FreakKind.Value = FreakKind.Value.HUMAN) -> String:
	if level == Level.KIND:
		return "+50%% %s" % FreakKind.label(kind).to_upper()
	return ""

static func scaled_value(base: int, boosted: bool) -> int:
	if base <= 0:
		return 0
	if not boosted:
		return base
	return ceili(float(base) * (1.0 + KIND_BONUS))

static func value_for_part(part: PartDef, card_parts: Array) -> int:
	if part == null:
		return 0
	return scaled_value(part.stat_value, kinds_match(card_parts))

static func best_level(card_parts: Array) -> Level:
	return level_for(card_parts)
