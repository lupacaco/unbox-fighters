class_name MoneyBar
extends Node2D

## The wallet: ten gold bricks stacked up, with "$N" written above them.
## A brick lights up with a small pop every time a coin lands.
## Lives at the world origin and reads its spot straight from AssemblyLayout.

const FILL := Color(0.98, 0.79, 0.33)
const FILL_EDGE := Color(0.58, 0.38, 0.10)

var _bricks: Array[Polygon2D] = []
var _shines: Array[Polygon2D] = []
var _label: Label
var _shown: int = -1

func _ready() -> void:
	_build()
	set_amount(MatchRules.STARTING_MONEY, false)

func set_amount(amount: int, animate: bool = true) -> void:
	if _bricks.is_empty():
		_build()
	var value := clampi(amount, 0, MatchRules.MAX_MONEY)
	if value == _shown:
		return
	var gained := value > _shown and _shown >= 0
	_shown = value
	_label.text = "$%d" % value
	for i in _bricks.size():
		var lit := i < value
		_bricks[i].color = FILL if lit else ThemeTokens.MONEY_EMPTY
		_shines[i].visible = lit
	if not animate:
		return
	if gained:
		_pop_brick(value - 1)
	Feel.punch(_label, Vector2(1.16, 0.88), Vector2.ONE)

## Shakes when you try to buy something you cannot pay for.
func deny() -> void:
	var tween := create_tween()
	tween.tween_property(self, "position:x", position.x + 8.0, 0.05)
	tween.tween_property(self, "position:x", position.x - 8.0, 0.06)
	tween.tween_property(self, "position:x", position.x, 0.06)
	for brick in _bricks:
		if brick.color == ThemeTokens.MONEY_EMPTY:
			var flash := brick.create_tween()
			flash.tween_property(brick, "color", ThemeTokens.X_RED, 0.08)
			flash.tween_property(brick, "color", ThemeTokens.MONEY_EMPTY, 0.24)

func _pop_brick(index: int) -> void:
	if index < 0 or index >= _bricks.size():
		return
	var brick := _bricks[index]
	brick.scale = Vector2(1.35, 0.6)
	var tween := brick.create_tween()
	tween.tween_property(brick, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _build() -> void:
	if not _bricks.is_empty():
		return
	var size := AssemblyLayout.MONEY_BRICK
	for i in MatchRules.MAX_MONEY:
		var holder := Node2D.new()
		holder.position = AssemblyLayout.money_brick_center(i)
		add_child(holder)

		var edge := Polygon2D.new()
		edge.polygon = _rounded_bar(size * 0.5 + Vector2(3, 3))
		edge.color = FILL_EDGE
		holder.add_child(edge)

		var brick := Polygon2D.new()
		brick.polygon = _rounded_bar(size * 0.5)
		brick.color = ThemeTokens.MONEY_EMPTY
		holder.add_child(brick)
		_bricks.append(brick)

		var shine := Polygon2D.new()
		shine.polygon = _rounded_bar(Vector2(size.x * 0.42, size.y * 0.2))
		shine.position = Vector2(-size.x * 0.16, -size.y * 0.22)
		shine.color = Color(1, 1, 1, 0.32)
		shine.visible = false
		holder.add_child(shine)
		_shines.append(shine)

	var label_size := Vector2(200, 70)
	_label = GameTheme.make_label(
		"$0", 54,
		Vector2(AssemblyLayout.MONEY_X, AssemblyLayout.MONEY_LABEL_Y),
		label_size, ThemeTokens.GOLD
	)
	_label.pivot_offset = label_size * 0.5
	add_child(_label)

## A bar with the corners cut, so it reads as a stamped metal token.
func _rounded_bar(half: Vector2) -> PackedVector2Array:
	var c := minf(half.y * 0.6, half.x * 0.3)
	return PackedVector2Array([
		Vector2(-half.x + c, -half.y), Vector2(half.x - c, -half.y),
		Vector2(half.x, -half.y + c), Vector2(half.x, half.y - c),
		Vector2(half.x - c, half.y), Vector2(-half.x + c, half.y),
		Vector2(-half.x, half.y - c), Vector2(-half.x, -half.y + c),
	])
