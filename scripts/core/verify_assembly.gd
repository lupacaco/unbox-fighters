extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed: PackedScene = load("res://scenes/assembly/Assembly.tscn")
	if packed == null:
		push_error("VERIFY_FAIL load Assembly.tscn")
		quit(1)
		return
	var scene := packed.instantiate()
	root.add_child(scene)
	await create_timer(0.45).timeout
	var slots := scene.get_node("Slots").get_child_count()
	if slots != 3:
		push_error("VERIFY_FAIL expected 3 slots")
		quit(1)
		return
	var crates := 0
	for child in scene.get_node("Tray").get_children():
		if child is Crate:
			crates += 1
	if crates != MatchRules.SHOP_SLOTS:
		push_error("VERIFY_FAIL expected 5 shop crates, got %d" % crates)
		quit(1)
		return
	print("VERIFY_OK slots=", slots, " crates=", crates)
	print("VERIFY_PASS")
	quit(0)
