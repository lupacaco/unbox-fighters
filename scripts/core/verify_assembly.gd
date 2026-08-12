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
	await create_timer(0.35).timeout
	var slots := scene.get_node("Slots").get_child_count()
	var tray_children := scene.get_node("Tray").get_child_count()
	print("VERIFY_OK slots=", slots, " tray_nodes=", tray_children)
	if slots != 3:
		push_error("VERIFY_FAIL expected 3 slots")
		quit(1)
		return
	# Shelf + 9 crates (vampiro + policial + bruxa)
	if tray_children < 10:
		push_error("VERIFY_FAIL expected platform + 9 crates")
		quit(1)
		return
	print("VERIFY_PASS")
	quit(0)
