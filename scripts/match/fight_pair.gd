class_name FightPair
extends RefCounted

## One fight this round. If right_is_ghost, the right fighter is a copy:
## a win against it does not take HP from the real contestant.

var left: Contestant
var right: Contestant
var right_is_ghost: bool = false


func _init(p_left: Contestant = null, p_right: Contestant = null, p_ghost: bool = false) -> void:
	left = p_left
	right = p_right
	right_is_ghost = p_ghost
