extends SceneTree

## The conveyor: a Freak paddles from the far end to the fighting tip in five
## strokes, only two fit at a time, and the one behind waits with space
## between the crates.

const TRAVEL := 700.0

## Counted from the signal. A lambda copies locals, so this has to live outside.
var _chips: int = 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	if not _check_intervals():
		quit(1)
		return
	if not _check_stroke_pose():
		quit(1)
		return
	if not _check_lane():
		quit(1)
		return
	if not _check_queue():
		quit(1)
		return
	if not _check_live_match():
		quit(1)
		return
	if not _check_live_duel():
		quit(1)
		return
	print("VERIFY_BELT_PASS")
	quit(0)

func _check_intervals() -> bool:
	if not is_equal_approx(MatchRules.stroke_interval(), 2.0):
		push_error("VERIFY_FAIL every Freak should wait 2s between strokes")
		return false
	if not is_equal_approx(MatchRules.stroke_step(), 0.2):
		push_error("VERIFY_FAIL five strokes should each cover a fifth of the belt")
		return false
	return true


func _check_stroke_pose() -> bool:
	if not is_equal_approx(BeltFreak.stroke_arm_angle(0.0), BeltFreak.ARM_FORWARD):
		push_error("VERIFY_FAIL a Freak on the belt starts with arms forward")
		return false
	if not is_equal_approx(BeltFreak.stroke_arm_angle(1.0), BeltFreak.ARM_FORWARD):
		push_error("VERIFY_FAIL after a paddle the arms return forward")
		return false
	if BeltFreak.stroke_arm_angle(BeltFreak.WIND_BACK_END) < BeltFreak.ARM_BACK - 0.05:
		push_error("VERIFY_FAIL the wind-up should finish with the arms back")
		return false
	for i in 21:
		var t := float(i) / 20.0
		var angle := BeltFreak.stroke_arm_angle(t)
		if angle < BeltFreak.ARM_FORWARD - 0.05 or angle > BeltFreak.ARM_BACK + 0.05:
			push_error("VERIFY_FAIL the paddle is a half-moon under, not over the head")
			return false
	var body_z := PartSlotType.fight_z_index(PartSlotType.Value.BODY, true)
	var plaque_z := CompositeResolver.crate_plaque_z(body_z)
	if BeltFreak.belt_arm_z(PartSlotType.Value.ARM_R, body_z) <= plaque_z:
		push_error("VERIFY_FAIL the near arm should sit in front of the crate numbers")
		return false
	if BeltFreak.belt_arm_z(PartSlotType.Value.ARM_L, body_z) <= plaque_z:
		push_error("VERIFY_FAIL both arms should sit in front of the crate numbers")
		return false
	return true

func _check_lane() -> bool:
	var lane := BeltLane.new()
	lane.travel_px = TRAVEL
	var runner := lane.add(_loadout(&"bruxa"))
	if runner == null:
		push_error("VERIFY_FAIL a finished card should get on the belt")
		return false
	if runner.hp != runner.stats.hp:
		push_error("VERIFY_FAIL a Freak starts with HP as its life")
		return false
	if lane.champion() != null:
		push_error("VERIFY_FAIL nobody fights before reaching the tip")
		return false

	var interval := MatchRules.stroke_interval()
	lane.advance(interval * 0.5)
	if runner.progress > 0.001:
		push_error("VERIFY_FAIL it should wait a full stroke beat before the first paddle")
		return false
	lane.advance(interval * 0.6)
	if not is_equal_approx(runner.progress, MatchRules.stroke_step()):
		push_error("VERIFY_FAIL the first paddle should cover one fifth, got %.2f" % runner.progress)
		return false
	lane.advance(interval * 4.0)
	if not runner.at_tip() or lane.champion() != runner:
		push_error("VERIFY_FAIL five paddles should stop and fight at the tip")
		return false

	if not lane.take_damage(runner, runner.hp):
		push_error("VERIFY_FAIL enough damage should knock it out")
		return false
	if lane.remove_dead().size() != 1 or not lane.is_empty():
		push_error("VERIFY_FAIL a beaten Freak leaves the belt")
		return false
	return true

