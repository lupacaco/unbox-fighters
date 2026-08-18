@tool
class_name ShopPool
extends RefCounted

## Every kit the shop can offer, read straight from data/parts/*_character.tres.
## Drop a new Freak in that folder and it shows up in the shop by itself.

const PARTS_DIR := "res://data/parts"
## Empty = every *_character.tres. Fill only to hide Freaks in a test.
const ACTIVE_SET_IDS: PackedStringArray = []

static var _all_parts: Array[PartDef] = []
static var _roster: Array[CharacterDef] = []


static func reload() -> void:
	_roster = []
	_all_parts = []
	_ensure_loaded()


static func roster() -> Array[CharacterDef]:
	_ensure_loaded()
	return _roster


static func all_parts() -> Array[PartDef]:
	_ensure_loaded()
	return _all_parts


static func character_by_id(set_id: StringName) -> CharacterDef:
	for character in roster():
		if character.id == set_id:
			return character
	return null


## Fills the shelves. Avoids showing the same kit twice while the pool allows it.
static func roll(rng: RandomNumberGenerator, count: int = MatchRules.SHOP_SLOTS) -> Array[PartDef]:
	var offers: Array[PartDef] = []
	var pool := all_parts().duplicate()
	if pool.is_empty():
		offers.resize(count)
		return offers
	var bag: Array[PartDef] = []
	for _i in count:
		if bag.is_empty():
			bag = pool.duplicate()
		var pick := rng.randi_range(0, bag.size() - 1) if rng != null else 0
		offers.append(bag[pick])
		bag.remove_at(pick)
	return offers


static func _ensure_loaded() -> void:
	if not _roster.is_empty():
		return
	_roster = []
	_all_parts = []
	var dir := DirAccess.open(PARTS_DIR)
	if dir == null:
		push_error("ShopPool missing folder: %s" % PARTS_DIR)
		return
	var names: PackedStringArray = []
	dir.list_dir_begin()
	var fname := dir.get_next()
	while fname != "":
		if not dir.current_is_dir() and fname.ends_with("_character.tres"):
			names.append(fname)
		fname = dir.get_next()
	names.sort()
	for name in names:
		var character := load("%s/%s" % [PARTS_DIR, name]) as CharacterDef
		if character == null:
			push_error("ShopPool missing character: %s" % name)
			continue
		if not ACTIVE_SET_IDS.is_empty() and String(character.id) not in ACTIVE_SET_IDS:
			continue
		_roster.append(character)
		for part in character.shop_parts():
			if part != null and part not in _all_parts:
				_all_parts.append(part)
