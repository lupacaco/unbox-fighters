class_name BoardLoadout
extends RefCounted

## Three cards in fight order: index 0 fights first (the "1º").

var fighters: Array[FighterLoadout] = []

func _init() -> void:
	fighters.clear()
	for _i in MatchRules.QUEUE_SIZE:
		fighters.append(FighterLoadout.new())

func fighter_at(index: int) -> FighterLoadout:
	if index < 0 or index >= fighters.size():
		return null
	return fighters[index]

func duplicate_board() -> BoardLoadout:
	var copy := BoardLoadout.new()
	for i in fighters.size():
		copy.fighters[i] = fighters[i].duplicate_loadout()
	return copy
