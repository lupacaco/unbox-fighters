extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var state := MatchState.new()
	state.rng.seed = 42
	state.start_match()
	if state.contestants.size() != 4:
		push_error("VERIFY_FAIL expected 4 contestants")
		quit(1)
		return
	if state.human().hp != 40 or state.round_index != 1:
		push_error("VERIFY_FAIL start hp/round")
		quit(1)
		return
	if state.human().gold != 3:
		push_error("VERIFY_FAIL round 1 gold should be 3")
		quit(1)
		return
	if state.opponent_of(state.human()) == null:
		push_error("VERIFY_FAIL player should have an opponent")
		quit(1)
		return
	var bots_alive := 0
	for contestant in state.contestants:
		if contestant.is_bot and contestant.is_alive():
			bots_alive += 1
	if bots_alive != 3:
		push_error("VERIFY_FAIL expected 3 bots")
		quit(1)
		return
	if state.contestants[1].display_name != "Sombra":
		push_error("VERIFY_FAIL bot names")
		quit(1)
		return
	state.contestants[3].hp = 0
	state.begin_prep()
	if state.pairings.size() != 2:
		push_error("VERIFY_FAIL 3 alive should make 2 pairings, got %d" % state.pairings.size())
		quit(1)
		return
	var ghost_pair: FightPair = state.pairings[1]
	if not ghost_pair.right_is_ghost:
		push_error("VERIFY_FAIL leftover bot should fight a ghost copy")
		quit(1)
		return
	var ghost_hp := ghost_pair.right.hp
	var leftover_hp := ghost_pair.left.hp
	var win := CombatResult.new()
	win.damage_to_right = 10
	win.winning_side = CombatEvent.Side.LEFT
	state.apply_result(ghost_pair.left, ghost_pair.right, win, true)
	if ghost_pair.right.hp != ghost_hp:
		push_error("VERIFY_FAIL ghost loss must not hurt the real opponent")
		quit(1)
		return
	var loss := CombatResult.new()
	loss.damage_to_left = 8
	loss.winning_side = CombatEvent.Side.RIGHT
	state.apply_result(ghost_pair.left, ghost_pair.right, loss, true)
	if ghost_pair.left.hp != leftover_hp - 8:
		push_error("VERIFY_FAIL leftover bot should still take HP damage")
		quit(1)
		return
	print("VERIFY_MATCH_STATE_PASS")
	quit(0)
