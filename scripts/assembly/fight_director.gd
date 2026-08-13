class_name FightDirector
extends Node

## Plays a simulated queue fight on the shelf: cards leave, parts collide in the center.

signal finished

const SHELF_Y := -150.0
const QUEUE_X: Array[float] = [210.0, 470.0, 690.0]
const QUEUE_SCALE: Array[float] = [1.18, 0.78, 0.62]
const CLASH_CENTER := Vector2(960, 430)
const CARD_LEAVE_SEC := 0.45
const FLY_SEC := 0.38
const HOLD_CLASH_SEC := 0.55
const RESULT_HOLD_SEC := 1.15

var _busy: bool = false
var _puppets: Dictionary = {}
var _overlay: FightOverlay
var _tray: Node2D
var _fx: Node2D

func is_busy() -> bool:
	return _busy

func play(
	result: CombatResult,
	slots: Array[CharacterSlot],
	opponent_board: BoardLoadout,
	tray: Node2D,
	fx_layer: Node2D,
	drag_service: DragDropService,
	overlay: FightOverlay,
	shop_nodes: Array
) -> void:
	if _busy:
		return
	_busy = true
	_overlay = overlay
	_tray = tray
	_fx = fx_layer
	if drag_service != null:
		drag_service.set_locked(true)
	overlay.reset()

	for slot in slots:
		slot.play_leave_for_fight()
	_hide_shop(shop_nodes)
	await get_tree().create_timer(0.2).timeout

	_spawn_side(result.left, false)
	_spawn_side(opponent_board, true)
	_layout_puppets(0, 0)
	await get_tree().create_timer(CARD_LEAVE_SEC).timeout

	for event in result.events:
		match event.kind:
			CombatEvent.Kind.CLASH:
				await _play_clash(event)
			CombatEvent.Kind.QUEUE_ADVANCE:
				_layout_puppets(event.left_queue, event.right_queue)
				await get_tree().create_timer(0.28).timeout
			CombatEvent.Kind.RESULT:
				overlay.hide_compare()
				overlay.hide_x()
				overlay.show_damage(event.damage_to_left, event.damage_to_left > 0)
				await get_tree().create_timer(RESULT_HOLD_SEC).timeout

	_clear_puppets()
	overlay.reset()
	_show_shop(shop_nodes)
	for slot in slots:
		slot.play_return_from_fight()
	await get_tree().create_timer(0.42).timeout
	if drag_service != null:
		drag_service.set_locked(false)
	_busy = false
	finished.emit()

func _spawn_side(board: BoardLoadout, opponent: bool) -> void:
	var prefix := "R" if opponent else "L"
	for i in board.fighters.size():
		var loadout: FighterLoadout = board.fighters[i]
		if loadout == null or loadout.is_empty():
			continue
		var puppet := FighterPuppet.new()
		_fx.add_child(puppet)
		puppet.setup_loadout(loadout, opponent)
		puppet.set_pose(FighterPuppet.Pose.PROFILE)
		_puppets["%s%d" % [prefix, i]] = puppet

func _layout_puppets(left_active: int, right_active: int) -> void:
	for key in _puppets.keys():
		var puppet: FighterPuppet = _puppets[key]
		var opponent := String(key).begins_with("R")
		var queue := int(String(key).substr(1))
		var visual_rank := queue - (right_active if opponent else left_active)
		visual_rank = clampi(visual_rank, 0, 2)
		var side := 1.0 if opponent else -1.0
		var target := _tray.global_position + Vector2(side * QUEUE_X[visual_rank], SHELF_Y)
		var target_scale := QUEUE_SCALE[visual_rank]
		var signed := absf(target_scale) * (-1.0 if opponent else 1.0)
		puppet.global_position = target
		puppet.scale = Vector2(signed, absf(target_scale))

