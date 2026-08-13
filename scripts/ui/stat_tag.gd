class_name StatTag
extends Node2D

const SIZE := Vector2(56, 28)

var _value: int = 0
var _color: Color = ThemeTokens.THREAT
var _label: Label

func _ready() -> void:
	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.position = Vector2(-SIZE.x * 0.5, -SIZE.y * 0.5)
	_label.size = SIZE
	_label.add_theme_font_size_override("font_size", 18)
	_label.add_theme_color_override("font_color", Color.WHITE)
	add_child(_label)
	z_index = 8

func setup(value: int, color: Color) -> void:
	_value = value
	_color = color
	if _label != null:
		_label.text = str(value)
	queue_redraw()
	visible = value > 0

func set_value(value: int) -> void:
	setup(value, _color)

func _draw() -> void:
	if _value <= 0:
		return
	var rect := Rect2(Vector2(-SIZE.x * 0.5, -SIZE.y * 0.5), SIZE)
	var style := StyleBoxFlat.new()
	style.bg_color = _color
	style.set_corner_radius_all(10)
	style.shadow_color = Color(0, 0, 0, 0.45)
	style.shadow_size = 4
	style.shadow_offset = Vector2(0, 2)
	draw_style_box(style, rect)
