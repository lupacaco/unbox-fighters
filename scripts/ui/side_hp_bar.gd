class_name SideHpBar
extends Node2D

## One wooden tube above a belt. Full at 50 life, empty at 0.
## Blue liquid for you, red liquid for them.

var player_side: bool = true

var _frame: Sprite2D
var _liquid: Sprite2D
var _caption: Label
var _value: Label
var _shown: int = -1

func setup(is_player: bool) -> void:
	player_side = is_player
	position = AssemblyLayout.hp_bar_center(is_player)
	scale = Vector2.ONE * AssemblyLayout.HP_SCALE
	_frame = Sprite2D.new()
	_frame.name = "Frame"
	_frame.texture = load(AssemblyLayout.HP_FRAME_TEX)
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

	_liquid = _make_liquid(AssemblyLayout.HP_PLAYER_TEX if is_player else AssemblyLayout.HP_OPPONENT_TEX)
	mask.add_child(_liquid)
	_add_captions()
	set_hp(MatchRules.PLAYER_HP, false)

func set_hp(value: int, animate: bool = true) -> void:
	var clamped := clampi(value, 0, MatchRules.PLAYER_HP)
	var changed := clamped != _shown
	_shown = clamped
	if _value != null:
		_value.text = str(clamped)
	_paint()
	if animate and changed and _frame != null:
		Feel.punch(_frame, Vector2(1.045, 0.92), Vector2.ONE)

func fill_visible() -> bool:
	return _liquid != null and _liquid.visible

func shown_hp() -> int:
	return _shown

func _add_captions() -> void:
	var names := Node2D.new()
	names.name = "Captions"
	names.scale = Vector2.ONE / maxf(AssemblyLayout.HP_SCALE, 0.01)
	names.z_index = 3
	add_child(names)
	var title := "JOGADOR" if player_side else "OPONENTE"
	_caption = GameTheme.make_label(title, 22, Vector2(0.0, -28.0), Vector2(220, 32), ThemeTokens.CREAM)
	_caption.name = "Caption"
	names.add_child(_caption)
	_value = GameTheme.make_label(str(MatchRules.PLAYER_HP), 28, Vector2(0.0, 2.0), Vector2(120, 36), ThemeTokens.CREAM)
	_value.name = "Value"
	names.add_child(_value)

func _make_liquid(path: String) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = load(path)
	sprite.centered = false
	sprite.region_enabled = true
	sprite.visible = false
	return sprite

func _paint() -> void:
	if _liquid == null:
		return
	var ratio := clampf(float(_shown) / float(MatchRules.PLAYER_HP), 0.0, 1.0)
	_liquid.visible = ratio > 0.001
	if not _liquid.visible:
		return
	var tex := _liquid.texture
	if tex == null:
		return
	var glass := AssemblyLayout.HP_GLASS
	var full := tex.get_size()
	var max_w := glass.size.x
	var w := max_w * ratio
	var h := minf(full.y, glass.size.y)
	var top := glass.position.y + (glass.size.y - h) * 0.5
	var src_w := full.x * ratio
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
