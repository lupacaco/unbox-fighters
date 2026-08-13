class_name FightDirector
extends Node

## Plays a simulated queue fight on the shelf: jump in, walk, collide, KO.

signal finished

const SHELF_Y := -148.0
const LAND_X := 640.0
const STAND_X: Array[float] = [250.0, 430.0, 610.0]
const QUEUE_SCALE: Array[float] = [1.18, 0.82, 0.66]
const CLASH_CENTER := Vector2(960, 440)
const OPPONENT_ENTER := Vector2(2040, 400)
const WALK_STEPS := 6
const WALK_STEP_SEC := 0.16
const JUMP_SEC := 0.48
const JUMP_HEIGHT := 240.0

class StageFighter:
	var root: Node2D
	var visual: Node2D
	var puppet: FighterPuppet
	var queue_index: int = 0
	var face_left: bool = false
	var down: bool = false
	var source_slot: CharacterSlot

var _busy: bool = false
var _tray: Node2D
var _fx: Node2D
var _camera: Camera2D
var _stage: Node2D
var _left: Array[StageFighter] = []
var _right: Array[StageFighter] = []
var _lifted: Dictionary = {}

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
	shop_nodes: Array,
	left_name: String = "Você",
	right_name: String = "",
	left_hp: int = 40,
	right_hp: int = 0
) -> void:
	if _busy:
		return
	_busy = true
	_tray = tray
	_fx = fx_layer
	_lifted.clear()
	_left.clear()
	_right.clear()
	if drag_service != null:
		drag_service.set_locked(true)
	if overlay != null:
		overlay.reset()
	_camera = _ensure_camera()
	_set_arena(true)
	_flash(Color(1, 0.92, 0.75, 0.22), 0.12)
	_camera_punch(8.0, 0.16)
	_hide_shop(shop_nodes)

	_stage = Node2D.new()
	_stage.name = "FightStage"
	_fx.add_child(_stage)

	_left = _build_line(result.left if result != null else BoardLoadout.new(), false, slots)
	_right = _build_line(opponent_board, true, slots)
	for slot in slots:
		slot.set_fight_locked(true)
		slot.set_fighter_visible(false)

	var name_l := _plaque(Vector2(320, 64), Vector2(280, 54), 22, Color(0.1, 0.09, 0.08, 0.94))
	name_l.set_text(left_name)
	name_l.set_label_color(ThemeTokens.COMPLETE)
	var hp_l := _plaque(Vector2(320, 132), Vector2(132, 78), 40, Color(0.42, 0.32, 0.12, 0.95))
	hp_l.set_text(str(left_hp))
	var name_r := _plaque(Vector2(1600, 64), Vector2(280, 54), 22, Color(0.1, 0.09, 0.08, 0.94))
	name_r.set_text(right_name)
	name_r.set_label_color(ThemeTokens.COMPLETE)
	var hp_r := _plaque(Vector2(1600, 132), Vector2(132, 78), 40, Color(0.42, 0.32, 0.12, 0.95))
	hp_r.set_text(str(right_hp))
	var vs := _plaque(Vector2(960, 80), Vector2(220, 52), 22, Color(0.1, 0.09, 0.08, 0.94))
	vs.set_text("VS")
	vs.set_label_color(ThemeTokens.COMPLETE)
	var clash_l := _plaque(CLASH_CENTER + Vector2(-150, -130), Vector2(168, 124), 56, ThemeTokens.THREAT)
	var clash_r := _plaque(CLASH_CENTER + Vector2(150, -130), Vector2(168, 124), 56, ThemeTokens.THREAT)
	clash_l.show_plaque(false)
	clash_r.show_plaque(false)
	var ko := _plaque(CLASH_CENTER, Vector2(240, 110), 48, ThemeTokens.X_RED)
	ko.set_text("KO")
	ko.show_plaque(false)

	var intro_n := maxi(_left.size(), _right.size())
	for i in intro_n:
		var a: StageFighter = _left[i] if i < _left.size() else null
		var b: StageFighter = _right[i] if i < _right.size() else null
		await _intro_pair(a, b, i, i == 0)
	for slot in slots:
		_lift_card(slot)
	await get_tree().create_timer(0.28).timeout

	var live_l := _first_index(_left)
	var live_r := _first_index(_right)
	if result != null:
		for event in result.events:
			match event.kind:
				CombatEvent.Kind.QUEUE_ADVANCE:
					if event.left_queue != live_l:
						await _drop_out(_fighter_by_queue(_left, live_l), ko)
						await _advance_line(_left, event.left_queue, false)
						live_l = event.left_queue
					if event.right_queue != live_r:
						await _drop_out(_fighter_by_queue(_right, live_r), ko)
						await _advance_line(_right, event.right_queue, true)
						live_r = event.right_queue
				CombatEvent.Kind.CLASH:
					if event.left_queue != live_l:
						await _drop_out(_fighter_by_queue(_left, live_l), ko)
						await _advance_line(_left, event.left_queue, false)
						live_l = event.left_queue
					if event.right_queue != live_r:
						await _drop_out(_fighter_by_queue(_right, live_r), ko)
						await _advance_line(_right, event.right_queue, true)
						live_r = event.right_queue
					await _play_clash(
						_fighter_by_queue(_left, event.left_queue),
						_fighter_by_queue(_right, event.right_queue),
						event,
						clash_l,
						clash_r
					)
				CombatEvent.Kind.RESULT:
					for fighter in _left:
						if fighter != null and not fighter.down and not fighter.puppet.has_living_part():
							await _drop_out(fighter, ko)
					for fighter in _right:
						if fighter != null and not fighter.down and not fighter.puppet.has_living_part():
							await _drop_out(fighter, ko)
					clash_l.show_plaque(false)
					clash_r.show_plaque(false)
					var end := "EMPATE"
					if event.winning_side == CombatEvent.Side.LEFT:
						end = "%s  +%d" % [left_name, event.damage_to_right]
					elif event.winning_side == CombatEvent.Side.RIGHT:
						end = "%s  +%d" % [right_name, event.damage_to_left]
					vs.set_text(end)
					vs.set_fill(Color(0.42, 0.32, 0.12, 0.95))
					vs.set_label_color(Color("F4EFE6"))
					vs.punch()
					await get_tree().create_timer(1.15).timeout

	if overlay != null:
		overlay.reset()
	for slot in slots:
		slot.play_return_from_fight()
	await get_tree().create_timer(0.45).timeout
	await _jump_home(_left, false)
	await _jump_home(_right, true)
	for slot in slots:
		slot.set_fighter_visible(true)
	_show_shop(shop_nodes)
	if is_instance_valid(_stage):
		_stage.queue_free()
	_stage = null
	_set_arena(false)
	if drag_service != null:
		drag_service.set_locked(false)
	_busy = false
	finished.emit()

