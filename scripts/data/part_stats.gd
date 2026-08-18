class_name PartStats
extends RefCounted

## What the number on a kit means, and what it costs in the shop.
##
## Cabeça  = Poder       (1 a 10)  quanto tira de vida por golpe
## Tronco  = Resistência (10 a 20) a vida daquele Freak
## Braços  = Agilidade   (1 a 5)   velocidade dele na esteira

const POWER_MIN := 1
const POWER_MAX := 10
const TOUGHNESS_MIN := 10
const TOUGHNESS_MAX := 20
const AGILITY_MIN := 1
const AGILITY_MAX := 5

## A torso of 10 toughness would cost nothing, so nothing is ever free.
const MIN_PRICE := 1

static func range_of(slot: PartSlotType.Value) -> Vector2i:
	match slot:
		PartSlotType.Value.BODY:
			return Vector2i(TOUGHNESS_MIN, TOUGHNESS_MAX)
		PartSlotType.Value.ARMS, PartSlotType.Value.ARM_L, PartSlotType.Value.ARM_R:
			return Vector2i(AGILITY_MIN, AGILITY_MAX)
		_:
			return Vector2i(POWER_MIN, POWER_MAX)

static func clamp_for(slot: PartSlotType.Value, value: int) -> int:
	var span := range_of(slot)
	return clampi(value, span.x, span.y)

## Head costs its Power, arms cost their Agility, a torso costs Toughness above 10.
static func price_for(slot: PartSlotType.Value, value: int) -> int:
	if slot == PartSlotType.Value.BODY:
		return maxi(MIN_PRICE, value - TOUGHNESS_MIN)
	return maxi(MIN_PRICE, value)

static func price_of(part: PartDef) -> int:
	if part == null:
		return 0
	return price_for(part.slot_type, part.stat_value)

## Selling gives back half of what you paid, rounded up.
static func sell_price(paid: int) -> int:
	if paid <= 0:
		return 0
	return int(ceil(float(paid) / 2.0))

static func label_of(slot: PartSlotType.Value) -> String:
	match slot:
		PartSlotType.Value.BODY:
			return "Resistência"
		PartSlotType.Value.ARMS, PartSlotType.Value.ARM_L, PartSlotType.Value.ARM_R:
			return "Agilidade"
		_:
			return "Poder"

## Shop tier so the pool can grow with the match. Cheap kits show up first.
static func tier_for(slot: PartSlotType.Value, value: int) -> int:
	var span := range_of(slot)
	var width := maxi(1, span.y - span.x)
	var share := float(clampi(value, span.x, span.y) - span.x) / float(width)
	return clampi(1 + int(floor(share * 4.999)), 1, 5)
