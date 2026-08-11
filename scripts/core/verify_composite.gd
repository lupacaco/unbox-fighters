extends SceneTree
func _init():
	call_deferred("_run")
func _run():
	var c: CharacterDef = load("res://data/parts/vampiro_character.tres")
	var t1 = CompositeResolver.resolve(c, true, false, false)
	var t2 = CompositeResolver.resolve(c, true, true, false)
	var t3 = CompositeResolver.resolve(c, true, true, true)
	print("COMPOSITE_HEAD=", t1.size(), " BODYHEAD=", t2.size(), " FULL=", t3.size())
	print("FULL_MATCH=", t3[0] == c.full_sprite)
	print("BODYHEAD_MATCH=", t2[0] == c.body_head_sprite)
	quit(0)
