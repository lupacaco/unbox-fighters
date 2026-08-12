class_name FightDirector3D
extends FightDirector

## Same LUTAR showcase as 2D. Profile is a 3D turn; attacks throw the 3D part.

func play(
	slot: CharacterSlot,
	tray: Node2D,
	fx_layer: Node2D,
	drag_service: DragDropService
) -> void:
	if _busy or slot == null or not slot.attached_parts_can_fight():
		return
	_busy = true
	if drag_service != null and drag_service.has_method("set_locked"):
		drag_service.set_locked(true)

	var head := slot.get_attached_part(PartSlotType.Value.HEAD)
	var body := slot.get_attached_part(PartSlotType.Value.BODY)
	var legs := slot.get_attached_part(PartSlotType.Value.LEGS)

	slot.set_fight_locked(true)
	slot.set_fighter_visible(false)

	await _clear_shelf(tray)

	var puppet := FighterPuppet3D.new()
	fx_layer.add_child(puppet)
	puppet.setup_parts(head, body, legs)
	puppet.global_position = slot.get_fighter_global_position()
	puppet.modulate.a = 1.0
	puppet.scale = Vector2.ONE

	var left_pos := tray.global_position + Vector2(SHELF_LEFT_X, SHELF_Y)
	var mid_pos := tray.global_position + Vector2(SHELF_MID_X, SHELF_Y)
	var peak := Vector2(
		lerpf(puppet.global_position.x, left_pos.x, 0.5),
		minf(puppet.global_position.y, left_pos.y) - 220.0
	)

	var leap := create_tween()
	leap.tween_property(puppet, "global_position", peak, JUMP_UP_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	leap.tween_property(puppet, "global_position", left_pos, JUMP_DOWN_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await leap.finished
	await _land_impact_3d(puppet, tray)
	await get_tree().create_timer(HOLD_AFTER_LAND_SEC).timeout

	var turn := create_tween()
	turn.tween_method(
		func(t: float) -> void:
			_blend_to_profile(puppet, t),
		0.0,
		1.0,
		0.28
	).set_trans(Tween.TRANS_SINE)
	await turn.finished
	puppet.set_pose(FighterPuppet.Pose.PROFILE)
	await get_tree().create_timer(HOLD_PROFILE_SEC).timeout
	await _walk_to_center_3d(puppet, left_pos, mid_pos)

	puppet.set_pose(FighterPuppet.Pose.PROFILE)
	await get_tree().create_timer(HOLD_BEFORE_ATTACK_SEC).timeout

	for part_slot in [PartSlotType.Value.HEAD, PartSlotType.Value.BODY, PartSlotType.Value.LEGS]:
		await _boomerang_part_3d(puppet, part_slot)

	var return_target := slot.get_fighter_global_position()
	var return_peak := Vector2(
		lerpf(puppet.global_position.x, return_target.x, 0.5),
		minf(puppet.global_position.y, return_target.y) - 220.0
	)
	puppet.set_pose(FighterPuppet.Pose.FRONT)
	var back := create_tween()
	back.tween_property(puppet, "global_position", return_peak, RETURN_JUMP_UP).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	back.tween_property(puppet, "global_position", return_target, RETURN_JUMP_DOWN).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await back.finished

	puppet.queue_free()
	slot.set_fighter_visible(true)
	slot.set_fight_locked(false)
	if drag_service != null and drag_service.has_method("set_locked"):
		drag_service.set_locked(false)
	_busy = false
	finished.emit()

func _blend_to_profile(puppet: FighterPuppet3D, t: float) -> void:
	if t >= 0.5:
		puppet.set_pose(FighterPuppet.Pose.PROFILE)

func _walk_to_center_3d(puppet: FighterPuppet3D, from_pos: Vector2, to_pos: Vector2) -> void:
	for i in WALK_STEPS:
		var t := float(i + 1) / float(WALK_STEPS)
		var next_pos := from_pos.lerp(to_pos, t)
		puppet.set_stride_frame((i % 2) == 0)
		var bob := next_pos + Vector2(0.0, -10.0 if (i % 2) == 0 else 0.0)
		var step := create_tween()
		step.tween_property(puppet, "global_position", bob, WALK_STEP_DURATION * 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		step.tween_property(puppet, "global_position", next_pos, WALK_STEP_DURATION * 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		await step.finished
	puppet.set_pose(FighterPuppet.Pose.PROFILE)
	puppet.global_position = to_pos

func _land_impact_3d(puppet: FighterPuppet3D, tray: Node2D) -> void:
	GameAudio.fighter_complete()
	var squash := create_tween()
	squash.tween_property(puppet, "scale", Vector2(1.18, 0.72), 0.06).set_trans(Tween.TRANS_QUAD)
	squash.tween_property(puppet, "scale", Vector2(0.94, 1.1), 0.08)
	squash.tween_property(puppet, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_SINE)
	var shelf_origin := tray.position
	var shake := create_tween()
	shake.tween_property(tray, "position", shelf_origin + Vector2(0, 10), 0.05)
	shake.tween_property(tray, "position", shelf_origin + Vector2(0, -6), 0.05)
	shake.tween_property(tray, "position", shelf_origin + Vector2(0, 4), 0.05)
	shake.tween_property(tray, "position", shelf_origin, 0.08)
	await squash.finished

func _boomerang_part_3d(puppet: FighterPuppet3D, slot: PartSlotType.Value) -> void:
	puppet.set_attacking(slot)
	var part_node := puppet.get_part_node(slot)
	var home := part_node.position
	var out := home + Vector2(BOOMERANG_DIST, -18.0)
	GameAudio.part_pickup()
	var tween := create_tween()
	tween.tween_property(part_node, "position", out, BOOMERANG_OUT).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(part_node, "position", home, BOOMERANG_BACK).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	await tween.finished
	GameAudio.part_place()
	puppet.set_attacking(null)
	puppet.set_pose(FighterPuppet.Pose.PROFILE)
