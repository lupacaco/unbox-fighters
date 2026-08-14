class_name FightDirector
extends Node

## Plays a simulated queue fight on the conveyor: one pair at a time, walk in, clash, KO.

const KitThrow := preload("res://scripts/assembly/thrown_kit.gd")

signal finished

## All fighters share this one floor line (same Y). Never shift it per freak.
## Spring origin so the disc sits on the conveyor rollers, not the red panel.
const LAND_X := 470.0
const DUEL_X := 305.0
const ENTRY_HOPS := 2
const THROW_SEC := 0.34
const BOOMERANG_SEC := 0.52
const WRECK_IMPULSE := 1680.0
const OPPONENT_ENTER := Vector2(2040, 400)
const WALK_PX_PER_SEC := 280.0
const JUMP_SEC := 0.5
const JUMP_HEIGHT := 260.0
const CAMERA_FIGHT_ZOOM := Vector2(1.12, 1.12)

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
var _camera_rest_zoom := Vector2.ONE
var _camera_rest_offset := Vector2.ZERO
var _stage: Node2D
var _hud_layer: CanvasLayer
var _dust_fx: CPUParticles2D
var _spark_fx: CPUParticles2D
var _flash_poly: Polygon2D
var _burst_poly: Polygon2D
var _slash: Line2D
var _shock: Line2D
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
	Engine.time_scale = 1.0
	if drag_service != null:
		drag_service.set_locked(true)
	_camera = _ensure_camera()
	_camera_rest_zoom = _camera.zoom
	_camera_rest_offset = _camera.offset
	_ensure_fx_pool()
	_set_arena(true)
	_flash(Color(1, 0.92, 0.75, 0.22), 0.12)
	_camera_punch(8.0, 0.16)
	_hide_shop(shop_nodes)

	_stage = Node2D.new()
	_stage.name = "FightStage"
	_stage.y_sort_enabled = false
	_fx.add_child(_stage)
	_hud_layer = CanvasLayer.new()
	_hud_layer.name = "FightHud"
	_hud_layer.layer = 20
	add_child(_hud_layer)

	_left = _build_line(result.left if result != null else BoardLoadout.new(), false, slots)
	_right = _build_line(opponent_board, true, slots)
	for fighter in _left:
		fighter.root.visible = false
	for fighter in _right:
		fighter.root.visible = false
	for slot in slots:
		slot.set_fight_locked(true)
		slot.set_fighter_visible(false)
		_lift_card(slot)
	_aim_camera(true)

	var name_l := _hud_plaque(AssemblyLayout.FIGHT_NAME_LEFT, Vector2(280, 54), 22, ThemeTokens.INK)
	name_l.set_text(left_name)
	name_l.set_label_color(ThemeTokens.GOLD)
	var hp_l := _hud_plaque(AssemblyLayout.FIGHT_HP_LEFT, Vector2(132, 78), 40, ThemeTokens.GOLD_DEEP)
	hp_l.set_text(str(left_hp))
	var name_r := _hud_plaque(AssemblyLayout.FIGHT_NAME_RIGHT, Vector2(280, 54), 22, ThemeTokens.INK)
	name_r.set_text(right_name)
	name_r.set_label_color(ThemeTokens.GOLD)
	var hp_r := _hud_plaque(AssemblyLayout.FIGHT_HP_RIGHT, Vector2(132, 78), 40, ThemeTokens.GOLD_DEEP)
	hp_r.set_text(str(right_hp))
	var vs := _hud_plaque(AssemblyLayout.FIGHT_VS, Vector2(220, 52), 22, ThemeTokens.INK)
	vs.set_text("VS")
	vs.set_label_color(ThemeTokens.GOLD)
	var clash_l := _plaque(AssemblyLayout.FIGHT_CLASH + Vector2(-120, 0), Vector2(168, 124), 56, ThemeTokens.THREAT)
	var clash_r := _plaque(AssemblyLayout.FIGHT_CLASH + Vector2(120, 0), Vector2(168, 124), 56, ThemeTokens.THREAT)
	clash_l.show_plaque(false)
	clash_r.show_plaque(false)
	var ko := _plaque(AssemblyLayout.FIGHT_CLASH, Vector2(240, 110), 48, ThemeTokens.BLOOD_HOT)
	ko.set_text("KO")
	ko.show_plaque(false)

	await _enter_duelists(_front(_left), _front(_right), true)
	await get_tree().create_timer(0.28).timeout

	var live_l := _first_index(_left)
	var live_r := _first_index(_right)
	if result != null:
		for event in result.events:
			match event.kind:
				CombatEvent.Kind.QUEUE_ADVANCE:
					await _advance_to(event, ko, live_l, live_r)
					live_l = event.left_queue
					live_r = event.right_queue
				CombatEvent.Kind.CLASH:
					if event.left_queue != live_l or event.right_queue != live_r:
						await _advance_to(event, ko, live_l, live_r)
						live_l = event.left_queue
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
					vs.set_fill(ThemeTokens.GOLD_DEEP)
					vs.set_label_color(ThemeTokens.CREAM)
					vs.punch()
					await get_tree().create_timer(1.15).timeout

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
	if is_instance_valid(_hud_layer):
		_hud_layer.queue_free()
	_hud_layer = null
	_set_arena(false)
	_restore_camera()
	Engine.time_scale = 1.0
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

