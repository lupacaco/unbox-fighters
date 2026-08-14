class_name SellZone
extends Area2D

## Drop target on the right of the conveyor. Gold flash when a piece is over it.

const REST := Color(0.18, 0.12, 0.14, 0.92)
const HOT := Color(0.96, 0.78, 0.36, 0.55)
const SIZE := Vector2(164, 110)

var _plate: Polygon2D
var _label: Label

func setup() -> void:
	name = "SellZone"
	position = AssemblyLayout.SELL_TRAY
	var half := SIZE * 0.5
	var rect := Rect2(-half, SIZE)
	set_meta("rect", rect)
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = SIZE
	shape.shape = box
	Feel.hide_collision_debug(shape)
	add_child(shape)
	_plate = Polygon2D.new()
	_plate.polygon = PackedVector2Array([
		Vector2(-half.x, -half.y),
		Vector2(half.x, -half.y),
		Vector2(half.x, half.y),
		Vector2(-half.x, half.y)
	])
	_plate.color = REST
	_plate.z_index = -1
	add_child(_plate)
	_label = Label.new()
	_label.text = "VENDER\n+1"
	_label.position = Vector2(-70, -28)
	_label.size = Vector2(140, 56)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 18)
	_label.add_theme_color_override("font_color", ThemeTokens.GOLD)
	add_child(_label)


func set_highlight(on: bool) -> void:
	if _plate == null:
		return
	_plate.color = HOT if on else REST
	Feel.to_scale(self, Vector2.ONE * 1.08 if on else Vector2.ONE, 0.1)
