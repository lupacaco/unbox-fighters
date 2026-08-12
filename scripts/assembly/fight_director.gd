class_name FightDirector
extends Node

## Plays the temporary solo fight showcase on the shelf.

signal finished

const CLEAR_DURATION := 0.45
const JUMP_UP_DURATION := 0.28
const JUMP_DOWN_DURATION := 0.34
const HOLD_FRONT_SEC := 2.0
const HOLD_PROFILE_SEC := 2.0
const BOOMERANG_OUT := 0.28
const BOOMERANG_BACK := 0.34
const BOOMERANG_DIST := 320.0
const RETURN_JUMP_UP := 0.26
const RETURN_JUMP_DOWN := 0.32

var _busy: bool = false

func is_busy() -> bool:
	return _busy

func play(
	slot: CharacterSlot,
	tray: Node2D,
	fx_layer: Node2D,
	drag_service: DragDropService
) -> void:
	if _busy or slot == null or not slot.is_complete() or not slot.character.can_fight():
		return
	_busy = true
	if drag_service != null and drag_service.has_method("set_locked"):
		drag_service.set_locked(true)
	slot.set_fight_locked(true)
	slot.set_fighter_visible(false)

	await _clear_shelf(tray)

	var puppet := FighterPuppet.new()
	fx_layer.add_child(puppet)
	puppet.setup(slot.character)
	puppet.global_position = slot.get_fighter_global_position()
	puppet.modulate.a = 1.0
	puppet.scale = Vector2.ONE

	var land_pos := tray.global_position + Vector2(0.0, -150.0)
	var peak := Vector2(
		lerpf(puppet.global_position.x, land_pos.x, 0.5),
		minf(puppet.global_position.y, land_pos.y) - 220.0
	)

	# Leap onto the shelf (front pose).
	var leap := create_tween()
	leap.set_parallel(false)
	leap.tween_property(puppet, "global_position", peak, JUMP_UP_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	leap.tween_property(puppet, "global_position", land_pos, JUMP_DOWN_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await leap.finished
	await _land_impact(puppet, tray)

	await get_tree().create_timer(HOLD_FRONT_SEC).timeout

	# Turn to profile.
	puppet.set_pose(FighterPuppet.Pose.PROFILE)
	await get_tree().create_timer(HOLD_PROFILE_SEC).timeout

	# Boomerang attacks: head → body → legs.
	for part_slot in [PartSlotType.Value.HEAD, PartSlotType.Value.BODY, PartSlotType.Value.LEGS]:
		await _boomerang_part(puppet, part_slot)

	# Jump back to the card.
	var return_peak := Vector2(
		lerpf(puppet.global_position.x, slot.get_fighter_global_position().x, 0.5),
		minf(puppet.global_position.y, slot.get_fighter_global_position().y) - 220.0
	)
	var back := create_tween()
	back.tween_property(puppet, "global_position", return_peak, RETURN_JUMP_UP).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	back.tween_property(puppet, "global_position", slot.get_fighter_global_position(), RETURN_JUMP_DOWN).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await back.finished

	puppet.queue_free()
	slot.set_fighter_visible(true)
	slot.set_fight_locked(false)
	if drag_service != null and drag_service.has_method("set_locked"):
		drag_service.set_locked(false)
	_busy = false
	finished.emit()

func _clear_shelf(tray: Node2D) -> void:
	var fleeing: Array[Node2D] = []
	for child in tray.get_children():
		if child is Crate or child is PartView:
			fleeing.append(child as Node2D)
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

func _land_impact(puppet: FighterPuppet, tray: Node2D) -> void:
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

func _boomerang_part(puppet: FighterPuppet, slot: PartSlotType.Value) -> void:
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
