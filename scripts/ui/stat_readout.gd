class_name StatReadout
extends Control

@onready var _name_label: Label = $NameLabel
@onready var _total_label: Label = $TotalLabel
@onready var _brain_label: Label = $Stats/Brain
@onready var _power_label: Label = $Stats/Power
@onready var _speed_label: Label = $Stats/Speed
@onready var _complete_glow: ColorRect = $CompleteGlow

func _ready() -> void:
	$Stats.visible = false

func set_display_name(value: String) -> void:
	_name_label.text = value

func set_stats(brain: int, power: int, speed: int) -> void:
	set_total(brain + power + speed)

func set_total(total: int) -> void:
	_total_label.text = str(total)

func set_complete(is_complete: bool) -> void:
	_complete_glow.visible = is_complete
	if is_complete:
		_complete_glow.modulate.a = 0.0
		var tween := create_tween()
		tween.tween_property(_complete_glow, "modulate:a", 1.0, 0.35).set_trans(Tween.TRANS_SINE)
