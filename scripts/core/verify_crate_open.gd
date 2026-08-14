extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed: PackedScene = load("res://scenes/assembly/Assembly.tscn")
	var scene := packed.instantiate()
	root.add_child(scene)
	await create_timer(0.5).timeout

	var crate: Crate = null
	for child in scene.get_node("Tray").get_children():
		if child is Crate:
			crate = child
			break
	if crate == null:
		push_error("VERIFY_FAIL no crate")
		quit(1)
		return

	var intact: Texture2D = load("res://assets/boxes/box-01.png")
	var smashed: Texture2D = load("res://assets/boxes/box-02.png")
	var sprite: Sprite2D = crate.get_node("Sprite")

	if sprite.texture != intact:
		push_error("VERIFY_FAIL expected box-01 at start")
		quit(1)
		return

	crate.call("_on_clicked")
	await create_timer(0.05).timeout
	if not is_instance_valid(crate):
		push_error("VERIFY_FAIL crate vanished too fast")
		quit(1)
		return
	if sprite.texture != smashed:
		push_error("VERIFY_FAIL expected box-02 after one click")
		quit(1)
		return

	await create_timer(0.8).timeout
	var parts := 0
	for child in scene.get_node("Tray").get_children():
		if child is PartView:
			parts += 1
	if parts < 1:
		push_error("VERIFY_FAIL part not revealed after one smash")
		quit(1)
		return

	print("VERIFY_CRATE_OPEN_PASS")
	quit(0)
