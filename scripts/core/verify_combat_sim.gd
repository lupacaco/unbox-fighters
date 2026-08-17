extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var freak: CharacterDef = load("res://data/parts/vampiro_character.tres")
	if not _test_clash_leftover(freak):
		quit(1)
		return
	if not _test_tie_kills_both(freak):
		quit(1)
		return
	if not _test_damage_cap(freak):
		quit(1)
		return
	if not _test_empty_vs_full(freak):
		quit(1)
		return
	if not _test_leftover_stable_when_random(freak):
		quit(1)
		return
	if not _test_random_slots_can_mix(freak):
		quit(1)
		return
	print("VERIFY_COMBAT_SIM_PASS")
	quit(0)

func _test_clash_leftover(freak: CharacterDef) -> bool:
	var left := BoardLoadout.new()
	left.fighters[0] = FighterLoadout.from_character(freak)
	var right := BoardLoadout.new()
	right.fighters[0] = FighterLoadout.from_parts(null, freak.body, null)
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

func _test_tie_kills_both(freak: CharacterDef) -> bool:
	var left := BoardLoadout.new()
	left.fighters[0] = FighterLoadout.from_parts(freak.head, null, null)
	var right := BoardLoadout.new()
	right.fighters[0] = FighterLoadout.from_parts(freak.head, null, null)
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

func _test_damage_cap(freak: CharacterDef) -> bool:
	var left := BoardLoadout.new()
	left.fighters[0] = FighterLoadout.from_character(freak)
	left.fighters[1] = FighterLoadout.from_character(freak)
	left.fighters[2] = FighterLoadout.from_character(freak)
	var right := BoardLoadout.new()
	var result := CombatSim.simulate(left, right)
	if result.damage_to_right != 36:
		push_error("VERIFY_FAIL three fighters vs empty should deal 36, got %d" % result.damage_to_right)
		return false
	return true

func _test_empty_vs_full(freak: CharacterDef) -> bool:
	var left := BoardLoadout.new()
	var right := BoardLoadout.new()
	right.fighters[0] = FighterLoadout.from_character(freak)
	var result := CombatSim.simulate(left, right)
	if result.winning_side != CombatEvent.Side.RIGHT or result.damage_to_left != 12:
		push_error("VERIFY_FAIL empty board should take 12 from one fighter")
		return false
	return true

func _test_leftover_stable_when_random(freak: CharacterDef) -> bool:
	for seed in 8:
		var rng := RandomNumberGenerator.new()
		rng.seed = seed
		var left := BoardLoadout.new()
		left.fighters[0] = FighterLoadout.from_character(freak)
		var right := BoardLoadout.new()
		right.fighters[0] = FighterLoadout.from_parts(null, freak.body, null)
		var result := CombatSim.simulate(left, right, rng)
		if result.damage_to_right != 12:
			push_error("VERIFY_FAIL random pairing should still deal 12 vs solo body, seed %d got %d" % [seed, result.damage_to_right])
			return false
	return true

func _test_random_slots_can_mix(freak: CharacterDef) -> bool:
	var bruxa: CharacterDef = load("res://data/parts/bruxa_character.tres")
	if bruxa == null:
		push_error("VERIFY_FAIL missing bruxa")
		return false
	var mixed := false
	for seed in 40:
		var rng := RandomNumberGenerator.new()
		rng.seed = seed
		var left := BoardLoadout.new()
		left.fighters[0] = FighterLoadout.from_character(freak)
		var right := BoardLoadout.new()
		right.fighters[0] = FighterLoadout.from_character(bruxa)
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
