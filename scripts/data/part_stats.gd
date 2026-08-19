class_name PartStats
extends RefCounted

## What the number on a kit means, and what it costs in the shop.
##
## Cabeça = Ataque (1 a 10)  quanto a cabeça tira de HP por golpe
## Corpo  = HP     (10 a 20) a vida daquele Freak (o corpo já traz os braços)

const ATTACK_MIN := 1
const ATTACK_MAX := 10
const HP_MIN := 10
const HP_MAX := 20

## A body of 10 HP would cost nothing, so nothing is ever free.
const MIN_PRICE := 1

static func range_of(slot: PartSlotType.Value) -> Vector2i:
	if slot == PartSlotType.Value.BODY:
		return Vector2i(HP_MIN, HP_MAX)
	return Vector2i(ATTACK_MIN, ATTACK_MAX)

static func clamp_for(slot: PartSlotType.Value, value: int) -> int:
	var span := range_of(slot)
	return clampi(value, span.x, span.y)

## Head costs its Attack; a body costs HP above 10.
static func price_for(slot: PartSlotType.Value, value: int) -> int:
	if slot == PartSlotType.Value.BODY:
		return maxi(MIN_PRICE, value - HP_MIN)
	return maxi(MIN_PRICE, value)

static func price_of(part: PartDef) -> int:
	if part == null:
		return 0
	return price_for(part.slot_type, part.stat_value)

## Selling always returns a flat coin, no matter what you paid.
static func sell_price(paid: int) -> int:
	if paid <= 0:
		return 0
	return MatchRules.SELL_REFUND

static func label_of(slot: PartSlotType.Value) -> String:
	if slot == PartSlotType.Value.BODY:
		return "HP"
	return "Ataque"

## Shop tier so the pool can grow with the match. Cheap kits show up first.
static func tier_for(slot: PartSlotType.Value, value: int) -> int:
	var span := range_of(slot)
	var width := maxi(1, span.y - span.x)
	var share := float(clampi(value, span.x, span.y) - span.x) / float(width)
	return clampi(1 + int(floor(share * 4.999)), 1, 5)
