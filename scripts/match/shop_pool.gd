class_name ShopPool
extends RefCounted

const CHARACTER_PATHS: Array[String] = [
	"res://data/parts/vampiro_character.tres",
	"res://data/parts/policial_character.tres",
	"res://data/parts/bruxa_character.tres",
]

static var _all_parts: Array[PartDef] = []
static var _roster: Array[CharacterDef] = []


static func roster() -> Array[CharacterDef]:
	_ensure_loaded()
	return _roster


static func all_parts() -> Array[PartDef]:
	_ensure_loaded()
	return _all_parts


static func parts_up_to_tier(tier: int) -> Array[PartDef]:
	var pool: Array[PartDef] = []
	for part in all_parts():
		if part.tier <= tier:
			pool.append(part)
	return pool


static func roll(tier: int, rng: RandomNumberGenerator, count: int = MatchRules.SHOP_SLOTS) -> Array:
	var pool := parts_up_to_tier(tier)
	var offers: Array = []
	if pool.is_empty():
		for _i in count:
			offers.append(null)
		return offers
	for _i in count:
		offers.append(pool[rng.randi_range(0, pool.size() - 1)])
	return offers


static func _ensure_loaded() -> void:
	if not _roster.is_empty():
		return
	_roster = []
	_all_parts = []
	for path in CHARACTER_PATHS:
		var character := load(path) as CharacterDef
		if character == null:
			push_error("ShopPool missing character: %s" % path)
			continue
		_roster.append(character)
		for part in [character.head, character.body, character.legs]:
			if part != null:
				_all_parts.append(part)
