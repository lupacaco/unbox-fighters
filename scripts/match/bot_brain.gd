class_name BotBrain
extends RefCounted

## Instant shop turn, matching Unity scoring: finish a set, then fill, then
## replace only if the card gets stronger. Levels up slowly and refills the shop.

const TURN_GUARD := 48

static func take_turn(bot: Contestant, rng: RandomNumberGenerator) -> void:
	if bot == null or not bot.is_alive():
		return
	var guard := TURN_GUARD
	while bot.gold > 0 and guard > 0:
		guard -= 1
		if _try_buy_best(bot):
			continue
		var upgrade := MatchRules.upgrade_cost(bot.shop_tier)
		var want_level := (
			bot.shop_tier < MatchRules.SHOP_MAX_TIER
			and upgrade > 0
			and bot.gold >= upgrade + 1
			and bot.shop_tier < 2 + (1 if bot.gold >= 6 else 0)
		)
		if want_level and bot.gold >= upgrade:
			bot.gold -= upgrade
			bot.shop_tier += 1
			bot.frozen = false
			bot.shop_offers = ShopPool.roll(bot.shop_tier, rng)
			continue
		if bot.gold >= MatchRules.REFRESH_COST:
			bot.gold -= MatchRules.REFRESH_COST
			bot.frozen = false
			bot.shop_offers = ShopPool.roll(bot.shop_tier, rng)
			continue
		break
	bot.frozen = _shop_helps_board(bot)


static func _try_buy_best(bot: Contestant) -> bool:
	var best_index := _best_buy_index(bot)
	if best_index < 0 or bot.gold < MatchRules.OPEN_CRATE_COST:
		return false
	var part: PartDef = bot.shop_offers[best_index]
	var card_index := _best_card_for(bot.board, part)
	if card_index < 0:
		return false
	bot.shop_offers[best_index] = null
	bot.gold -= MatchRules.OPEN_CRATE_COST
	bot.board.fighters[card_index].set_part(part.slot_type, part)
	return true


static func _best_buy_index(bot: Contestant) -> int:
	var best := -1
	var best_score := 0
	for i in bot.shop_offers.size():
		var part: PartDef = bot.shop_offers[i]
		if part == null:
			continue
		var card := _best_card_for(bot.board, part)
		if card < 0:
			continue
		var score := _score_placement(bot.board.fighters[card], part)
		if score > best_score:
			best_score = score
			best = i
	return best


static func _best_card_for(board: BoardLoadout, part: PartDef) -> int:
	if board == null or part == null:
		return -1
	var best := -1
	var best_score := -1
	for i in board.fighters.size():
		var card: FighterLoadout = board.fighters[i]
		var current := card.get_part(part.slot_type)
		if current != null and current.set_id == part.set_id:
			continue
		var score := _score_placement(card, part)
		if current != null:
			var old_power := card.total_power()
			var trial := card.duplicate_loadout()
			trial.set_part(part.slot_type, part)
			var next_power := trial.total_power()
			if next_power <= old_power:
				continue
			score = next_power
		elif score < 1:
			score = 1
		if score > best_score:
			best_score = score
			best = i
	return best


static func _score_placement(card: FighterLoadout, part: PartDef) -> int:
	if card == null or part == null:
		return 0
	var same := 0
	for slot in PartSlotType.all_slots():
		var owned := card.get_part(slot)
		if owned != null and owned.set_id == part.set_id:
			same += 1
	if card.get_part(part.slot_type) != null:
		same -= 1
	if same >= 3:
		return 30 + part.combat_value
	if same >= 1:
		return 12 + part.combat_value
	if card.is_empty():
		return 3 + part.combat_value
	return part.combat_value


static func _shop_helps_board(bot: Contestant) -> bool:
	for offer in bot.shop_offers:
		var part := offer as PartDef
		if part == null:
			continue
		for card in bot.board.fighters:
			if card.get_part(part.slot_type) != null:
				continue
			var helps := false
			for slot in PartSlotType.all_slots():
				var owned := card.get_part(slot)
				if owned != null and owned.set_id == part.set_id:
					helps = true
					break
			if helps:
				return true
	return false