func _build_line(board: BoardLoadout, opponent: bool, slots: Array[CharacterSlot]) -> Array[StageFighter]:
	var line: Array[StageFighter] = []
	if board == null:
		return line
	for i in board.fighters.size():
		var loadout: FighterLoadout = board.fighters[i]
		if loadout == null or loadout.is_empty():
			continue
		var fighter := StageFighter.new()
		fighter.queue_index = i
		fighter.face_left = opponent
		fighter.root = Node2D.new()
		fighter.visual = Node2D.new()
		fighter.puppet = FighterPuppet.new()
		_stage.add_child(fighter.root)
		fighter.root.add_child(fighter.visual)
		fighter.visual.add_child(fighter.puppet)
		fighter.puppet.setup_loadout(loadout, false)
		if opponent:
			fighter.root.scale.x = -1.0
			fighter.root.global_position = OPPONENT_ENTER
		else:
			var slot := _slot_for_queue(i, slots)
			fighter.source_slot = slot
			fighter.root.global_position = slot.get_fighter_global_position() if slot != null else Vector2(960, 400)
		line.append(fighter)
	return line

func _slot_for_queue(queue_index: int, slots: Array[CharacterSlot]) -> CharacterSlot:
	var visual := 2 - queue_index
	if visual < 0 or visual >= slots.size():
		return null
	return slots[visual]

