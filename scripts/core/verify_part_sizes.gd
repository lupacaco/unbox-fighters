extends SceneTree

const EXPECTED := Vector2(200, 200)

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var scale := CompositeResolver.display_scale()
	assert(is_equal_approx(scale, CompositeResolver.PART_SIZE_PX / CompositeResolver.PART_WIDTH_PX))
	assert(is_equal_approx(scale, 1.0))
	var vampiro: CharacterDef = load("res://data/parts/vampiro_character.tres")
	assert(vampiro != null, "Missing vampire")
	for part in vampiro.visual_parts():
		_assert_part_art(part)
	assert(vampiro.can_fight(), "Vampire needs a side view on every drawing")
	assert(vampiro.shop_parts().size() == 4)
	assert(vampiro.head.combat_value == 3)
	assert(vampiro.body.combat_value == 4)
	assert(vampiro.legs.combat_value == 3)
	var bruxa: CharacterDef = load("res://data/parts/bruxa_character.tres")
	assert(bruxa != null, "Missing witch")
	for part in bruxa.visual_parts():
		_assert_part_art(part)
	assert(bruxa.can_fight(), "Witch needs a side view on every drawing")
	assert(bruxa.shop_parts().size() == 4)
	var full := CompositeResolver.resolve(vampiro)
	assert(full["mode"] == "layered")
	var textures: Dictionary = full["textures"]
	var positions: Dictionary = full["positions"]
	for slot in PartSlotType.visual_slots():
		if slot == PartSlotType.Value.LEG_L or slot == PartSlotType.Value.LEG_R:
			continue
		assert(textures.get(slot) != null, "Missing texture %s" % slot)
		assert(positions.has(slot), "Missing position %s" % slot)
	assert(full.get("spring_texture") != null)
	assert(positions[PartSlotType.Value.HEAD].y < positions[PartSlotType.Value.BODY].y)
	assert(float(full["spring_pos"].y) > positions[PartSlotType.Value.BODY].y)
	var witch := CompositeResolver.resolve(bruxa)
	var witch_pos: Dictionary = witch["positions"]
	assert(witch_pos[PartSlotType.Value.HEAD].y < witch_pos[PartSlotType.Value.BODY].y)
	print("SIZE_AND_LAYOUT_OK")
	quit(0)

func _assert_part_art(part: PartDef) -> void:
	assert(part != null, "Missing part")
	assert(part.sprite != null, "Missing front on %s" % part.id)
	assert(part.sprite_profile != null, "Missing profile on %s" % part.id)
	assert(part.sprite.get_size() == EXPECTED, "%s front size %s" % [part.id, part.sprite.get_size()])
	assert(part.sprite_profile.get_size() == EXPECTED, "%s profile size %s" % [part.id, part.sprite_profile.get_size()])
	if part.sprite_attack != null:
		assert(part.sprite_attack.get_size() == EXPECTED, "%s attack size %s" % [part.id, part.sprite_attack.get_size()])
