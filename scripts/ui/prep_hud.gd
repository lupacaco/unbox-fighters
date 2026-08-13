class_name PrepHud
extends Control

signal ready_pressed

var _phase: Label
var _timer: Label
var _ready_button: Button
var _hp_row: HBoxContainer
var _chips: Array[Label] = []

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

	_ready_button = Button.new()
	_ready_button.text = "PRONTO"
	_ready_button.position = Vector2(1640, 36)
	_ready_button.size = Vector2(220, 56)
	_ready_button.focus_mode = Control.FOCUS_NONE
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

	_hp_row = HBoxContainer.new()
	_hp_row.position = Vector2(480, 36)
	_hp_row.size = Vector2(1100, 56)
	_hp_row.add_theme_constant_override("separation", 16)
	add_child(_hp_row)

func show_prep() -> void:
	_phase.text = "PREP."
	_phase.add_theme_color_override("font_color", ThemeTokens.PREP_ORANGE)
	_ready_button.visible = true
	_timer.visible = true

func show_fight(round_index: int) -> void:
	_phase.text = "LUTEM!"
	_phase.add_theme_color_override("font_color", ThemeTokens.PREP_ORANGE)
	_ready_button.visible = false
	_timer.visible = false
	await get_tree().create_timer(0.85).timeout
	if is_inside_tree():
		_phase.text = "ROUND %d" % round_index

func show_game_over(won: bool) -> void:
	_phase.text = "VOCÊ GANHOU" if won else "VOCÊ PERDEU"
	_ready_button.visible = false
	_timer.visible = false

func set_time(seconds_left: float) -> void:
	_timer.text = "%d s" % ceili(seconds_left)

func refresh_players(match_state: MatchState) -> void:
	while _chips.size() < match_state.contestants.size():
		var chip := Label.new()
		chip.size_flags_horizontal = Control.SIZE_EXPAND | Control.SIZE_FILL
		chip.add_theme_font_size_override("font_size", 16)
		chip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		chip.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_hp_row.add_child(chip)
		_chips.append(chip)
	var opponent := match_state.opponent_of(match_state.human())
	for i in match_state.contestants.size():
		var contestant: Contestant = match_state.contestants[i]
		var chip: Label = _chips[i]
		var mark := ""
		if contestant == opponent:
			mark = "  vs"
		chip.text = "%s  %d HP%s" % [contestant.display_name, contestant.hp, mark]
		if not contestant.is_alive():
			chip.add_theme_color_override("font_color", ThemeTokens.TEXT_DIM)
		elif contestant == opponent:
			chip.add_theme_color_override("font_color", ThemeTokens.PREP_ORANGE)
		else:
			chip.add_theme_color_override("font_color", ThemeTokens.TEXT)
