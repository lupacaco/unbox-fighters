extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var pool := ShopPool.parts_up_to_tier(1)
	if pool.is_empty():
		push_error("VERIFY_FAIL shop tier 1 empty")
		quit(1)
		return
	for part in pool:
		if part.tier > 1 or part.combat_value >= 9:
			push_error("VERIFY_FAIL tier 1 sold a high part: %s" % part.id)
			quit(1)
			return
	var high := ShopPool.parts_up_to_tier(5)
	var has_nine := false
	for part in high:
		if part.combat_value == 9:
			has_nine = true
	if not has_nine:
		push_error("VERIFY_FAIL tier 5 should include 9s")
		quit(1)
		return
	if ShopPool.roster().size() != 6:
		push_error("VERIFY_FAIL expected 6 characters, got %d" % ShopPool.roster().size())
		quit(1)
		return
	var ids: PackedStringArray = []
	for character in ShopPool.roster():
		ids.append(String(character.id))
	for needed in ["vampiro", "policial", "bruxa", "mumia", "medico", "cachorro"]:
		if needed not in ids:
			push_error("VERIFY_FAIL missing character %s" % needed)
			quit(1)
			return
	var mumia_body := false
	for part in ShopPool.parts_up_to_tier(1):
		if part.id == &"mumia_body":
			mumia_body = true
	if mumia_body:
		push_error("VERIFY_FAIL mummy body should not appear at shop level 1")
		quit(1)
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var offers := ShopPool.roll(1, rng)
	if offers.size() != MatchRules.SHOP_SLOTS:
		push_error("VERIFY_FAIL shop should roll 5")
		quit(1)
		return
	print("VERIFY_SHOP_POOL_PASS")
	quit(0)
