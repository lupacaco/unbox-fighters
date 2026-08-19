extends SceneTree

## The maths of one exchange of blows, with no screen involved: blows are
## sequential, a killing hit is thrown by the winner, and both only swing when
## the trade would drop them together.

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
	var strong := _stats(8, 20)
	var quick := _stats(4, 12)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7

	var trade := Duel.exchange(strong, quick, 20, 12, rng)
	if trade.damage_to_right != 8 or trade.damage_to_left != 4:
		push_error("VERIFY_FAIL damage should equal the attacker's Attack")
		return false
	if trade.left_dies or trade.right_dies or not trade.second_happens:
		push_error("VERIFY_FAIL nobody dies here, so both should swing")
		return false

	var winner_left := Duel.exchange(strong, quick, 20, 5, rng)
	if not winner_left.first_is_left or winner_left.second_happens:
		push_error("VERIFY_FAIL the Freak that can finish the fight should strike alone")
		return false
	if winner_left.left_dies or not winner_left.right_dies:
		push_error("VERIFY_FAIL only the loser should fall on a clean killing blow")
		return false
	if winner_left.damage_to_left != 0:
		push_error("VERIFY_FAIL a finished Freak does not get a counter")
		return false

	var winner_right := Duel.exchange(quick, strong, 5, 20, rng)
	if winner_right.first_is_left or winner_right.second_happens:
		push_error("VERIFY_FAIL the right-hand winner should strike first and alone")
		return false
	if not winner_right.left_dies or winner_right.right_dies:
		push_error("VERIFY_FAIL only the left Freak should fall here")
		return false

	var lethal := Duel.exchange(strong, quick, 3, 5, rng)
	if not lethal.left_dies or not lethal.right_dies or not lethal.second_happens:
		push_error("VERIFY_FAIL both should swing when the trade would drop them together")
		return false
	if not lethal.both_die():
		push_error("VERIFY_FAIL both_die should agree with the two flags")
		return false

	if Duel.blows_to_kill(20, 8) != 3:
		push_error("VERIFY_FAIL 20 life against Attack 8 takes 3 blows")
		return false
	if Duel.blows_to_kill(20, 0) < 999:
		push_error("VERIFY_FAIL Attack 0 never kills")
		return false
	return true

func _check_prices() -> bool:
	if PartStats.price_for(PartSlotType.Value.HEAD, 8) != 8:
		push_error("VERIFY_FAIL a head costs its Attack")
		return false
	if PartStats.price_for(PartSlotType.Value.BODY, 15) != 5:
		push_error("VERIFY_FAIL a body costs HP minus 10")
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
	if side.money != MatchRules.STARTING_MONEY:
		push_error("VERIFY_FAIL a fresh player starts with a full wallet")
		return false
	if side.shop_offers.size() != MatchRules.SHOP_SLOTS:
		push_error("VERIFY_FAIL a fresh shop has %d crate(s)" % MatchRules.SHOP_SLOTS)
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
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	side.roll_shop(rng)
	var money_before := side.money
	if not side.refresh_shop(rng):
		push_error("VERIFY_FAIL a free refresh should always work")
		return false
	if side.money != money_before:
		push_error("VERIFY_FAIL refreshing the shop is free")
		return false
	return true

func _stats(attack: int, hp: int) -> FreakStats:
	var stats := FreakStats.new()
	stats.attack = attack
	stats.hp = hp
	return stats
