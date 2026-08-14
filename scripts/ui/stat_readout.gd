class_name StatReadout
extends Control

@onready var _name_label: Label = $NameLabel
@onready var _total_label: Label = $TotalLabel
@onready var _complete_glow: ColorRect = $CompleteGlow

func _ready() -> void:
	if has_node("Stats"):
		$Stats.visible = false

func set_display_name(value: String) -> void:
	_name_label.text = value

func set_total(total: int) -> void:
	set_breakdown(0, 0, total)

func set_breakdown(threat: int, might: int, power: int) -> void:
	_total_label.text = "Cabeça %d   Tronco %d   ·  %d" % [threat, might, power]

func set_from_loadout(loadout: FighterLoadout) -> void:
	if loadout == null:
		set_breakdown(0, 0, 0)
		return
	set_breakdown(
		loadout.combat_value_of(PartSlotType.Value.HEAD),
		loadout.combat_value_of(PartSlotType.Value.BODY),
		loadout.total_power()
	)

func set_complete(is_complete: bool) -> void:
	_complete_glow.visible = is_complete
	if is_complete:
		_complete_glow.modulate.a = 0.0
		var tween := create_tween()
		tween.tween_property(_complete_glow, "modulate:a", 1.0, 0.35).set_trans(Tween.TRANS_SINE)
