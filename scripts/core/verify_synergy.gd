extends SceneTree

## Same-type kits give +50% (rounded up). A complete set also turns the power on.

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
	if Synergy.scaled_value(8, false) != 8:
		push_error("VERIFY_FAIL a lone kit keeps its number")
		return false
	if Synergy.scaled_value(8, true) != 12:
		push_error("VERIFY_FAIL 8 with type bonus should be 12")
		return false
	if Synergy.scaled_value(15, true) != 23:
		push_error("VERIFY_FAIL 15 with type bonus should be 23")
		return false
	if Synergy.scaled_value(4, true) != 6:
		push_error("VERIFY_FAIL 4 with type bonus should be 6")
		return false
	return true

func _check_card() -> bool:
	var bruxa: CharacterDef = load("res://data/parts/bruxa_character.tres")
	var advogado: CharacterDef = load("res://data/parts/advogado_character.tres")
	if bruxa == null or advogado == null:
		push_error("VERIFY_FAIL missing bruxa or advogado")
		return false
	if bruxa.head.stat_value != 8 or bruxa.body.stat_value != 15:
		push_error("VERIFY_FAIL bruxa should be attack 8 / HP 15")
		return false
	if advogado.head.stat_value != 4 or advogado.body.stat_value != 18:
		push_error("VERIFY_FAIL advogado should be attack 4 / HP 18")
		return false
	if bruxa.kind != FreakKind.Value.SUPERNATURAL:
		push_error("VERIFY_FAIL bruxa should be Sobrenatural")
		return false
	if advogado.kind != FreakKind.Value.HUMAN:
		push_error("VERIFY_FAIL advogado should be Humano")
		return false
	if bruxa.ability != FreakAbility.Value.MIND_CONTROL:
		push_error("VERIFY_FAIL bruxa should have Controle de Mente")
		return false
	if advogado.ability != FreakAbility.Value.APPEAL:
		push_error("VERIFY_FAIL advogado should have Recurso")
		return false

	var mixed := FighterLoadout.from_parts(bruxa.head, advogado.body)
	if mixed.stat_of(PartSlotType.Value.HEAD) != 8:
		push_error("VERIFY_FAIL mixed types keep the head's Attack")
		return false
	if mixed.stat_of(PartSlotType.Value.BODY) != 18:
		push_error("VERIFY_FAIL mixed types keep the body's HP")
		return false
	if mixed.stats().ability != FreakAbility.Value.NONE:
		push_error("VERIFY_FAIL a mixed Freak should have no power")
		return false
	if mixed.is_complete_set():
		push_error("VERIFY_FAIL mixed kits are not a complete set")
		return false
	if mixed.crate_title() != "FREAK":
		push_error("VERIFY_FAIL a mixed Freak should read FREAK on the crate")
		return false

	var full_loadout := FighterLoadout.from_character(bruxa)
	if full_loadout.crate_title() != "BRUXA":
		push_error("VERIFY_FAIL a complete Bruxa should read BRUXA on the crate")
		return false
	if CratePlaque.color_for(15, 15) != ThemeTokens.STAT_FLAT:
		push_error("VERIFY_FAIL a printed number should stay white")
		return false
	if CratePlaque.color_for(10, 15) != ThemeTokens.STAT_DOWN:
		push_error("VERIFY_FAIL a drop below the printed number should be red")
		return false
	if CratePlaque.color_for(18, 15) != ThemeTokens.STAT_UP:
		push_error("VERIFY_FAIL a bonus above the printed number should be green")
		return false

	var full := full_loadout.stats()
	if full.attack != 12 or full.hp != 23:
		push_error("VERIFY_FAIL full bruxa should be 12 / 23, got %d / %d" % [full.attack, full.hp])
		return false
	if full.synergy_level != Synergy.Level.KIND:
		push_error("VERIFY_FAIL a whole Freak of one type should get the bonus")
		return false
	if full.ability != FreakAbility.Value.MIND_CONTROL:
		push_error("VERIFY_FAIL a whole bruxa should have Controle de Mente")
		return false

	var lawyer := FighterLoadout.from_character(advogado).stats()
	if lawyer.attack != 6 or lawyer.hp != 27:
		push_error("VERIFY_FAIL full advogado should be 6 / 27, got %d / %d" % [lawyer.attack, lawyer.hp])
		return false
	if lawyer.ability != FreakAbility.Value.APPEAL:
		push_error("VERIFY_FAIL a whole advogado should have Recurso")
		return false
	return true
