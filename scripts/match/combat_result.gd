class_name CombatResult
extends RefCounted

var events: Array[CombatEvent] = []
var damage_to_left: int = 0
var damage_to_right: int = 0
var winning_side: int = CombatEvent.Side.TIE
var left: BoardLoadout
var right: BoardLoadout
