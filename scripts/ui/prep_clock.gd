class_name PrepClock
extends Node2D

## The shared preparation countdown between the belts, plus a button to skip
## the wait and start the fight for both sides.

signal skip_pressed

var _label: Label
var _skip: Button
var _shown: int = -1

func _ready() -> void:
	_label = GameTheme.make_label(
		"60s", 52, AssemblyLayout.TIMER_CENTER, Vector2(180, 70), ThemeTokens.CREAM
	)
	_label.z_index = 22
	add_child(_label)
	_skip = GameTheme.make_button(
		"LUTAR AGORA",
		AssemblyLayout.SKIP_CENTER,
		AssemblyLayout.SKIP_SIZE,
		ThemeTokens.REFRESH_BLUE,
		28
	)
	_skip.pressed.connect(func() -> void: skip_pressed.emit())
	add_child(_skip)
	set_seconds(MatchRules.PREP_SECONDS)

func set_seconds(seconds_left: float) -> void:
	var whole := maxi(0, int(ceil(seconds_left)))
	if whole == _shown:
		return
	_shown = whole
	_label.text = "%ds" % whole
	if whole <= 10 and whole > 0:
		Feel.punch(_label, Vector2(1.12, 0.9), Vector2.ONE)

func set_fight_mode() -> void:
	_shown = -1
	_label.text = "LUTA"
	_skip.visible = false

func set_prep_mode() -> void:
	_skip.visible = true
	set_seconds(MatchRules.PREP_SECONDS)

func set_skip_enabled(on: bool) -> void:
	if _skip == null:
		return
	_skip.disabled = not on
	_skip.modulate = Color.WHITE if on else Color(0.6, 0.6, 0.6, 0.75)
