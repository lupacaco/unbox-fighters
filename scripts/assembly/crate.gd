class_name Crate
extends Area2D

signal broken(crate: Crate, part: PartDef)

const TEX_INTACT := preload("res://assets/boxes/box-01.png")
const TEX_BROKEN := preload("res://assets/boxes/box-02.png")
const TARGET_HEIGHT_PX := 228.0

@onready var _sprite: Sprite2D = $Sprite
@onready var _shadow: Polygon2D = $Shadow
@onready var _collision: CollisionShape2D = $CollisionShape2D
@onready var _label: Label = $Hint

var reward_part: PartDef
var shop_index: int = -1
var on_paid_open: Callable
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
var _frozen_look: bool = false

func setup(part: PartDef, part_scene: PackedScene, drag_service: DragDropService, tray: Node2D) -> void:
	reward_part = part
	_part_scene = part_scene
	_drag_service = drag_service
	_tray = tray
	_base_y = position.y
	_apply_stage_art(TEX_INTACT)
	set_frozen_look(false)
	_start_idle()

func set_rest_y(value: float) -> void:
	_base_y = value

func set_frozen_look(frozen: bool) -> void:
	_frozen_look = frozen
	if _sprite != null:
		_sprite.modulate = _rest_modulate()

func _rest_modulate() -> Color:
	return ThemeTokens.FREEZE_CRATE if _frozen_look else Color.WHITE

func _ready() -> void:
	input_pickable = true
	mouse_entered.connect(_on_hover.bind(true))
	mouse_exited.connect(_on_hover.bind(false))
	var shape := RectangleShape2D.new()
	shape.size = Vector2(230, 220)
	_collision.shape = shape
	Feel.hide_collision_debug(_collision)
	_label.visible = false
	_label.text = ""

func _exit_tree() -> void:
	_clear_hover_cursor()

func _input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if _opened or _busy:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_on_clicked()
		get_viewport().set_input_as_handled()

func _on_clicked() -> void:
	if _opened or _busy:
		return
	if _drag_service != null and _drag_service.is_locked():
		return
	if on_paid_open.is_valid() and not on_paid_open.call(self):
		GameAudio.part_reject()
		return
	HammerCursor.strike()
	GameAudio.open_crate()
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
	_idle.tween_property(_sprite, "position:y", -6.0, 1.6).set_trans(Tween.TRANS_SINE)
	_idle.tween_property(_sprite, "position:y", 5.0, 1.6).set_trans(Tween.TRANS_SINE)

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
		var target_y := _base_y - 14.0
		var target_mod := _rest_modulate() * Color(1.08, 1.06, 1.04, 1)
		_kill_motion()
		_motion = create_tween()
		_motion.tween_property(self, "position:y", target_y, 0.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_motion.parallel().tween_property(_sprite, "modulate", target_mod, 0.18)
		_motion.parallel().tween_property(_sprite, "scale", Vector2.ONE * _display_scale * 1.06, 0.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		return

	_clear_hover_cursor()
	if _opened or _busy:
		return
	_kill_motion()
	_motion = create_tween()
	_motion.tween_property(self, "position:y", _base_y, 0.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_motion.parallel().tween_property(_sprite, "modulate", _rest_modulate(), 0.18)
	_motion.parallel().tween_property(_sprite, "scale", Vector2.ONE * _display_scale, 0.18)

func _finish_open() -> void:
	_busy = true
	_opened = true
	_stop_idle()
	_kill_motion()
	_label.visible = false
	_apply_stage_art(TEX_BROKEN)
	input_pickable = false
	_clear_hover_cursor()
	_motion = create_tween()
	_motion.tween_property(self, "scale", Vector2(1.18, 0.82), 0.08)
	_motion.tween_property(self, "scale", Vector2.ONE, 0.08)
	_motion.tween_interval(0.18)
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
