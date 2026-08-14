class_name CombatSim
extends RefCounted

## Resolves a 3-card queue fight. Presentation reads the event list; it does not
## recompute the rules.

class LivePart:
	var slot: PartSlotType.Value
	var part: PartDef
	var value: int


class LiveFighter:
	var queue_index: int
	var parts: Array[LivePart] = []

	func is_alive() -> bool:
		for live_part in parts:
			if live_part.value > 0:
				return true
		return false

	func top() -> LivePart:
		for live_part in parts:
			if live_part.value > 0:
				return live_part
		return null

	func remaining_power() -> int:
		var total := 0
		for live_part in parts:
			total += maxi(live_part.value, 0)
		return total


static func simulate(left: BoardLoadout, right: BoardLoadout) -> CombatResult:
	var result := CombatResult.new()
	result.left = left
	result.right = right
	var left_queue := _queue_from_board(left)
	var right_queue := _queue_from_board(right)
	var left_i := 0
	var right_i := 0
	var clash_n := 0

	if left_queue.is_empty() and right_queue.is_empty():
		result.events.append(CombatEvent.result(0, 0, CombatEvent.Side.TIE))
		return result
	if left_queue.is_empty():
		result.damage_to_left = _hp_damage(right_queue, 0)
		result.winning_side = CombatEvent.Side.RIGHT
		result.events.append(CombatEvent.result(result.damage_to_left, 0, result.winning_side))
		return result
	if right_queue.is_empty():
		result.damage_to_right = _hp_damage(left_queue, 0)
		result.winning_side = CombatEvent.Side.LEFT
		result.events.append(CombatEvent.result(0, result.damage_to_right, result.winning_side))
		return result

	while left_i < left_queue.size() and right_i < right_queue.size():
		var left_fighter: LiveFighter = left_queue[left_i]
		var right_fighter: LiveFighter = right_queue[right_i]
		while left_fighter.is_alive() and right_fighter.is_alive():
			var a: LivePart = left_fighter.top()
			var b: LivePart = right_fighter.top()
			clash_n += 1
			var left_v := a.value
			var right_v := b.value
			var who: int = CombatEvent.Side.TIE
			if left_v > right_v:
				a.value = left_v - right_v
				b.value = 0
				who = CombatEvent.Side.LEFT
			elif right_v > left_v:
				b.value = right_v - left_v
				a.value = 0
				who = CombatEvent.Side.RIGHT
			else:
				a.value = 0
				b.value = 0
				who = CombatEvent.Side.TIE
			result.events.append(CombatEvent.clash(
				clash_n,
				left_fighter.queue_index,
				right_fighter.queue_index,
				a.slot,
				b.slot,
				left_v,
				right_v,
				a.value,
				b.value,
				who
			))
		var left_dead := not left_fighter.is_alive()
		var right_dead := not right_fighter.is_alive()
		if left_dead:
			left_i += 1
		if right_dead:
			right_i += 1
		if left_i < left_queue.size() and right_i < right_queue.size() and (left_dead or right_dead):
			result.events.append(CombatEvent.queue_advance(
				clash_n,
				left_queue[left_i].queue_index,
				right_queue[right_i].queue_index
			))

	if left_i >= left_queue.size() and right_i >= right_queue.size():
		result.winning_side = CombatEvent.Side.TIE
	elif left_i >= left_queue.size():
		result.damage_to_left = _hp_damage(right_queue, right_i)
		result.winning_side = CombatEvent.Side.RIGHT
	else:
		result.damage_to_right = _hp_damage(left_queue, left_i)
		result.winning_side = CombatEvent.Side.LEFT
	result.events.append(CombatEvent.result(result.damage_to_left, result.damage_to_right, result.winning_side))
	return result


static func _queue_from_board(board: BoardLoadout) -> Array[LiveFighter]:
	var queue: Array[LiveFighter] = []
	for i in board.fighters.size():
		var loadout: FighterLoadout = board.fighters[i]
		if loadout == null or loadout.is_empty():
			continue
		queue.append(_live_from_loadout(loadout, i))
	return queue


static func _live_from_loadout(loadout: FighterLoadout, queue_index: int) -> LiveFighter:
	var fighter := LiveFighter.new()
	fighter.queue_index = queue_index
	for slot in PartSlotType.fight_order():
		var live := LivePart.new()
		live.slot = slot
		live.part = loadout.get_part(slot)
		live.value = loadout.combat_value_of(slot)
		fighter.parts.append(live)
	return fighter


static func _hp_damage(queue: Array[LiveFighter], start_index: int) -> int:
	var damage := 0
	for i in range(start_index, queue.size()):
		var fighter: LiveFighter = queue[i]
		if fighter.is_alive():
			damage += mini(MatchRules.DAMAGE_CAP_PER_FIGHTER, fighter.remaining_power())
	return damage
