extends SceneTree

## Every fighter in the queue uses the same floor Y and the same scale.

const FightDir := preload("res://scripts/assembly/fight_director.gd")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var tray := Node2D.new()
	tray.position = AssemblyLayout.TRAY
	root.add_child(tray)
	var floor_y := tray.global_position.y - 148.0

	var leao: CharacterDef = load("res://data/parts/leao_character.tres")
	var ys: Array[float] = []
	var scales: Array[float] = []
	for i in 3:
		var puppet := FighterPuppet.new()
		root.add_child(puppet)
		puppet.setup_loadout(FighterLoadout.from_character(leao), false)
		puppet.global_position = Vector2(200.0 * float(i), floor_y)
		ys.append(puppet.global_position.y)
		scales.append(puppet.get_part_node(PartSlotType.Value.BODY).scale.x)

	for i in range(1, ys.size()):
		assert(is_equal_approx(ys[0], ys[i]), "Queue Y mismatch: %s vs %s" % [ys[0], ys[i]])
		assert(is_equal_approx(scales[0], scales[i]), "Scale mismatch: %s vs %s" % [scales[0], scales[i]])
		assert(is_equal_approx(scales[i], CompositeResolver.display_scale()))
	var walker := FighterPuppet.new()
	root.add_child(walker)
	walker.setup_loadout(FighterLoadout.from_character(leao), false)
	assert(walker.is_spring_pressed(), "Idle freak should keep the spring pressed")
	walker.set_pose(FighterPuppet.Pose.PROFILE)
	walker.set_stride_frame(true)
	assert(walker.hop_lift() > 8.0, "Hop should lift the freak off the ground")
	assert(not walker.is_spring_pressed(), "Airborne hop should use the loose spring")
	walker.set_pose(FighterPuppet.Pose.PROFILE)
	walker.set_attacking(PartSlotType.Value.BODY)
	assert(not is_zero_approx(walker.joint_rotation(PartSlotType.Value.ARM_R)), "Body clash should swing an arm")
	assert(FightDir.DUEL_X >= 260.0, "Fighters should stand far enough to throw kits")
	_assert_hud_fits(AssemblyLayout.FIGHT_NAME_LEFT, Vector2(280, 54))
	_assert_hud_fits(AssemblyLayout.FIGHT_HP_LEFT, Vector2(132, 78))
	_assert_hud_fits(AssemblyLayout.FIGHT_VS, Vector2(220, 52))
	print("VERIFY_FIGHT_LINE_PASS y=", ys[0], " scale=", scales[0])
	quit(0)

func _assert_hud_fits(center: Vector2, size: Vector2) -> void:
	var top := center.y - size.y * 0.5
	assert(top >= 24.0, "Fight HUD would clip the top of the screen at y=%s" % top)
