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
var _tile: Control
var _syncing := false

func _ready() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	custom_minimum_size = Vector2(380, 280)
	_build()

func set_target(next_part: PartDef, next_pose: int) -> void:
	part = next_part
	pose = next_pose
	_sync_controls()
	if _tile != null:
		(_tile as MagnetTile).set_target(part, pose)

func _build() -> void:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 6)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_right", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	add_child(margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(row)

	var controls := VBoxContainer.new()
	controls.add_theme_constant_override("separation", 5)
	controls.custom_minimum_size.x = 132
	controls.size_flags_horizontal = 0
	controls.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_child(controls)

	_slot_pick = OptionButton.new()
	_slot_pick.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for slot in PartSlotType.visual_slots():
		_slot_pick.add_item(PartSlotType.display_label(slot))
		_slot_pick.set_item_metadata(_slot_pick.item_count - 1, int(slot))
	_slot_pick.item_selected.connect(_on_slot_selected)
	controls.add_child(_slot_pick)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 6)
	controls.add_child(top)

	var z_lab := Label.new()
	z_lab.text = "Z"
	top.add_child(z_lab)

	_z_spin = SpinBox.new()
	_z_spin.min_value = 1
	_z_spin.max_value = 9
	_z_spin.step = 1
	_z_spin.rounded = true
	_z_spin.custom_minimum_size.x = 64
	_z_spin.tooltip_text = "1 fica na frente. Número maior fica atrás."
	_z_spin.value_changed.connect(_on_z_changed)
	top.add_child(_z_spin)

	_flip_btn = Button.new()
	_flip_btn.toggle_mode = true
	_flip_btn.text = "Virar"
	_flip_btn.tooltip_text = "Espelha a imagem na horizontal."
	_flip_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_flip_btn.toggled.connect(_on_flip_toggled)
	controls.add_child(_flip_btn)

	_rotate_btn = Button.new()
	_rotate_btn.text = "Girar 90°"
	_rotate_btn.tooltip_text = "Gira a imagem 90 graus."
	_rotate_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rotate_btn.pressed.connect(_on_rotate_pressed)
	controls.add_child(_rotate_btn)

	_replace_btn = Button.new()
	_replace_btn.text = "Trocar imagem"
	_replace_btn.tooltip_text = "Escolhe um PNG ou WEBP do computador. O jogo grava em 200×200."
	_replace_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_replace_btn.pressed.connect(_on_replace_pressed)
	controls.add_child(_replace_btn)

	_tile = MagnetTile.new()
	_tile.custom_minimum_size = Vector2(260, 260)
	_tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tile.size_flags_vertical = Control.SIZE_EXPAND_FILL
	(_tile as MagnetTile).magnets_changed.connect(func() -> void: magnets_changed.emit())
	row.add_child(_tile)

func _sync_controls() -> void:
	_syncing = true
	if part == null:
		_slot_pick.disabled = true
		_z_spin.editable = false
		_flip_btn.disabled = true
		_rotate_btn.disabled = true
		_replace_btn.disabled = true
		_syncing = false
		return
	_slot_pick.disabled = false
	_z_spin.editable = true
	_flip_btn.disabled = false
	_rotate_btn.disabled = false
	_replace_btn.disabled = false
	_select_slot(part.slot_type)
	_z_spin.value = part.effective_draw_z()
	_flip_btn.button_pressed = part.flip_h_for(pose)
	_rotate_btn.text = "Girar 90°  (%d°)" % part.rotation_for(pose)
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
	transform_changed.emit()

func _on_replace_pressed() -> void:
	if part == null:
		return
	replace_requested.emit(part, pose)

func _save_part() -> void:
	if part == null or part.resource_path.is_empty():
		return
	ResourceSaver.save(part, part.resource_path)
