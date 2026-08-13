class_name MatchState
extends RefCounted

enum Phase { PREP, FIGHT, GAME_OVER }

var round_index: int = 0
var phase: Phase = Phase.PREP
var contestants: Array[Contestant] = []
var pairings: Array[FightPair] = []
var rng := RandomNumberGenerator.new()
var prep_time_left: float = MatchRules.PREP_SECONDS
var winner_id: StringName = &""

func _init() -> void:
	rng.randomize()

func human() -> Contestant:
	return contestants[0] if not contestants.is_empty() else null

func start_match() -> void:
	contestants.clear()
	var player := Contestant.new()
	player.id = &"player"
	player.display_name = "Você"
	player.is_bot = false
	player.reset_shop_slots()
	contestants.append(player)
	for i in MatchRules.BOT_COUNT:
		var bot := Contestant.new()
		bot.id = StringName("bot_%d" % i)
		bot.display_name = MatchRules.BOT_NAMES[i]
		bot.is_bot = true
		bot.reset_shop_slots()
		contestants.append(bot)
	round_index = 0
	winner_id = &""
	begin_prep()

func begin_prep() -> void:
	round_index += 1
	phase = Phase.PREP
	prep_time_left = MatchRules.PREP_SECONDS
	var gold := MatchRules.gold_for_round(round_index)
	for contestant in contestants:
		if not contestant.is_alive():
			continue
		contestant.gold = gold
		if contestant.frozen:
			_fill_empty_shop_slots(contestant)
		else:
			contestant.shop_offers = ShopPool.roll(contestant.shop_tier, rng)
	_pair_round()
	for contestant in contestants:
		if contestant.is_bot and contestant.is_alive():
			BotBrain.take_turn(contestant, rng)

func tick_prep(delta: float) -> bool:
	if phase != Phase.PREP:
		return false
	prep_time_left = maxf(0.0, prep_time_left - delta)
	return prep_time_left <= 0.0

func ready_up() -> void:
	prep_time_left = 0.0

func try_spend(contestant: Contestant, amount: int) -> bool:
	if contestant == null or amount <= 0 or contestant.gold < amount:
		return false
	contestant.gold -= amount
	return true

func refresh_shop(contestant: Contestant) -> bool:
	if not try_spend(contestant, MatchRules.REFRESH_COST):
		return false
	contestant.frozen = false
	contestant.shop_offers = ShopPool.roll(contestant.shop_tier, rng)
	return true

func toggle_freeze(contestant: Contestant) -> void:
	if contestant == null:
		return
	contestant.frozen = not contestant.frozen

func upgrade_shop(contestant: Contestant) -> bool:
	var cost := MatchRules.upgrade_cost(contestant.shop_tier)
	if cost < 0:
		return false
	if not try_spend(contestant, cost):
		return false
	contestant.shop_tier += 1
	return true

func take_shop_part(contestant: Contestant, slot_index: int) -> PartDef:
	if contestant == null or slot_index < 0 or slot_index >= contestant.shop_offers.size():
		return null
	if not try_spend(contestant, MatchRules.OPEN_CRATE_COST):
		return null
	var part: PartDef = contestant.shop_offers[slot_index]
	contestant.shop_offers[slot_index] = null
	return part

func grant_sell(contestant: Contestant) -> void:
	if contestant == null:
		return
	contestant.gold += MatchRules.SELL_REWARD

func opponent_of(contestant: Contestant) -> Contestant:
	for pair in pairings:
		if pair.left == contestant:
			return pair.right
		if pair.right == contestant and not pair.right_is_ghost:
			return pair.left
	return null

func field_line() -> String:
	var parts: PackedStringArray = []
	for contestant in contestants:
		parts.append("%s %d" % [contestant.display_name, contestant.hp])
	parts.append("r%d" % round_index)
	return "     ".join(parts)

func alive_count() -> int:
	var n := 0
	for contestant in contestants:
		if contestant.is_alive():
			n += 1
	return n

func apply_result(left: Contestant, right: Contestant, result: CombatResult, right_is_ghost: bool = false) -> void:
	if result == null:
		return
	if left != null:
		left.hp = maxi(0, left.hp - result.damage_to_left)
		if right != null and not right_is_ghost:
			left.last_opponent_id = right.id
	if right != null and not right_is_ghost:
		right.hp = maxi(0, right.hp - result.damage_to_right)
		if left != null:
			right.last_opponent_id = left.id

func finish_round() -> void:
	if alive_count() <= 1:
		phase = Phase.GAME_OVER
		for contestant in contestants:
			if contestant.is_alive():
				winner_id = contestant.id
				return
		winner_id = &""
		return
	begin_prep()

func _fill_empty_shop_slots(contestant: Contestant) -> void:
	var pool := ShopPool.parts_up_to_tier(contestant.shop_tier)
	if pool.is_empty():
		return
	if contestant.shop_offers.size() < MatchRules.SHOP_SLOTS:
		contestant.reset_shop_slots()
	for i in contestant.shop_offers.size():
		if contestant.shop_offers[i] == null:
			contestant.shop_offers[i] = pool[rng.randi_range(0, pool.size() - 1)]

func _pair_round() -> void:
	pairings.clear()
	var alive: Array[Contestant] = []
	for contestant in contestants:
		if contestant.is_alive():
			alive.append(contestant)
	if alive.size() <= 1:
		return
	var player := human()
	if player != null and player.is_alive():
		var bots: Array[Contestant] = []
		for contestant in alive:
			if contestant != player:
				bots.append(contestant)
		var opponent := _pick_opponent(player, bots)
		if opponent != null:
			pairings.append(FightPair.new(player, opponent, false))
		var leftover: Array[Contestant] = []
		for bot in bots:
			if bot != opponent:
				leftover.append(bot)
		if leftover.size() >= 2:
			pairings.append(FightPair.new(leftover[0], leftover[1], false))
		elif leftover.size() == 1 and opponent != null:
			pairings.append(FightPair.new(leftover[0], opponent, true))
		return
	pairings.append(FightPair.new(alive[0], alive[1], false))
	if alive.size() >= 4:
		pairings.append(FightPair.new(alive[2], alive[3], false))
	elif alive.size() == 3:
		pairings.append(FightPair.new(alive[2], alive[0], true))

func _pick_opponent(who: Contestant, pool: Array[Contestant]) -> Contestant:
	var candidates: Array[Contestant] = []
	for contestant in pool:
		if contestant == who:
			continue
		candidates.append(contestant)
	if candidates.is_empty():
		return null
	var preferred: Array[Contestant] = []
	for contestant in candidates:
		if contestant.id != who.last_opponent_id:
			preferred.append(contestant)
	var list := preferred if not preferred.is_empty() else candidates
	return list[rng.randi_range(0, list.size() - 1)]