func _front(line: Array[StageFighter]) -> StageFighter:
	for fighter in line:
		if fighter != null and not fighter.down:
			return fighter
	return null

func _enter_duelists(player: StageFighter, enemy: StageFighter, heavy: bool) -> void:
	var done := [0]
	var need := 0
	if player != null and not player.down:
		need += 1
		_jump_walk_in(player, false, heavy, func() -> void: done[0] += 1)
	if enemy != null and not enemy.down:
		need += 1
		_jump_walk_in(enemy, true, heavy and player == null, func() -> void: done[0] += 1)
	if need == 0:
		return
	while done[0] < need:
		await get_tree().process_frame

func _advance_to(event: CombatEvent, ko: FightPlaque, live_l: int, live_r: int) -> void:
	var next_l: StageFighter = null
	var next_r: StageFighter = null
	if event.left_queue != live_l:
		await _drop_out(_fighter_by_queue(_left, live_l), ko)
		next_l = _fighter_by_queue(_left, event.left_queue)
	if event.right_queue != live_r:
		await _drop_out(_fighter_by_queue(_right, live_r), ko)
		next_r = _fighter_by_queue(_right, event.right_queue)
	if next_l == null and next_r == null:
		return
	await _enter_duelists(next_l, next_r, false)
	await get_tree().create_timer(0.2).timeout

func _jump_walk_in(fighter: StageFighter, opponent: bool, heavy: bool, done: Callable = Callable()) -> void:
	if fighter == null or fighter.root == null or not is_instance_valid(fighter.root):
		if done.is_valid():
			done.call()
		return
	fighter.root.visible = true
	_lift_card(fighter.source_slot)
	fighter.visual.scale = Vector2(1.12, 0.78)
	fighter.puppet.freeze_motion(true)
	var land := _shelf_pos(opponent, LAND_X)
	await _jump_arc(fighter.root, land, JUMP_HEIGHT, JUMP_SEC)
	fighter.puppet.freeze_motion(false)
	if heavy:
		await _land_impact(fighter)
	else:
		_dust(fighter.puppet.feet_position())
		await _squash(fighter.visual, Vector2(1.18, 0.78), 0.08)
		await _squash(fighter.visual, Vector2.ONE, 0.14)
	await get_tree().create_timer(0.1).timeout
	fighter.puppet.set_pose(FighterPuppet.Pose.PROFILE)
	await _squash(fighter.visual, Vector2(1.04, 0.96), 0.1)
	await _squash(fighter.visual, Vector2.ONE, 0.1)
	var stand := _shelf_pos(opponent, DUEL_X)
	await _walk_to(fighter, land, stand, ENTRY_HOPS)
	_face_on_stage(fighter)
	if done.is_valid():
		done.call()

