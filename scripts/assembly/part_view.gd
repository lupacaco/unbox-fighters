class_name PartView
extends Area2D

signal pressed(part: PartView)

@onready var _sprite: Sprite2D = $Sprite
@onready var _shadow: Sprite2D = $Shadow
@onready var _glow: Polygon2D = $Glow
@onready var _plate: Polygon2D = $Plate
@onready var _collision: CollisionShape2D = $CollisionShape2D

var part_def: PartDef
var tray_home: Vector2 = Vector2.ZERO
var _interaction_locked: bool = false
var _dragging: bool = false
var _attached_slot: CharacterSlot = null
var _float_tween: Tween
var _drag_service: DragDropService

func setup(def: PartDef, drag_service: DragDropService) -> void:
	part_def = def
	_drag_service = drag_service
	_sprite.texture = def.sprite
	_shadow.texture = def.sprite
	_shadow.modulate = Color(0, 0, 0, 0.45)
	_shadow.position = Vector2(8, 14)
	_fit_visuals()
	_start_idle_float()

func can_interact() -> bool:
	return not _interaction_locked and part_def != null

func is_attached() -> bool:
	return _attached_slot != null

func set_attached_slot(slot: CharacterSlot) -> void:
	_attached_slot = slot
	visible = slot == null

func begin_drag() -> void:
	_dragging = true
	_stop_idle_float()
	z_index = 120
	_glow.color = Color(0.77, 0.12, 0.23, 0.22)
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2.ONE * 1.05, 0.12).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if _attached_slot != null:
		_attached_slot.detach_part(part_def.slot_type, false)
		_attached_slot = null
		visible = true
	_drag_service.notify_drag_process_needed()

func cancel_drag_return() -> void:
	_dragging = false
	z_index = 0
	scale = Vector2.ONE
	return_to_tray()

func contains_point(global_point: Vector2) -> bool:
	var shape := _collision.shape as RectangleShape2D
	if shape == null:
		return false
	var local := to_local(global_point)
	return Rect2(-shape.size * 0.5, shape.size).has_point(local)

func unbind_from_card() -> void:
	if _attached_slot == null:
		return
	_attached_slot.detach_part(part_def.slot_type, true)
	_attached_slot = null
	visible = true

func return_to_tray() -> void:
	_dragging = false
	_attached_slot = null
	visible = true
	z_index = 0
	_glow.color = Color(0.77, 0.12, 0.23, 0.1)
	if not is_inside_tree():
		global_position = tray_home
		scale = Vector2.ONE
		return
	var tween := create_tween()
	tween.tween_property(self, "global_position", tray_home, 0.24).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "scale", Vector2.ONE, 0.24).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.finished.connect(_start_idle_float, CONNECT_ONE_SHOT)

func snap_hide_for_slot() -> void:
	_dragging = false
	visible = false
	z_index = 0
	scale = Vector2.ONE
	_stop_idle_float()

func lock_interaction(locked: bool) -> void:
	_interaction_locked = locked

func _ready() -> void:
	input_pickable = true
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if not can_interact():
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		pressed.emit(self)
		_drag_service.begin_drag(self)
		get_viewport().set_input_as_handled()

func _fit_visuals() -> void:
	# Assets are normalized to 300x300 transparent squares.
	var target := 168.0
	var s := target / 300.0
	_sprite.scale = Vector2.ONE * s
	_shadow.scale = Vector2.ONE * s
	var shape := RectangleShape2D.new()
	shape.size = Vector2(target, target) * 0.82
	_collision.shape = shape
	_plate.polygon = PackedVector2Array([
		Vector2(-58, 48), Vector2(58, 48), Vector2(48, 68), Vector2(-48, 68)
	])
	_plate.color = Color(0, 0, 0, 0.3)
	_glow.polygon = PackedVector2Array([
		Vector2(-70, -70), Vector2(70, -70), Vector2(70, 70), Vector2(-70, 70)
	])
	_glow.color = Color(0.77, 0.12, 0.23, 0.0)

func _start_idle_float() -> void:
	_stop_idle_float()
	if not visible or _dragging:
		return
	_float_tween = create_tween().set_loops()
	_float_tween.tween_property(_sprite, "position:y", -2.5, 1.6).set_trans(Tween.TRANS_SINE)
	_float_tween.tween_property(_sprite, "position:y", 2.5, 1.6).set_trans(Tween.TRANS_SINE)

func _stop_idle_float() -> void:
	if _float_tween != null and _float_tween.is_valid():
		_float_tween.kill()
	_sprite.position.y = 0.0

func _on_mouse_entered() -> void:
	if can_interact() and not _dragging:
		var tween := create_tween()
		tween.tween_property(self, "scale", Vector2.ONE * 1.03, 0.12).set_trans(Tween.TRANS_SINE)

func _on_mouse_exited() -> void:
	if not _dragging:
		var tween := create_tween()
		tween.tween_property(self, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_SINE)
