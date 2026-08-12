extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var c: CharacterDef = load("res://data/parts/vampiro_character.tres")
	assert(c.head.sprite.get_size() == Vector2(300, 300))
	assert(c.body.sprite.get_size() == Vector2(300, 300))
	assert(c.legs.sprite.get_size() == Vector2(300, 300))
	var layered := CompositeResolver.resolve(c, true, false, false)
	assert(layered["mode"] == "layered")
	assert(layered["head"] != null)
	var full := CompositeResolver.resolve(c, true, true, true)
	assert(full["mode"] == "layered")
	assert(full["head"] != null and full["body"] != null and full["legs"] != null)
	print("SIZE_AND_LAYOUT_OK")
	quit(0)