func _walk_to(fighter: StageFighter, from: Vector2, to: Vector2, hops: int = 0) -> void:
	from.y = _shelf_y()
	to.y = _shelf_y()
	var dist := from.distance_to(to)
	if dist < 10.0:
		fighter.root.global_position = to
		return
	var on_step := func() -> void:
		if fighter.puppet != null and is_instance_valid(fighter.puppet):
			GameAudio.step()
			_dust(fighter.puppet.feet_position())
	var on_hop := func() -> void:
		if fighter.puppet != null and is_instance_valid(fighter.puppet):
			GameAudio.spring_boing()
	fighter.puppet.stepped.connect(on_step)
	fighter.puppet.hopped.connect(on_hop)
	fighter.puppet.start_walk()
	fighter.root.global_position = from
	var duration := float(hops) / FighterPuppet.HOP_HZ if hops > 0 else dist / WALK_PX_PER_SEC
	await _move_to(fighter.root, to, duration)
	fighter.puppet.stop_walk()
	if fighter.puppet.stepped.is_connected(on_step):
		fighter.puppet.stepped.disconnect(on_step)
	if fighter.puppet.hopped.is_connected(on_hop):
		fighter.puppet.hopped.disconnect(on_hop)
	await fighter.puppet.settle_idle()
	fighter.root.global_position = Vector2(to.x, _shelf_y())
	fighter.visual.rotation_degrees = 0.0

func _face_on_stage(fighter: StageFighter) -> void:
	if fighter == null or not is_instance_valid(fighter.root):
		return
	var face := -1.0 if fighter.face_left else 1.0
	fighter.root.scale = Vector2(face, 1.0)
	fighter.visual.scale = Vector2.ONE
	fighter.visual.rotation_degrees = 0.0
	fighter.root.z_index = 12
	fighter.root.global_position.y = _shelf_y()

func _play_clash(left: StageFighter, right: StageFighter, event: CombatEvent, clash_l: FightPlaque, clash_r: FightPlaque) -> void:
	if left == null or right == null:
		return
	left.root.global_position = _shelf_pos(false, DUEL_X)
	right.root.global_position = _shelf_pos(true, DUEL_X)
	_face_on_stage(left)
	_face_on_stage(right)
	clash_l.global_position = AssemblyLayout.FIGHT_CLASH + Vector2(-120, 0)
	clash_r.global_position = AssemblyLayout.FIGHT_CLASH + Vector2(120, 0)
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
	if event.winning_side == CombatEvent.Side.TIE:
		await _play_tie_clash(left, right, event)
	elif event.winning_side == CombatEvent.Side.LEFT:
		await _play_winning_throw(left, event.left_slot, right, event.right_slot, event)
	else:
		await _play_winning_throw(right, event.right_slot, left, event.left_slot, event)
	if event.winning_side != CombatEvent.Side.LEFT:
		clash_l.set_fill(Color(0.28, 0.08, 0.1, 0.95))
		clash_l.set_label_color(ThemeTokens.X_RED)
	else:
		clash_l.set_text(str(event.left_leftover))
		clash_l.punch()
	if event.winning_side != CombatEvent.Side.RIGHT:
		clash_r.set_fill(Color(0.28, 0.08, 0.1, 0.95))
		clash_r.set_label_color(ThemeTokens.X_RED)
	else:
		clash_r.set_text(str(event.right_leftover))
		clash_r.punch()
	await get_tree().create_timer(0.12).timeout
	clash_l.show_plaque(false)
	clash_r.show_plaque(false)

