class_name ShopBar
extends Control

signal refresh_pressed
signal freeze_pressed
signal upgrade_pressed

var _level: Label
var _pancada_word: Label
var _dots: Array[ColorRect] = []
var _refresh: Button
var _freeze: Button
var _upgrade_hint: Label
var _fight_style: bool = false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build()

func _build() -> void:
	_level = _make_label("NÍVEL 1", 22, Vector2(48, 1008), Vector2(220, 40))
	_level.mouse_filter = Control.MOUSE_FILTER_STOP
	_level.gui_input.connect(_on_level_input)
	add_child(_level)

	_upgrade_hint = _make_label("", 14, Vector2(48, 1044), Vector2(280, 24))
	_upgrade_hint.add_theme_color_override("font_color", ThemeTokens.TEXT_DIM)
	add_child(_upgrade_hint)

	_pancada_word = _make_label("PANCADAS", 18, Vector2(700, 1004), Vector2(160, 28))
	add_child(_pancada_word)

	for i in MatchRules.MAX_GOLD:
		var dot := ColorRect.new()
		dot.size = Vector2(28, 28)
		dot.position = Vector2(870 + i * 38, 1006)
		dot.color = Color(0.12, 0.12, 0.14, 1)
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(dot)
		_dots.append(dot)

	_refresh = _make_button("ATUALIZAR", Vector2(1580, 968), Vector2(260, 36))
	_refresh.pressed.connect(func() -> void: refresh_pressed.emit())
	add_child(_refresh)

	_freeze = _make_button("TRAVAR", Vector2(1580, 1012), Vector2(260, 36))
	_freeze.pressed.connect(func() -> void: freeze_pressed.emit())
	add_child(_freeze)

func set_fight_style(enabled: bool) -> void:
	_fight_style = enabled
	_refresh.visible = not enabled
	_freeze.visible = not enabled
	_upgrade_hint.visible = not enabled
	_level.mouse_filter = Control.MOUSE_FILTER_IGNORE if enabled else Control.MOUSE_FILTER_STOP

func refresh(contestant: Contestant, round_index: int) -> void:
	if contestant == null:
		return
	_level.text = "NÍVEL %d" % contestant.shop_tier
	var max_gold := MatchRules.gold_for_round(round_index)
	var filled := contestant.gold
	for i in _dots.size():
		var dot := _dots[i]
		dot.visible = i < max_gold
		if i < filled:
			dot.color = Color.WHITE if _fight_style else ThemeTokens.PANCADA_RED
		else:
			dot.color = Color(0.18, 0.18, 0.2, 0.9)
	var cost := MatchRules.upgrade_cost(contestant.shop_tier)
	if cost < 0:
		_upgrade_hint.text = "Nível máximo"
	else:
		_upgrade_hint.text = "Clique para subir · %d pancadas" % cost
	_freeze.text = "TRAVADO" if contestant.frozen else "TRAVAR"
	_freeze.modulate = ThemeTokens.PREP_ORANGE if contestant.frozen else Color.WHITE

func _on_level_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		upgrade_pressed.emit()

func _make_label(text: String, size: int, pos: Vector2, rect: Vector2) -> Label:
	var label := Label.new()
	label.text = text
	label.position = pos
	label.size = rect
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", ThemeTokens.TEXT)
	return label

func _make_button(text: String, pos: Vector2, rect: Vector2) -> Button:
	var button := Button.new()
	button.text = text
	button.position = pos
	button.size = rect
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 18)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.08, 0.09, 0.11, 0.0)
	normal.set_corner_radius_all(4)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(1, 1, 1, 0.08)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_color_override("font_color", ThemeTokens.TEXT)
	return button
