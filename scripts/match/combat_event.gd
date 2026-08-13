class_name CombatEvent
extends RefCounted

enum Kind { CLASH, QUEUE_ADVANCE, RESULT }

enum Side { LEFT, RIGHT, TIE }

var kind: Kind = Kind.CLASH
var clash_index: int = 0
var left_queue: int = -1
var right_queue: int = -1
var left_slot: PartSlotType.Value = PartSlotType.Value.HEAD
var right_slot: PartSlotType.Value = PartSlotType.Value.HEAD
var left_value: int = 0
var right_value: int = 0
var left_leftover: int = 0
var right_leftover: int = 0
var winning_side: int = Side.TIE
var damage_to_left: int = 0
var damage_to_right: int = 0

static func clash(
	index: int,
	left_q: int,
	right_q: int,
	left_part_slot: PartSlotType.Value,
	right_part_slot: PartSlotType.Value,
	left_v: int,
	right_v: int,
	left_remain: int,
	right_remain: int,
	who: int
) -> CombatEvent:
	var event := CombatEvent.new()
	event.kind = Kind.CLASH
	event.clash_index = index
	event.left_queue = left_q
	event.right_queue = right_q
	event.left_slot = left_part_slot
	event.right_slot = right_part_slot
	event.left_value = left_v
	event.right_value = right_v
	event.left_leftover = left_remain
	event.right_leftover = right_remain
	event.winning_side = who
	return event

static func queue_advance(index: int, left_q: int, right_q: int) -> CombatEvent:
	var event := CombatEvent.new()
	event.kind = Kind.QUEUE_ADVANCE
	event.clash_index = index
	event.left_queue = left_q
	event.right_queue = right_q
	return event

static func result(dmg_left: int, dmg_right: int, who: int) -> CombatEvent:
	var event := CombatEvent.new()
	event.kind = Kind.RESULT
	event.damage_to_left = dmg_left
	event.damage_to_right = dmg_right
	event.winning_side = who
	return event
