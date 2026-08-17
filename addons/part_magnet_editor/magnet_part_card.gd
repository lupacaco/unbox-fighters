@tool
extends PanelContainer

## One drawing: pick its role, flip, rotate, set Z, and drag magnets.

signal magnets_changed
signal slot_chosen(part: PartDef, slot: PartSlotType.Value)
signal transform_changed
signal replace_requested(part: PartDef, pose: int)

const MagnetTile := preload("res://addons/part_magnet_editor/magnet_tile.gd")

var part: PartDef
var pose: int = 0

var _slot_pick: OptionButton
var _z_spin: SpinBox
var _flip_btn: Button
var _rotate_btn: Button
var _replace_btn: Button
var _swap_btn: Button
var _expand_btn: Button
var _tile: Control
var _syncing := false
var _zoom_win: Window
var _zoom_tile: Control

func _ready() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	custom_minimum_size = Vector2(268, 184)
	_build()

func set_target(next_part: PartDef, next_pose: int) -> void:
	part = next_part
	pose = next_pose
	_sync_controls()
	if _tile != null:
		(_tile as MagnetTile).set_target(part, pose)
	if _zoom_tile != null and is_instance_valid(_zoom_tile):
		(_zoom_tile as MagnetTile).set_target(part, pose)

func _build() -> void:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 5)
	margin.add_theme_constant_override("margin_top", 5)
	margin.add_theme_constant_override("margin_right", 5)
	margin.add_theme_constant_override("margin_bottom", 5)
	add_child(margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(row)

	var controls := VBoxContainer.new()
	controls.add_theme_constant_override("separation", 4)
	controls.custom_minimum_size.x = 118
	controls.size_flags_horizontal = 0
	controls.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_child(controls)

	_slot_pick = OptionButton.new()
	_slot_pick.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for slot in PartSlotType.shop_slots():
		_slot_pick.add_item(PartSlotType.display_label(slot))
		_slot_pick.set_item_metadata(_slot_pick.item_count - 1, int(slot))
	_slot_pick.item_selected.connect(_on_slot_selected)
	controls.add_child(_slot_pick)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 4)
	controls.add_child(top)

	var z_lab := Label.new()
	z_lab.text = "Z"
	top.add_child(z_lab)

	_z_spin = SpinBox.new()
	_z_spin.min_value = 1
	_z_spin.max_value = 9
	_z_spin.step = 1
	_z_spin.rounded = true
	_z_spin.custom_minimum_size.x = 52
	_z_spin.tooltip_text = "Só a carta. 1 fica na frente. A luta tem ordem própria (frente e perfil)."
	_z_spin.value_changed.connect(_on_z_changed)
	top.add_child(_z_spin)

	var pose_row := HBoxContainer.new()
	pose_row.add_theme_constant_override("separation", 4)
	controls.add_child(pose_row)

	_flip_btn = Button.new()
	_flip_btn.toggle_mode = true
	_flip_btn.text = "Virar"
	_flip_btn.tooltip_text = "Espelha a imagem na horizontal."
	_flip_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_flip_btn.toggled.connect(_on_flip_toggled)
	pose_row.add_child(_flip_btn)

	_rotate_btn = Button.new()
	_rotate_btn.text = "Girar"
	_rotate_btn.tooltip_text = "Gira a imagem 90 graus."
	_rotate_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rotate_btn.pressed.connect(_on_rotate_pressed)
	pose_row.add_child(_rotate_btn)

	var file_row := HBoxContainer.new()
	file_row.add_theme_constant_override("separation", 4)
	controls.add_child(file_row)

	_replace_btn = Button.new()
	_replace_btn.text = "Imagem"
	_replace_btn.tooltip_text = "Escolhe um PNG da pasta do Freak para esta peça. Não apaga nem substitui arquivos."
	_replace_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_replace_btn.pressed.connect(_on_replace_pressed)
	file_row.add_child(_replace_btn)

	_swap_btn = Button.new()
	_swap_btn.text = "Trocar"
	_swap_btn.tooltip_text = "Errou o desenho? Escolhe outro PNG. A pasta fica igual; só muda o que esta peça usa."
	_swap_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_swap_btn.pressed.connect(_on_replace_pressed)
	file_row.add_child(_swap_btn)

	_expand_btn = Button.new()
	_expand_btn.text = "Ampliar"
	_expand_btn.tooltip_text = "Abre a imagem grande para marcar o ímã. Roda do mouse amplia."
	_expand_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_expand_btn.pressed.connect(_on_expand_pressed)
	controls.add_child(_expand_btn)

	_tile = MagnetTile.new()
	_tile.custom_minimum_size = Vector2(128, 128)
	_tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tile.size_flags_vertical = Control.SIZE_EXPAND_FILL
	(_tile as MagnetTile).magnets_changed.connect(func() -> void: magnets_changed.emit())
	(_tile as MagnetTile).expand_requested.connect(_on_expand_pressed)
	row.add_child(_tile)

