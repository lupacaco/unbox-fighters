class_name MoneyBar
extends Node2D

## A gold coin with the wallet written on it. Sits to the right of the shop.

const FILL := Color(0.98, 0.79, 0.33)
const FILL_EDGE := Color(0.58, 0.38, 0.10)

var _disc: Polygon2D
var _label: Label
var _shown: int = -1

func _ready() -> void:
	position = AssemblyLayout.MONEY_CENTER
	_build()
	set_amount(MatchRules.STARTING_MONEY, false)

func set_amount(amount: int, animate: bool = true) -> void:
	if _label == null:
		_build()
	var value := clampi(amount, 0, MatchRules.MAX_MONEY)
	if value == _shown:
		return
	var gained := value > _shown and _shown >= 0
	_shown = value
	_label.text = "$%d" % value
	if not animate:
		return
	if gained:
		Feel.punch(self, Vector2(1.16, 0.88), Vector2.ONE)
	else:
		Feel.punch(_label, Vector2(1.1, 0.92), Vector2.ONE)

## Shakes when you try to buy something you cannot pay for.
func deny() -> void:
	var tween := create_tween()
	tween.tween_property(self, "position:x", position.x + 8.0, 0.05)
	tween.tween_property(self, "position:x", position.x - 8.0, 0.06)
	tween.tween_property(self, "position:x", position.x, 0.06)

func _build() -> void:
	if _disc != null:
		return
	var edge := Polygon2D.new()
	edge.polygon = _circle(AssemblyLayout.MONEY_RADIUS + 5.0)
	edge.color = FILL_EDGE
	add_child(edge)
	_disc = Polygon2D.new()
	_disc.polygon = _circle(AssemblyLayout.MONEY_RADIUS)
	_disc.color = FILL
	add_child(_disc)
	var shine := Polygon2D.new()
	shine.polygon = _circle(AssemblyLayout.MONEY_RADIUS * 0.28)
	shine.position = Vector2(-18.0, -16.0)
	shine.color = Color(1, 1, 1, 0.32)
	add_child(shine)
	var label_size := Vector2(120, 64)
	_label = GameTheme.make_label("$0", 42, Vector2.ZERO, label_size, ThemeTokens.INK)
	_label.position = -label_size * 0.5
	_label.pivot_offset = label_size * 0.5
	add_child(_label)

func _circle(radius: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	const SEGMENTS := 28
	for i in SEGMENTS:
		var angle := TAU * float(i) / float(SEGMENTS)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points
