class_name GameTheme
extends Object

## Shared look for HUD text and buttons: gold rim, ink outline, display type.

const PATH_DISPLAY := "res://assets/fonts/BebasNeue-Regular.ttf"
const PATH_BODY := "res://assets/fonts/Oswald-Variable.ttf"
const INK := Color(0.05, 0.04, 0.07, 0.92)

static var _display: Font
static var _body: Font

static func display_font() -> Font:
	if _display == null:
		var file := FontFile.new()
		file.load_dynamic_font(PATH_DISPLAY)
		_display = file
	return _display


static func body_font() -> Font:
	if _body == null:
		var file := FontFile.new()
		file.load_dynamic_font(PATH_BODY)
		var variation := FontVariation.new()
		variation.base_font = file
		variation.variation_opentype = { &"wght": 600 }
		_body = variation
	return _body


static func apply_display(control: Control, size_px: int, color: Color, outline_px: int = 4) -> void:
	if control == null:
		return
	control.add_theme_font_override("font", display_font())
	control.add_theme_font_size_override("font_size", size_px)
	control.add_theme_color_override("font_color", color)
	control.add_theme_color_override("font_hover_color", color.lightened(0.08))
	control.add_theme_color_override("font_pressed_color", ThemeTokens.CREAM)
	control.add_theme_color_override("font_outline_color", INK)
	control.add_theme_constant_override("outline_size", outline_px)
	control.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
	control.add_theme_constant_override("shadow_offset_x", 0)
	control.add_theme_constant_override("shadow_offset_y", 2)


static func apply_body(control: Control, size_px: int, color: Color, outline_px: int = 2) -> void:
	if control == null:
		return
	control.add_theme_font_override("font", body_font())
	control.add_theme_font_size_override("font_size", size_px)
	control.add_theme_color_override("font_color", color)
	control.add_theme_color_override("font_outline_color", INK)
	control.add_theme_constant_override("outline_size", outline_px)
	control.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.4))
	control.add_theme_constant_override("shadow_offset_x", 0)
	control.add_theme_constant_override("shadow_offset_y", 1)


static func plate_style(fill: Color, hot: bool = false) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill.lightened(0.08) if hot else fill
	box.border_color = ThemeTokens.GOLD.lightened(0.12) if hot else ThemeTokens.GOLD
	box.set_border_width_all(2)
	box.set_corner_radius_all(6)
	box.shadow_color = Color(0, 0, 0, 0.55)
	box.shadow_size = 8
	box.shadow_offset = Vector2(0, 4)
	box.content_margin_left = 14
	box.content_margin_right = 14
	box.content_margin_top = 8
	box.content_margin_bottom = 8
	return box


static func paint_button(button: Button, fill: Color, font_px: int = 26) -> void:
	if button == null:
		return
	apply_display(button, font_px, ThemeTokens.CREAM, 3)
	button.add_theme_stylebox_override("normal", plate_style(fill, false))
	button.add_theme_stylebox_override("hover", plate_style(fill, true))
	button.add_theme_stylebox_override("pressed", plate_style(fill.darkened(0.08), true))
	button.add_theme_stylebox_override("focus", plate_style(fill, true))


static func make_button(text: String, center: Vector2, size: Vector2, fill: Color, font_px: int = 26) -> Button:
	var button := Button.new()
	button.text = text
	button.size = size
	button.position = AssemblyLayout.top_left(center, size)
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	paint_button(button, fill, font_px)
	Feel.wire_button(button)
	return button


static func make_label(text: String, font_px: int, center: Vector2, size: Vector2, color: Color, display: bool = true) -> Label:
	var label := Label.new()
	label.text = text
	label.size = size
	label.position = AssemblyLayout.top_left(center, size)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if display:
		apply_display(label, font_px, color)
	else:
		apply_body(label, font_px, color)
	return label


static func gold_token_style(filled: bool) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	if filled:
		box.bg_color = ThemeTokens.GOLD
		box.border_color = ThemeTokens.GOLD_DEEP
	else:
		box.bg_color = Color(0.12, 0.1, 0.08, 0.72)
		box.border_color = Color(0.32, 0.26, 0.18, 0.85)
	box.set_border_width_all(2)
	box.set_corner_radius_all(11)
	box.shadow_color = Color(0, 0, 0, 0.4)
	box.shadow_size = 3
	box.shadow_offset = Vector2(0, 2)
	return box