func _intro_pair(player: StageFighter, enemy: StageFighter, rank: int, heavy: bool) -> void:
	if player != null:
		await _jump_walk_in(player, _land_pos(false), _stand_pos(false, rank), heavy, rank)
	if enemy != null:
		await _jump_walk_in(enemy, _land_pos(true), _stand_pos(true, rank), heavy and player == null, rank)

func _jump_walk_in(fighter: StageFighter, land: Vector2, stand: Vector2, heavy: bool, rank: int) -> void:
	_lift_card(fighter.source_slot)
	var face := -1.0 if fighter.face_left else 1.0
	fighter.visual.scale = Vector2(1.12, 0.78)
	GameAudio.whoosh()
	await _jump_arc(fighter.root, land, JUMP_HEIGHT, JUMP_SEC)
	if heavy:
		await _land_impact(fighter)
	else:
		await _squash(fighter.visual, Vector2(1.1, 0.88), 0.08)
	await get_tree().create_timer(0.18).timeout
	fighter.puppet.set_pose(FighterPuppet.Pose.PROFILE)
	await _squash(fighter.visual, Vector2(1.06, 0.94), 0.14)
	await get_tree().create_timer(0.2).timeout
	await _walk_to(fighter, land, stand)
	fighter.puppet.set_pose(FighterPuppet.Pose.PROFILE)
	var signed := QUEUE_SCALE[clampi(rank, 0, 2)]
	fighter.root.scale = Vector2(face * signed, signed)

func _walk_to(fighter: StageFighter, from: Vector2, to: Vector2) -> void:
	for i in WALK_STEPS:
		var t := float(i + 1) / float(WALK_STEPS)
		var next := from.lerp(to, t)
		fighter.puppet.set_stride_frame((i % 2) == 0)
		GameAudio.step()
		_dust(fighter.puppet.feet_position())
		var bob := next + Vector2(0, -16.0 if (i % 2) == 0 else 0.0)
		fighter.visual.rotation_degrees = 6.0 if (i % 2) == 0 else -4.0
		await _move_to(fighter.root, bob, WALK_STEP_SEC * 0.5)
		await _move_to(fighter.root, next, WALK_STEP_SEC * 0.5)
	fighter.root.global_position = to
	fighter.visual.rotation_degrees = 0.0
	fighter.puppet.set_pose(FighterPuppet.Pose.PROFILE)

func _advance_line(line: Array[StageFighter], new_front: int, opponent: bool) -> void:
	var rank := 0
	for fighter in line:
		if fighter.down or fighter.queue_index < new_front:
			continue
		var dest := _stand_pos(opponent, rank)
		await _walk_to(fighter, fighter.root.global_position, dest)
		var signed := QUEUE_SCALE[clampi(rank, 0, 2)]
		var face := -1.0 if opponent else 1.0
		fighter.root.scale = Vector2(face * signed, signed)
		rank += 1

