extends SceneTree

## Preparation, fight, leftover money, survivor damage, and Freaks that stay
## on the cards after the round.

const TRAVEL := 700.0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	if not _check_empty_round():
		quit(1)
		return
	if not _check_survivor_damage():
		quit(1)
		return
	if not _check_money_carry():
		quit(1)
		return
	print("VERIFY_MATCH_PHASES_PASS")
	quit(0)

func _check_empty_round() -> bool:
	var live := LiveMatch.new()
	live.start()
	if live.phase != MatchRules.Phase.PREP:
		push_error("VERIFY_FAIL a match opens in preparation")
		return false
	live.skip_prep()
	if live.phase != MatchRules.Phase.PREP:
		push_error("VERIFY_FAIL a fight with nobody PRONTO should skip to the next prep")
		return false
	if live.player.life != MatchRules.PLAYER_HP or live.opponent.life != MatchRules.PLAYER_HP:
		push_error("VERIFY_FAIL an empty fight deals no life damage")
		return false
	if live.player.money != MatchRules.STARTING_MONEY + MatchRules.MONEY_PER_ROUND:
		push_error("VERIFY_FAIL leftover plus $%d should land after the round" % MatchRules.MONEY_PER_ROUND)
		return false
	return true

func _check_survivor_damage() -> bool:
	var live := LiveMatch.new()
	live.player.lane.travel_px = TRAVEL
	live.opponent.lane.travel_px = TRAVEL
	live.start()
	live.player.cards[0] = _loadout(&"bruxa")
	live.player.cards[1] = _loadout(&"advogado")
	live.skip_prep()
	for _i in 120:
		live.tick(0.1)
		if live.phase != MatchRules.Phase.FIGHT:
			break
	var expected := MatchRules.PLAYER_HP - 2 * MatchRules.SURVIVOR_DAMAGE
	if live.opponent.life != expected:
		push_error("VERIFY_FAIL two living Freaks should deal 10 life, got %d" % live.opponent.life)
		return false
	if live.player.cards[0] == null or not live.player.cards[0].is_complete():
		push_error("VERIFY_FAIL the first card should still hold its Freak")
		return false
	if live.player.cards[1] == null or not live.player.cards[1].is_complete():
		push_error("VERIFY_FAIL the second card should still hold its Freak")
		return false
	return true

func _check_money_carry() -> bool:
	var live := LiveMatch.new()
	live.start()
	if not live.player.spend(3):
		push_error("VERIFY_FAIL should be able to spend during prep")
		return false
	live.skip_prep()
	if live.player.money != MatchRules.STARTING_MONEY - 3 + MatchRules.MONEY_PER_ROUND:
		push_error("VERIFY_FAIL leftover coins should stay and then get $%d" % MatchRules.MONEY_PER_ROUND)
		return false
	if live.player.money > MatchRules.MAX_MONEY:
		push_error("VERIFY_FAIL the wallet cannot pass %d" % MatchRules.MAX_MONEY)
		return false
	return true

func _loadout(set_id: StringName) -> FighterLoadout:
	return FighterLoadout.from_character(ShopPool.character_by_id(set_id))
