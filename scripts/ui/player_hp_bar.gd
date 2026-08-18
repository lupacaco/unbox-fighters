class_name PlayerHpBar
extends Node2D

## One player's life: a name, a bar that drains, and the number.
## Flashes red each time the enemy Freak chips a point off.

const FRAME := Color(0.08, 0.07, 0.10, 0.92)
const EDGE := Color(0.72, 0.62, 0.40, 0.9)

var _fill: Polygon2D
var _ghost: Polygon2D
var _name_label: Label
var _value_label: Label
var _colour := ThemeTokens.BELT_PLAYER
var _shown: int = MatchRules.STARTING_HP
var _drain: Tween

func setup(display_name: String, colour: Color, mirrored: bool) -> void:
	_colour = colour
	var size := AssemblyLayout.HP_SIZE
	var half := size * 0.5

	var back := Polygon2D.new()
	back.polygon = _bar_shape(half + Vector2(4, 4))
	back.color = FRAME
	add_child(back)

	var rim := Polygon2D.new()
	rim.polygon = _bar_shape(half + Vector2(1, 1))
	rim.color = EDGE
	add_child(rim)

	var hole := Polygon2D.new()
	hole.polygon = _bar_shape(half)
	hole.color = Color(0.05, 0.05, 0.07, 1)
	add_child(hole)

	_ghost = Polygon2D.new()
	_ghost.color = Color(0.95, 0.95, 0.95, 0.5)
	add_child(_ghost)

	_fill = Polygon2D.new()
	_fill.color = colour
	add_child(_fill)

	_name_label = GameTheme.make_label(display_name, 30, Vector2.ZERO, Vector2(300, 40), ThemeTokens.CREAM)
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT if mirrored else HORIZONTAL_ALIGNMENT_LEFT
	_name_label.position = Vector2(half.x - 300.0 if mirrored else -half.x, -half.y - 46.0)
	add_child(_name_label)

	_value_label = GameTheme.make_label("100", 34, Vector2.ZERO, Vector2(140, 40), ThemeTokens.CREAM)
	_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if mirrored else HORIZONTAL_ALIGNMENT_RIGHT
	_value_label.position = Vector2(-half.x if mirrored else half.x - 140.0, -half.y - 46.0)
	_value_label.pivot_offset = Vector2(70, 20)
	add_child(_value_label)

	_shown = MatchRules.STARTING_HP
	_paint(1.0, 1.0)

func set_hp(value: int) -> void:
	var clamped := clampi(value, 0, MatchRules.STARTING_HP)
	if clamped == _shown:
		return
	var was := float(_shown) / float(MatchRules.STARTING_HP)
	_shown = clamped
	_value_label.text = str(clamped)
	var now := float(clamped) / float(MatchRules.STARTING_HP)
	_paint(now, was)
	Feel.punch(_value_label, Vector2(1.24, 0.82), Vector2.ONE)
	if _drain != null and _drain.is_valid():
		_drain.kill()
	_drain = create_tween()
	_drain.tween_interval(0.16)
	_drain.tween_method(func(t: float) -> void: _paint(now, lerpf(was, now, t)), 0.0, 1.0, 0.34)

func _paint(ratio: float, ghost_ratio: float) -> void:
	var half := AssemblyLayout.HP_SIZE * 0.5
	_fill.polygon = _fill_shape(half, ratio)
	_ghost.polygon = _fill_shape(half, maxf(ghost_ratio, ratio))
	_fill.color = _colour.lerp(ThemeTokens.X_RED, clampf(1.0 - ratio, 0.0, 1.0) * 0.7)

func _fill_shape(half: Vector2, ratio: float) -> PackedVector2Array:
	var w := half.x * 2.0 * clampf(ratio, 0.0, 1.0)
	if w <= 1.0:
		return PackedVector2Array()
	return PackedVector2Array([
		Vector2(-half.x, -half.y + 2.0), Vector2(-half.x + w, -half.y + 2.0),
		Vector2(-half.x + w, half.y - 2.0), Vector2(-half.x, half.y - 2.0),
	])

func _bar_shape(half: Vector2) -> PackedVector2Array:
	var c := half.y * 0.5
	return PackedVector2Array([
		Vector2(-half.x + c, -half.y), Vector2(half.x - c, -half.y),
		Vector2(half.x, 0), Vector2(half.x - c, half.y),
		Vector2(-half.x + c, half.y), Vector2(-half.x, 0),
	])
