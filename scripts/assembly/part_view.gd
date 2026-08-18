class_name PartView
extends Area2D

## A kit you can pick up: one drawing for the head or the torso, two for the arms.
## It remembers what it cost, so selling can pay half of it back.

signal pressed(part: PartView)

@onready var _sprite: Sprite2D = $Sprite
@onready var _shadow: Sprite2D = $Shadow
@onready var _glow: Polygon2D = $Glow
@onready var _plate: Polygon2D = $Plate
@onready var _collision: CollisionShape2D = $CollisionShape2D

var part_def: PartDef
var paid_price: int = 0
var home_shelf: ShopShelf
var rest_home: Vector2 = Vector2.ZERO

var _interaction_locked: bool = false
var _dragging: bool = false
var _selected: bool = false
var _attached_slot: CharacterSlot = null
var _drag_service: DragDropService
var _kit_root: Node2D
var _kit_sprites: Dictionary = {}
var _shows_kit: bool = false
var _over_target: bool = false
var _base_scale: float = 1.0
var _select_pulse: Tween
var _shadow_rest := Vector2(8, 14)
## The card this kit was pulled from, so a bad drop puts it back where it was.
var _origin_card: CharacterSlot = null

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
		_shadow.position = _shadow_rest
		_sprite.flip_h = false
		_sprite.rotation = 0.0
		if def != null:
			def.apply_to_sprite(_sprite, def.sprite)
			_shadow.flip_h = _sprite.flip_h
			_shadow.rotation = _sprite.rotation
		_fit_hitbox(Vector2(CompositeResolver.PART_SIZE_PX * 0.82, CompositeResolver.PART_SIZE_PX * 0.82))

## Places the kit so its bottom rests on `surface`, at the given scale.
func stand_on(surface: Vector2, display_scale: float) -> void:
	_base_scale = display_scale
	scale = Vector2.ONE * display_scale
	global_position = surface - Vector2(0.0, _visual_bottom_local() * display_scale)
	rest_home = global_position

