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
	var belt := scene.get_node_or_null("Tray/Shelf") as Sprite2D
	if belt == null or belt.texture == null or not String(belt.texture.resource_path).ends_with("esteira-01.png"):
		push_error("VERIFY_FAIL tray should show the conveyor belt")
		quit(1)
		return
	if belt.global_position.y + belt.texture.get_size().y * belt.scale.y * 0.5 < AssemblyLayout.HEIGHT - 2.0:
		push_error("VERIFY_FAIL belt should sit on the bottom of the screen")
		quit(1)
		return
	if absf(belt.texture.get_size().x * belt.scale.x - AssemblyLayout.WIDTH) > 2.0:
		push_error("VERIFY_FAIL belt should span the full screen width")
		quit(1)
		return
	var crate_y := AssemblyLayout.crate_y()
	var sit := crate_y + AssemblyLayout.CRATE_SIT_OFFSET
	var roller_local := AssemblyLayout.belt_roller_y() - AssemblyLayout.TRAY.y
	if absf(sit - roller_local) > 1.0:
		push_error("VERIFY_FAIL crates should sit on the conveyor rollers")
		quit(1)
		return
	for child in scene.get_node("Tray").get_children():
		if child is Crate and absf((child as Crate).position.y - crate_y) > 1.0:
			push_error("VERIFY_FAIL crate Y should match the belt sit line")
			quit(1)
			return
	var sell := scene.get_node_or_null("Tray/SellZone")
	if sell == null or sell.position.x < 0.0:
		push_error("VERIFY_FAIL sell zone should sit on the right of the belt")
		quit(1)
		return
	print("VERIFY_OK slots=", slots, " crates=", crates)
	print("VERIFY_PASS")
	quit(0)
