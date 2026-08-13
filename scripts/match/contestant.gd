class_name Contestant
extends RefCounted

var id: StringName
var display_name: String = ""
var is_bot: bool = false
var hp: int = MatchRules.STARTING_HP
var gold: int = 0
var shop_tier: int = 1
var frozen: bool = false
var board: BoardLoadout = BoardLoadout.new()
var shop_offers: Array = []
var last_opponent_id: StringName = &""

func is_alive() -> bool:
	return hp > 0

func reset_shop_slots() -> void:
	shop_offers.clear()
	for _i in MatchRules.SHOP_SLOTS:
		shop_offers.append(null)
