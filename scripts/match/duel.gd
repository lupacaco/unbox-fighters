class_name Duel
extends RefCounted

## One exchange of blows between the two Freaks at the end of the belts.
##
## Only heads attack. The draw picks who swings first for the show, but both
## land their hit and the damage is applied together, so a Freak can never be
## robbed of its swing by losing the coin toss.

class Exchange extends RefCounted:
	var first_is_left: bool = true
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
	result.first_is_left = rng == null or rng.randi_range(0, 1) == 0
	result.damage_to_right = maxi(0, left.power)
	result.damage_to_left = maxi(0, right.power)
	result.left_dies = left_hp - result.damage_to_left <= 0
	result.right_dies = right_hp - result.damage_to_right <= 0
	return result

## Rounds of blows a Freak survives against a given power. Used by the bot.
static func blows_to_kill(hp: int, power: int) -> int:
	if power <= 0:
		return 9999
	return ceili(float(hp) / float(power))