func _play_winning_throw(
	attacker: StageFighter,
	atk_slot: PartSlotType.Value,
	defender: StageFighter,
	def_slot: PartSlotType.Value,
	event: CombatEvent
) -> void:
	Feel.punch(attacker.visual, Vector2(0.9, 1.1), Vector2.ONE)
	Feel.punch(defender.visual, Vector2(1.06, 0.94), Vector2.ONE)
	await attacker.puppet.play_throw_windup(atk_slot)
	attacker.puppet.snap_rest()
	var bolt := _spawn_thrown_kit(attacker, atk_slot)
	attacker.puppet.play_throw_recoil(atk_slot)
	var dest := func() -> Vector2:
		return defender.puppet.kit_anchor(def_slot)
	bolt.launch_toward(dest.call(), THROW_SEC)
	await _wait_kit_reaches(bolt, dest, 78.0)
	_freeze_hit(bolt)
	await _clash_impact(attacker, defender, event, bolt.global_position)
	var leftover := event.left_leftover if not attacker.face_left else event.right_leftover
	_fling_victim(defender, def_slot)
	await _return_winner(bolt, attacker, atk_slot, leftover)

func _play_tie_clash(left: StageFighter, right: StageFighter, event: CombatEvent) -> void:
	Feel.punch(left.visual, Vector2(0.9, 1.1), Vector2.ONE)
	Feel.punch(right.visual, Vector2(0.9, 1.1), Vector2.ONE)
	await _windup_pair(left, event.left_slot, right, event.right_slot)
	left.puppet.snap_rest()
	right.puppet.snap_rest()
	var meet := _clash_meet(left, event.left_slot, right, event.right_slot)
	var kit_l := _spawn_thrown_kit(left, event.left_slot)
	var kit_r := _spawn_thrown_kit(right, event.right_slot)
	left.puppet.play_throw_recoil(event.left_slot)
	right.puppet.play_throw_recoil(event.right_slot)
	kit_l.launch_toward(meet, THROW_SEC)
	kit_r.launch_toward(meet, THROW_SEC)
	await _wait_kits_collide(kit_l, kit_r, meet)
	_freeze_hit(kit_l)
	_freeze_hit(kit_r)
	var impact := meet
	if is_instance_valid(kit_l) and is_instance_valid(kit_r):
		impact = (kit_l.global_position + kit_r.global_position) * 0.5
	await _clash_impact(left, right, event, impact)
	_wreck_kit(kit_l, left, event.left_slot)
	_wreck_kit(kit_r, right, event.right_slot)
	await get_tree().create_timer(0.28).timeout

func _windup_pair(
	left: StageFighter,
	left_slot: PartSlotType.Value,
	right: StageFighter,
	right_slot: PartSlotType.Value
) -> void:
	var done := [0]
	_windup_one(left, left_slot, func() -> void: done[0] += 1)
	_windup_one(right, right_slot, func() -> void: done[0] += 1)
	while done[0] < 2:
		await get_tree().process_frame

func _windup_one(fighter: StageFighter, slot: PartSlotType.Value, done: Callable) -> void:
	await fighter.puppet.play_throw_windup(slot)
	if done.is_valid():
		done.call()

func _clash_meet(
	left: StageFighter,
	left_slot: PartSlotType.Value,
	right: StageFighter,
	right_slot: PartSlotType.Value
) -> Vector2:
	var left_at := left.puppet.kit_anchor(left_slot)
	var right_at := right.puppet.kit_anchor(right_slot)
	return Vector2(_tray.global_position.x, (left_at.y + right_at.y) * 0.5)

func _wait_kits_collide(kit_l: KitThrow, kit_r: KitThrow, meet: Vector2) -> void:
	var hit := [false]
	var on_hit := func() -> void:
		hit[0] = true
	if is_instance_valid(kit_l):
		kit_l.collided.connect(on_hit)
	if is_instance_valid(kit_r):
		kit_r.collided.connect(on_hit)
	var waited := 0.0
	while not hit[0] and waited < THROW_SEC + 0.4:
		if not is_instance_valid(kit_l) or not is_instance_valid(kit_r):
			break
		if kit_l.global_position.distance_to(kit_r.global_position) <= 118.0:
			break
		if kit_l.global_position.distance_to(meet) < 40.0 and kit_r.global_position.distance_to(meet) < 40.0:
			break
		await get_tree().physics_frame
		waited += get_physics_process_delta_time()
	if is_instance_valid(kit_l) and kit_l.collided.is_connected(on_hit):
		kit_l.collided.disconnect(on_hit)
	if is_instance_valid(kit_r) and kit_r.collided.is_connected(on_hit):
		kit_r.collided.disconnect(on_hit)

