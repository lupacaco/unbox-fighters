extends SceneTree

## The conveyor: a Freak slides from the far end to the fighting tip at a speed
## set by its Agility, only two fit at a time, and the one behind has to wait.

const TRAVEL := 700.0

## Counted from the signal. A lambda copies locals, so this has to live outside.
var _chips: int = 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	if not _check_lane():
		quit(1)
		return
	if not _check_queue():
		quit(1)
		return
	if not _check_live_match():
		quit(1)
		return
	print("VERIFY_BELT_PASS")
	quit(0)

func _check_lane() -> bool:
	var lane := BeltLane.new()
	lane.travel_px = TRAVEL
	var runner := lane.add(_loadout(&"bruxa"))
	if runner == null:
		push_error("VERIFY_FAIL a finished card should get on the belt")
		return false
	if runner.hp != runner.stats.toughness:
		push_error("VERIFY_FAIL a Freak starts with Toughness as its life")
		return false
	if lane.champion() != null:
		push_error("VERIFY_FAIL nobody fights before reaching the tip")
		return false

	var seconds := TRAVEL / runner.stats.speed()
	lane.advance(seconds * 0.5)
	if runner.progress <= 0.4 or runner.progress >= 0.6:
		push_error("VERIFY_FAIL half the time should be about half the way, got %.2f" % runner.progress)
		return false
	lane.advance(seconds)
	if not runner.at_tip() or lane.champion() != runner:
		push_error("VERIFY_FAIL the Freak should stop and fight at the tip")
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
	lane.travel_px = TRAVEL
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
	if live.launch(live.player, FighterLoadout.new()) != null:
		push_error("VERIFY_FAIL an unfinished card cannot fight")
		return false
	if live.launch(live.player, _loadout(&"bruxa")) == null:
		push_error("VERIFY_FAIL a finished card should launch")
		return false

	_chips = 0
	live.player_chipped.connect(_count_chip)
	## Long enough for the slide plus one chip a second through 100 life.
	var ticks := int((MatchRules.STARTING_HP * MatchRules.CHIP_INTERVAL + 20.0) / 0.1)
	for _i in ticks:
		live.tick(0.1)
		if not live.running:
			break
	if _chips < MatchRules.STARTING_HP:
		push_error("VERIFY_FAIL a lone Freak at the tip should chip the other player, got %d" % _chips)
		return false
	if live.opponent.is_alive():
		push_error("VERIFY_FAIL 100 chips should end the match")
		return false
	if live.winner != live.player:
		push_error("VERIFY_FAIL the side still standing wins")
		return false
	return true

func _count_chip(_victim: PlayerState, _attacker: PlayerState) -> void:
	_chips += 1

func _loadout(set_id: StringName) -> FighterLoadout:
	return FighterLoadout.from_character(ShopPool.character_by_id(set_id))
