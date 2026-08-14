extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	ShopPool.reload()
	var on_disk := _character_ids_on_disk()
	if on_disk.is_empty():
		push_error("VERIFY_FAIL no *_character.tres in data/parts")
		quit(1)
		return
	var roster := ShopPool.roster()
	var ids: PackedStringArray = []
	for character in roster:
		ids.append(String(character.id))
	ids.sort()
	if ids != on_disk:
		push_error("VERIFY_FAIL shop should sell every Freak file, got %s expected %s" % [", ".join(ids), ", ".join(on_disk)])
		quit(1)
		return

	var tier1 := ShopPool.parts_up_to_tier(1)
	if tier1.is_empty():
		push_error("VERIFY_FAIL shop level 1 should sell kits")
		quit(1)
		return
	for part in tier1:
		if not PartSlotType.is_shop_slot(part.slot_type):
			push_error("VERIFY_FAIL shop sold a visual limb: %s" % part.id)
			quit(1)
			return
		if String(part.set_id) == "medico" and part.slot_type == PartSlotType.Value.BODY:
			push_error("VERIFY_FAIL doctor torso is shop level 2")
			quit(1)
			return

	var high := ShopPool.parts_up_to_tier(5)
	if high.size() != roster.size() * 2:
		push_error("VERIFY_FAIL shop should sell 2 kits per Freak, got %d" % high.size())
		quit(1)
		return
	var body: PartDef = load("res://data/parts/medico_body.tres")
	if body == null or body.combat_value != 6 or body.tier != 2:
		push_error("VERIFY_FAIL doctor torso should be 6 (shop level 2)")
		quit(1)
		return

	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var offers := ShopPool.roll(1, rng)
	if offers.size() != MatchRules.SHOP_SLOTS:
		push_error("VERIFY_FAIL shop should roll 5")
		quit(1)
		return
	print("VERIFY_SHOP_POOL_PASS")
	quit(0)

func _character_ids_on_disk() -> PackedStringArray:
	var ids: PackedStringArray = []
	var dir := DirAccess.open("res://data/parts")
	if dir == null:
		return ids
	dir.list_dir_begin()
	var fname := dir.get_next()
	while fname != "":
		if not dir.current_is_dir() and fname.ends_with("_character.tres"):
			var character := load("res://data/parts/%s" % fname) as CharacterDef
			if character != null and not String(character.id).is_empty():
				ids.append(String(character.id))
		fname = dir.get_next()
	ids.sort()
	return ids
