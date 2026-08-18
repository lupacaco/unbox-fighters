class_name BotBrain
extends RefCounted

## The opponent plays the same game you do: it waits for money, buys kits onto
## its two cards, prefers matching sets for the synergy, and sends a card to the
## belt as soon as all three kits are on it.

## A short pause after each action so the opponent feels like a hand, not a script.
const THINK_TIME := 0.55

var _think: float = 0.0
var cards: Array[FighterLoadout] = []

func _init() -> void:
	reset()

func reset() -> void:
	_think = 0.0
	cards.clear()
	for _i in MatchRules.CARD_COUNT:
		cards.append(FighterLoadout.new())

func tick(delta: float, side: PlayerState, match_ref: LiveMatch) -> void:
	if side == null or match_ref == null or not match_ref.running:
		return
	_think += delta
	if _think < THINK_TIME:
		return
	_think = 0.0
	if _try_launch(side, match_ref):
		return
	if _try_buy(side):
		return
	_try_refresh(side, match_ref)

func _try_launch(side: PlayerState, match_ref: LiveMatch) -> bool:
	if not side.lane.can_accept():
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
