class_name FreakStats
extends RefCounted

## The numbers a finished Freak takes into the fight, type bonus already applied.

var attack: int = 0
var hp: int = 0
var kind: FreakKind.Value = FreakKind.Value.HUMAN
var ability: FreakAbility.Value = FreakAbility.Value.NONE
var synergy_level: Synergy.Level = Synergy.Level.NONE
var complete_set: bool = false
var set_name: String = ""

static func from_loadout(loadout: FighterLoadout) -> FreakStats:
	var stats := FreakStats.new()
	if loadout == null:
		return stats
	var parts := loadout.parts_array()
	stats.attack = Synergy.value_for_part(loadout.head, parts)
	stats.hp = Synergy.value_for_part(loadout.body, parts)
	stats.synergy_level = Synergy.best_level(parts)
	stats.complete_set = loadout.is_complete_set()
	stats.set_name = _dominant_name(parts)
	if loadout.head != null:
		stats.kind = Synergy.kind_of(loadout.head)
	if stats.complete_set:
		var character := ShopPool.character_by_id(loadout.head.set_id)
		if character != null:
			stats.ability = character.ability
			stats.kind = character.kind
	return stats

func is_ready() -> bool:
	return attack > 0 and hp > 0

func base_of(loadout: FighterLoadout, slot: PartSlotType.Value) -> int:
	if loadout == null:
		return 0
	var part := loadout.get_part(slot)
	return part.stat_value if part != null else 0

static func _dominant_name(parts: Array) -> String:
	var tally := {}
	var best_name := ""
	var best_count := 0
	for item in parts:
		var part := item as PartDef
		if part == null or part.set_id == StringName():
			continue
		var key := String(part.set_id)
		tally[key] = int(tally.get(key, 0)) + 1
		if tally[key] > best_count:
			best_count = tally[key]
			best_name = part.display_name.get_slice(" ", 0)
	return best_name
