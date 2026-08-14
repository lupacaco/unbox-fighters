extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var leao: CharacterDef = load("res://data/parts/leao_character.tres")
	if not _test_clash_leftover(leao):
		quit(1)
		return
	if not _test_tie_kills_both(leao):
		quit(1)
		return
	if not _test_damage_cap(leao):
		quit(1)
		return
	if not _test_empty_vs_full(leao):
		quit(1)
		return
	if not _test_leftover_stable_when_random(leao):
		quit(1)
		return
	if not _test_random_slots_can_mix(leao):
		quit(1)
		return
	print("VERIFY_COMBAT_SIM_PASS")
	quit(0)

func _test_clash_leftover(leao: CharacterDef) -> bool:
	var left := BoardLoadout.new()
	left.fighters[0] = FighterLoadout.from_character(leao)
	var right := BoardLoadout.new()
	right.fighters[0] = FighterLoadout.from_parts(null, leao.body, null)
	var result := CombatSim.simulate(left, right)
	var first = result.events[0]
	if first.kind != CombatEvent.Kind.CLASH:
		push_error("VERIFY_FAIL expected a clash")
		return false
	if first.left_value != 4 or first.right_value != 2:
		push_error("VERIFY_FAIL expected 4 vs 2 (body solo 50%), got %d vs %d" % [first.left_value, first.right_value])
		return false
	if first.winning_side != CombatEvent.Side.LEFT or first.left_leftover != 2:
		push_error("VERIFY_FAIL leftover should be 2")
		return false
	if result.damage_to_right != 12:
		push_error("VERIFY_FAIL leftover should be 12, got %d" % result.damage_to_right)
		return false
	return true

func _test_tie_kills_both(leao: CharacterDef) -> bool:
	var left := BoardLoadout.new()
	left.fighters[0] = FighterLoadout.from_parts(leao.head, null, null)
	var right := BoardLoadout.new()
	right.fighters[0] = FighterLoadout.from_parts(leao.head, null, null)
	var result := CombatSim.simulate(left, right)
	var first = result.events[0]
	if first.winning_side != CombatEvent.Side.TIE:
		push_error("VERIFY_FAIL equal parts should tie")
		return false
	if first.left_leftover != 0 or first.right_leftover != 0:
		push_error("VERIFY_FAIL tie should kill both")
		return false
	if result.winning_side != CombatEvent.Side.TIE or result.damage_to_left != 0:
		push_error("VERIFY_FAIL mutual last-part kill is a draw")
		return false
	return true

func _test_damage_cap(leao: CharacterDef) -> bool:
	var left := BoardLoadout.new()
	left.fighters[0] = FighterLoadout.from_character(leao)
	left.fighters[1] = FighterLoadout.from_character(leao)
	left.fighters[2] = FighterLoadout.from_character(leao)
	var right := BoardLoadout.new()
	var result := CombatSim.simulate(left, right)
	if result.damage_to_right != 36:
		push_error("VERIFY_FAIL three lions vs empty should deal 36, got %d" % result.damage_to_right)
		return false
	return true

func _test_empty_vs_full(leao: CharacterDef) -> bool:
	var left := BoardLoadout.new()
	var right := BoardLoadout.new()
	right.fighters[0] = FighterLoadout.from_character(leao)
	var result := CombatSim.simulate(left, right)
	if result.winning_side != CombatEvent.Side.RIGHT or result.damage_to_left != 12:
		push_error("VERIFY_FAIL empty board should take 12 from one lion")
		return false
	return true

func _test_leftover_stable_when_random(leao: CharacterDef) -> bool:
	for seed in 8:
		var rng := RandomNumberGenerator.new()
		rng.seed = seed
		var left := BoardLoadout.new()
		left.fighters[0] = FighterLoadout.from_character(leao)
		var right := BoardLoadout.new()
		right.fighters[0] = FighterLoadout.from_parts(null, leao.body, null)
		var result := CombatSim.simulate(left, right, rng)
		if result.damage_to_right != 12:
			push_error("VERIFY_FAIL random pairing should still deal 12 vs solo body, seed %d got %d" % [seed, result.damage_to_right])
			return false
	return true

func _test_random_slots_can_mix(leao: CharacterDef) -> bool:
	var medico: CharacterDef = load("res://data/parts/medico_character.tres")
	if medico == null:
		push_error("VERIFY_FAIL missing medico")
		return false
	var mixed := false
	for seed in 40:
		var rng := RandomNumberGenerator.new()
		rng.seed = seed
		var left := BoardLoadout.new()
		left.fighters[0] = FighterLoadout.from_character(leao)
		var right := BoardLoadout.new()
		right.fighters[0] = FighterLoadout.from_character(medico)
		var result := CombatSim.simulate(left, right, rng)
		for event in result.events:
			if event.kind == CombatEvent.Kind.CLASH and event.left_slot != event.right_slot:
				mixed = true
				break
		if mixed:
			break
	if not mixed:
		push_error("VERIFY_FAIL expected some clashes to mix slots (head vs arm)")
		return false
	return true
