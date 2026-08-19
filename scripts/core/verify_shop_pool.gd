extends SceneTree

## The shop reads data/parts by itself: every Freak file shows up, each one sells
## two kits (head and body), and a roll fills the shop.

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
		push_error("VERIFY_FAIL shop should sell every Freak file, got %s expected %s" % [
			", ".join(ids), ", ".join(on_disk)
		])
		quit(1)
		return

	var parts := ShopPool.all_parts()
	if parts.size() != roster.size() * PartSlotType.shop_slots().size():
		push_error("VERIFY_FAIL shop should sell 2 kits per Freak, got %d" % parts.size())
		quit(1)
		return
	for part in parts:
		if not PartSlotType.is_shop_slot(part.slot_type):
			push_error("VERIFY_FAIL shop sold a drawing, not a kit: %s" % part.id)
			quit(1)
			return
		if PartStats.price_of(part) < PartStats.MIN_PRICE:
			push_error("VERIFY_FAIL no crate may be free: %s" % part.id)
			quit(1)
			return

	var body := ShopPool.character_by_id(&"bruxa").body
	var expanded := PartKit.expand_shop_part(body)
	if expanded.size() != 3 or not expanded.has(PartSlotType.Value.BODY):
		push_error("VERIFY_FAIL the body kit should open into the crate plus both arms")
		quit(1)
		return
	if not expanded.has(PartSlotType.Value.ARM_L) or not expanded.has(PartSlotType.Value.ARM_R):
		push_error("VERIFY_FAIL the body kit should bring both arms")
		quit(1)
		return

	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var offers := ShopPool.roll(rng, MatchRules.SHOP_SLOTS)
	if offers.size() != MatchRules.SHOP_SLOTS:
		push_error("VERIFY_FAIL a roll should fill %d shop slots" % MatchRules.SHOP_SLOTS)
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
