class_name PrepHud
extends Control

signal ready_pressed

var _phase: Label
var _timer: Label
var _vs: Label
var _field: Label
var _ready_button: Button
var _ready_fill: Color = ThemeTokens.BLOOD_HOT

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_phase = GameTheme.make_label("PREP", 42, AssemblyLayout.PREP_LABEL, Vector2(220, 52), ThemeTokens.GOLD)
	add_child(_phase)
	_timer = GameTheme.make_label("1:00", 56, AssemblyLayout.TIMER, Vector2(240, 64), ThemeTokens.GOLD)
	add_child(_timer)
	_vs = GameTheme.make_label("", 22, AssemblyLayout.VS, Vector2(520, 32), ThemeTokens.CREAM, false)
	add_child(_vs)
	_field = GameTheme.make_label("", 16, AssemblyLayout.FIELD, Vector2(980, 28), ThemeTokens.MUTE, false)
	add_child(_field)
	_ready_button = GameTheme.make_button(
		"PRONTO", AssemblyLayout.READY, Vector2(236, 62), _ready_fill, 30
	)
	_ready_button.pressed.connect(func() -> void: ready_pressed.emit())
	add_child(_ready_button)

func show_prep() -> void:
	_place(_phase, AssemblyLayout.PREP_LABEL, Vector2(220, 52))
	_phase.text = "PREP"
	GameTheme.apply_display(_phase, 42, ThemeTokens.GOLD)
	_ready_button.text = "PRONTO"
	_ready_button.size = Vector2(236, 62)
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
	GameTheme.apply_body(_phase, 52, ThemeTokens.GOLD, 5)
	_place(_phase, Vector2(960, 460), Vector2(900, 90))
	_ready_button.text = "NOVA PARTIDA"
	_ready_button.size = Vector2(280, 66)
	_ready_button.visible = true
	_ready_button.position = AssemblyLayout.top_left(AssemblyLayout.READY_GAME_OVER, _ready_button.size)
	_ready_button.pivot_offset = _ready_button.size * 0.5

func set_time(seconds_left: float) -> void:
	var total := maxi(0, ceili(seconds_left))
	var minutes := total / 60
	var seconds := total % 60
	_timer.text = "%d:%02d" % [minutes, seconds]

func refresh_players(match_state: MatchState) -> void:
	_field.text = _hp_line(match_state)
	var opponent := match_state.opponent_of(match_state.human())
	if opponent == null:
		_vs.text = ""
	else:
		_vs.text = "vs  %s" % opponent.display_name
		GameTheme.apply_body(_vs, 22, ThemeTokens.CREAM)

func _hp_line(match_state: MatchState) -> String:
	var parts: PackedStringArray = []
	for contestant in match_state.contestants:
		parts.append("%s %d" % [contestant.display_name, contestant.hp])
	return "  ·  ".join(parts)

func _set_top_visible(on: bool) -> void:
	_phase.visible = on
	_timer.visible = on
	_vs.visible = on
	_field.visible = on
	_ready_button.visible = on

func _place(label: Label, center: Vector2, size: Vector2) -> void:
	label.size = size
	label.position = AssemblyLayout.top_left(center, size)
