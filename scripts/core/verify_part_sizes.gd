extends SceneTree

const EXPECTED := Vector2(300, 200)

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var scale := CompositeResolver.display_scale()
	assert(is_equal_approx(scale, CompositeResolver.PART_SIZE_PX / CompositeResolver.PART_WIDTH_PX))
	for path in [
		"res://data/parts/vampiro_character.tres",
		"res://data/parts/policial_character.tres",
		"res://data/parts/bruxa_character.tres",
		"res://data/parts/mumia_character.tres",
		"res://data/parts/medico_character.tres",
		"res://data/parts/cachorro_character.tres",
	]:
		var c: CharacterDef = load(path)
		assert(c != null, "Missing character: %s" % path)
		for part in [c.head, c.body, c.legs]:
			_assert_part_art(part, path)
		assert(c.can_fight(), "Missing fight poses: %s" % path)
		var layered := CompositeResolver.resolve(c, true, false, false)
		assert(layered["mode"] == "layered")
		assert(layered["head"] != null)
		var full := CompositeResolver.resolve(c, true, true, true)
		assert(full["mode"] == "layered")
		assert(full["head"] != null and full["body"] != null and full["legs"] != null)
	print("SIZE_AND_LAYOUT_OK")
	quit(0)

func _assert_part_art(part: PartDef, owner_path: String) -> void:
	assert(part != null, "Missing part on %s" % owner_path)
	for tex in [part.sprite, part.sprite_profile, part.sprite_attack]:
		assert(tex != null, "Missing pose texture on %s" % part.id)
		assert(tex.get_size() == EXPECTED, "%s size %s expected %s" % [part.id, tex.get_size(), EXPECTED])
	assert(is_equal_approx(CompositeResolver.display_scale(part.sprite), CompositeResolver.display_scale()))
