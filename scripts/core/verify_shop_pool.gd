extends SceneTree

## The shop reads data/parts by itself: every Freak file shows up, each one sells
## three kits (head, torso, arm pair), and a roll fills the four shelves.

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
		push_error("VERIFY_FAIL shop should sell 3 kits per Freak, got %d" % parts.size())
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

	var arms := ShopPool.character_by_id(&"bruxa").arms
	if arms == null or not arms.is_bundle() or PartKit.expand_shop_part(arms).size() != 2:
		push_error("VERIFY_FAIL the arm kit should open into two arms")
		quit(1)
		return

	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var offers := ShopPool.roll(rng, MatchRules.SHOP_SLOTS)
	if offers.size() != MatchRules.SHOP_SLOTS:
		push_error("VERIFY_FAIL a roll should fill %d shelves" % MatchRules.SHOP_SLOTS)
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
