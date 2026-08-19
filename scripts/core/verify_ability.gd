extends SceneTree

## Recurso keeps a Freak at 1 HP once. Controle de Mente sends the next blow
## at an ally on the same belt, and only spends the charge if that happens.

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	if not _check_appeal():
		quit(1)
		return
	if not _check_mind_control():
		quit(1)
		return
	if not _check_mind_control_without_ally():
		quit(1)
		return
	print("VERIFY_ABILITY_PASS")
	quit(0)

func _check_appeal() -> bool:
	var live := LiveMatch.new()
	live.start()
	live.enter_fight()
	var mine := live.launch(live.player, _loadout(&"bruxa"))
	var theirs := live.launch(live.opponent, _loadout(&"advogado"))
	if mine == null or theirs == null:
		push_error("VERIFY_FAIL both sides should launch")
		return false
	theirs.hp = 5
	if live.apply_hit(live.opponent, theirs, 12):
		push_error("VERIFY_FAIL Recurso should stop the first lethal hit")
		return false
	if not theirs.alive or theirs.hp != 1:
		push_error("VERIFY_FAIL Recurso should leave the Advogado at 1 HP, got alive=%s hp=%d" % [
			str(theirs.alive), theirs.hp
		])
		return false
	if not theirs.appeal_used:
		push_error("VERIFY_FAIL Recurso should be spent after that save")
		return false
	if not live.apply_hit(live.opponent, theirs, 12):
		push_error("VERIFY_FAIL Recurso only works once")
		return false
	return true

func _check_mind_control() -> bool:
	var live := LiveMatch.new()
	live.start()
	live.enter_fight()
	var witch := live.launch(live.player, _loadout(&"bruxa"))
	var lead := live.launch(live.opponent, _loadout(&"advogado"))
	var ally := live.launch(live.opponent, _loadout(&"advogado"))
	if witch == null or lead == null or ally == null:
		push_error("VERIFY_FAIL need a witch plus two on the other belt")
		return false
	lead.hp = 40
	ally.hp = 8
	lead.appeal_used = true
	ally.appeal_used = true
	live.apply_blow(witch, lead, live.player, live.opponent)
	if not lead.redirect_next:
		push_error("VERIFY_FAIL a witch hit should mark the enemy when an ally is waiting")
		return false
	if not witch.mc_available:
		push_error("VERIFY_FAIL the charge should wait until the redirect happens")
		return false
	var ally_hp_before := ally.hp
	var witch_hp := witch.hp
	live.apply_blow(lead, witch, live.opponent, live.player)
	if ally.hp >= ally_hp_before:
		push_error("VERIFY_FAIL the marked Freak should hit its ally, ally hp %d -> %d" % [
			ally_hp_before, ally.hp
		])
		return false
	if witch.hp != witch_hp:
		push_error("VERIFY_FAIL the redirected blow should not hit the witch")
		return false
	if witch.mc_available:
		push_error("VERIFY_FAIL Controle de Mente should spend the charge after a redirect")
		return false
	return true

func _check_mind_control_without_ally() -> bool:
	var live := LiveMatch.new()
	live.start()
	live.enter_fight()
	var witch := live.launch(live.player, _loadout(&"bruxa"))
	var lead := live.launch(live.opponent, _loadout(&"advogado"))
	if witch == null or lead == null:
		push_error("VERIFY_FAIL need one Freak on each belt")
		return false
	lead.hp = 40
	lead.appeal_used = true
	live.apply_blow(witch, lead, live.player, live.opponent)
	if lead.redirect_next:
		push_error("VERIFY_FAIL no ally means the mark should not land")
		return false
	if not witch.mc_available:
		push_error("VERIFY_FAIL Controle de Mente should stay ready when nothing happened")
		return false
	return true

func _loadout(set_id: StringName) -> FighterLoadout:
	return FighterLoadout.from_character(ShopPool.character_by_id(set_id))
