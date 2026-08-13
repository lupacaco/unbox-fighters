class_name FightOverlay
extends Control

var _clash_index: Label
var _compare: RichTextLabel
var _damage: Label
var _x_mark: Label

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_clash_index = Label.new()
	_clash_index.position = Vector2(48, 28)
	_clash_index.size = Vector2(120, 80)
	_clash_index.add_theme_font_size_override("font_size", 64)
	_clash_index.add_theme_color_override("font_color", Color.WHITE)
	_clash_index.visible = false
	add_child(_clash_index)

	_compare = RichTextLabel.new()
	_compare.bbcode_enabled = true
	_compare.fit_content = true
	_compare.scroll_active = false
	_compare.position = Vector2(560, 120)
	_compare.size = Vector2(800, 120)
	_compare.add_theme_font_size_override("normal_font_size", 72)
	_compare.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_compare.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_compare.visible = false
	add_child(_compare)

	_damage = Label.new()
	_damage.position = Vector2(660, 260)
	_damage.size = Vector2(600, 80)
	_damage.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_damage.add_theme_font_size_override("font_size", 42)
	_damage.add_theme_color_override("font_color", ThemeTokens.X_RED)
	_damage.visible = false
	add_child(_damage)

	_x_mark = Label.new()
	_x_mark.text = "X"
	_x_mark.add_theme_font_size_override("font_size", 96)
	_x_mark.add_theme_color_override("font_color", ThemeTokens.X_RED)
	_x_mark.size = Vector2(120, 120)
	_x_mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_x_mark.visible = false
	_x_mark.z_index = 40
	add_child(_x_mark)

func reset() -> void:
	_clash_index.visible = false
	_compare.visible = false
	_damage.visible = false
	_x_mark.visible = false

func set_clash_index(index: int) -> void:
	_clash_index.text = str(index)
	_clash_index.visible = index > 0

func show_compare(left_value: int, right_value: int, left_color: Color, right_color: Color) -> void:
	var op := "="
	if left_value > right_value:
		op = ">"
	elif right_value > left_value:
		op = "<"
	_compare.text = "[center][color=#%s]%d[/color]  %s  [color=#%s]%d[/color][/center]" % [
		left_color.to_html(false), left_value, op, right_color.to_html(false), right_value
	]
	_compare.visible = true

func hide_compare() -> void:
	_compare.visible = false

func show_x_at(screen_pos: Vector2) -> void:
	_x_mark.position = screen_pos - Vector2(60, 60)
	_x_mark.visible = true
	_x_mark.modulate = Color.WHITE
	_x_mark.scale = Vector2(0.4, 0.4)
	var tween := create_tween()
	tween.tween_property(_x_mark, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func hide_x() -> void:
	_x_mark.visible = false

func show_damage(amount: int, to_player: bool) -> void:
	if amount <= 0:
		_damage.text = "EMPATE"
		_damage.add_theme_color_override("font_color", ThemeTokens.TEXT)
	elif to_player:
		_damage.text = "-%d HP" % amount
		_damage.add_theme_color_override("font_color", ThemeTokens.X_RED)
	else:
		_damage.text = "ACERTO  -%d" % amount
		_damage.add_theme_color_override("font_color", ThemeTokens.PREP_ORANGE)
	_damage.visible = true
	_damage.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(_damage, "modulate:a", 1.0, 0.2)
