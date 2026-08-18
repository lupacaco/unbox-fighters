class_name ActionBar
extends Node2D

## The two buttons on the right: ATUALIZAR swaps every crate in the shop,
## VENDER turns the picked piece back into money.

signal refresh_pressed
signal sell_pressed

var _refresh: Button
var _sell: Button
var _sell_hint: Label
var _sell_glow: Tween

func _ready() -> void:
	_refresh = GameTheme.make_button(
		"ATUALIZAR $%d" % MatchRules.REFRESH_COST,
		AssemblyLayout.REFRESH_BUTTON,
		AssemblyLayout.ACTION_BUTTON_SIZE,
		ThemeTokens.REFRESH_BLUE,
		28
	)
	_refresh.pressed.connect(func() -> void: refresh_pressed.emit())
	add_child(_refresh)

	_sell = GameTheme.make_button(
		"VENDER",
		AssemblyLayout.SELL_BUTTON,
		AssemblyLayout.ACTION_BUTTON_SIZE,
		ThemeTokens.SELL_RED,
		28
	)
	_sell.pressed.connect(func() -> void: sell_pressed.emit())
	add_child(_sell)

	_sell_hint = GameTheme.make_label(
		"",
		24,
		AssemblyLayout.SELL_BUTTON + Vector2(0, AssemblyLayout.ACTION_BUTTON_SIZE.y * 0.5 + 22.0),
		Vector2(260, 32),
		ThemeTokens.GOLD
	)
	add_child(_sell_hint)
	set_sell_target(0)

func set_can_refresh(can: bool) -> void:
	if _refresh == null:
		return
	_refresh.disabled = not can
	_refresh.modulate = Color.WHITE if can else Color(0.6, 0.6, 0.6, 0.75)

## Shows what the picked piece is worth. Zero means nothing is picked.
## The plate stays red even when idle, so it still reads as a button.
func set_sell_target(refund: int) -> void:
	if _sell == null:
		return
	var armed := refund > 0
	_sell.disabled = false
	_sell.modulate = Color.WHITE if armed else Color(0.78, 0.78, 0.78, 1)
	_sell_hint.text = "+$%d" % refund if armed else ""
	_stop_glow()
	if armed:
		_start_glow()

## Lights up while a piece is being dragged over it.
func set_drop_hot(hot: bool) -> void:
	if _sell == null:
		return
	Feel.to_scale(_sell, Vector2.ONE * (1.12 if hot else 1.0), 0.1)
	_sell.modulate = ThemeTokens.GOLD if hot else Color.WHITE

func sell_button_rect() -> Rect2:
	return Rect2(
		AssemblyLayout.top_left(AssemblyLayout.SELL_BUTTON, AssemblyLayout.ACTION_BUTTON_SIZE),
		AssemblyLayout.ACTION_BUTTON_SIZE
	)

func play_sold() -> void:
	Feel.punch(_sell, Vector2(1.2, 0.8), Vector2.ONE)

func _start_glow() -> void:
	_sell_glow = create_tween().set_loops()
	_sell_glow.tween_property(_sell, "modulate", Color(1.25, 1.1, 0.95, 1), 0.5).set_trans(Tween.TRANS_SINE)
	_sell_glow.tween_property(_sell, "modulate", Color.WHITE, 0.5).set_trans(Tween.TRANS_SINE)

func _stop_glow() -> void:
	if _sell_glow != null and _sell_glow.is_valid():
		_sell_glow.kill()
	_sell_glow = null
	_sell.modulate = Color.WHITE
