class_name BotBrain
extends RefCounted

## The opponent plays with the same hands you do: it waits for money, cracks a
## crate, drags the kit onto a card, and only then presses LUTAR. It cannot
## assemble a Freak in a blink because opening and placing take real time.

## Glance at the shop before the next move.
const LOOK_TIME := 0.85
## Matches the crate cracking on your shelves.
const OPEN_TIME := 0.45
## Time to pick a kit up and drop it on a card.
const PLACE_TIME := 1.2
## Time to notice LUTAR and press it.
const LAUNCH_TIME := 0.9

static func kit_handle_time() -> float:
	return OPEN_TIME + PLACE_TIME

## Fastest a finished Freak can leave a card: look, three kits, then LUTAR.
static func earliest_launch_time() -> float:
	return LOOK_TIME + kit_handle_time() * 3.0 + LAUNCH_TIME

var _wait: float = 0.0
var _launch_armed: bool = false
var cards: Array[FighterLoadout] = []

func _init() -> void:
	reset()

func reset() -> void:
	_wait = LOOK_TIME
	_launch_armed = false
	cards.clear()
	for _i in MatchRules.CARD_COUNT:
		cards.append(FighterLoadout.new())

func tick(delta: float, side: PlayerState, match_ref: LiveMatch) -> void:
	if side == null or match_ref == null or not match_ref.running:
		return
	_wait -= delta
	if _wait > 0.0:
		return
	if _launch_armed:
		_launch_armed = false
		if _try_launch(side, match_ref):
			_wait = LOOK_TIME
			return
	if _can_launch(side):
		_launch_armed = true
		_wait = LAUNCH_TIME
		return
	if _try_buy(side):
		_wait = kit_handle_time()
		return
	if _try_refresh(side, match_ref):
		_wait = LOOK_TIME
		return
	_wait = LOOK_TIME

func _can_launch(side: PlayerState) -> bool:
	if side == null or not side.lane.can_accept():
		return false
	for card in cards:
		if card.is_complete():
			return true
	return false

func _try_launch(side: PlayerState, match_ref: LiveMatch) -> bool:
	if not _can_launch(side):
		return false
	var best := -1
	var best_power := -1
	for i in cards.size():
		var card := cards[i]
		if not card.is_complete():
			continue
		var stats := card.stats()
		var worth := stats.power * 3 + stats.toughness + stats.agility
		if worth > best_power:
			best_power = worth
			best = i
	if best < 0:
		return false
	if match_ref.launch(side, cards[best]) == null:
		return false
	cards[best] = FighterLoadout.new()
	return true

func _try_buy(side: PlayerState) -> bool:
	var best_offer := -1
	var best_card := -1
	var best_score := 0
	for i in side.shop_offers.size():
		var part := side.shop_offers[i]
		if part == null or not side.can_afford(side.price_at(i)):
			continue
		for c in cards.size():
			var score := _score(cards[c], part)
			if score > best_score:
				best_score = score
				best_offer = i
				best_card = c
	if best_offer < 0:
		return false
	var bought := side.buy(best_offer)
	if bought == null:
		return false
	cards[best_card].set_part(bought.slot_type, bought)
	return true

## Rerolls only when the shop has nothing it can use and there is money to spare.
func _try_refresh(side: PlayerState, match_ref: LiveMatch) -> bool:
	if side.money < MatchRules.MAX_MONEY - 1:
		return false
	for i in side.shop_offers.size():
		var part := side.shop_offers[i]
		if part == null:
			continue
		for card in cards:
			if _score(card, part) > 0:
				return false
	return match_ref.refresh_shop(side)

## Higher is better: finishing a set beats a big lone number.
func _score(card: FighterLoadout, part: PartDef) -> int:
	if card == null or part == null:
		return 0
	if card.get_part(part.slot_type) != null:
		return 0
	var matching := 0
	for slot in PartSlotType.shop_slots():
		var owned := card.get_part(slot)
		if owned != null and owned.set_id == part.set_id:
			matching += 1
	var bonus := 0
	if matching >= 2:
		bonus = 40
	elif matching == 1:
		bonus = 18
	return 1 + bonus + part.stat_value
