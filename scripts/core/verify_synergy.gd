extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	if not _check_synergy():
		quit(1)
		return
	if not _check_part_numbers():
		quit(1)
		return
	print("VERIFY_SYNERGY_PASS")
	quit(0)

func _check_synergy() -> bool:
	if Synergy.scaled_value(4, 1) != 2:
		push_error("VERIFY_FAIL 4 alone should be 2")
		return false
	if Synergy.scaled_value(4, 2) != 4:
		push_error("VERIFY_FAIL 4 with matching torso should stay 4")
		return false
	if Synergy.scaled_value(9, 1) != 5:
		push_error("VERIFY_FAIL 9 at 50% should be 5")
		return false
	if Synergy.scaled_value(9, 2) != 9:
		push_error("VERIFY_FAIL 9 with a matching pair should stay 9")
		return false
	if MatchRules.gold_for_round(1) != 3 or MatchRules.gold_for_round(8) != 10:
		push_error("VERIFY_FAIL gold curve")
		return false
	if MatchRules.upgrade_cost(1) != 4 or MatchRules.upgrade_cost(5) != -1:
		push_error("VERIFY_FAIL upgrade costs")
		return false
	return true

func _check_part_numbers() -> bool:
	var leao: CharacterDef = load("res://data/parts/leao_character.tres")
	if leao == null:
		push_error("VERIFY_FAIL missing leao")
		return false
	if leao.shop_parts().size() != 4:
		push_error("VERIFY_FAIL lion should sell 4 kits")
		return false
	for part in leao.shop_parts():
		if part == null or part.combat_value != 4 or part.tier != 1:
			push_error("VERIFY_FAIL lion kits should all be 4 / shop level 1")
			return false
	var full := FighterLoadout.from_character(leao)
	if full.total_power() != 16:
		push_error("VERIFY_FAIL lion full should be 16, got %d" % full.total_power())
		return false
	var solo := FighterLoadout.from_parts(leao.head, null, null)
	if solo.combat_value_of(PartSlotType.Value.HEAD) != 2:
		push_error("VERIFY_FAIL lone lion head should be 2")
		return false
	var pair := FighterLoadout.from_parts(leao.head, leao.body, null)
	if pair.combat_value_of(PartSlotType.Value.HEAD) != 4:
		push_error("VERIFY_FAIL two matching lion kits should be 100%")
		return false
	if pair.total_power() != 8:
		push_error("VERIFY_FAIL head+torso lion should be 8, got %d" % pair.total_power())
		return false
	return true