func _check_queue() -> bool:
	var lane := BeltLane.new()
	lane.travel_px = AssemblyLayout.belt_travel_px(true)
	lane.queue_gap_px = AssemblyLayout.belt_queue_gap_px()
	var first := lane.add(_loadout(&"bruxa"))
	var second := lane.add(_loadout(&"advogado"))
	if first == null or second == null:
		push_error("VERIFY_FAIL two Freaks should fit")
		return false
	if lane.can_accept():
		push_error("VERIFY_FAIL only %d fit on a belt" % MatchRules.BELT_CAPACITY)
		return false
	lane.advance(30.0)
	if not first.at_tip():
		push_error("VERIFY_FAIL the leader should reach the tip")
		return false
	if second.at_tip():
		push_error("VERIFY_FAIL the second one has to wait behind")
		return false
	var expected := 1.0 - lane.follow_gap()
	if not is_equal_approx(second.progress, expected):
		push_error("VERIFY_FAIL the waiter should sit a crate behind, got %.2f" % second.progress)
		return false
	var lead_x := AssemblyLayout.belt_x_at(true, 1.0)
	var wait_x := AssemblyLayout.belt_x_at(true, second.progress)
	if absf(lead_x - wait_x) + 0.5 < AssemblyLayout.belt_freak_width():
		push_error("VERIFY_FAIL the two crates should not overlap on the belt")
		return false
	if lane.champion() != first:
		push_error("VERIFY_FAIL only the leader fights")
		return false
	return true

func _check_live_match() -> bool:
	var live := LiveMatch.new()
	live.player.lane.travel_px = TRAVEL
	live.opponent.lane.travel_px = TRAVEL
	live.start()
	if not live.running:
		push_error("VERIFY_FAIL the match should be running after start")
		return false
	if live.player.shop_offers.size() != MatchRules.SHOP_SLOTS:
		push_error("VERIFY_FAIL the shop should open with %d crates" % MatchRules.SHOP_SLOTS)
		return false
	if live.tug != 0:
		push_error("VERIFY_FAIL the tug bar should start empty")
		return false
	if live.launch(live.player, FighterLoadout.new()) != null:
		push_error("VERIFY_FAIL an unfinished card cannot fight")
		return false
	if live.launch(live.player, _loadout(&"bruxa")) == null:
		push_error("VERIFY_FAIL a finished card should launch")
		return false

	_chips = 0
	live.tug_changed.connect(_count_chip)
	## Long enough for five paddles plus one chip a second through 50 on the bar.
	var ticks := int((MatchRules.TUG_MAX * MatchRules.CHIP_INTERVAL + 30.0) / 0.1)
	for _i in ticks:
		live.tick(0.1)
		if not live.running:
			break
	if _chips < MatchRules.TUG_MAX:
		push_error("VERIFY_FAIL a lone Freak at the tip should push the bar, got %d" % _chips)
		return false
	if live.tug != -MatchRules.TUG_MAX:
		push_error("VERIFY_FAIL 50 chips from 0 should fill your side of the bar")
		return false
	if live.winner != live.player:
		push_error("VERIFY_FAIL the side still standing wins")
		return false
	return true

func _check_live_duel() -> bool:
	var live := LiveMatch.new()
	live.start()
	var mine := live.launch(live.player, _loadout(&"bruxa"))
	var theirs := live.launch(live.opponent, _loadout(&"advogado"))
	if mine == null or theirs == null:
		push_error("VERIFY_FAIL both sides should be able to send a Freak")
		return false
	mine.progress = 1.0
	theirs.progress = 1.0
	theirs.hp = 10
	theirs.appeal_used = true
	live.tick(MatchRules.DUEL_INTERVAL + 0.05)
	if theirs.alive or live.opponent.lane.front() != null:
		push_error("VERIFY_FAIL the winner's blow should finish the weaker Freak")
		return false
	if not mine.alive or mine.hp != mine.stats.hp:
		push_error("VERIFY_FAIL a finished Freak must not get a counter")
		return false
	return true

func _count_chip(_tug: int, _attacker: PlayerState) -> void:
	_chips += 1

func _loadout(set_id: StringName) -> FighterLoadout:
	return FighterLoadout.from_character(ShopPool.character_by_id(set_id))