func _freeze_hit(kit: KitThrow) -> void:
	if not is_instance_valid(kit):
		return
	kit.linear_velocity = Vector2.ZERO
	kit.angular_velocity = 0.0
	kit.freeze = true
	kit.flash_hit()

func _wait_kit_reaches(kit: KitThrow, dest: Callable, radius: float) -> void:
	var waited := 0.0
	while waited < THROW_SEC + 0.4 and is_instance_valid(kit):
		var target: Vector2 = dest.call()
		if kit.global_position.distance_to(target) <= radius:
			return
		await get_tree().physics_frame
		waited += get_physics_process_delta_time()
	if is_instance_valid(kit):
		kit.global_position = dest.call()

func _spawn_thrown_kit(fighter: StageFighter, slot: PartSlotType.Value) -> KitThrow:
	var kit := KitThrow.new()
	_stage.add_child(kit)
	kit.setup_from_puppet(fighter.puppet, slot, fighter.face_left)
	fighter.puppet.detach_kit(slot)
	return kit

func _fling_victim(fighter: StageFighter, slot: PartSlotType.Value) -> void:
	var kit := _spawn_thrown_kit(fighter, slot)
	_wreck_kit(kit, fighter, slot)

func _wreck_kit(kit: KitThrow, fighter: StageFighter, slot: PartSlotType.Value) -> void:
	if is_instance_valid(kit):
		var away := WRECK_IMPULSE if fighter.face_left else -WRECK_IMPULSE
		kit.begin_wreck(away)
		kit.fly_off_and_free()
	fighter.puppet.set_part_dead(slot, true)

func _return_winner(
	kit: KitThrow,
	fighter: StageFighter,
	slot: PartSlotType.Value,
	leftover: int
) -> void:
	await kit.fly_boomerang_to(func() -> Vector2: return fighter.puppet.kit_anchor(slot), BOOMERANG_SEC)
	if is_instance_valid(kit):
		kit.queue_free()
	fighter.puppet.attach_kit(slot)
	fighter.puppet.set_tag_value(slot, leftover)
	await fighter.puppet.play_catch_kit()

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
	tilt.tween_property(fighter.visual, "rotation_degrees", side * 78.0, 0.2).set_trans(Tween.TRANS_BACK)
	await tilt.finished
	var slide := create_tween()
	slide.tween_property(fighter.root, "global_position", fighter.root.global_position + Vector2(side * 110.0, 48.0), 0.32).set_trans(Tween.TRANS_QUAD)
	slide.parallel().tween_property(fighter.root, "modulate:a", 0.0, 0.32)
	slide.parallel().tween_property(fighter.visual, "scale", Vector2(0.7, 0.7), 0.32)
	await slide.finished
	ko.show_plaque(false)
	fighter.root.visible = false

func _jump_home(line: Array[StageFighter], opponent: bool) -> void:
	var done := [0]
	var need := 0
	for fighter in line:
		if fighter.down or fighter.root == null or not is_instance_valid(fighter.root) or not fighter.root.visible:
			continue
		need += 1
		_jump_home_one(fighter, opponent, func() -> void: done[0] += 1)
	while done[0] < need:
		await get_tree().process_frame

func _jump_home_one(fighter: StageFighter, opponent: bool, done: Callable) -> void:
	var home := OPPONENT_ENTER if opponent else (
		fighter.source_slot.get_fighter_global_position() if fighter.source_slot != null else fighter.root.global_position + Vector2(0, -200)
	)
	fighter.puppet.set_pose(FighterPuppet.Pose.FRONT)
	await _jump_arc(fighter.root, home, 200.0, 0.42)
	fighter.root.visible = false
	if done.is_valid():
		done.call()

