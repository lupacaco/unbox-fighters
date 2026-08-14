class_name PartView
extends Area2D

signal pressed(part: PartView)

const KIT_PREVIEW_SCALE := 0.48

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
var _kit_root: Node2D
var _kit_sprites: Dictionary = {}
var _kit_home := Vector2.ZERO
var _shows_kit: bool = false

func setup(def: PartDef, drag_service: DragDropService) -> void:
	part_def = def
	_drag_service = drag_service
	_ensure_kit()
	var expanded := PartKit.expand_shop_part(def)
	_shows_kit = expanded.size() > 1
	if _shows_kit:
		_sprite.visible = false
		_shadow.visible = false
		_kit_root.visible = true
		_apply_kit(expanded)
	else:
		_kit_root.visible = false
		_sprite.visible = true
		_shadow.visible = true
		_sprite.texture = def.sprite if def != null else null
		_shadow.texture = _sprite.texture
		_shadow.modulate = Color(0, 0, 0, 0.45)
		_shadow.position = Vector2(8, 14)
		_fit_single()
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
	_ensure_kit()

func _input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if not can_interact():
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		pressed.emit(self)
		_drag_service.begin_drag(self)
		get_viewport().set_input_as_handled()

func _ensure_kit() -> void:
	if _kit_root != null:
		return
	_kit_root = get_node_or_null("KitRoot") as Node2D
	if _kit_root == null:
		_kit_root = Node2D.new()
		_kit_root.name = "KitRoot"
		add_child(_kit_root)
	_kit_root.visible = false
	for slot in PartSlotType.draw_order():
		var sprite := Sprite2D.new()
		sprite.centered = true
		sprite.visible = false
		_kit_root.add_child(sprite)
		_kit_sprites[slot] = sprite

func _apply_kit(expanded: Dictionary) -> void:
	var plan := CompositeResolver.resolve_slots(expanded)
	var textures: Dictionary = plan.get("textures", {})
	var positions: Dictionary = plan.get("positions", {})
	var s := CompositeResolver.display_scale() * KIT_PREVIEW_SCALE
	for slot in PartSlotType.draw_order():
		var sprite: Sprite2D = _kit_sprites.get(slot)
		if sprite == null:
			continue
		var texture: Texture2D = textures.get(slot)
		if texture == null:
			sprite.visible = false
			sprite.texture = null
			continue
		sprite.texture = texture
		sprite.visible = true
		sprite.scale = Vector2.ONE * s
		sprite.position = positions.get(slot, Vector2.ZERO) * KIT_PREVIEW_SCALE
	_center_kit()
	_fit_kit_hitbox()

func _center_kit() -> void:
	var bounds := Rect2()
	var first := true
	for slot in _kit_sprites.keys():
		var sprite: Sprite2D = _kit_sprites[slot]
		if sprite == null or not sprite.visible or sprite.texture == null:
			continue
		var half := sprite.texture.get_size() * sprite.scale.abs() * 0.5
		var rect := Rect2(sprite.position - half, half * 2.0)
		if first:
			bounds = rect
			first = false
		else:
			bounds = bounds.merge(rect)
	_kit_root.position = Vector2.ZERO if first else -bounds.get_center()
	_kit_home = _kit_root.position

func _fit_kit_hitbox() -> void:
	var shape := RectangleShape2D.new()
	shape.size = Vector2(168, 230)
	_collision.shape = shape
	var hw := 84.0
	var hh := 115.0
	_plate.polygon = PackedVector2Array([
		Vector2(-hw * 0.7, hh * 0.58), Vector2(hw * 0.7, hh * 0.58),
		Vector2(hw * 0.58, hh * 0.82), Vector2(-hw * 0.58, hh * 0.82)
	])
	_plate.color = Color(0, 0, 0, 0.3)
	_glow.polygon = PackedVector2Array([
		Vector2(-hw, -hh), Vector2(hw, -hh), Vector2(hw, hh), Vector2(-hw, hh)
	])
	_glow.color = Color(0.77, 0.12, 0.23, 0.0)

func _fit_single() -> void:
	var target := CompositeResolver.PART_SIZE_PX
	var s := CompositeResolver.display_scale()
	_sprite.scale = Vector2.ONE * s
	_shadow.scale = Vector2.ONE * s
	var shape := RectangleShape2D.new()
	shape.size = Vector2(target, CompositeResolver.PART_HEIGHT_PX * s) * 0.82
	_collision.shape = shape
	var hw := target * 0.5
	var hh := CompositeResolver.PART_HEIGHT_PX * s * 0.5
	_plate.polygon = PackedVector2Array([
		Vector2(-hw * 0.7, hh * 0.58), Vector2(hw * 0.7, hh * 0.58),
		Vector2(hw * 0.58, hh * 0.82), Vector2(-hw * 0.58, hh * 0.82)
	])
	_plate.color = Color(0, 0, 0, 0.3)
	_glow.polygon = PackedVector2Array([
		Vector2(-hw, -hh), Vector2(hw, -hh), Vector2(hw, hh), Vector2(-hw, hh)
	])
	_glow.color = Color(0.77, 0.12, 0.23, 0.0)

func _start_idle_float() -> void:
	_stop_idle_float()
	if not visible or _dragging:
		return
	_float_tween = create_tween().set_loops()
	if _shows_kit:
		_float_tween.tween_property(_kit_root, "position:y", _kit_home.y - 2.5, 1.6).set_trans(Tween.TRANS_SINE)
		_float_tween.tween_property(_kit_root, "position:y", _kit_home.y + 2.5, 1.6).set_trans(Tween.TRANS_SINE)
	else:
		_float_tween.tween_property(_sprite, "position:y", -2.5, 1.6).set_trans(Tween.TRANS_SINE)
		_float_tween.tween_property(_sprite, "position:y", 2.5, 1.6).set_trans(Tween.TRANS_SINE)

func _stop_idle_float() -> void:
	if _float_tween != null and _float_tween.is_valid():
		_float_tween.kill()
	_sprite.position.y = 0.0
	if _kit_root != null:
		_kit_root.position = _kit_home

func _on_mouse_entered() -> void:
	if can_interact() and not _dragging:
		var tween := create_tween()
		tween.tween_property(self, "scale", Vector2.ONE * 1.03, 0.12).set_trans(Tween.TRANS_SINE)

func _on_mouse_exited() -> void:
	if not _dragging:
		var tween := create_tween()
		tween.tween_property(self, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_SINE)
