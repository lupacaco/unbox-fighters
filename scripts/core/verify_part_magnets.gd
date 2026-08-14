extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var head: PartDef = load("res://data/parts/leao_head.tres")
	if head == null or head.sprite_profile == null:
		push_error("VERIFY_FAIL missing lion head")
		quit(1)
		return
	if head.uses_magnet_up() or head.is_torso():
		push_error("VERIFY_FAIL head should only use magnet_down")
		quit(1)
		return
	if head.magnet_down.y <= 0:
		push_error("VERIFY_FAIL lion head magnet should sit at the bottom")
		quit(1)
		return
	if head.texture_for_pose(1) != head.sprite_profile:
		push_error("VERIFY_FAIL pose 1 should be profile")
		quit(1)
		return

	var body: PartDef = load("res://data/parts/leao_body.tres")
	if body == null or not body.is_torso():
		push_error("VERIFY_FAIL lion body should be the torso")
		quit(1)
		return
	if body.socket_names().size() != 5:
		push_error("VERIFY_FAIL torso should have 5 magnets")
		quit(1)
		return
	if not body.uses_hub_sockets():
		push_error("VERIFY_FAIL torso magnets were not marked")
		quit(1)
		return
	print("VERIFY_PART_MAGNETS_PASS")
	quit(0)
