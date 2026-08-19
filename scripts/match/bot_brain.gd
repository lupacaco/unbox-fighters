class_name BotBrain
extends RefCounted

## The opponent shops with the same clock you do. It looks, buys a kit, and
## drops it on a card. It never sends anyone to the belt — that happens when
## preparation ends, for both sides at once.

## Glance at the shop before the next move.
const LOOK_TIME := 0.85
## Time to pick a kit up and drop it on a card.
const PLACE_TIME := 1.2

var _wait: float = 0.0

func reset() -> void:
	_wait = LOOK_TIME

func tick(delta: float, side: PlayerState, match_ref: LiveMatch) -> void:
	if side == null or match_ref == null or not match_ref.is_prep():
		return
	_wait -= delta
	if _wait > 0.0:
		return
	if _try_buy(side):
		_wait = PLACE_TIME
		return
	if _try_refresh(side, match_ref):
		_wait = LOOK_TIME
		return
	_wait = LOOK_TIME

func _try_buy(side: PlayerState) -> bool:
	var best_offer := -1
	var best_card := -1
	var best_score := 0
	for i in side.shop_offers.size():
		var part := side.shop_offers[i]
		if part == null or (i < side.shop_owned.size() and side.shop_owned[i]):
			continue
		var price := side.price_at(i)
		if not side.can_afford(price):
			continue
		for c in side.cards.size():
			if not _can_finish_after(side, side.cards[c], part, price, i):
				continue
			var score := _score(side.cards[c], part)
			if score > best_score:
				best_score = score
				best_offer = i
				best_card = c
	if best_offer < 0:
		return false
	var bought := side.buy(best_offer)
	if bought == null:
		return false
	side.cards[best_card].set_part(bought.slot_type, bought)
	return true

## Pays to reroll only when leftover coins can still buy a full Freak.
func _try_refresh(side: PlayerState, match_ref: LiveMatch) -> bool:
	if not side.can_afford(MatchRules.REFRESH_COST):
		return false
	if side.money - MatchRules.REFRESH_COST < _cheapest_pair_cost():
		return false
	return match_ref.refresh_shop(side, side.owned_keep())

## True when this buy either closes the card, or leaves enough for a mate on a shelf.
func _can_finish_after(
	side: PlayerState,
	card: FighterLoadout,
	part: PartDef,
	price: int,
	offer_index: int
) -> bool:
	if side == null or card == null or part == null:
		return false
	if card.get_part(part.slot_type) != null:
		return false
	var leftover := side.money - price
	if leftover < 0:
		return false
	var mate := _mate_slot(part.slot_type)
	if card.get_part(mate) != null:
		return true
	for i in side.shop_offers.size():
		if i == offer_index:
			continue
		var other: PartDef = side.shop_offers[i]
		if other == null or other.slot_type != mate:
			continue
		if side.price_at(i) <= leftover:
			return true
	return false

func _mate_slot(slot: PartSlotType.Value) -> PartSlotType.Value:
	if slot == PartSlotType.Value.HEAD:
		return PartSlotType.Value.BODY
	return PartSlotType.Value.HEAD

func _cheapest_pair_cost() -> int:
	var min_head := 99
	var min_body := 99
	for part in ShopPool.all_parts():
		if part == null:
			continue
		var price := PartStats.price_of(part)
		if part.slot_type == PartSlotType.Value.HEAD:
			min_head = mini(min_head, price)
		elif part.slot_type == PartSlotType.Value.BODY:
			min_body = mini(min_body, price)
	return maxi(2, min_head + min_body)

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
