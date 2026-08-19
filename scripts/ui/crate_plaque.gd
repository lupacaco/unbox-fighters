class_name CratePlaque
extends Node2D

## Name and numbers painted on the crate's black inner panel.
## White = the printed kit number. Green = above it. Red = below it.

const ATTACK_ICON_PATH := "res://assets/nova-ui/ataque.png"
const HP_ICON_PATH := "res://assets/nova-ui/hp.png"
const PANEL_PAD := 4.0

var _board: Control
var _title: Label
var _attack: Label
var _hp: Label
var _attack_icon: TextureRect
var _hp_icon: TextureRect
var _attack_row: Control
var _hp_row: Control
var _shown_title := "FREAK"
var _shown_attack := 0
var _shown_hp := 0


func _ready() -> void:
	if _title != null:
		return
	_build()


func show_loadout(loadout: FighterLoadout, current_hp: int = -1) -> void:
	if _title == null:
		_build()
	if loadout == null or loadout.is_empty():
		visible = false
		return
	visible = true
	_shown_title = loadout.crate_title()
	_title.text = _shown_title
	_set_stat(
		_attack_row, _attack, loadout.stat_of(PartSlotType.Value.HEAD),
		loadout.base_stat_of(PartSlotType.Value.HEAD), true
	)
	var hp := current_hp if current_hp >= 0 else loadout.stat_of(PartSlotType.Value.BODY)
	_set_stat(
		_hp_row, _hp, hp, loadout.base_stat_of(PartSlotType.Value.BODY), false
	)
	_shown_attack = loadout.stat_of(PartSlotType.Value.HEAD)
	_shown_hp = hp
	_layout()


func set_hp(current: int, base: int) -> void:
	if _hp == null:
		_build()
	_set_stat(_hp_row, _hp, current, base, false)
	_shown_hp = current
	_layout()


func play_pulse() -> void:
	if not visible:
		return
	var rest := scale
	var squash := Vector2(rest.x * 1.04, rest.y * 0.97)
	Feel.punch(self, squash, rest)


func shown_title() -> String:
	return _shown_title


func shown_attack() -> int:
	return _shown_attack


func shown_hp() -> int:
	return _shown_hp


static func color_for(current: int, base: int) -> Color:
	if current > base:
		return ThemeTokens.STAT_UP
	if current < base:
		return ThemeTokens.STAT_DOWN
	return ThemeTokens.STAT_FLAT


func _set_stat(row: Control, label: Label, current: int, base: int, is_attack: bool) -> void:
	var show := current > 0
	var previous := shown_attack() if is_attack else shown_hp()
	row.visible = show
	if not show:
		return
	label.text = str(current)
	label.add_theme_color_override("font_color", color_for(current, base))
	if visible and previous != current:
		Feel.punch(row, Vector2(1.06, 0.96), Vector2.ONE)


func _build() -> void:
	_board = Control.new()
	_board.name = "Board"
	_board.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_board.clip_contents = true
	add_child(_board)

	_title = _make_label()
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.clip_text = true
	_board.add_child(_title)

	_attack_row = _make_row("Attack")
	_board.add_child(_attack_row)
	_attack = _make_label()
	_attack_row.add_child(_attack)
	_attack_icon = _make_icon(ATTACK_ICON_PATH)
	_attack_row.add_child(_attack_icon)

	_hp_row = _make_row("HP")
	_board.add_child(_hp_row)
	_hp = _make_label()
	_hp_row.add_child(_hp)
	_hp_icon = _make_icon(HP_ICON_PATH)
	_hp_row.add_child(_hp_icon)

	_layout()


func _make_row(row_name: String) -> Control:
	var row := Control.new()
	row.name = row_name
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return row


func _make_label() -> Label:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	GameTheme.apply_display(label, 20, ThemeTokens.STAT_FLAT, 3)
	return label


func _make_icon(path: String) -> TextureRect:
	var icon := TextureRect.new()
	icon.texture = load(path) as Texture2D
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return icon


func _layout() -> void:
	var box := CompositeResolver.crate_front_panel_rect()
	_board.position = box.position
	_board.size = box.size
	var inner := Rect2(Vector2.ZERO, box.size).grow(-PANEL_PAD)
	var title_h := inner.size.y * 0.40
	_title.position = inner.position
	_title.size = Vector2(inner.size.x, title_h)
	GameTheme.apply_display(_title, maxi(14, int(title_h * 0.70)), ThemeTokens.STAT_FLAT, 3)
	var stats := Rect2(inner.position + Vector2(0.0, title_h), Vector2(inner.size.x, inner.size.y - title_h))
	var col_w := stats.size.x * 0.5
	_place_row(_attack_row, _attack, _attack_icon, Rect2(stats.position, Vector2(col_w, stats.size.y)))
	_place_row(
		_hp_row, _hp, _hp_icon,
		Rect2(stats.position + Vector2(col_w, 0.0), Vector2(col_w, stats.size.y))
	)


func _place_row(row: Control, label: Label, icon: TextureRect, col: Rect2) -> void:
	row.position = col.position
	row.size = col.size
	row.pivot_offset = col.size * 0.5
	var icon_side := minf(col.size.y - 2.0, col.size.x * 0.34)
	icon.size = Vector2(icon_side, icon_side)
	icon.position = Vector2(col.size.x - icon_side, (col.size.y - icon_side) * 0.5)
	var font_px := maxi(14, int(col.size.y * 0.62))
	var color := label.get_theme_color("font_color")
	GameTheme.apply_display(label, font_px, color, 3)
	label.size = Vector2(maxf(8.0, icon.position.x - 2.0), col.size.y)
	label.position = Vector2.ZERO
