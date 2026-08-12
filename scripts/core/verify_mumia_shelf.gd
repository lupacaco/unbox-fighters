extends SceneTree

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	for path in [
		"res://assets/characters/mumia/3d/mumia-head-rig.glb",
		"res://assets/characters/mumia/3d/mumia-body-rig.glb",
		"res://assets/characters/mumia/3d/mumia-legs-rig.glb",
	]:
		var packed: PackedScene = load(path)
		if packed == null:
			push_error("VERIFY_FAIL load %s" % path)
			quit(1)
			return
		var model := packed.instantiate()
		root.add_child(model)
		var player := _find_animation_player(model)
		if player == null:
			push_error("VERIFY_FAIL no AnimationPlayer in %s" % path)
			quit(1)
			return
		for clip in ["idle", "walk", "punch", "kick", "jump", "look"]:
			if not player.has_animation(clip):
				push_error("VERIFY_FAIL %s missing %s" % [path, clip])
				quit(1)
				return
		player.play("walk")
		player.advance(0.2)
		print("VERIFY_MUMIA part ok ", path, " anims=", player.get_animation_list())

	var scene_packed: PackedScene = load("res://scenes/preview/MumiaShelfPreview.tscn")
	if scene_packed == null:
		push_error("VERIFY_FAIL load MumiaShelfPreview.tscn")
		quit(1)
		return
	var scene := scene_packed.instantiate()
	root.add_child(scene)
	await create_timer(0.4).timeout
	if scene.get_node_or_null("HUD/StartButton") == null:
		push_error("VERIFY_FAIL missing INICIAR button")
		quit(1)
		return
	if scene.get_node_or_null("Tray/Shelf") == null:
		push_error("VERIFY_FAIL missing shelf")
		quit(1)
		return
	print("VERIFY_MUMIA_SHELF_PASS")
	quit(0)


func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child in node.get_children():
		var found := _find_animation_player(child)
		if found != null:
			return found
	return null
