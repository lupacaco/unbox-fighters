class_name TugBar
extends Node2D

## One wooden tube above the belts. Empty at 0. Blue grows left for you,
## red grows right for them. Never both at once.

var _frame: Sprite2D
var _player: Sprite2D
var _opponent: Sprite2D
var _shown: int = 0

func _ready() -> void:
	position = AssemblyLayout.TUG_CENTER
	_player = _make_liquid(AssemblyLayout.TUG_PLAYER_TEX)
	_opponent = _make_liquid(AssemblyLayout.TUG_OPPONENT_TEX)
	_frame = Sprite2D.new()
	_frame.name = "Frame"
	_frame.texture = load(AssemblyLayout.TUG_FRAME_TEX)
	_frame.centered = true
	_frame.z_index = 1
	add_child(_frame)
	set_tug(0, false)

func set_tug(value: int, animate: bool = true) -> void:
	var clamped := clampi(value, -MatchRules.TUG_MAX, MatchRules.TUG_MAX)
	var changed := clamped != _shown
	_shown = clamped
	_paint()
	if animate and changed:
		Feel.punch(self, Vector2(1.045, 0.92), Vector2.ONE)

func _make_liquid(path: String) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = load(path)
	sprite.centered = false
	sprite.region_enabled = true
	sprite.z_index = 0
	sprite.visible = false
	add_child(sprite)
	return sprite

func _paint() -> void:
	if _player == null or _opponent == null:
		return
	var ratio := clampf(float(absi(_shown)) / float(MatchRules.TUG_MAX), 0.0, 1.0)
	if _shown < 0:
		_opponent.visible = false
		_player.visible = ratio > 0.001
		_clip_from_center(_player, true, ratio)
	elif _shown > 0:
		_player.visible = false
		_opponent.visible = ratio > 0.001
		_clip_from_center(_opponent, false, ratio)
	else:
		_player.visible = false
		_opponent.visible = false

func _clip_from_center(sprite: Sprite2D, player_side: bool, ratio: float) -> void:
	var tex := sprite.texture
	if tex == null:
		return
	var full := tex.get_size()
	var w := full.x * ratio
	var h := full.y
	sprite.region_enabled = true
	if player_side:
		sprite.region_rect = Rect2(full.x - w, 0.0, w, h)
		sprite.position = Vector2(-w, -h * 0.5)
	else:
		sprite.region_rect = Rect2(0.0, 0.0, w, h)
		sprite.position = Vector2(0.0, -h * 0.5)
