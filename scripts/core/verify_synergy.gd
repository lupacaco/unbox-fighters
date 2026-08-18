extends SceneTree

## Synergy: two matching kits give +25%, three give +50%, always rounding up.
## Also checks the numbers on the two Freaks that ship with the game.

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	if not _check_scaling():
		quit(1)
		return
	if not _check_card():
		quit(1)
		return
	print("VERIFY_SYNERGY_PASS")
	quit(0)

func _check_scaling() -> bool:
	if Synergy.scaled_value(8, 1) != 8:
		push_error("VERIFY_FAIL a lone kit keeps its number")
		return false
	if Synergy.scaled_value(8, 2) != 10:
		push_error("VERIFY_FAIL 8 in a pair should be 10")
		return false
	if Synergy.scaled_value(8, 3) != 12:
		push_error("VERIFY_FAIL 8 in a triple should be 12")
		return false
	if Synergy.scaled_value(15, 2) != 19 or Synergy.scaled_value(15, 3) != 23:
		push_error("VERIFY_FAIL toughness 15 should be 19 in a pair and 23 in a triple")
		return false
	if Synergy.scaled_value(2, 3) != 3:
		push_error("VERIFY_FAIL agility 2 in a triple should round up to 3")
		return false
	if Synergy.level_for(1) != Synergy.Level.NONE:
		push_error("VERIFY_FAIL one kit is not synergy")
		return false
	if Synergy.level_for(2) != Synergy.Level.PAIR or Synergy.level_for(3) != Synergy.Level.TRIPLE:
		push_error("VERIFY_FAIL synergy levels")
		return false
	return true

func _check_card() -> bool:
	var bruxa: CharacterDef = load("res://data/parts/bruxa_character.tres")
	var advogado: CharacterDef = load("res://data/parts/advogado_character.tres")
	if bruxa == null or advogado == null:
		push_error("VERIFY_FAIL missing bruxa or advogado")
		return false
	if bruxa.head.stat_value != 8 or bruxa.body.stat_value != 15 or bruxa.arms.stat_value != 2:
		push_error("VERIFY_FAIL bruxa should be 8 / 15 / 2")
		return false
	if advogado.head.stat_value != 4 or advogado.body.stat_value != 18 or advogado.arms.stat_value != 5:
		push_error("VERIFY_FAIL advogado should be 4 / 18 / 5")
		return false

	var mixed := FighterLoadout.from_parts(bruxa.head, bruxa.body, advogado.arms)
	if mixed.stat_of(PartSlotType.Value.HEAD) != 10:
		push_error("VERIFY_FAIL a pair should lift power 8 to 10")
		return false
	if mixed.stat_of(PartSlotType.Value.BODY) != 19:
		push_error("VERIFY_FAIL a pair should lift toughness 15 to 19")
		return false
	if mixed.stat_of(PartSlotType.Value.ARMS) != 5:
		push_error("VERIFY_FAIL the odd kit out keeps its own number")
		return false

	var full := FighterLoadout.from_character(bruxa).stats()
	if full.power != 12 or full.toughness != 23 or full.agility != 3:
		push_error("VERIFY_FAIL full bruxa should be 12 / 23 / 3, got %d / %d / %d" % [
			full.power, full.toughness, full.agility
		])
		return false
	if full.synergy_level != Synergy.Level.TRIPLE:
		push_error("VERIFY_FAIL a whole Freak is a triple")
		return false
	return true
