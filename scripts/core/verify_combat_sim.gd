extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var policial: CharacterDef = load("res://data/parts/policial_character.tres")
	var vampiro: CharacterDef = load("res://data/parts/vampiro_character.tres")
	var bruxa: CharacterDef = load("res://data/parts/bruxa_character.tres")

	if not _test_clash_leftover(policial, bruxa):
		quit(1)
		return
	if not _test_tie_kills_both(policial):
		quit(1)
		return
	if not _test_damage_cap(vampiro):
		quit(1)
		return
	if not _test_empty_vs_full(vampiro):
		quit(1)
		return
	print("VERIFY_COMBAT_SIM_PASS")
	quit(0)

func _test_clash_leftover(policial: CharacterDef, bruxa: CharacterDef) -> bool:
	var left := BoardLoadout.new()
	left.fighters[0] = FighterLoadout.from_parts(policial.head, policial.body, policial.legs)
	var right := BoardLoadout.new()
	right.fighters[0] = FighterLoadout.from_parts(null, bruxa.body, null)
	var result := CombatSim.simulate(left, right)
	var first = result.events[0]
	if first.kind != CombatEvent.Kind.CLASH:
		push_error("VERIFY_FAIL expected a clash")
		return false
	if first.left_value != 7 or first.right_value != 2:
		push_error("VERIFY_FAIL expected 7 vs 2 (witch body solo 50%), got %d vs %d" % [first.left_value, first.right_value])
		return false
	if first.winning_side != CombatEvent.Side.LEFT or first.left_leftover != 5:
		push_error("VERIFY_FAIL leftover should be 5")
		return false
	if result.damage_to_right != 12:
		push_error("VERIFY_FAIL police leftover should cap at 12, got %d" % result.damage_to_right)
		return false
	return true

func _test_tie_kills_both(policial: CharacterDef) -> bool:
	var left := BoardLoadout.new()
	left.fighters[0] = FighterLoadout.from_parts(policial.legs, null, null)
	var right := BoardLoadout.new()
	right.fighters[0] = FighterLoadout.from_parts(policial.legs, null, null)
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

func _test_damage_cap(vampiro: CharacterDef) -> bool:
	var left := BoardLoadout.new()
	left.fighters[0] = FighterLoadout.from_parts(vampiro.head, vampiro.body, vampiro.legs)
	left.fighters[1] = FighterLoadout.from_parts(vampiro.head, vampiro.body, vampiro.legs)
	left.fighters[2] = FighterLoadout.from_parts(vampiro.head, vampiro.body, vampiro.legs)
	var right := BoardLoadout.new()
	var result := CombatSim.simulate(left, right)
	if result.damage_to_right != 36:
		push_error("VERIFY_FAIL three vampires vs empty should deal 36, got %d" % result.damage_to_right)
		return false
	return true

func _test_empty_vs_full(vampiro: CharacterDef) -> bool:
	var left := BoardLoadout.new()
	var right := BoardLoadout.new()
	right.fighters[0] = FighterLoadout.from_parts(vampiro.head, vampiro.body, vampiro.legs)
	var result := CombatSim.simulate(left, right)
	if result.winning_side != CombatEvent.Side.RIGHT or result.damage_to_left != 12:
		push_error("VERIFY_FAIL empty board should take 12 from one vampire")
		return false
	return true