func _land_impact(fighter: StageFighter) -> void:
	_dust(fighter.puppet.feet_position())
	_flash(Color(1, 0.95, 0.8, 0.16), 0.08)
	_camera_punch(12.0, 0.22)
	await _squash(fighter.visual, Vector2(1.24, 0.64), 0.07)
	await _squash(fighter.visual, Vector2(0.94, 1.10), 0.10)
	await _squash(fighter.visual, Vector2.ONE, 0.16)
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

func _shelf_y() -> float:
	return _tray.global_position.y + AssemblyLayout.fight_shelf_y()

func _shelf_pos(opponent: bool, x: float) -> Vector2:
	var side := 1.0 if opponent else -1.0
	return Vector2(_tray.global_position.x + side * x, _shelf_y())

func _first_index(line: Array[StageFighter]) -> int:
	for fighter in line:
		return fighter.queue_index
	return 0

func _fighter_by_queue(line: Array[StageFighter], queue_index: int) -> StageFighter:
	for fighter in line:
		if fighter.queue_index == queue_index:
			return fighter
	return null

func _hud_plaque(pos: Vector2, size: Vector2, font_px: int, fill: Color) -> FightPlaque:
	return _make_plaque(_hud_layer, pos, size, font_px, fill)

func _plaque(pos: Vector2, size: Vector2, font_px: int, fill: Color) -> FightPlaque:
	return _make_plaque(_stage, pos, size, font_px, fill)

func _make_plaque(host: Node, pos: Vector2, size: Vector2, font_px: int, fill: Color) -> FightPlaque:
	var plaque := FightPlaque.new()
	host.add_child(plaque)
	plaque.position = pos
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

func _move_to(node: Node2D, to: Vector2, duration: float) -> void:
	var tween := create_tween()
	tween.tween_property(node, "global_position", to, duration).set_trans(Tween.TRANS_SINE)
	await tween.finished

func _clash_impact(left: StageFighter, right: StageFighter, event: CombatEvent, mid: Vector2) -> void:
	var tint := ThemeTokens.color_for_slot(event.left_slot).lerp(ThemeTokens.color_for_slot(event.right_slot), 0.5)
	_flash(Color(tint.r, tint.g, tint.b, 0.28), 0.12)
	_camera_punch(26.0, 0.28)
	_shelf_thump()
	_hit_spark(mid, tint)
	_impact_burst(mid, tint)
	_shockwave(mid, tint)
	GameAudio.impact()
	Feel.punch(left.visual, Vector2(1.22, 0.78), Vector2.ONE)
	Feel.punch(right.visual, Vector2(1.22, 0.78), Vector2.ONE)
	_hit_flash(left)
	_hit_flash(right)
	left.puppet.play_flinch(-1.0)
	right.puppet.play_flinch(1.0)
	await _hit_stop(0.09)

func _shelf_thump() -> void:
	if _tray == null:
		return
	var origin := _tray.position
	var shake := create_tween()
	shake.tween_property(_tray, "position", origin + Vector2(0, 10), 0.04)
	shake.tween_property(_tray, "position", origin + Vector2(0, -6), 0.05)
	shake.tween_property(_tray, "position", origin, 0.08)

func _hit_flash(fighter: StageFighter) -> void:
	if fighter == null or not is_instance_valid(fighter.visual):
		return
	fighter.visual.modulate = Color(1.45, 1.35, 1.15)
	var tween := create_tween()
	tween.tween_property(fighter.visual, "modulate", Color.WHITE, 0.18)

func _hit_stop(real_sec: float) -> void:
	Engine.time_scale = 0.07
	await get_tree().create_timer(real_sec, true, false, true).timeout
	Engine.time_scale = 1.0