func _sync_controls() -> void:
	_syncing = true
	if part == null:
		_slot_pick.disabled = true
		_z_spin.editable = false
		_flip_btn.disabled = true
		_rotate_btn.disabled = true
		_replace_btn.disabled = true
		_swap_btn.disabled = true
		_expand_btn.disabled = true
		_syncing = false
		return
	_slot_pick.disabled = false
	_z_spin.editable = true
	_flip_btn.disabled = false
	_rotate_btn.disabled = false
	_replace_btn.disabled = false
	_swap_btn.disabled = false
	_expand_btn.disabled = false
	_select_slot(part.slot_type)
	_z_spin.value = part.effective_draw_z()
	_flip_btn.button_pressed = part.flip_h_for(pose)
	_rotate_btn.text = "Girar (%d°)" % part.rotation_for(pose)
	_syncing = false

func _select_slot(slot: PartSlotType.Value) -> void:
	for i in _slot_pick.item_count:
		if int(_slot_pick.get_item_metadata(i)) == int(slot):
			_slot_pick.select(i)
			return

func _on_slot_selected(index: int) -> void:
	if _syncing or part == null:
		return
	var slot: PartSlotType.Value = _slot_pick.get_item_metadata(index) as PartSlotType.Value
	slot_chosen.emit(part, slot)

func _on_z_changed(value: float) -> void:
	if _syncing or part == null:
		return
	part.draw_z = int(value)
	part.emit_changed()
	_save_part()
	transform_changed.emit()

func _on_flip_toggled(on: bool) -> void:
	if _syncing or part == null:
		return
	part.set_flip_h_for(pose, on)
	part.emit_changed()
	_save_part()
	if _tile != null:
		_tile.queue_redraw()
	if _zoom_tile != null and is_instance_valid(_zoom_tile):
		_zoom_tile.queue_redraw()
	transform_changed.emit()

func _on_rotate_pressed() -> void:
	if part == null:
		return
	part.rotate_cw_90(pose)
	part.emit_changed()
	_save_part()
	_sync_controls()
	if _tile != null:
		(_tile as MagnetTile).set_target(part, pose)
	if _zoom_tile != null and is_instance_valid(_zoom_tile):
		(_zoom_tile as MagnetTile).set_target(part, pose)
	transform_changed.emit()

func _on_replace_pressed() -> void:
	if part == null:
		return
	replace_requested.emit(part, pose)

func _on_expand_pressed() -> void:
	if part == null:
		return
	_ensure_zoom_window()
	var tile := _zoom_tile as MagnetTile
	tile.start_zoom = 2.2
	tile.set_target(part, pose)
	_zoom_win.title = "Ímã — %s" % PartSlotType.display_label(part.slot_type)
	_zoom_win.popup_centered(Vector2i(720, 780))
	tile.call_deferred("reset_view")

func _ensure_zoom_window() -> void:
	if _zoom_win != null and is_instance_valid(_zoom_win):
		return
	_zoom_win = Window.new()
	_zoom_win.min_size = Vector2i(560, 620)
	_zoom_win.unresizable = false
	_zoom_win.exclusive = false
	_zoom_win.close_requested.connect(func() -> void: _zoom_win.hide())
	var root := MarginContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("margin_left", 12)
	root.add_theme_constant_override("margin_top", 10)
	root.add_theme_constant_override("margin_right", 12)
	root.add_theme_constant_override("margin_bottom", 12)
	_zoom_win.add_child(root)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(column)
	var help := Label.new()
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help.modulate = Color(0.78, 0.8, 0.84, 1)
	help.text = "Roda do mouse amplia. Botão direito (ou esquerdo no vazio) arrasta a imagem. Esquerdo na bolinha move o ímã. Clique duas vezes na miniatura também abre esta tela."
	column.add_child(help)
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 8)
	column.add_child(bar)
	var minus := Button.new()
	minus.text = "−"
	minus.custom_minimum_size = Vector2(40, 28)
	minus.pressed.connect(func() -> void: (_zoom_tile as MagnetTile).zoom_by(1.0 / 1.25))
	bar.add_child(minus)
	var plus := Button.new()
	plus.text = "+"
	plus.custom_minimum_size = Vector2(40, 28)
	plus.pressed.connect(func() -> void: (_zoom_tile as MagnetTile).zoom_by(1.25))
	bar.add_child(plus)
	var reset := Button.new()
	reset.text = "100%"
	reset.pressed.connect(func() -> void:
		(_zoom_tile as MagnetTile).start_zoom = 1.0
		(_zoom_tile as MagnetTile).reset_view()
	)
	bar.add_child(reset)
	_zoom_tile = MagnetTile.new()
	_zoom_tile.custom_minimum_size = Vector2(520, 520)
	_zoom_tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_zoom_tile.size_flags_vertical = Control.SIZE_EXPAND_FILL
	(_zoom_tile as MagnetTile).start_zoom = 2.2
	(_zoom_tile as MagnetTile).can_expand = false
	(_zoom_tile as MagnetTile).magnets_changed.connect(func() -> void:
		if _tile != null:
			_tile.queue_redraw()
		magnets_changed.emit()
	)
	column.add_child(_zoom_tile)
	var host := EditorInterface.get_base_control()
	host.add_child(_zoom_win)

func _exit_tree() -> void:
	if _zoom_win != null and is_instance_valid(_zoom_win):
		_zoom_win.queue_free()
	_zoom_win = null
	_zoom_tile = null

func _save_part() -> void:
	if part == null or part.resource_path.is_empty():
		return
	ResourceSaver.save(part, part.resource_path)