func _play_clash(left: StageFighter, right: StageFighter, event: CombatEvent, clash_l: FightPlaque, clash_r: FightPlaque) -> void:
	if left == null or right == null:
		return
	left.puppet.set_attacking(event.left_slot)
	right.puppet.set_attacking(event.right_slot)
	var left_ghost := _make_ghost(left, event.left_slot)
	var right_ghost := _make_ghost(right, event.right_slot)
	var left_hit := CLASH_CENTER + Vector2(-78, 0)
	var right_hit := CLASH_CENTER + Vector2(78, 0)
	clash_l.global_position = CLASH_CENTER + Vector2(-150, -130)
	clash_r.global_position = CLASH_CENTER + Vector2(150, -130)
	clash_l.set_fill(ThemeTokens.color_for_slot(event.left_slot))
	clash_r.set_fill(ThemeTokens.color_for_slot(event.right_slot))
	clash_l.set_label_color(Color("F4EFE6"))
	clash_r.set_label_color(Color("F4EFE6"))
	clash_l.set_text(str(event.left_value))
	clash_r.set_text(str(event.right_value))
	clash_l.show_plaque(true)
	clash_r.show_plaque(true)
	clash_l.punch()
	clash_r.punch()
	GameAudio.whoosh()
	var spin_l := create_tween()
	spin_l.tween_property(left_ghost, "rotation_degrees", 220.0, 0.55)
	var spin_r := create_tween()
	spin_r.tween_property(right_ghost, "rotation_degrees", -220.0, 0.55)
	await _jump_arc_scale_pair(left_ghost, left_hit, left_ghost.scale * 2.15, right_ghost, right_hit, right_ghost.scale * 2.15, 160.0, 0.55)
	await get_tree().create_timer(0.18).timeout
	_flash(Color(1, 0.85, 0.45, 0.22), 0.1)
	_camera_punch(14.0, 0.22)
	GameAudio.impact()
	await get_tree().create_timer(0.42).timeout
	var left_dies := event.winning_side != CombatEvent.Side.LEFT
	var right_dies := event.winning_side != CombatEvent.Side.RIGHT
	if left_dies:
		_kill_ghost(left, event.left_slot, left_ghost)
		clash_l.set_fill(Color(0.28, 0.08, 0.1, 0.95))
		clash_l.set_label_color(ThemeTokens.X_RED)
	else:
		clash_l.set_text(str(event.left_leftover))
		clash_l.punch()
	if right_dies:
		_kill_ghost(right, event.right_slot, right_ghost)
		clash_r.set_fill(Color(0.28, 0.08, 0.1, 0.95))
		clash_r.set_label_color(ThemeTokens.X_RED)
	else:
		clash_r.set_text(str(event.right_leftover))
		clash_r.punch()
	if left_dies or right_dies:
		GameAudio.impact()
	await get_tree().create_timer(0.38).timeout
	if not left_dies:
		left.puppet.set_tag_value(event.left_slot, event.left_leftover)
		await _return_ghost(left_ghost, left, event.left_slot)
	if not right_dies:
		right.puppet.set_tag_value(event.right_slot, event.right_leftover)
		await _return_ghost(right_ghost, right, event.right_slot)
	left.puppet.set_attacking(null)
	right.puppet.set_attacking(null)
	clash_l.show_plaque(false)
	clash_r.show_plaque(false)
	GameAudio.part_place()

func _make_ghost(fighter: StageFighter, slot: PartSlotType.Value) -> Sprite2D:
	var src := fighter.puppet.get_part_node(slot)
	var ghost := Sprite2D.new()
	ghost.texture = src.texture
	ghost.centered = true
	ghost.z_index = 80
	_stage.add_child(ghost)
	ghost.global_position = src.global_position
	ghost.global_scale = src.global_scale.abs()
	ghost.flip_h = fighter.face_left
	src.visible = false
	return ghost

func _return_ghost(ghost: Sprite2D, fighter: StageFighter, slot: PartSlotType.Value) -> void:
	var src := fighter.puppet.get_part_node(slot)
	await _jump_arc_scale(ghost, src.global_position, src.global_scale.abs(), 110.0, 0.48)
	src.visible = true
	if is_instance_valid(ghost):
		ghost.queue_free()

func _kill_ghost(fighter: StageFighter, slot: PartSlotType.Value, ghost: Sprite2D) -> void:
	fighter.puppet.set_part_dead(slot, true)
	var mark := Label.new()
	mark.text = "X"
	mark.add_theme_font_size_override("font_size", 72)
	mark.add_theme_color_override("font_color", ThemeTokens.X_RED)
	mark.size = Vector2(80, 80)
	mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stage.add_child(mark)
	mark.global_position = ghost.global_position - Vector2(40, 40)
	var tween := create_tween()
	tween.tween_property(ghost, "modulate:a", 0.0, 0.45)
	tween.parallel().tween_property(ghost, "scale", ghost.scale * 0.4, 0.45)
	tween.parallel().tween_property(mark, "modulate:a", 0.0, 0.45)
	tween.tween_callback(func() -> void:
		if is_instance_valid(ghost):
			ghost.queue_free()
		if is_instance_valid(mark):
			mark.queue_free()
	)

