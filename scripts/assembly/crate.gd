class_name Crate
extends Area2D

## A closed box on a shop shelf, with its price stamped under it.
## Clicking asks the shelf to pay; if the money is there, the box cracks open.

signal clicked(crate: Crate)

const TEX_INTACT := preload("res://assets/boxes/box-01.png")
const TEX_BROKEN := preload("res://assets/boxes/box-02.png")

@onready var _sprite: Sprite2D = $Sprite
@onready var _shadow: Polygon2D = $Shadow
@onready var _collision: CollisionShape2D = $CollisionShape2D
@onready var _label: Label = $Hint

var price: int = 0
var _busy: bool = false
var _hovered: bool = false
var _display_scale: float = 1.0
var _motion: Tween
var _affordable: bool = true

func _ready() -> void:
	input_pickable = true
	mouse_entered.connect(_on_hover.bind(true))
	mouse_exited.connect(_on_hover.bind(false))
	Feel.hide_collision_debug(_collision)

func setup(part_price: int) -> void:
	price = part_price
	_busy = false
	_apply_art(TEX_INTACT)
	_paint_price()

func set_affordable(can_pay: bool) -> void:
	if _affordable == can_pay:
		return
	_affordable = can_pay
	_paint_price()
	_sprite.modulate = Color.WHITE if can_pay else Color(0.62, 0.60, 0.62, 1)

## Plays the crack, then reports back so the shelf can put the part out.
func play_open() -> void:
	if _busy:
		return
	_busy = true
	input_pickable = false
	_clear_hover_cursor()
	_label.visible = false
	HammerCursor.strike()
	GameAudio.open_crate()
	_kill_motion()
	_motion = create_tween()
	_motion.tween_property(self, "scale", Vector2(1.22, 0.78), 0.07)
	_motion.tween_callback(func() -> void: _apply_art(TEX_BROKEN))
	_motion.tween_property(self, "scale", Vector2(0.92, 1.1), 0.07)
	_motion.tween_property(self, "scale", Vector2.ONE, 0.08)
	_motion.tween_property(self, "modulate:a", 0.0, 0.14)
	await _motion.finished

func play_reject() -> void:
	GameAudio.part_reject()
	_kill_motion()
	_motion = create_tween()
	_motion.tween_property(self, "position:x", position.x + 7.0, 0.05)
	_motion.tween_property(self, "position:x", position.x - 7.0, 0.06)
	_motion.tween_property(self, "position:x", position.x, 0.06)

func _exit_tree() -> void:
	_clear_hover_cursor()

func _input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if _busy:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		clicked.emit(self)
		get_viewport().set_input_as_handled()

func _paint_price() -> void:
	_label.visible = true
	_label.text = "$%d" % price
	_label.size = Vector2(160, 44)
	_label.position = Vector2(-80.0, AssemblyLayout.PRICE_TAG_DROP - 22.0)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	GameTheme.apply_display(_label, 38, ThemeTokens.GOLD if _affordable else ThemeTokens.MUTE, 5)

func _apply_art(tex: Texture2D) -> void:
	_sprite.texture = tex
	_sprite.centered = true
	_display_scale = AssemblyLayout.SHOP_CRATE_HEIGHT / maxf(tex.get_size().y, 1.0)
	_sprite.scale = Vector2.ONE * _display_scale
	## The box hangs above its origin so the origin is the point it rests on.
	_sprite.position = Vector2(0.0, -AssemblyLayout.SHOP_CRATE_HEIGHT * 0.5)
	var shape := RectangleShape2D.new()
	shape.size = Vector2(tex.get_size().x * _display_scale * 0.92, AssemblyLayout.SHOP_CRATE_HEIGHT * 0.92)
	_collision.shape = shape
	_collision.position = _sprite.position
	Feel.hide_collision_debug(_collision)
	_layout_ground_shadow()

func _layout_ground_shadow() -> void:
	var half_w := AssemblyLayout.SHOP_CRATE_HEIGHT * 0.42
	var points := PackedVector2Array()
	const SEGMENTS := 24
	for i in SEGMENTS:
		var angle := TAU * float(i) / float(SEGMENTS)
		points.append(Vector2(cos(angle) * half_w, sin(angle) * 8.0))
	_shadow.polygon = points
	_shadow.color = Color(0.02, 0.02, 0.04, 0.42)
	_shadow.position = Vector2.ZERO

func _kill_motion() -> void:
	if _motion != null and _motion.is_valid():
		_motion.kill()
	_motion = null

func _clear_hover_cursor() -> void:
	if not _hovered:
		return
	_hovered = false
	HammerCursor.exit_crate()

func _on_hover(entering: bool) -> void:
	if _busy:
		return
	if entering:
		if not _hovered:
			_hovered = true
			HammerCursor.enter_crate()
		_kill_motion()
		_motion = create_tween()
		_motion.tween_property(_sprite, "position:y", -AssemblyLayout.SHOP_CRATE_HEIGHT * 0.5 - 9.0, 0.16).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_motion.parallel().tween_property(_sprite, "scale", Vector2.ONE * _display_scale * 1.06, 0.16)
		return
	_clear_hover_cursor()
	_kill_motion()
	_motion = create_tween()
	_motion.tween_property(_sprite, "position:y", -AssemblyLayout.SHOP_CRATE_HEIGHT * 0.5, 0.16).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_motion.parallel().tween_property(_sprite, "scale", Vector2.ONE * _display_scale, 0.16)
