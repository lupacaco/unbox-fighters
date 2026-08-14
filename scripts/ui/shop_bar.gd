class_name ShopBar
extends Control

signal refresh_pressed
signal freeze_pressed
signal upgrade_pressed

const BTN := Vector2(176, 52)

var _level: Button
var _pancada_word: Label
var _dots: Array[Panel] = []
var _refresh: Button
var _freeze: Button
var _freeze_fill: Color
var _fight_style: bool = false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build()

func _build() -> void:
	_level = GameTheme.make_button("NÍVEL 1", AssemblyLayout.LEVEL, BTN, ThemeTokens.GOLD_DEEP, 24)
	_level.pressed.connect(func() -> void: upgrade_pressed.emit())
	add_child(_level)

	_pancada_word = GameTheme.make_label(
		"PANCADAS", 18, AssemblyLayout.SMASH_LABEL, Vector2(180, 28), ThemeTokens.GOLD
	)
	add_child(_pancada_word)

	for i in MatchRules.MAX_GOLD:
		var dot := Panel.new()
		dot.size = Vector2(22, 22)
		dot.position = AssemblyLayout.smash_dot_center(i) - dot.size * 0.5
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dot.add_theme_stylebox_override("panel", GameTheme.gold_token_style(false))
		add_child(dot)
		_dots.append(dot)

	_refresh = GameTheme.make_button("ATUALIZAR", AssemblyLayout.REFRESH, BTN, ThemeTokens.WOOD, 24)
	_refresh.pressed.connect(func() -> void: refresh_pressed.emit())
	add_child(_refresh)

	_freeze_fill = Color(0.18, 0.36, 0.48, 1)
	_freeze = GameTheme.make_button("TRAVAR", AssemblyLayout.FREEZE, BTN, _freeze_fill, 24)
	_freeze.pressed.connect(func() -> void: freeze_pressed.emit())
	add_child(_freeze)

func set_fight_style(enabled: bool) -> void:
	_fight_style = enabled
	_set_chrome_visible(not enabled)

func refresh(contestant: Contestant, _round_index: int) -> void:
	if contestant == null:
		return
	var cost := MatchRules.upgrade_cost(contestant.shop_tier)
	if cost < 0:
		_level.text = "NÍVEL %d" % contestant.shop_tier
	else:
		_level.text = "NÍVEL %d  (%d)" % [contestant.shop_tier, cost]
	for i in _dots.size():
		_dots[i].visible = not _fight_style
		_dots[i].add_theme_stylebox_override(
			"panel", GameTheme.gold_token_style(i < contestant.gold)
		)
	_freeze.text = "TRAVADO" if contestant.frozen else "TRAVAR"
	var fill := _freeze_fill.lerp(ThemeTokens.ICE, 0.5) if contestant.frozen else _freeze_fill
	GameTheme.paint_button(_freeze, fill, 24)

func _set_chrome_visible(on: bool) -> void:
	_refresh.visible = on
	_freeze.visible = on
	_level.visible = on
	_pancada_word.visible = on
	for dot in _dots:
		dot.visible = on
