class_name StatTag
extends Node2D

## The little coloured badge with a kit's number on it.
## When synergy is boosting that number the badge gets a gold rim.

const SIZE := Vector2(66, 32)

var _value: int = 0
var _color: Color = ThemeTokens.MIGHT
var _boosted: bool = false
var _label: Label

func _ready() -> void:
	if _label != null:
		return
	_build()

func setup(value: int, color: Color, boosted: bool = false) -> void:
	if _label == null:
		_build()
	var grew := value > _value
	_value = value
	_color = color
	_boosted = boosted
	_label.text = str(value)
	_label.add_theme_color_override("font_color", ThemeTokens.INK if boosted else Color.WHITE)
	visible = value > 0
	queue_redraw()
	if grew and visible:
		Feel.punch(self, Vector2(1.2, 0.8), Vector2.ONE)

func play_boost() -> void:
	if not visible or not _boosted:
		return
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.3, 1.3), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE, 0.26).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _build() -> void:
	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.position = -SIZE * 0.5
	_label.size = SIZE
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	GameTheme.apply_display(_label, 24, Color.WHITE, 3)
	add_child(_label)
	z_index = 8

func _draw() -> void:
	if _value <= 0:
		return
	var rect := Rect2(-SIZE * 0.5, SIZE)
	var style := StyleBoxFlat.new()
	style.bg_color = ThemeTokens.GOLD if _boosted else _color
	style.set_corner_radius_all(12)
	style.shadow_color = Color(0, 0, 0, 0.45)
	style.shadow_size = 4
	style.shadow_offset = Vector2(0, 2)
	if _boosted:
		style.border_color = _color
		style.set_border_width_all(3)
	draw_style_box(style, rect)