func _drop_out(fighter: StageFighter, ko: FightPlaque) -> void:
	if fighter == null or fighter.down or not is_instance_valid(fighter.root):
		return
	fighter.down = true
	GameAudio.impact()
	_dust(fighter.puppet.feet_position())
	ko.global_position = fighter.root.global_position + Vector2(0, -110)
	ko.set_text("KO")
	ko.set_fill(ThemeTokens.X_RED)
	ko.set_label_color(Color("F4EFE6"))
	ko.show_plaque(true)
	ko.punch()
	var side := 1.0 if fighter.face_left else -1.0
	var tilt := create_tween()
	tilt.tween_property(fighter.visual, "rotation_degrees", side * 70.0, 0.18)
	await tilt.finished
	var slide := create_tween()
	slide.tween_property(fighter.root, "global_position", fighter.root.global_position + Vector2(side * 80.0, 40.0), 0.28)
	slide.parallel().tween_property(fighter.root, "modulate:a", 0.0, 0.28)
	await slide.finished
	ko.show_plaque(false)
	fighter.root.visible = false

func _jump_home(line: Array[StageFighter], opponent: bool) -> void:
	for fighter in line:
		if fighter.down or fighter.root == null or not is_instance_valid(fighter.root) or not fighter.root.visible:
			continue
		var home := OPPONENT_ENTER if opponent else (
			fighter.source_slot.get_fighter_global_position() if fighter.source_slot != null else fighter.root.global_position + Vector2(0, -200)
		)
		GameAudio.whoosh()
		fighter.puppet.set_pose(FighterPuppet.Pose.FRONT)
		await _jump_arc(fighter.root, home, 200.0, 0.42)
		fighter.root.visible = false

func _land_impact(fighter: StageFighter) -> void:
	GameAudio.land()
	GameAudio.fighter_complete()
	_dust(fighter.puppet.feet_position())
	_flash(Color(1, 0.95, 0.8, 0.16), 0.08)
	_camera_punch(12.0, 0.22)
	await _squash(fighter.visual, Vector2(1.22, 0.68), 0.06)
	await _squash(fighter.visual, Vector2(0.92, 1.12), 0.08)
	await _squash(fighter.visual, Vector2.ONE, 0.12)
	if _tray == null:
		return
	var origin := _tray.position
	var shake := create_tween()
	shake.tween_property(_tray, "position", origin + Vector2(0, 14), 0.05)
	shake.tween_property(_tray, "position", origin + Vector2(0, -8), 0.05)
	shake.tween_property(_tray, "position", origin, 0.08)
	await shake.finished

func _lift_card(slot: CharacterSlot) -> void:
	if slot == null or _lifted.has(slot):
		return
	_lifted[slot] = true
	slot.play_leave_for_fight()

func _land_pos(opponent: bool) -> Vector2:
	var side := 1.0 if opponent else -1.0
	return _tray.global_position + Vector2(side * LAND_X, SHELF_Y)

func _stand_pos(opponent: bool, rank: int) -> Vector2:
	var x := STAND_X[clampi(rank, 0, 2)]
	var side := 1.0 if opponent else -1.0
	return _tray.global_position + Vector2(side * x, SHELF_Y)

func _first_index(line: Array[StageFighter]) -> int:
	for fighter in line:
		return fighter.queue_index
	return 0

func _fighter_by_queue(line: Array[StageFighter], queue_index: int) -> StageFighter:
	for fighter in line:
		if fighter.queue_index == queue_index:
			return fighter
	return null

func _plaque(pos: Vector2, size: Vector2, font_px: int, fill: Color) -> FightPlaque:
	var plaque := FightPlaque.new()
	_stage.add_child(plaque)
	plaque.global_position = pos
	plaque.setup(size, font_px, fill)
	return plaque

