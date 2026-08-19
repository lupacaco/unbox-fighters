class_name CratePlaque
extends Node2D

## Name and numbers painted on the crate's front panel.
## White = the printed kit number. Green = above it. Red = below it.

const ATTACK_ICON_PATH := "res://assets/nova-ui/ataque.png"
const HP_ICON_PATH := "res://assets/nova-ui/hp.png"
const TITLE_SIZE := 30
const STAT_SIZE := 48
const ICON_PX := 42.0
const LABEL_SIZE := Vector2(72, 58)

var _title: Label
var _attack: Label
var _hp: Label
var _attack_icon: Sprite2D
var _hp_icon: Sprite2D
var _attack_row: Node2D
var _hp_row: Node2D
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
	var squash := Vector2(rest.x * 1.08, rest.y * 0.92)
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


func _set_stat(row: Node2D, label: Label, current: int, base: int, is_attack: bool) -> void:
	var show := current > 0
	var previous := shown_attack() if is_attack else shown_hp()
	row.visible = show
	if not show:
		return
	label.text = str(current)
	label.add_theme_color_override("font_color", color_for(current, base))
	if visible and previous != current:
		Feel.punch(row, Vector2(1.16, 0.88), Vector2.ONE)


func _build() -> void:
	z_index = 6
	_title = _make_label(TITLE_SIZE)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_title)

	_attack_row = Node2D.new()
	_attack_row.name = "Attack"
	add_child(_attack_row)
	_attack = _make_label(STAT_SIZE)
	_attack_row.add_child(_attack)
	_attack_icon = _make_icon(ATTACK_ICON_PATH)
	_attack_row.add_child(_attack_icon)

	_hp_row = Node2D.new()
	_hp_row.name = "HP"
	add_child(_hp_row)
	_hp = _make_label(STAT_SIZE)
	_hp_row.add_child(_hp)
	_hp_icon = _make_icon(HP_ICON_PATH)
	_hp_row.add_child(_hp_icon)

	_layout()


func _make_label(size_px: int) -> Label:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.size = LABEL_SIZE
	GameTheme.apply_display(label, size_px, ThemeTokens.STAT_FLAT, 5)
	return label


func _make_icon(path: String) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = load(path) as Texture2D
	sprite.centered = true
	var side := ICON_PX
	if sprite.texture != null:
		side = maxf(float(sprite.texture.get_width()), float(sprite.texture.get_height()))
	sprite.scale = Vector2.ONE * (ICON_PX / maxf(side, 1.0))
	return sprite


func _layout() -> void:
	var panel := CompositeResolver.crate_front_size()
	_title.position = Vector2(-panel.x * 0.44, -panel.y * 0.40)
	_title.size = Vector2(panel.x * 0.88, 36.0)
	var row_y := panel.y * 0.12
	_place_row(_attack_row, _attack, _attack_icon, Vector2(-panel.x * 0.22, row_y))
	_place_row(_hp_row, _hp, _hp_icon, Vector2(panel.x * 0.24, row_y))


func _place_row(row: Node2D, label: Label, icon: Sprite2D, center: Vector2) -> void:
	row.position = center
	label.size = LABEL_SIZE
	label.position = Vector2(-LABEL_SIZE.x - 2.0, -LABEL_SIZE.y * 0.5)
	icon.position = Vector2(ICON_PX * 0.52, 0.0)
