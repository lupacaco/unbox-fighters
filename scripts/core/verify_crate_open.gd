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
	var cracked: Texture2D = load("res://assets/boxes/box-02.png")
	var broken: Texture2D = load("res://assets/boxes/box-03.png")
	var sprite: Sprite2D = crate.get_node("Sprite")

	if sprite.texture != intact:
		push_error("VERIFY_FAIL expected box-01 at start")
		quit(1)
		return

	crate.call("_on_clicked")
	await create_timer(0.05).timeout
	if sprite.texture != cracked:
		push_error("VERIFY_FAIL expected box-02 after first click")
		quit(1)
		return
	if crate.get("_hits") != 1:
		push_error("VERIFY_FAIL hits should be 1")
		quit(1)
		return

	crate.call("_on_clicked")
	await create_timer(0.05).timeout
	if sprite.texture != broken:
		push_error("VERIFY_FAIL expected box-03 after second click")
		quit(1)
		return

	await create_timer(1.2).timeout
	var parts := 0
	for child in scene.get_node("Tray").get_children():
		if child is PartView:
			parts += 1
	if parts < 1:
		push_error("VERIFY_FAIL part not revealed after open")
		quit(1)
		return

	print("VERIFY_CRATE_OPEN_PASS")
	quit(0)
