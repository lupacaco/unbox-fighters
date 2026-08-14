extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var pool := ShopPool.parts_up_to_tier(1)
	if pool.size() != 3:
		push_error("VERIFY_FAIL shop level 1 should sell the 3 lion kits, got %d" % pool.size())
		quit(1)
		return
	for part in pool:
		if String(part.set_id) != "leao" or part.tier != 1 or part.combat_value != 4:
			push_error("VERIFY_FAIL unexpected shop part: %s" % part.id)
			quit(1)
			return
		if not PartSlotType.is_shop_slot(part.slot_type):
			push_error("VERIFY_FAIL shop sold a visual limb: %s" % part.id)
			quit(1)
			return
	var roster := ShopPool.roster()
	if roster.size() != 1 or String(roster[0].id) != "leao":
		push_error("VERIFY_FAIL shop roster should be only the lion")
		quit(1)
		return
	var high := ShopPool.parts_up_to_tier(5)
	if high.size() != 3:
		push_error("VERIFY_FAIL other freaks should stay out of the shop")
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
