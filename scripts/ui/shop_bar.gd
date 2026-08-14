class_name ShopBar
extends Control

signal refresh_pressed
signal freeze_pressed
signal upgrade_pressed

var _level: Button
var _pancada_word: Label
var _dots: Array[ColorRect] = []
var _refresh: Button
var _freeze: Button
var _freeze_fill: Color
var _fight_style: bool = false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build()

func _build() -> void:
	_level = _make_fill_button("NÍVEL 1", AssemblyLayout.LEVEL, Vector2(220, 56), ThemeTokens.GOLD_DEEP)
	_level.pressed.connect(func() -> void: upgrade_pressed.emit())
	add_child(_level)

	_pancada_word = _make_label("PANCADAS", 16, AssemblyLayout.SMASH_LABEL, Vector2(220, 28), ThemeTokens.GOLD)
	add_child(_pancada_word)

	for i in MatchRules.MAX_GOLD:
		var dot := ColorRect.new()
		dot.size = Vector2(18, 18)
		dot.position = AssemblyLayout.smash_dot_center(i) - dot.size * 0.5
		dot.color = ThemeTokens.DOT_EMPTY
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(dot)
		_dots.append(dot)

	_refresh = _make_fill_button("ATUALIZAR", AssemblyLayout.REFRESH, Vector2(210, 56), ThemeTokens.WOOD)
	_refresh.pressed.connect(func() -> void: refresh_pressed.emit())
	add_child(_refresh)

	_freeze_fill = Color(0.22, 0.42, 0.55, 1)
	_freeze = _make_fill_button("TRAVAR", AssemblyLayout.FREEZE, Vector2(200, 56), _freeze_fill)
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
		if i < contestant.gold:
			_dots[i].color = ThemeTokens.GOLD
		else:
			_dots[i].color = ThemeTokens.DOT_EMPTY
	_freeze.text = "TRAVADO" if contestant.frozen else "TRAVAR"
	_paint_button(_freeze, _freeze_fill.lerp(ThemeTokens.ICE, 0.45) if contestant.frozen else _freeze_fill)

func _set_chrome_visible(on: bool) -> void:
	_refresh.visible = on
	_freeze.visible = on
	_level.visible = on
	_pancada_word.visible = on
	for dot in _dots:
		dot.visible = on

func _make_label(text: String, font_px: int, center: Vector2, size: Vector2, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.size = size
	label.position = AssemblyLayout.top_left(center, size)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_px)
	label.add_theme_color_override("font_color", color)
	return label

func _make_fill_button(text: String, center: Vector2, size: Vector2, fill: Color) -> Button:
	var button := Button.new()
	button.text = text
	button.size = size
	button.position = AssemblyLayout.top_left(center, size)
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_color_override("font_color", ThemeTokens.CREAM)
	_paint_button(button, fill)
	return button

func _paint_button(button: Button, fill: Color) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = fill
	normal.set_corner_radius_all(8)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = fill.lerp(ThemeTokens.GOLD, 0.18)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
