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
	var vampiro: CharacterDef = load("res://data/parts/vampiro_character.tres")
	if vampiro == null:
		push_error("VERIFY_FAIL missing vampiro")
		return false
	if vampiro.shop_parts().size() != 4:
		push_error("VERIFY_FAIL vampire should sell 4 kits")
		return false
	if vampiro.head.combat_value != 3 or vampiro.body.combat_value != 4:
		push_error("VERIFY_FAIL vampire head 3 / torso 4")
		return false
	for part in vampiro.shop_parts():
		if part == null or part.tier != 1:
			push_error("VERIFY_FAIL vampire kits should be shop level 1")
			return false
	var full := FighterLoadout.from_character(vampiro)
	if full.total_power() != 15:
		push_error("VERIFY_FAIL vampire full should be 15, got %d" % full.total_power())
		return false
	var solo := FighterLoadout.from_parts(vampiro.head, null, null)
	if solo.combat_value_of(PartSlotType.Value.HEAD) != 2:
		push_error("VERIFY_FAIL lone vampire head should be 2")
		return false
	var pair := FighterLoadout.from_parts(vampiro.head, vampiro.body, null)
	if pair.combat_value_of(PartSlotType.Value.HEAD) != 3:
		push_error("VERIFY_FAIL two matching vampire kits should be 100%")
		return false
	if pair.total_power() != 7:
		push_error("VERIFY_FAIL head+torso vampire should be 7, got %d" % pair.total_power())
		return false
	return true
