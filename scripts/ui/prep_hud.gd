class_name PrepHud
extends Control

signal ready_pressed

var _phase: Label
var _timer: Label
var _vs: Label
var _field: Label
var _ready_button: Button
var _ready_normal: StyleBoxFlat
var _ready_hover: StyleBoxFlat

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_phase = _make_label("PREP", 36, AssemblyLayout.PREP_LABEL, Vector2(280, 48), ThemeTokens.GOLD)
	_timer = _make_label("1:00", 40, AssemblyLayout.TIMER, Vector2(200, 52), ThemeTokens.GOLD)
	_vs = _make_label("", 18, AssemblyLayout.VS, Vector2(420, 28), ThemeTokens.CREAM)
	_field = _make_label("", 18, AssemblyLayout.FIELD, Vector2(1180, 40), ThemeTokens.CREAM)
	_ready_button = Button.new()
	_ready_button.text = "PRONTO"
	_ready_button.size = Vector2(220, 64)
	_ready_button.position = AssemblyLayout.top_left(AssemblyLayout.READY, _ready_button.size)
	_ready_button.focus_mode = Control.FOCUS_NONE
	_ready_button.mouse_filter = Control.MOUSE_FILTER_STOP
	_ready_button.add_theme_font_size_override("font_size", 22)
	_ready_button.add_theme_color_override("font_color", ThemeTokens.CREAM)
	_ready_normal = StyleBoxFlat.new()
	_ready_normal.bg_color = ThemeTokens.BLOOD_HOT
	_ready_normal.set_corner_radius_all(8)
	_ready_hover = _ready_normal.duplicate() as StyleBoxFlat
	_ready_hover.bg_color = Color(1.0, 0.28, 0.28)
	_ready_button.add_theme_stylebox_override("normal", _ready_normal)
	_ready_button.add_theme_stylebox_override("hover", _ready_hover)
	_ready_button.add_theme_stylebox_override("pressed", _ready_hover)
	_ready_button.pressed.connect(func() -> void: ready_pressed.emit())
	add_child(_ready_button)
	Feel.wire_button(_ready_button)

func show_prep() -> void:
	_place(_phase, AssemblyLayout.PREP_LABEL, Vector2(280, 48))
	_phase.text = "PREP"
	_phase.add_theme_font_size_override("font_size", 36)
	_phase.add_theme_color_override("font_color", ThemeTokens.GOLD)
	_ready_button.text = "PRONTO"
	_ready_button.position = AssemblyLayout.top_left(AssemblyLayout.READY, _ready_button.size)
	_set_top_visible(true)

func show_fight(_round_index: int) -> void:
	_set_top_visible(false)

func show_game_over(won: bool) -> void:
	_timer.visible = false
	_vs.visible = false
	_field.visible = false
	_phase.visible = true
	_phase.text = "Você venceu!" if won else "Você saiu"
	_phase.add_theme_font_size_override("font_size", 48)
	_phase.add_theme_color_override("font_color", ThemeTokens.GOLD)
	_place(_phase, Vector2(960, 480), Vector2(800, 80))
	_ready_button.text = "NOVA PARTIDA"
	_ready_button.visible = true
	_ready_button.position = AssemblyLayout.top_left(AssemblyLayout.READY, _ready_button.size)

func set_time(seconds_left: float) -> void:
	var total := maxi(0, ceili(seconds_left))
	var minutes := total / 60
	var seconds := total % 60
	_timer.text = "%d:%02d" % [minutes, seconds]

func refresh_players(match_state: MatchState) -> void:
	_field.text = match_state.field_line()
	var opponent := match_state.opponent_of(match_state.human())
	if opponent == null:
		_vs.text = ""
	else:
		_vs.text = "vs  %s" % opponent.display_name
		_vs.add_theme_color_override("font_color", ThemeTokens.CREAM)

func _set_top_visible(on: bool) -> void:
	_phase.visible = on
	_timer.visible = on
	_vs.visible = on
	_field.visible = on
	_ready_button.visible = on

func _make_label(text: String, font_px: int, center: Vector2, size: Vector2, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.size = size
	label.position = AssemblyLayout.top_left(center, size)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_px)
	label.add_theme_color_override("font_color", color)
	add_child(label)
	return label

func _place(label: Label, center: Vector2, size: Vector2) -> void:
	label.size = size
	label.position = AssemblyLayout.top_left(center, size)