func _impact_burst(pos: Vector2, tint: Color) -> void:
	_ensure_fx_pool()
	if _burst_poly != null and is_instance_valid(_burst_poly):
		_burst_poly.global_position = pos
		_burst_poly.color = Color(tint.r, tint.g, tint.b, 0.95)
		_burst_poly.scale = Vector2(0.2, 0.2)
		_burst_poly.rotation = randf() * TAU
		_burst_poly.modulate.a = 1.0
		_burst_poly.visible = true
		var burst := create_tween()
		burst.tween_property(_burst_poly, "scale", Vector2(2.6, 2.6), 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		burst.parallel().tween_property(_burst_poly, "modulate:a", 0.0, 0.2)
		burst.tween_callback(func() -> void:
			if is_instance_valid(_burst_poly):
				_burst_poly.visible = false
		)
	if _slash == null or not is_instance_valid(_slash):
		return
	_slash.global_position = pos
	_slash.rotation = deg_to_rad(-40.0 + randf() * 80.0)
	_slash.default_color = Color(1.0, 0.96, 0.82, 1.0)
	_slash.width = 16.0
	_slash.modulate.a = 1.0
	_slash.visible = true
	var slash := create_tween()
	slash.tween_property(_slash, "width", 0.0, 0.16)
	slash.parallel().tween_property(_slash, "modulate:a", 0.0, 0.16)
	slash.tween_callback(func() -> void:
		if is_instance_valid(_slash):
			_slash.visible = false
	)

func _shockwave(pos: Vector2, tint: Color) -> void:
	_ensure_fx_pool()
	if _shock == null or not is_instance_valid(_shock):
		return
	_shock.global_position = pos
	_shock.default_color = Color(tint.r, tint.g, tint.b, 0.95)
	_shock.width = 14.0
	_shock.modulate.a = 1.0
	_shock.scale = Vector2(0.18, 0.18)
	_shock.visible = true
	var wave := create_tween()
	wave.tween_property(_shock, "scale", Vector2(2.4, 2.4), 0.28).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	wave.parallel().tween_property(_shock, "modulate:a", 0.0, 0.28)
	wave.parallel().tween_property(_shock, "width", 2.0, 0.28)
	wave.tween_callback(func() -> void:
		if is_instance_valid(_shock):
			_shock.visible = false
	)

func _star_points(count: int, outer: float, inner: float) -> PackedVector2Array:
	var verts := PackedVector2Array()
	for i in count * 2:
		var ang := float(i) * PI / float(count) - PI * 0.5
		var radius := outer if i % 2 == 0 else inner
		verts.append(Vector2(cos(ang), sin(ang)) * radius)
	return verts

func _squash(node: Node2D, to: Vector2, duration: float) -> void:
	var tween := create_tween()
	tween.tween_property(node, "scale", to, duration)
	await tween.finished

func _flash(color: Color, duration: float) -> void:
	_ensure_fx_pool()
	if _flash_poly == null:
		return
	_flash_poly.color = color
	_flash_poly.modulate.a = 1.0
	_flash_poly.visible = true
	var tween := create_tween()
	tween.tween_property(_flash_poly, "modulate:a", 0.0, duration)
	tween.tween_callback(func() -> void:
		if is_instance_valid(_flash_poly):
			_flash_poly.visible = false
	)

func _camera_punch(amount: float, duration: float) -> void:
	if _camera == null:
		return
	var origin := _camera.offset
	var tween := create_tween()
	tween.tween_property(_camera, "offset", origin + Vector2(amount * 0.45, amount), duration * 0.3)
	tween.tween_property(_camera, "offset", origin + Vector2(-amount * 0.25, amount * 0.2), duration * 0.25)
	tween.tween_property(_camera, "offset", origin, duration * 0.45)

func _aim_camera(on: bool) -> void:
	if _camera == null:
		return
	var zoom := CAMERA_FIGHT_ZOOM if on else _camera_rest_zoom
	var offset := _camera_rest_offset + (Vector2(0, 26) if on else Vector2.ZERO)
	var tween := create_tween()
	tween.tween_property(_camera, "zoom", zoom, 0.38).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(_camera, "offset", offset, 0.38)

func _dust(pos: Vector2) -> void:
	_ensure_fx_pool()
	if _dust_fx == null:
		return
	_dust_fx.global_position = pos
	_dust_fx.restart()
	_dust_fx.emitting = true

func _hit_spark(pos: Vector2, tint: Color = Color(1.0, 0.86, 0.45, 0.95)) -> void:
	_dust(pos)
	_ensure_fx_pool()
	if _spark_fx == null:
		return
	_spark_fx.color = tint
	_spark_fx.global_position = pos
	_spark_fx.restart()
	_spark_fx.emitting = true

func _ensure_fx_pool() -> void:
	if _fx == null:
		return
	if _dust_fx == null or not is_instance_valid(_dust_fx):
		_dust_fx = CPUParticles2D.new()
		_dust_fx.emitting = false
		_dust_fx.one_shot = true
		_dust_fx.explosiveness = 1.0
		_dust_fx.amount = 14
		_dust_fx.lifetime = 0.4
		_dust_fx.direction = Vector2(0, -1)
		_dust_fx.spread = 80.0
		_dust_fx.initial_velocity_min = 40.0
		_dust_fx.initial_velocity_max = 90.0
		_dust_fx.gravity = Vector2(0, 180)
		_dust_fx.scale_amount_min = 0.4
		_dust_fx.scale_amount_max = 1.1
		_dust_fx.color = Color(0.85, 0.82, 0.74, 0.7)
		_dust_fx.z_index = 50
		_fx.add_child(_dust_fx)
	if _spark_fx == null or not is_instance_valid(_spark_fx):
		_spark_fx = CPUParticles2D.new()
		_spark_fx.emitting = false
		_spark_fx.one_shot = true
		_spark_fx.explosiveness = 1.0
		_spark_fx.amount = 36
		_spark_fx.lifetime = 0.38
		_spark_fx.direction = Vector2(0, -1)
		_spark_fx.spread = 180.0
		_spark_fx.initial_velocity_min = 120.0
		_spark_fx.initial_velocity_max = 280.0
		_spark_fx.gravity = Vector2(0, 240)
		_spark_fx.scale_amount_min = 0.5
		_spark_fx.scale_amount_max = 1.4
		_spark_fx.color = Color(1.0, 0.86, 0.45, 0.9)
		_spark_fx.z_index = 60
		_fx.add_child(_spark_fx)
	if _flash_poly == null or not is_instance_valid(_flash_poly):
		_flash_poly = Polygon2D.new()
		_flash_poly.polygon = PackedVector2Array([
			Vector2(0, 0), Vector2(1920, 0), Vector2(1920, 1080), Vector2(0, 1080)
		])
		_flash_poly.z_index = 200
		_flash_poly.visible = false
		_fx.add_child(_flash_poly)
	if _burst_poly == null or not is_instance_valid(_burst_poly):
		_burst_poly = Polygon2D.new()
		_burst_poly.polygon = _star_points(8, 42.0, 16.0)
		_burst_poly.z_index = 70
		_burst_poly.visible = false
		_fx.add_child(_burst_poly)
	if _slash == null or not is_instance_valid(_slash):
		_slash = Line2D.new()
		_slash.points = PackedVector2Array([Vector2(-78, 0), Vector2(78, 0)])
		_slash.width = 16.0
		_slash.begin_cap_mode = Line2D.LINE_CAP_ROUND
		_slash.end_cap_mode = Line2D.LINE_CAP_ROUND
		_slash.z_index = 71
		_slash.visible = false
		_fx.add_child(_slash)
	if _shock == null or not is_instance_valid(_shock):
		_shock = Line2D.new()
		var ring := PackedVector2Array()
		for i in 28:
			var ang := TAU * float(i) / 28.0
			ring.append(Vector2(cos(ang), sin(ang)) * 70.0)
		ring.append(ring[0])
		_shock.points = ring
		_shock.width = 14.0
		_shock.begin_cap_mode = Line2D.LINE_CAP_ROUND
		_shock.end_cap_mode = Line2D.LINE_CAP_ROUND
		_shock.z_index = 72
		_shock.visible = false
		_fx.add_child(_shock)

func _restore_camera() -> void:
	if _camera == null:
		return
	_camera.zoom = _camera_rest_zoom
	_camera.offset = _camera_rest_offset

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
