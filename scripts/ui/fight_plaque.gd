class_name FightPlaque
extends Node2D

## Gold-rimmed plate for fight names, HP, clash numbers, and KO.

var _size := Vector2(168, 72)
var _fill := Color(0.1, 0.09, 0.08, 0.94)
var _box: StyleBoxFlat
var _label: Label
var _shown: bool = true

func setup(size_px: Vector2, font_px: int, fill: Color) -> void:
	_size = size_px
	_fill = fill
	z_index = 90
	_box = StyleBoxFlat.new()
	_box.bg_color = _fill
	_box.set_corner_radius_all(10)
	_box.border_width_left = 3
	_box.border_width_top = 3
	_box.border_width_right = 3
	_box.border_width_bottom = 3
	_box.border_color = ThemeTokens.GOLD
	_box.shadow_color = Color(0, 0, 0, 0.4)
	_box.shadow_size = 6
	_box.shadow_offset = Vector2(0, 3)
	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.position = -_size * 0.5
	_label.size = _size
	_label.add_theme_font_size_override("font_size", font_px)
	_label.add_theme_color_override("font_color", Color("F4EFE6"))
	add_child(_label)
	queue_redraw()

func set_text(text: String) -> void:
	if _label:
		_label.text = text

func set_fill(fill: Color) -> void:
	_fill = fill
	if _box != null:
		_box.bg_color = _fill
	queue_redraw()

func set_label_color(color: Color) -> void:
	if _label:
		_label.add_theme_color_override("font_color", color)

func show_plaque(on: bool) -> void:
	_shown = on
	visible = on
	if on:
		scale = Vector2(0.82, 0.82)
		var tween := create_tween()
		tween.tween_property(self, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func punch() -> void:
	var rest := scale
	var tween := create_tween()
	tween.tween_property(self, "scale", rest * 1.18, 0.08)
	tween.tween_property(self, "scale", rest, 0.14)

func _draw() -> void:
	if not _shown or _box == null:
		return
	draw_style_box(_box, Rect2(-_size * 0.5, _size))
