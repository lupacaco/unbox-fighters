extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var c: CharacterDef = load("res://data/parts/vampiro_character.tres")
	var only_head := CompositeResolver.resolve(c, true, false, false)
	var head_body := CompositeResolver.resolve(c, true, true, false)
	var full := CompositeResolver.resolve(c, true, true, true)

	if only_head["mode"] != "layered" or only_head["head"] == null:
		push_error("VERIFY_FAIL head-only should be layered with head texture")
		quit(1)
		return
	if head_body["body"] == null or head_body["head"] == null:
		push_error("VERIFY_FAIL head+body missing textures")
		quit(1)
		return
	if full["legs"] == null:
		push_error("VERIFY_FAIL full set missing legs")
		quit(1)
		return

	# Magnets should pull head above body (smaller Y) and legs below body (larger Y).
	if not (full["head_pos"].y < full["body_pos"].y and full["legs_pos"].y > full["body_pos"].y):
		push_error("VERIFY_FAIL magnet layout order wrong: %s / %s / %s" % [full["head_pos"], full["body_pos"], full["legs_pos"]])
		quit(1)
		return

	print("VERIFY_COMPOSITE_PASS head=", full["head_pos"], " body=", full["body_pos"], " legs=", full["legs_pos"])
	quit(0)
