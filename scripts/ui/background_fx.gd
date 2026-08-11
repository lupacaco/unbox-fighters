class_name BackgroundFX
extends Node2D

@onready var _bg: Sprite2D = $ArenaBackground
@onready var _vignette: Polygon2D = $Vignette
@onready var _dust: CPUParticles2D = $Dust

func _ready() -> void:
	_bg.texture = load("res://assets/ui/bg_premium.png")
	_bg.centered = true
	_bg.position = Vector2(960, 540)
	var tex_size := _bg.texture.get_size()
	_bg.scale = Vector2(1920.0 / tex_size.x, 1080.0 / tex_size.y)
	_bg.modulate = Color(0.92, 0.93, 0.95, 1)
	_configure_dust()
	_breathe_vignette()

func _configure_dust() -> void:
	_dust.emitting = true
	_dust.amount = 14
	_dust.lifetime = 7.0
	_dust.preprocess = 3.0
	_dust.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_dust.emission_rect_extents = Vector2(880, 360)
	_dust.direction = Vector2(0, -1)
	_dust.spread = 140.0
	_dust.gravity = Vector2(0, -2)
	_dust.initial_velocity_min = 2.0
	_dust.initial_velocity_max = 10.0
	_dust.scale_amount_min = 0.3
	_dust.scale_amount_max = 0.8
	_dust.color = Color(0.7, 0.75, 0.82, 0.18)

func _breathe_vignette() -> void:
	var tween := create_tween().set_loops()
	tween.tween_property(_vignette, "modulate:a", 0.55, 4.0).set_trans(Tween.TRANS_SINE)
	tween.tween_property(_vignette, "modulate:a", 0.75, 4.0).set_trans(Tween.TRANS_SINE)
