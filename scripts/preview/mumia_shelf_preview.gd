extends Node2D

## Shelf-only preview: assembled mummy walks and attacks when INICIAR is pressed.
## Does not replace the official 2D assembly scene.

const SHELF_Y := -150.0
const SHELF_LEFT_X := -520.0
const SHELF_MID_X := 0.0
const SHELF_RIGHT_X := 520.0
const TURN_SEC := 0.4
const WALK_TO_MID_SEC := 1.7
const WALK_TO_END_SEC := 1.5
const JUMP_UP_SEC := 0.32
const JUMP_DOWN_SEC := 0.38
const HOLD_SEC := 0.28

var _fighter: MumiaFighter3D
var _tray: Node2D
var _start_button: Button
var _busy: bool = false

func _ready() -> void:
	_tray = $Tray
	_start_button = $HUD/StartButton
	_start_button.pressed.connect(_on_start_pressed)
	_fighter = MumiaFighter3D.new()
	_fighter.name = "Mumia"
	$FxLayer.add_child(_fighter)
	_place_on_shelf(SHELF_LEFT_X)
	_fighter.set_yaw(MumiaFighter3D.FRONT_YAW)
	_fighter.play("idle")


func _on_start_pressed() -> void:
	if _busy:
		return
	_play_sequence()


func _play_sequence() -> void:
	_busy = true
	_start_button.disabled = true

	_place_on_shelf(SHELF_LEFT_X)
	_fighter.set_yaw(MumiaFighter3D.FRONT_YAW)
	_fighter.play("idle")
	await get_tree().create_timer(HOLD_SEC).timeout

	var turn := create_tween()
	turn.tween_property(_fighter, "yaw", MumiaFighter3D.PROFILE_RIGHT_YAW, TURN_SEC).set_trans(Tween.TRANS_SINE)
	await turn.finished

	_fighter.play("walk")
	await _move_to(SHELF_MID_X, WALK_TO_MID_SEC)
	_fighter.play("idle")
	await get_tree().create_timer(HOLD_SEC).timeout

	_fighter.play("punch")
	await get_tree().create_timer(0.5).timeout
	_fighter.play("punch")
	await get_tree().create_timer(0.5).timeout
	_fighter.play("kick")
	await get_tree().create_timer(0.58).timeout
	_fighter.play("look")
	await get_tree().create_timer(0.85).timeout
	_fighter.play("idle")
	await get_tree().create_timer(HOLD_SEC).timeout

	_fighter.play("walk")
	await _move_to(SHELF_RIGHT_X, WALK_TO_END_SEC)

	_fighter.play("idle")
	var about_face := create_tween()
	about_face.tween_property(_fighter, "yaw", MumiaFighter3D.PROFILE_LEFT_YAW, TURN_SEC).set_trans(Tween.TRANS_SINE)
	await about_face.finished

	_fighter.play("jump")
	var start_pos := _shelf_point(SHELF_LEFT_X)
	var peak := Vector2(
		lerpf(_fighter.global_position.x, start_pos.x, 0.5),
		minf(_fighter.global_position.y, start_pos.y) - 220.0
	)
	var jump := create_tween()
	jump.tween_property(_fighter, "global_position", peak, JUMP_UP_SEC).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	jump.tween_property(_fighter, "global_position", start_pos, JUMP_DOWN_SEC).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await jump.finished

	_fighter.set_yaw(MumiaFighter3D.FRONT_YAW)
	_fighter.play("idle")
	_busy = false
	_start_button.disabled = false


func _move_to(shelf_x: float, duration: float) -> void:
	var tween := create_tween()
	tween.tween_property(_fighter, "global_position", _shelf_point(shelf_x), duration).set_trans(Tween.TRANS_SINE)
	await tween.finished


func _place_on_shelf(shelf_x: float) -> void:
	_fighter.global_position = _shelf_point(shelf_x)


func _shelf_point(shelf_x: float) -> Vector2:
	return _tray.global_position + Vector2(shelf_x, SHELF_Y)
