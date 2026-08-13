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
	if Synergy.scaled_value(5, 1) != 3:
		push_error("VERIFY_FAIL head 5 alone should be 3")
		return false
	if Synergy.scaled_value(9, 1) != 5:
		push_error("VERIFY_FAIL 9 at 50% should be 5")
		return false
	if Synergy.scaled_value(9, 2) != 7:
		push_error("VERIFY_FAIL 9 at 75% should be 7")
		return false
	if Synergy.scaled_value(9, 3) != 9:
		push_error("VERIFY_FAIL 9 at 100% should be 9")
		return false
	if MatchRules.gold_for_round(1) != 3 or MatchRules.gold_for_round(8) != 10:
		push_error("VERIFY_FAIL gold curve")
		return false
	if MatchRules.upgrade_cost(1) != 4 or MatchRules.upgrade_cost(5) != -1:
		push_error("VERIFY_FAIL upgrade costs")
		return false
	return true

func _check_part_numbers() -> bool:
	var policial: CharacterDef = load("res://data/parts/policial_character.tres")
	var vampiro: CharacterDef = load("res://data/parts/vampiro_character.tres")
	var bruxa: CharacterDef = load("res://data/parts/bruxa_character.tres")
	if policial.head.combat_value != 7 or policial.body.combat_value != 6 or policial.legs.combat_value != 5:
		push_error("VERIFY_FAIL policial combat values")
		return false
	if vampiro.head.combat_value != 9 or vampiro.body.combat_value != 9 or vampiro.legs.combat_value != 8:
		push_error("VERIFY_FAIL vampiro combat values")
		return false
	if bruxa.head.combat_value != 9 or bruxa.body.combat_value != 4 or bruxa.legs.combat_value != 9:
		push_error("VERIFY_FAIL bruxa combat values")
		return false
	var mumia: CharacterDef = load("res://data/parts/mumia_character.tres")
	var medico: CharacterDef = load("res://data/parts/medico_character.tres")
	var cachorro: CharacterDef = load("res://data/parts/cachorro_character.tres")
	if mumia.head.combat_value != 5 or mumia.body.combat_value != 8 or mumia.legs.combat_value != 6:
		push_error("VERIFY_FAIL mumia combat values")
		return false
	if medico.head.combat_value != 3 or medico.body.combat_value != 4 or medico.legs.combat_value != 4:
		push_error("VERIFY_FAIL medico combat values")
		return false
	if cachorro.head.combat_value != 5 or cachorro.body.combat_value != 5 or cachorro.legs.combat_value != 7:
		push_error("VERIFY_FAIL cachorro combat values")
		return false
	if mumia.body.tier != 4 or medico.head.tier != 1 or cachorro.legs.tier != 3:
		push_error("VERIFY_FAIL extra set shop tiers")
		return false
	if policial.head.tier != 3 or vampiro.head.tier != 5 or bruxa.body.tier != 1:
		push_error("VERIFY_FAIL shop tiers")
		return false
	var full := FighterLoadout.from_parts(policial.head, policial.body, policial.legs)
	if full.total_power() != 18:
		push_error("VERIFY_FAIL policial full should be 18, got %d" % full.total_power())
		return false
	var mix := FighterLoadout.from_parts(vampiro.head, policial.body, bruxa.legs)
	if mix.combat_value_of(PartSlotType.Value.HEAD) != 5:
		push_error("VERIFY_FAIL mix vamp head should be 5")
		return false
	if mix.combat_value_of(PartSlotType.Value.BODY) != 3:
		push_error("VERIFY_FAIL mix police body should be 3")
		return false
	if mix.combat_value_of(PartSlotType.Value.LEGS) != 5:
		push_error("VERIFY_FAIL mix witch legs should be 5")
		return false
	return true