func play_reveal() -> void:
	modulate.a = 0.0
	var start := global_position
	global_position = start - Vector2(0.0, 26.0)
	scale = Vector2.ONE * _base_scale * 0.8
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.2).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(self, "global_position", start, 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "scale", Vector2.ONE * _base_scale, 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func sell_value() -> int:
	return PartStats.sell_price(paid_price)

func can_interact() -> bool:
	return not _interaction_locked and part_def != null

func is_attached() -> bool:
	return _attached_slot != null

func attached_slot() -> CharacterSlot:
	return _attached_slot

func set_attached_slot(slot: CharacterSlot) -> void:
	_attached_slot = slot
	visible = slot == null
	if slot == null:
		return
	_origin_card = null
	if home_shelf != null:
		home_shelf.take_part()
		home_shelf = null

## Gold pulse that says "this is the one VENDER will take".
func set_selected(on: bool) -> void:
	if _selected == on:
		return
	_selected = on
	_stop_select_pulse()
	if not on:
		modulate = Color.WHITE
		return
	_select_pulse = create_tween().set_loops()
	_select_pulse.tween_property(self, "modulate", Color(1.35, 1.18, 0.72, 1), 0.42).set_trans(Tween.TRANS_SINE)
	_select_pulse.tween_property(self, "modulate", Color.WHITE, 0.42).set_trans(Tween.TRANS_SINE)

func is_selected() -> bool:
	return _selected

func begin_drag() -> void:
	_dragging = true
	_over_target = false
	z_index = 120
	_plate.visible = false
	_glow.visible = false
	rotation = 0.0
	_shadow.position = Vector2(18, 28)
	_shadow.modulate = Color(0, 0, 0, 0.55)
	Feel.punch(self, Vector2(_base_scale * 1.2, _base_scale * 0.84), Vector2.ONE * _base_scale * 1.14)
	_origin_card = _attached_slot
	if _attached_slot != null:
		_attached_slot.detach_part(part_def.slot_type, true)
		_attached_slot = null
		visible = true
	_drag_service.notify_drag_process_needed()

func apply_drag_tilt(mouse_dx: float) -> void:
	if not _dragging:
		return
	rotation = lerp_angle(rotation, clampf(mouse_dx * 0.045, -0.18, 0.18), 0.28)

func set_over_target(on: bool) -> void:
	if _over_target == on:
		return
	_over_target = on
	if not _dragging:
		return
	Feel.to_scale(self, Vector2.ONE * _base_scale * (1.24 if on else 1.14), 0.1)

func contains_point(global_point: Vector2) -> bool:
	var shape := _collision.shape as RectangleShape2D
	if shape == null:
		return false
	return Rect2(-shape.size * 0.5, shape.size).has_point(to_local(global_point))

func unbind_from_card() -> void:
	if _attached_slot == null:
		return
	_attached_slot.detach_part(part_def.slot_type, true)
	_attached_slot = null
	visible = true

## Puts the kit back where it belongs: on the card it came from, or on its shelf.
func return_home() -> void:
	_clear_drag_pose()
	_attached_slot = null
	visible = true
	Feel.kill_scale(self)
	var card := _origin_card
	_origin_card = null
	if card != null and is_instance_valid(card) and card.try_attach(self):
		return
	if not is_inside_tree():
		global_position = rest_home
		scale = Vector2.ONE * _base_scale
		return
	var tween := create_tween()
	tween.tween_property(self, "global_position", rest_home, 0.24).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "scale", Vector2.ONE * _base_scale, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func snap_hide_for_slot() -> void:
	_clear_drag_pose()
	set_selected(false)
	scale = Vector2.ONE * _base_scale
	visible = false

func lock_interaction(locked: bool) -> void:
	_interaction_locked = locked

func _ready() -> void:
	input_pickable = true
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	_plate.visible = false
	_glow.visible = false
	Feel.hide_collision_debug(_collision)
	_ensure_kit()

func _exit_tree() -> void:
	_stop_select_pulse()

func _input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if not can_interact():
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		pressed.emit(self)
		_drag_service.begin_drag(self)
		get_viewport().set_input_as_handled()

func _clear_drag_pose() -> void:
	_dragging = false
	_over_target = false
	z_index = 0
	rotation = 0.0
	_shadow.position = _shadow_rest
	_shadow.modulate = Color(0, 0, 0, 0.45)

func _stop_select_pulse() -> void:
	if _select_pulse != null and _select_pulse.is_valid():
		_select_pulse.kill()
	_select_pulse = null

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
	var textures: Dictionary = plan["textures"]
	var positions: Dictionary = plan["positions"]
	var s := CompositeResolver.display_scale()
	for slot in PartSlotType.draw_order_for(expanded):
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
		sprite.position = positions.get(slot, Vector2.ZERO)
		sprite.flip_h = false
		sprite.rotation = 0.0
		var part := expanded.get(slot) as PartDef
		if part != null:
			part.apply_to_sprite(sprite, texture)
	_center_kit()
	_fit_hitbox(Vector2(190, 200))

func _center_kit() -> void:
	var bounds := Rect2()
	var first := true
	for slot in _kit_sprites.keys():
		var sprite: Sprite2D = _kit_sprites[slot]
		if sprite == null or not sprite.visible or sprite.texture == null:
			continue
		var half := sprite.texture.get_size() * sprite.scale.abs() * 0.5
		var rect := Rect2(sprite.position - half, half * 2.0)
		bounds = rect if first else bounds.merge(rect)
		first = false
	_kit_root.position = Vector2.ZERO if first else -bounds.get_center()

func _fit_hitbox(size: Vector2) -> void:
	var shape := RectangleShape2D.new()
	shape.size = size
	_collision.shape = shape
	var half := size * 0.5
	_plate.polygon = PackedVector2Array([
		Vector2(-half.x * 0.7, half.y * 0.58), Vector2(half.x * 0.7, half.y * 0.58),
		Vector2(half.x * 0.58, half.y * 0.82), Vector2(-half.x * 0.58, half.y * 0.82)
	])
	_plate.color = Color(0, 0, 0, 0.3)
	_glow.polygon = PackedVector2Array([
		Vector2(-half.x, -half.y), Vector2(half.x, -half.y), Vector2(half.x, half.y), Vector2(-half.x, half.y)
	])
	_plate.visible = false
	_glow.visible = false
	_glow.color = Color(0, 0, 0, 0)
	Feel.hide_collision_debug(_collision)

## Lowest drawn pixel, in local units before the node scale.
func _visual_bottom_local() -> float:
	if _shows_kit and _kit_root != null:
		var max_y := 0.0
		var any := false
		for slot in _kit_sprites.keys():
			var sprite: Sprite2D = _kit_sprites.get(slot)
			if sprite == null or not sprite.visible or sprite.texture == null:
				continue
			var half := sprite.texture.get_size().y * absf(sprite.scale.y) * 0.5
			var bottom := _kit_root.position.y + sprite.position.y + half
			if not any or bottom > max_y:
				max_y = bottom
				any = true
		if any:
			return max_y
	if _sprite != null and _sprite.texture != null:
		return _sprite.position.y + _sprite.texture.get_size().y * absf(_sprite.scale.y) * 0.5
	return CompositeResolver.PART_SIZE_PX * 0.5

func _on_mouse_entered() -> void:
	if can_interact() and not _dragging:
		Feel.to_scale(self, Vector2.ONE * _base_scale * 1.08, 0.1)

func _on_mouse_exited() -> void:
	if not _dragging:
		Feel.to_scale(self, Vector2.ONE * _base_scale, 0.12)
