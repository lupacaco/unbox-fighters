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
	print("VERIFY_MATCH_STATE_PASS")
	quit(0)
