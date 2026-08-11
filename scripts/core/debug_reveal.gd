extends SceneTree
func _init():
	call_deferred("_run")
func _run():
	var packed: PackedScene = load("res://scenes/assembly/Assembly.tscn")
	var scene = packed.instantiate()
	root.add_child(scene)
	await create_timer(0.5).timeout
	var tray = scene.get_node("Tray")
	var crates = []
	for child in tray.get_children():
		if child is Crate:
			crates.append(child)
	print("CRATES=", crates.size())
	if crates.is_empty():
		quit(1); return
	var crate: Crate = crates[0]
	crate.call("_reveal_part")
	await create_timer(0.4).timeout
	var parts = []
	for child in tray.get_children():
		if child is PartView:
			parts.append(child)
	print("PARTS=", parts.size())
	if parts.is_empty():
		push_error("NO_PART_AFTER_REVEAL")
		quit(1); return
	var p: PartView = parts[0]
	print("PART_A=", p.modulate.a, " SCALE=", p.scale, " VIS=", p.visible)
	print("HAS_TEX=", p.get_node("Sprite").texture != null)
	if p.modulate.a < 0.9:
		push_error("PART_STILL_TRANSPARENT")
		quit(1); return
	print("REVEAL_OK")
	quit(0)
