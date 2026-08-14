extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	ShopPool.reload()
	var roster := ShopPool.roster()
	if roster.size() != 2:
		push_error("VERIFY_FAIL shop roster should be lion + doctor, got %d" % roster.size())
		quit(1)
		return
	var ids: PackedStringArray = []
	for character in roster:
		ids.append(String(character.id))
	ids.sort()
	if ids != PackedStringArray(["leao", "medico"]):
		push_error("VERIFY_FAIL unexpected roster: %s" % ", ".join(ids))
		quit(1)
		return

	var tier1 := ShopPool.parts_up_to_tier(1)
	if tier1.size() != 5:
		push_error("VERIFY_FAIL shop level 1 should sell 5 kits (3 lion + doctor head/legs), got %d" % tier1.size())
		quit(1)
		return
	for part in tier1:
		if String(part.set_id) not in ["leao", "medico"]:
			push_error("VERIFY_FAIL unexpected shop part: %s" % part.id)
			quit(1)
			return
		if not PartSlotType.is_shop_slot(part.slot_type):
			push_error("VERIFY_FAIL shop sold a visual limb: %s" % part.id)
			quit(1)
			return
		if String(part.set_id) == "medico" and part.slot_type == PartSlotType.Value.BODY:
			push_error("VERIFY_FAIL doctor torso is shop level 2")
			quit(1)
			return

	var high := ShopPool.parts_up_to_tier(5)
	if high.size() != 6:
		push_error("VERIFY_FAIL both sets should sell 6 kits, got %d" % high.size())
		quit(1)
		return
	var body: PartDef = load("res://data/parts/medico_body.tres")
	if body == null or body.combat_value != 6 or body.tier != 2:
		push_error("VERIFY_FAIL doctor torso should be 6 (shop level 2)")
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