func _jump_arc(node: Node2D, to: Vector2, height: float, duration: float) -> void:
	var from := node.global_position
	var tween := create_tween()
	tween.tween_method(
		func(t: float) -> void:
			var p := from.lerp(to, t)
			p.y -= sin(t * PI) * height
			node.global_position = p,
		0.0,
		1.0,
		duration
	).set_trans(Tween.TRANS_SINE)
	await tween.finished

func _jump_arc_scale(node: Node2D, to: Vector2, to_scale: Vector2, height: float, duration: float) -> void:
	await _jump_arc_scale_pair(node, to, to_scale, null, Vector2.ZERO, Vector2.ONE, height, duration)

func _jump_arc_scale_pair(
	a: Node2D,
	a_to: Vector2,
	a_scale: Vector2,
	b: Node2D,
	b_to: Vector2,
	b_scale: Vector2,
	height: float,
	duration: float
) -> void:
	var a_from := a.global_position
	var b_from := b.global_position if b != null else Vector2.ZERO
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_method(
		func(t: float) -> void:
			var pa := a_from.lerp(a_to, t)
			pa.y -= sin(t * PI) * height
			a.global_position = pa
			if b != null:
				var pb := b_from.lerp(b_to, t)
				pb.y -= sin(t * PI) * height
				b.global_position = pb,
		0.0,
		1.0,
		duration
	).set_trans(Tween.TRANS_SINE)
	tween.tween_property(a, "scale", a_scale, duration)
	if b != null:
		tween.tween_property(b, "scale", b_scale, duration)
	await tween.finished

func _move_to(node: Node2D, to: Vector2, duration: float) -> void:
	var tween := create_tween()
	tween.tween_property(node, "global_position", to, duration).set_trans(Tween.TRANS_SINE)
	await tween.finished

func _squash(node: Node2D, to: Vector2, duration: float) -> void:
	var tween := create_tween()
	tween.tween_property(node, "scale", to, duration)
	await tween.finished

func _flash(color: Color, duration: float) -> void:
	var flash := Polygon2D.new()
	flash.polygon = PackedVector2Array([
		Vector2(0, 0), Vector2(1920, 0), Vector2(1920, 1080), Vector2(0, 1080)
	])
	flash.color = color
	flash.z_index = 200
	_fx.add_child(flash)
	var tween := create_tween()
	tween.tween_property(flash, "modulate:a", 0.0, duration)
	tween.tween_callback(flash.queue_free)

func _camera_punch(amount: float, duration: float) -> void:
	if _camera == null:
		return
	var origin := _camera.offset
	var tween := create_tween()
	tween.tween_property(_camera, "offset", origin + Vector2(0, amount), duration * 0.35)
	tween.tween_property(_camera, "offset", origin, duration * 0.65)

func _dust(pos: Vector2) -> void:
	var dust := CPUParticles2D.new()
	dust.emitting = false
	dust.one_shot = true
	dust.explosiveness = 1.0
	dust.amount = 10
	dust.lifetime = 0.35
	dust.direction = Vector2(0, -1)
	dust.spread = 80.0
	dust.initial_velocity_min = 40.0
	dust.initial_velocity_max = 90.0
	dust.gravity = Vector2(0, 180)
	dust.scale_amount_min = 0.4
	dust.scale_amount_max = 1.1
	dust.color = Color(0.85, 0.82, 0.74, 0.7)
	_fx.add_child(dust)
	dust.global_position = pos
	dust.emitting = true
	get_tree().create_timer(0.5).timeout.connect(dust.queue_free)

func _ensure_camera() -> Camera2D:
	var cam := get_viewport().get_camera_2d()
	if cam != null:
		return cam
	cam = Camera2D.new()
	cam.position = Vector2(960, 540)
	get_parent().add_child(cam)
	cam.make_current()
	return cam

func _set_arena(on: bool) -> void:
	var bg := get_parent().get_node_or_null("BackgroundFX") as BackgroundFX
	if bg != null:
		bg.set_arena(on)

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
