class_name SellZone
extends Area2D

## Drop target on the right of the conveyor. Gold flash when a piece is over it.

const SIZE := Vector2(176, 100)

var _plate: Panel
var _label: Label

func setup() -> void:
	name = "SellZone"
	position = AssemblyLayout.SELL_TRAY
	var half := SIZE * 0.5
	set_meta("rect", Rect2(-half, SIZE))
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = SIZE
	shape.shape = box
	Feel.hide_collision_debug(shape)
	add_child(shape)
	_plate = Panel.new()
	_plate.size = SIZE
	_plate.position = -half
	_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_plate.add_theme_stylebox_override("panel", GameTheme.plate_style(Color(0.16, 0.1, 0.08, 0.94)))
	add_child(_plate)
	_label = Label.new()
	_label.text = "VENDER  +1"
	_label.position = -half
	_label.size = SIZE
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	GameTheme.apply_display(_label, 26, ThemeTokens.GOLD)
	add_child(_label)


func set_highlight(on: bool) -> void:
	if _plate == null:
		return
	var fill := Color(0.42, 0.3, 0.1, 0.96) if on else Color(0.16, 0.1, 0.08, 0.94)
	_plate.add_theme_stylebox_override("panel", GameTheme.plate_style(fill, on))
	Feel.to_scale(self, Vector2.ONE * 1.08 if on else Vector2.ONE, 0.1)
