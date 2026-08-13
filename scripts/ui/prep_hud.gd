class_name PrepHud
extends Control

signal ready_pressed

var _phase: Label
var _timer: Label
var _vs: Label
var _field: Label
var _ready_button: Button

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_phase = Label.new()
	_phase.position = Vector2(48, 28)
	_phase.size = Vector2(420, 64)
	_phase.text = "PREP."
	_phase.add_theme_font_size_override("font_size", 48)
	_phase.add_theme_color_override("font_color", ThemeTokens.PREP_ORANGE)
	add_child(_phase)

	_timer = Label.new()
	_timer.position = Vector2(48, 88)
	_timer.size = Vector2(200, 36)
	_timer.add_theme_font_size_override("font_size", 22)
	_timer.add_theme_color_override("font_color", ThemeTokens.TEXT)
	add_child(_timer)

	_vs = Label.new()
	_vs.position = Vector2(48, 118)
	_vs.size = Vector2(420, 28)
	_vs.add_theme_font_size_override("font_size", 18)
	_vs.add_theme_color_override("font_color", ThemeTokens.TEXT_DIM)
	add_child(_vs)

	_field = Label.new()
	_field.position = Vector2(420, 36)
	_field.size = Vector2(1180, 40)
	_field.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_field.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_field.add_theme_font_size_override("font_size", 18)
	_field.add_theme_color_override("font_color", ThemeTokens.TEXT)
	add_child(_field)

	_ready_button = Button.new()
	_ready_button.text = "PRONTO"
	_ready_button.position = Vector2(1640, 36)
	_ready_button.size = Vector2(220, 56)
	_ready_button.focus_mode = Control.FOCUS_NONE
	_ready_button.mouse_filter = Control.MOUSE_FILTER_STOP
	_ready_button.add_theme_font_size_override("font_size", 22)
	var normal := StyleBoxFlat.new()
	normal.bg_color = ThemeTokens.PREP_ORANGE
	normal.set_corner_radius_all(8)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("FF7A1A")
	_ready_button.add_theme_stylebox_override("normal", normal)
	_ready_button.add_theme_stylebox_override("hover", hover)
	_ready_button.add_theme_stylebox_override("pressed", hover)
	_ready_button.pressed.connect(func() -> void: ready_pressed.emit())
	add_child(_ready_button)

func show_prep() -> void:
	_phase.text = "PREP."
	_phase.add_theme_color_override("font_color", ThemeTokens.PREP_ORANGE)
	_ready_button.text = "PRONTO"
	_ready_button.visible = true
	_timer.visible = true
	_vs.visible = true
	_field.visible = true

func show_fight(_round_index: int) -> void:
	_phase.text = "LUTA"
	_phase.add_theme_color_override("font_color", ThemeTokens.PREP_ORANGE)
	_ready_button.visible = false
	_timer.visible = false
	_vs.visible = true
	_field.visible = true

func show_game_over(won: bool) -> void:
	_phase.text = "VOCÊ GANHOU" if won else "VOCÊ PERDEU"
	_ready_button.text = "NOVA PARTIDA"
	_ready_button.visible = true
	_timer.visible = false
	_vs.visible = false

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
		_vs.add_theme_color_override("font_color", ThemeTokens.PREP_ORANGE)
