class_name Duel
extends RefCounted

## One exchange of blows between the two Freaks at the end of the belts.
##
## Only heads attack. Blows are sequential: one lands, then the other answers
## if it is still standing. A killing blow is always thrown by the winner. If
## both would die on the same hit, either may go first and both still swing.

class Exchange extends RefCounted:
	var first_is_left: bool = true
	var second_happens: bool = true
	var damage_to_left: int = 0
	var damage_to_right: int = 0
	var left_dies: bool = false
	var right_dies: bool = false

	func both_die() -> bool:
		return left_dies and right_dies

static func exchange(
	left: FreakStats,
	right: FreakStats,
	left_hp: int,
	right_hp: int,
	rng: RandomNumberGenerator
) -> Exchange:
	var result := Exchange.new()
	if left == null or right == null:
		return result
	result.damage_to_right = maxi(0, left.power)
	result.damage_to_left = maxi(0, right.power)
	var left_kills := right_hp - result.damage_to_right <= 0
	var right_kills := left_hp - result.damage_to_left <= 0
	if left_kills and right_kills:
		result.first_is_left = _coin(rng)
		result.second_happens = true
		result.left_dies = true
		result.right_dies = true
	elif left_kills:
		result.first_is_left = true
		result.second_happens = false
		result.left_dies = false
		result.right_dies = true
		result.damage_to_left = 0
	elif right_kills:
		result.first_is_left = false
		result.second_happens = false
		result.left_dies = true
		result.right_dies = false
		result.damage_to_right = 0
	else:
		result.first_is_left = _coin(rng)
		result.second_happens = true
		result.left_dies = false
		result.right_dies = false
	return result

static func _coin(rng: RandomNumberGenerator) -> bool:
	return rng == null or rng.randi_range(0, 1) == 0

## Rounds of blows a Freak survives against a given power. Used by the bot.
static func blows_to_kill(hp: int, power: int) -> int:
	if power <= 0:
		return 9999
	return ceili(float(hp) / float(power))
