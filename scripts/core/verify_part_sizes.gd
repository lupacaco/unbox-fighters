extends SceneTree

## Every drawing is a 200x200 PNG with a front and a side view, and every Freak
## on disk sells exactly two crates with numbers inside the allowed range.

const EXPECTED := Vector2(200, 200)

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var scale := CompositeResolver.display_scale()
	assert(is_equal_approx(scale, 1.0), "Parts are drawn at their own size")
	ShopPool.reload()
	var roster := ShopPool.roster()
	assert(not roster.is_empty(), "No Freaks in data/parts")
	for character in roster:
		_check_character(character)
	print("SIZE_AND_LAYOUT_OK")
	quit(0)

func _check_character(character: CharacterDef) -> void:
	var who := String(character.id)
	assert(character.can_fight(), "%s needs a side view on every drawing" % who)
	assert(
		character.shop_parts().size() == PartSlotType.shop_slots().size(),
		"%s should sell head and body" % who
	)
	for part in character.visual_parts():
		_check_art(part)
	for part in character.shop_parts():
		var span := PartStats.range_of(part.slot_type)
		assert(
			part.stat_value >= span.x and part.stat_value <= span.y,
			"%s is outside %d..%d" % [part.id, span.x, span.y]
		)
		assert(PartStats.price_of(part) >= PartStats.MIN_PRICE, "%s would be free" % part.id)

	var plan := CompositeResolver.resolve(character)
	var textures: Dictionary = plan["textures"]
	var positions: Dictionary = plan["positions"]
	for slot in PartSlotType.visual_slots():
		assert(textures.get(slot) != null, "%s missing drawing for %s" % [who, slot])
		assert(positions.has(slot), "%s missing spot for %s" % [who, slot])
	assert(
		positions[PartSlotType.Value.HEAD].y < positions[PartSlotType.Value.BODY].y,
		"%s head should sit above the torso" % who
	)
	assert(
		positions[PartSlotType.Value.BODY].y < 0.0,
		"%s torso should sit above the crate floor" % who
	)

func _check_art(part: PartDef) -> void:
	assert(part != null, "Missing part")
	assert(part.sprite != null, "Missing front on %s" % part.id)
	assert(part.sprite_profile != null, "Missing profile on %s" % part.id)
	assert(part.sprite.get_size() == EXPECTED, "%s front size %s" % [part.id, part.sprite.get_size()])
	assert(
		part.sprite_profile.get_size() == EXPECTED,
		"%s profile size %s" % [part.id, part.sprite_profile.get_size()]
	)
	if part.sprite_attack != null:
		assert(
			part.sprite_attack.get_size() == EXPECTED,
			"%s attack size %s" % [part.id, part.sprite_attack.get_size()]
		)
