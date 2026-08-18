extends SceneTree

## The maths of one exchange of blows, with no screen involved: both Freaks
## always land their hit, damage equals the attacker's Power, and a Freak with
## no life left is marked dead.

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	if not _check_exchange():
		quit(1)
		return
	if not _check_prices():
		quit(1)
		return
	if not _check_money():
		quit(1)
		return
	print("VERIFY_DUEL_PASS")
	quit(0)

func _check_exchange() -> bool:
	var strong := _stats(8, 20, 2)
	var quick := _stats(4, 12, 5)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7

	var trade := Duel.exchange(strong, quick, 20, 12, rng)
	if trade.damage_to_right != 8 or trade.damage_to_left != 4:
		push_error("VERIFY_FAIL damage should equal the attacker's Power")
		return false
	if trade.left_dies or trade.right_dies:
		push_error("VERIFY_FAIL nobody dies on the first blow here")
		return false

	var lethal := Duel.exchange(strong, quick, 3, 5, rng)
	if not lethal.left_dies or not lethal.right_dies:
		push_error("VERIFY_FAIL both should fall when neither survives the trade")
		return false
	if not lethal.both_die():
		push_error("VERIFY_FAIL both_die should agree with the two flags")
		return false

	if Duel.blows_to_kill(20, 8) != 3:
		push_error("VERIFY_FAIL 20 life against Power 8 takes 3 blows")
		return false
	if Duel.blows_to_kill(20, 0) < 999:
		push_error("VERIFY_FAIL Power 0 never kills")
		return false
	return true

func _check_prices() -> bool:
	if PartStats.price_for(PartSlotType.Value.HEAD, 8) != 8:
		push_error("VERIFY_FAIL a head costs its Power")
		return false
	if PartStats.price_for(PartSlotType.Value.ARMS, 5) != 5:
		push_error("VERIFY_FAIL arms cost their Agility")
		return false
	if PartStats.price_for(PartSlotType.Value.BODY, 15) != 5:
		push_error("VERIFY_FAIL a torso costs Toughness minus 10")
		return false
	if PartStats.price_for(PartSlotType.Value.BODY, 10) != PartStats.MIN_PRICE:
		push_error("VERIFY_FAIL no crate may be free")
		return false
	if PartStats.sell_price(5) != 3 or PartStats.sell_price(8) != 4:
		push_error("VERIFY_FAIL selling gives back half, rounded up")
		return false
	if PartStats.sell_price(0) != 0:
		push_error("VERIFY_FAIL nothing paid, nothing back")
		return false
	return true

func _check_money() -> bool:
	var side := PlayerState.new()
	side.reset()
	if side.money != MatchRules.STARTING_MONEY or side.hp != MatchRules.STARTING_HP:
		push_error("VERIFY_FAIL a fresh player starts full")
		return false
	if side.tick_money(MatchRules.MONEY_INTERVAL * 2.0):
		push_error("VERIFY_FAIL a full wallet cannot grow")
		return false
	side.spend(4)
	if side.money != MatchRules.STARTING_MONEY - 4:
		push_error("VERIFY_FAIL spending should take the coins")
		return false
	if not side.tick_money(MatchRules.MONEY_INTERVAL):
		push_error("VERIFY_FAIL a coin should land after %.0f seconds" % MatchRules.MONEY_INTERVAL)
		return false
	if side.money != MatchRules.STARTING_MONEY - 3:
		push_error("VERIFY_FAIL the wallet should gain exactly one coin")
		return false
	side.earn(99)
	if side.money != MatchRules.MAX_MONEY:
		push_error("VERIFY_FAIL the wallet stops at %d" % MatchRules.MAX_MONEY)
		return false
	for _i in MatchRules.STARTING_HP:
		side.take_chip_damage()
	if side.is_alive():
		push_error("VERIFY_FAIL one chip a second should empty the life bar")
		return false
	return true

func _stats(power: int, toughness: int, agility: int) -> FreakStats:
	var stats := FreakStats.new()
	stats.power = power
	stats.toughness = toughness
	stats.agility = agility
	return stats
