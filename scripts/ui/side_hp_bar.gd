class_name SideHpBar
extends Node2D

## A wooden tube on the far side of the screen. Full at 50 life, empty at 0.
## Blue liquid for you (left), red liquid for them (right). Fill rises from
## the bottom after the tube is stood on end.

var player_side: bool = true

var _tube: Node2D
var _frame: Sprite2D
var _liquid: Sprite2D
var _caption: Label
var _value: Label
var _shown: int = -1
var _visual_ratio: float = 1.0
var _fill_tween: Tween

func setup(is_player: bool) -> void:
	player_side = is_player
	position = AssemblyLayout.hp_bar_center(is_player)
	_build_tube()
	_add_captions()
	set_hp(MatchRules.PLAYER_HP, false)

func set_hp(value: int, animate: bool = true) -> void:
	var clamped := clampi(value, 0, MatchRules.PLAYER_HP)
	var changed := clamped != _shown
	_shown = clamped
	if _value != null:
		_value.text = str(clamped)
	var ratio := clampf(float(clamped) / float(MatchRules.PLAYER_HP), 0.0, 1.0)
	if animate and changed:
		_tween_fill(ratio)
		if _tube != null:
			Feel.punch(_tube, Vector2(1.06, 0.94), Vector2.ONE)
	else:
		_kill_fill_tween()
		_set_fill(ratio)

func fill_visible() -> bool:
	return _liquid != null and _liquid.visible

func shown_hp() -> int:
	return _shown

func _build_tube() -> void:
	_tube = Node2D.new()
	_tube.name = "Tube"
	_tube.rotation = AssemblyLayout.HP_TUBE_ROTATION
	_tube.scale = Vector2.ONE * AssemblyLayout.HP_SCALE
	add_child(_tube)

	_frame = Sprite2D.new()
	_frame.name = "Frame"
	_frame.texture = load(AssemblyLayout.HP_FRAME_TEX)
	_frame.centered = true
	_frame.z_index = 0
	_tube.add_child(_frame)

	var mask := Polygon2D.new()
	mask.name = "Glass"
	mask.color = Color.WHITE
	mask.polygon = _glass_polygon()
	mask.z_index = 1
	mask.clip_children = CanvasItem.CLIP_CHILDREN_ONLY
	_tube.add_child(mask)

	_liquid = _make_liquid(AssemblyLayout.HP_PLAYER_TEX if player_side else AssemblyLayout.HP_OPPONENT_TEX)
	mask.add_child(_liquid)

func _add_captions() -> void:
	var names := Node2D.new()
	names.name = "Captions"
	names.z_index = 3
	add_child(names)
	var title := "JOGADOR" if player_side else "OPONENTE"
	var side := 58.0 if player_side else -58.0
	_caption = GameTheme.make_label(title, 20, Vector2(side, -36.0), Vector2(160, 28), ThemeTokens.CREAM)
	_caption.name = "Caption"
	names.add_child(_caption)
	_value = GameTheme.make_label(str(MatchRules.PLAYER_HP), 34, Vector2(side, 4.0), Vector2(120, 40), ThemeTokens.CREAM)
	_value.name = "Value"
	names.add_child(_value)

func _make_liquid(path: String) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = load(path)
	sprite.centered = false
	sprite.region_enabled = true
	sprite.visible = false
	return sprite

func _tween_fill(ratio: float) -> void:
	_kill_fill_tween()
	_fill_tween = create_tween()
	_fill_tween.tween_method(_set_fill, _visual_ratio, ratio, 0.22).set_trans(Tween.TRANS_SINE)

func _kill_fill_tween() -> void:
	if _fill_tween != null and _fill_tween.is_valid():
		_fill_tween.kill()
	_fill_tween = null

func _set_fill(ratio: float) -> void:
	_visual_ratio = clampf(ratio, 0.0, 1.0)
	_paint()

func _paint() -> void:
	if _liquid == null:
		return
	_liquid.visible = _visual_ratio > 0.001
	if not _liquid.visible:
		return
	var tex := _liquid.texture
	if tex == null:
		return
	var glass := AssemblyLayout.HP_GLASS
	var full := tex.get_size()
	var max_w := glass.size.x
	var w := max_w * _visual_ratio
	var h := minf(full.y, glass.size.y)
	var top := glass.position.y + (glass.size.y - h) * 0.5
	var src_w := full.x * _visual_ratio
	_liquid.region_enabled = true
	_liquid.region_rect = Rect2(0.0, 0.0, src_w, full.y)
	_liquid.position = Vector2(glass.position.x, top)
	_liquid.scale = Vector2(w / maxf(src_w, 0.001), h / full.y)

func _glass_polygon() -> PackedVector2Array:
	var glass := AssemblyLayout.HP_GLASS
	return PackedVector2Array([
		glass.position,
		glass.position + Vector2(glass.size.x, 0.0),
		glass.end,
		glass.position + Vector2(0.0, glass.size.y),
	])
