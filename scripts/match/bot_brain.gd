class_name BotBrain
extends RefCounted

## Instant shop turn. Prefers finishing a set, then filling empty slots,
## then upgrading or refreshing. Freezes when the shelf matches a set on board.

static func take_turn(bot: Contestant, rng: RandomNumberGenerator) -> void:
	if bot == null or not bot.is_alive():
		return
	var refreshes := 0
	while bot.gold > 0:
		if _try_buy_best(bot):
			continue
		var upgrade := MatchRules.upgrade_cost(bot.shop_tier)
		if upgrade > 0 and bot.gold >= upgrade and bot.gold - upgrade <= 1:
			bot.gold -= upgrade
			bot.shop_tier += 1
			continue
		if bot.gold >= MatchRules.REFRESH_COST and refreshes < MatchRules.MAX_BOT_REFRESHES:
			bot.gold -= MatchRules.REFRESH_COST
			bot.frozen = false
			bot.shop_offers = ShopPool.roll(bot.shop_tier, rng)
			refreshes += 1
			continue
		if upgrade > 0 and bot.gold >= upgrade:
			bot.gold -= upgrade
			bot.shop_tier += 1
			continue
		break
	bot.frozen = _should_freeze(bot)


static func _try_buy_best(bot: Contestant) -> bool:
	var best_index := -1
	var best_score := -1
	for i in bot.shop_offers.size():
		var part: PartDef = bot.shop_offers[i]
		if part == null:
			continue
		var score := _score_part(bot, part)
		if score > best_score:
			best_score = score
			best_index = i
	if best_index < 0 or bot.gold < MatchRules.OPEN_CRATE_COST:
		return false
	if best_score < 1:
		return false
	var bought: PartDef = bot.shop_offers[best_index]
	bot.shop_offers[best_index] = null
	bot.gold -= MatchRules.OPEN_CRATE_COST
	_place_part(bot, bought)
	return true


static func _score_part(bot: Contestant, part: PartDef) -> int:
	var complete_score := 0
	var fill_score := 0
	for fighter in bot.board.fighters:
		if fighter.get_part(part.slot_type) != null:
			continue
		fill_score = maxi(fill_score, 2)
		var same := 0
		for existing in fighter.parts_array():
			var owned := existing as PartDef
			if owned != null and owned.set_id == part.set_id:
				same += 1
		if same == 2:
			complete_score = 10
		elif same == 1:
			complete_score = maxi(complete_score, 6)
	if complete_score > 0:
		return complete_score
	return fill_score


static func _place_part(bot: Contestant, part: PartDef) -> void:
	var best: FighterLoadout = null
	var best_same := -1
	for fighter in bot.board.fighters:
		if fighter.get_part(part.slot_type) != null:
			continue
		var same := Synergy.set_count(fighter.parts_array(), part.set_id)
		if same > best_same:
			best_same = same
			best = fighter
	if best != null:
		best.set_part(part.slot_type, part)
		return
	_replace_weakest(bot, part)


static func _replace_weakest(bot: Contestant, part: PartDef) -> void:
	var worst: FighterLoadout = null
	var worst_value := 1_000_000
	for fighter in bot.board.fighters:
		var current := fighter.get_part(part.slot_type)
		if current == null:
			fighter.set_part(part.slot_type, part)
			return
		var value := fighter.combat_value_of(part.slot_type)
		if value < worst_value:
			worst_value = value
			worst = fighter
	if worst != null and part.combat_value > worst.get_part(part.slot_type).combat_value:
		worst.set_part(part.slot_type, part)


static func _should_freeze(bot: Contestant) -> bool:
	var wanted: Dictionary = {}
	for fighter in bot.board.fighters:
		for existing in fighter.parts_array():
			var owned := existing as PartDef
			if owned != null:
				wanted[owned.set_id] = true
	if wanted.is_empty():
		return false
	for offer in bot.shop_offers:
		var part := offer as PartDef
		if part != null and wanted.has(part.set_id):
			return true
	return false
