class_name FightDirector3D
extends Node

## Mesma coreografia do FightDirector 2D, com giro 3D e ataque lançando a parte 3D.

signal finished

const CLEAR_DURATION := 0.45
const JUMP_UP_DURATION := 0.28
const JUMP_DOWN_DURATION := 0.34
const HOLD_AFTER_LAND_SEC := 0.35
const HOLD_PROFILE_SEC := 0.35
const WALK_STEPS := 5
const WALK_STEP_DURATION := 0.22
const HOLD_BEFORE_ATTACK_SEC := 0.45
const BOOMERANG_OUT := 0.28
const BOOMERANG_BACK := 0.34
const BOOMERANG_DIST_3D := 1.35
const RETURN_JUMP_UP := 0.26
const RETURN_JUMP_DOWN := 0.32
const SHELF_Y := -150.0
const SHELF_LEFT_X := -520.0
const SHELF_MID_X := 0.0
const TURN_DURATION := 0.28

var _busy: bool = false

func is_busy() -> bool:
	return _busy

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

	# Salto para a ESQUERDA do shelf (ainda de frente).
	var leap := create_tween()
	leap.tween_property(puppet, "global_position", peak, JUMP_UP_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	leap.tween_property(puppet, "global_position", left_pos, JUMP_DOWN_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await leap.finished
	await _land_impact(puppet, tray)
	await get_tree().create_timer(HOLD_AFTER_LAND_SEC).timeout

	# Gira em 3D para o perfil (em vez de trocar sprite).
	var turn := create_tween()
	turn.tween_method(func(yaw: float): puppet.set_yaw(yaw), 0.0, -PI * 0.5, TURN_DURATION).set_trans(Tween.TRANS_SINE)
	await turn.finished
	await get_tree().create_timer(HOLD_PROFILE_SEC).timeout

	await _walk_to_center(puppet, left_pos, mid_pos)
	puppet.set_pose_profile()
	await get_tree().create_timer(HOLD_BEFORE_ATTACK_SEC).timeout

	for part_slot in [PartSlotType.Value.HEAD, PartSlotType.Value.BODY, PartSlotType.Value.LEGS]:
		await _boomerang_part(puppet, part_slot)

	# Volta de frente e salta para a carta.
	var face := create_tween()
	face.tween_method(func(yaw: float): puppet.set_yaw(yaw), puppet.get_yaw(), 0.0, 0.2)
	await face.finished

	var return_target := slot.get_fighter_global_position()
	var return_peak := Vector2(
		lerpf(puppet.global_position.x, return_target.x, 0.5),
		minf(puppet.global_position.y, return_target.y) - 220.0
	)
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

func _walk_to_center(puppet: FighterPuppet3D, from_pos: Vector2, to_pos: Vector2) -> void:
	for i in WALK_STEPS:
		var t := float(i + 1) / float(WALK_STEPS)
		var next_pos := from_pos.lerp(to_pos, t)
		puppet.set_stride_frame((i % 2) == 0)
		var bob := next_pos + Vector2(0.0, -10.0 if (i % 2) == 0 else 0.0)
		var step := create_tween()
		step.tween_property(puppet, "global_position", bob, WALK_STEP_DURATION * 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		step.tween_property(puppet, "global_position", next_pos, WALK_STEP_DURATION * 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		await step.finished
	puppet.reset_lean_safe()
	puppet.global_position = to_pos

func _clear_shelf(tray: Node2D) -> void:
	var fleeing: Array[Node2D] = []
	for child in tray.get_children():
		if child is Crate:
			fleeing.append(child as Node2D)
		elif child is PartView:
			var part_view := child as PartView
			if part_view.is_attached():
				continue
			fleeing.append(part_view)
	if fleeing.is_empty():
		return

	var tween := create_tween()
	tween.set_parallel(true)
	for i in fleeing.size():
		var node := fleeing[i]
		var side := 1.0 if (i % 2) == 0 else -1.0
		var target := node.global_position + Vector2(side * 1400.0, -40.0)
		tween.tween_property(node, "global_position", target, CLEAR_DURATION).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		tween.tween_property(node, "modulate:a", 0.0, CLEAR_DURATION).set_trans(Tween.TRANS_SINE)
		tween.tween_property(node, "rotation", side * 0.55, CLEAR_DURATION)
	await tween.finished
	for node in fleeing:
		if is_instance_valid(node):
			node.queue_free()

func _land_impact(puppet: FighterPuppet3D, tray: Node2D) -> void:
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

func _boomerang_part(puppet: FighterPuppet3D, slot: PartSlotType.Value) -> void:
	var part_node := puppet.get_part_node(slot)
	if part_node == null:
		return
	var home := part_node.position
	# Em perfil (yaw -90°), +X local do slot empurra a peça “para frente” na tela.
	var outward := home + Vector3(BOOMERANG_DIST_3D, 0.06, 0.0)
	GameAudio.part_pickup()
	var tween := create_tween()
	tween.tween_property(part_node, "position", outward, BOOMERANG_OUT).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(part_node, "position", home, BOOMERANG_BACK).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	await tween.finished
	GameAudio.part_place()