func _play_clash(event: CombatEvent) -> void:
	_overlay.set_clash_index(event.clash_index)
	var left_puppet: FighterPuppet = _puppets.get("L%d" % event.left_queue)
	var right_puppet: FighterPuppet = _puppets.get("R%d" % event.right_queue)
	if left_puppet == null or right_puppet == null:
		return
	left_puppet.set_attacking(event.left_slot)
	right_puppet.set_attacking(event.right_slot)
	var left_ghost := _make_ghost(left_puppet, event.left_slot)
	var right_ghost := _make_ghost(right_puppet, event.right_slot)
	var left_target := CLASH_CENTER + Vector2(-90, 0)
	var right_target := CLASH_CENTER + Vector2(90, 0)
	var fly := create_tween()
	fly.set_parallel(true)
	fly.tween_property(left_ghost, "global_position", left_target, FLY_SEC).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	fly.tween_property(right_ghost, "global_position", right_target, FLY_SEC).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	fly.tween_property(left_ghost, "scale", left_ghost.scale * 1.55, FLY_SEC)
	fly.tween_property(right_ghost, "scale", right_ghost.scale * 1.55, FLY_SEC)
	await fly.finished
	await _impact()
	_overlay.show_compare(
		event.left_value,
		event.right_value,
		ThemeTokens.color_for_slot(event.left_slot),
		ThemeTokens.color_for_slot(event.right_slot)
	)
	if event.winning_side == CombatEvent.Side.TIE:
		_overlay.show_x_at(CLASH_CENTER)
	elif event.winning_side == CombatEvent.Side.LEFT:
		_overlay.show_x_at(right_target)
	else:
		_overlay.show_x_at(left_target)
	GameAudio.fighter_complete()
	await get_tree().create_timer(HOLD_CLASH_SEC).timeout
	if event.left_leftover <= 0:
		left_puppet.set_part_dead(event.left_slot, true)
		_fade_out(left_ghost)
	else:
		left_puppet.set_tag_value(event.left_slot, event.left_leftover)
		await _return_ghost(left_ghost, left_puppet, event.left_slot)
	if event.right_leftover <= 0:
		right_puppet.set_part_dead(event.right_slot, true)
		_fade_out(right_ghost)
	else:
		right_puppet.set_tag_value(event.right_slot, event.right_leftover)
		await _return_ghost(right_ghost, right_puppet, event.right_slot)
	left_puppet.set_attacking(null)
	right_puppet.set_attacking(null)
	_overlay.hide_compare()
	_overlay.hide_x()

func _make_ghost(puppet: FighterPuppet, slot: PartSlotType.Value) -> Sprite2D:
	var src := puppet.get_part_node(slot)
	var ghost := Sprite2D.new()
	ghost.texture = src.texture
	ghost.centered = true
	ghost.z_index = 80
	_fx.add_child(ghost)
	ghost.global_position = src.global_position
	ghost.global_scale = src.global_scale
	ghost.flip_h = puppet.scale.x < 0.0
	src.visible = false
	return ghost

func _return_ghost(ghost: Sprite2D, puppet: FighterPuppet, slot: PartSlotType.Value) -> void:
	var src := puppet.get_part_node(slot)
	var tween := create_tween()
	tween.tween_property(ghost, "global_position", src.global_position, 0.28).set_trans(Tween.TRANS_CUBIC)
	tween.parallel().tween_property(ghost, "scale", src.global_scale, 0.28)
	await tween.finished
	src.visible = true
	if is_instance_valid(ghost):
		ghost.queue_free()

func _fade_out(ghost: Sprite2D) -> void:
	if ghost == null or not is_instance_valid(ghost):
		return
	var tween := create_tween()
	tween.tween_property(ghost, "modulate:a", 0.0, 0.22)
	tween.tween_callback(ghost.queue_free)

func _impact() -> void:
	var flash := ColorRect.new()
	flash.color = Color(1, 1, 1, 0.35)
	flash.size = Vector2(260, 180)
	flash.position = CLASH_CENTER - flash.size * 0.5
	flash.z_index = 70
	_fx.add_child(flash)
	var origin := _tray.position
	var shake := create_tween()
	shake.tween_property(_tray, "position", origin + Vector2(0, 12), 0.05)
	shake.tween_property(_tray, "position", origin + Vector2(0, -8), 0.05)
	shake.tween_property(_tray, "position", origin, 0.08)
	var pop := create_tween()
	pop.tween_property(flash, "modulate:a", 0.0, 0.18)
	pop.tween_callback(flash.queue_free)
	await shake.finished

func _hide_shop(nodes: Array) -> void:
	for node in nodes:
		if node is Node2D and is_instance_valid(node):
			var tween := create_tween()
			tween.tween_property(node, "modulate:a", 0.0, 0.28)

func _show_shop(nodes: Array) -> void:
	for node in nodes:
		if node is Node2D and is_instance_valid(node):
			var tween := create_tween()
			tween.tween_property(node, "modulate:a", 1.0, 0.28)

func _clear_puppets() -> void:
	for key in _puppets.keys():
		var puppet: FighterPuppet = _puppets[key]
		if is_instance_valid(puppet):
			puppet.queue_free()
	_puppets.clear()
