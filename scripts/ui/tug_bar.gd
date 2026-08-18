class_name TugBar
extends Node2D

## One wooden tube above the belts. Empty at 0. Blue grows left for you,
## red grows right for them. Never both at once. Liquids sit in front of the
## opaque glass, clipped so they stay inside the window.

var _frame: Sprite2D
var _player: Sprite2D
var _opponent: Sprite2D
var _shown: int = 0

func _ready() -> void:
	position = AssemblyLayout.TUG_CENTER
	scale = Vector2.ONE * AssemblyLayout.TUG_SCALE
	_frame = Sprite2D.new()
	_frame.name = "Frame"
	_frame.texture = load(AssemblyLayout.TUG_FRAME_TEX)
	_frame.centered = true
	_frame.z_index = 0
	add_child(_frame)

	var mask := Polygon2D.new()
	mask.name = "Glass"
	mask.color = Color.WHITE
	mask.polygon = _glass_polygon()
	mask.z_index = 1
	mask.clip_children = CanvasItem.CLIP_CHILDREN_ONLY
	add_child(mask)

	_player = _make_liquid(AssemblyLayout.TUG_PLAYER_TEX)
	_opponent = _make_liquid(AssemblyLayout.TUG_OPPONENT_TEX)
	mask.add_child(_player)
	mask.add_child(_opponent)
	set_tug(0, false)

func set_tug(value: int, animate: bool = true) -> void:
	var clamped := clampi(value, -MatchRules.TUG_MAX, MatchRules.TUG_MAX)
	var changed := clamped != _shown
	_shown = clamped
	_paint()
	if animate and changed and _frame != null:
		Feel.punch(_frame, Vector2(1.045, 0.92), Vector2.ONE)

## Used by the headless check to confirm the fill is actually drawn.
func player_fill_visible() -> bool:
	return _player != null and _player.visible

func opponent_fill_visible() -> bool:
	return _opponent != null and _opponent.visible

func _make_liquid(path: String) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = load(path)
	sprite.centered = false
	sprite.region_enabled = true
	sprite.visible = false
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
	var glass := AssemblyLayout.TUG_GLASS
	var full := tex.get_size()
	var max_w := glass.size.x * 0.5
	var w := max_w * ratio
	var h := minf(full.y, glass.size.y)
	var top := glass.position.y + (glass.size.y - h) * 0.5
	sprite.region_enabled = true
	if player_side:
		var src_w := full.x * ratio
		sprite.region_rect = Rect2(full.x - src_w, 0.0, src_w, full.y)
		sprite.position = Vector2(-w, top)
		sprite.scale = Vector2(w / maxf(src_w, 0.001), h / full.y)
	else:
		var src_w := full.x * ratio
		sprite.region_rect = Rect2(0.0, 0.0, src_w, full.y)
		sprite.position = Vector2(0.0, top)
		sprite.scale = Vector2(w / maxf(src_w, 0.001), h / full.y)

func _glass_polygon() -> PackedVector2Array:
	var glass := AssemblyLayout.TUG_GLASS
	return PackedVector2Array([
		glass.position,
		glass.position + Vector2(glass.size.x, 0.0),
		glass.end,
		glass.position + Vector2(0.0, glass.size.y),
	])
