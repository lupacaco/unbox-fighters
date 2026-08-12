extends SceneTree

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed: PackedScene = load("res://assets/characters/policial/3d/policial-legs-3d-walk.glb")
	if packed == null:
		push_error("VERIFY_FAIL load policial-legs-3d-walk.glb")
		quit(1)
		return
	var model := packed.instantiate()
	root.add_child(model)
	var player := _find_animation_player(model)
	if player == null:
		push_error("VERIFY_FAIL no AnimationPlayer")
		quit(1)
		return
	var names := player.get_animation_list()
	print("VERIFY_LEGS_WALK animations=", names)
	var has_walk := false
	for anim_name in names:
		if "walk" in String(anim_name).to_lower():
			has_walk = true
			break
	if not has_walk:
		push_error("VERIFY_FAIL missing walk animation")
		quit(1)
		return
	var skeleton := _find_skeleton(model)
	if skeleton == null:
		push_error("VERIFY_FAIL no Skeleton3D")
		quit(1)
		return
	if skeleton.get_bone_count() < 7:
		push_error("VERIFY_FAIL expected 7 bones, got %s" % skeleton.get_bone_count())
		quit(1)
		return
	player.play("walk")
	player.advance(0.25)
	var moved := false
	for bone_i in skeleton.get_bone_count():
		if skeleton.get_bone_pose(bone_i) != skeleton.get_bone_rest(bone_i):
			moved = true
			break
	if not moved:
		push_error("VERIFY_FAIL walk did not move bones")
		quit(1)
		return
	print("VERIFY_LEGS_WALK_PASS bones=", skeleton.get_bone_count())
	quit(0)


func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child in node.get_children():
		var found := _find_animation_player(child)
		if found != null:
			return found
	return null


func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node as Skeleton3D
	for child in node.get_children():
		var found := _find_skeleton(child)
		if found != null:
			return found
	return null
