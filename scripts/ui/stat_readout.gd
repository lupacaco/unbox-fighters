class_name StatReadout
extends Control

@onready var _name_label: Label = $NameLabel
@onready var _total_label: Label = $TotalLabel
@onready var _complete_glow: ColorRect = $CompleteGlow

func _ready() -> void:
	if has_node("Stats"):
		$Stats.visible = false
	if has_node("Panel"):
		var panel := $Panel
		if panel is ColorRect:
			(panel as ColorRect).visible = false
		var plate := Panel.new()
		plate.name = "Plate"
		plate.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
		plate.add_theme_stylebox_override("panel", GameTheme.plate_style(Color(0.08, 0.07, 0.06, 0.92)))
		add_child(plate)
		move_child(plate, 0)
	if has_node("Edge"):
		$Edge.visible = false
	GameTheme.apply_body(_name_label, 20, ThemeTokens.GOLD, 2)
	GameTheme.apply_body(_total_label, 15, ThemeTokens.CREAM, 2)

func set_display_name(value: String) -> void:
	_name_label.text = value

func set_total(total: int) -> void:
	set_breakdown(0, 0, total)

func set_breakdown(threat: int, might: int, power: int, arm_l: int = 0, arm_r: int = 0) -> void:
	_total_label.text = "Cabeça %d   Tronco %d   E %d   D %d   ·   %d" % [threat, might, arm_l, arm_r, power]

func set_from_loadout(loadout: FighterLoadout) -> void:
	if loadout == null:
		set_breakdown(0, 0, 0)
		return
	set_breakdown(
		loadout.combat_value_of(PartSlotType.Value.HEAD),
		loadout.combat_value_of(PartSlotType.Value.BODY),
		loadout.total_power(),
		loadout.combat_value_of(PartSlotType.Value.ARM_L),
		loadout.combat_value_of(PartSlotType.Value.ARM_R)
	)

func set_complete(is_complete: bool) -> void:
	_complete_glow.visible = is_complete
	if is_complete:
		_complete_glow.modulate.a = 0.0
		var tween := create_tween()
		tween.tween_property(_complete_glow, "modulate:a", 1.0, 0.35).set_trans(Tween.TRANS_SINE)
