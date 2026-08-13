class_name Crate
extends Area2D

signal broken(crate: Crate, part: PartDef)

const TEX_INTACT := preload("res://assets/boxes/box-01.png")
const TEX_CRACKED := preload("res://assets/boxes/box-02.png")
const TEX_BROKEN := preload("res://assets/boxes/box-03.png")
const TARGET_HEIGHT_PX := 185.0
const BROKEN_HOLD_SEC := 0.5

@onready var _sprite: Sprite2D = $Sprite
@onready var _shadow: Polygon2D = $Shadow
@onready var _collision: CollisionShape2D = $CollisionShape2D
@onready var _label: Label = $Hint

var reward_part: PartDef
var shop_index: int = -1
var can_afford: Callable
var on_paid_open: Callable
## 0 = intact, 1 = cracked, 2 = broken / finishing open.
var _hits: int = 0
var _opened: bool = false
var _busy: bool = false
var _hovered: bool = false
var _base_y: float = 0.0
var _display_scale: float = 1.0
var _part_scene: PackedScene
var _drag_service: DragDropService
var _tray: Node2D
var _idle: Tween
var _motion: Tween

func setup(part: PartDef, part_scene: PackedScene, drag_service: DragDropService, tray: Node2D) -> void:
	reward_part = part
	_part_scene = part_scene
	_drag_service = drag_service
	_tray = tray
	_base_y = position.y
	_apply_stage_art(TEX_INTACT)
	_start_idle()

func set_rest_y(value: float) -> void:
	_base_y = value

func _ready() -> void:
	input_pickable = true
	mouse_entered.connect(_on_hover.bind(true))
	mouse_exited.connect(_on_hover.bind(false))
	var shape := RectangleShape2D.new()
	shape.size = Vector2(190, 180)
	_collision.shape = shape

func _exit_tree() -> void:
	_clear_hover_cursor()

func _input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if _opened or _busy:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_on_clicked()
		get_viewport().set_input_as_handled()

func _on_clicked() -> void:
	if can_afford.is_valid() and not can_afford.call():
		GameAudio.part_reject()
		return
	HammerCursor.strike()
	GameAudio.hammer_hit()
	if _hits == 0:
		_hits = 1
		_apply_stage_art(TEX_CRACKED)
		GameAudio.crate_crack()
		_play_hit_feedback()
		return
	if _hits == 1:
		if on_paid_open.is_valid() and not on_paid_open.call(self):
			GameAudio.part_reject()
			return
		_hits = 2
		GameAudio.crate_break()
		_finish_open()

func _clear_hover_cursor() -> void:
	if not _hovered:
		return
	_hovered = false
	HammerCursor.exit_crate()

func _apply_stage_art(tex: Texture2D) -> void:
	_sprite.texture = tex
	_sprite.centered = true
	var tex_size := tex.get_size()
	_display_scale = TARGET_HEIGHT_PX / maxf(tex_size.y, 1.0)
	_sprite.scale = Vector2.ONE * _display_scale
	_layout_ground_shadow()

func _layout_ground_shadow() -> void:
	## Flat oval under the box — light from above, shadow only on the floor.
	var half_w := TARGET_HEIGHT_PX * 0.46
	var half_h := 11.0
	var points := PackedVector2Array()
	const SEGMENTS := 28
	for i in SEGMENTS:
		var angle := TAU * float(i) / float(SEGMENTS)
		points.append(Vector2(cos(angle) * half_w, sin(angle) * half_h))
	_shadow.polygon = points
	_shadow.color = Color(0.02, 0.02, 0.04, 0.4)
	_shadow.position = Vector2(0.0, TARGET_HEIGHT_PX * 0.48)

func _kill_motion() -> void:
	if _motion != null and _motion.is_valid():
		_motion.kill()
	_motion = null

func _start_idle() -> void:
	_stop_idle()
	_idle = create_tween().set_loops()
	_idle.tween_property(_sprite, "position:y", -3.0, 1.8).set_trans(Tween.TRANS_SINE)
	_idle.tween_property(_sprite, "position:y", 3.0, 1.8).set_trans(Tween.TRANS_SINE)

func _stop_idle() -> void:
	if _idle != null and _idle.is_valid():
		_idle.kill()
	_idle = null
	_sprite.position.y = 0.0

func _on_hover(entering: bool) -> void:
	if entering:
		if _opened or _busy:
			return
		if not _hovered:
			_hovered = true
			HammerCursor.enter_crate()
		var target_y := _base_y - 10.0
		var target_mod := Color(1.08, 1.06, 1.04, 1)
		_kill_motion()
		_motion = create_tween()
		_motion.tween_property(self, "position:y", target_y, 0.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_motion.parallel().tween_property(_sprite, "modulate", target_mod, 0.18)
		return

	_clear_hover_cursor()
	if _opened or _busy:
		return
	_kill_motion()
	_motion = create_tween()
	_motion.tween_property(self, "position:y", _base_y, 0.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_motion.parallel().tween_property(_sprite, "modulate", Color.WHITE, 0.18)

func _play_hit_feedback() -> void:
	_stop_idle()
	_kill_motion()
	var base_scale := Vector2.ONE * _display_scale
	var origin_x := position.x
	_motion = create_tween()
	_motion.tween_property(_sprite, "scale", base_scale * 1.06, 0.06)
	_motion.tween_property(self, "position:x", origin_x + 3.0, 0.03)
	_motion.tween_property(self, "position:x", origin_x - 3.0, 0.03)
	_motion.tween_property(self, "position:x", origin_x, 0.03)
	_motion.tween_property(_sprite, "scale", base_scale, 0.08)
	_motion.tween_callback(_start_idle)

func _finish_open() -> void:
	_busy = true
	_stop_idle()
	_kill_motion()
	_label.visible = false
	_apply_stage_art(TEX_BROKEN)
	input_pickable = false
	_clear_hover_cursor()

	var base_scale := Vector2.ONE * _display_scale
	var origin_x := position.x
	_motion = create_tween()
	_motion.tween_property(_sprite, "scale", base_scale * 1.08, 0.06)
	_motion.tween_property(self, "position:x", origin_x + 4.0, 0.03)
	_motion.tween_property(self, "position:x", origin_x - 4.0, 0.03)
	_motion.tween_property(self, "position:x", origin_x, 0.03)
	_motion.tween_property(_sprite, "scale", base_scale, 0.08)
	_motion.tween_interval(BROKEN_HOLD_SEC)
	_motion.tween_property(self, "modulate:a", 0.0, 0.12).set_trans(Tween.TRANS_CUBIC)
	_motion.tween_callback(_reveal_part)

func _reveal_part() -> void:
	_opened = true
	visible = false
	var spawn_pos := global_position
	var part := _part_scene.instantiate() as PartView
	_tray.add_child(part)
	part.global_position = spawn_pos
	part.tray_home = spawn_pos
	part.setup(reward_part, _drag_service)
	part.scale = Vector2.ONE * 0.85
	part.modulate.a = 0.0
	var tween := part.create_tween()
	tween.tween_property(part, "modulate:a", 1.0, 0.22).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(part, "scale", Vector2.ONE, 0.32).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	broken.emit(self, reward_part)
	_busy = false
	queue_free()
