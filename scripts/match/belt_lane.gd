class_name BeltLane
extends RefCounted

## One side's conveyor. Freaks enter at the far end, slide to the fighting tip
## and queue up. Only the Freak at the tip fights; the one behind waits.
##
## Progress runs 0 (just dropped on) to 1 (at the tip), so the same code works
## for the blue belt sliding right and the red belt sliding left.

class Runner extends RefCounted:
	var stats: FreakStats
	## The three kits it was built from, so the screen can draw it.
	var loadout: FighterLoadout
	var hp: int = 0
	var progress: float = 0.0
	var alive: bool = true
	## Stable id so the screen can match a drawing to this runner.
	var id: int = 0

	func at_tip() -> bool:
		return progress >= 1.0

var runners: Array[Runner] = []
var travel_px: float = 1.0
var _next_id: int = 1

func can_accept() -> bool:
	return runners.size() < MatchRules.BELT_CAPACITY

func add(loadout: FighterLoadout) -> Runner:
	if loadout == null or not loadout.is_complete() or not can_accept():
		return null
	var runner := Runner.new()
	runner.loadout = loadout.duplicate_loadout()
	runner.stats = runner.loadout.stats()
	runner.hp = runner.stats.toughness
	runner.id = _next_id
	_next_id += 1
	runners.append(runner)
	return runner

func front() -> Runner:
	for runner in runners:
		if runner.alive:
			return runner
	return null

## The Freak that is at the tip and ready to trade blows.
func champion() -> Runner:
	var lead := front()
	return lead if lead != null and lead.at_tip() else null

func is_empty() -> bool:
	return runners.is_empty()

func advance(delta: float) -> void:
	if travel_px <= 0.0:
		travel_px = 1.0
	var blocked_at := 1.0
	for i in runners.size():
		var runner := runners[i]
		if not runner.alive:
			continue
		var step := runner.stats.speed() * delta / travel_px
		runner.progress = minf(runner.progress + step, blocked_at)
		blocked_at = maxf(0.0, runner.progress - _gap_share())

## Freaks queue one behind the other instead of stacking on the same spot.
func _gap_share() -> float:
	return clampf(180.0 / travel_px, 0.05, 0.45)

func take_damage(runner: Runner, amount: int) -> bool:
	if runner == null or not runner.alive:
		return false
	runner.hp = maxi(0, runner.hp - amount)
	if runner.hp > 0:
		return false
	runner.alive = false
	return true

func remove_dead() -> Array[Runner]:
	var gone: Array[Runner] = []
	for runner in runners:
		if not runner.alive:
			gone.append(runner)
	for runner in gone:
		runners.erase(runner)
	return gone

func clear() -> void:
	runners.clear()
