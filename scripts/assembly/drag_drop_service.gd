class_name DragDropService
extends Node

signal drag_started(part: PartView)
signal drag_ended(part: PartView, accepted: bool)

var _dragging: PartView = null
var _slots: Array[CharacterSlot] = []
var _tray: Node2D = null
var _hover_slot: CharacterSlot = null

func setup(slots: Array[CharacterSlot], tray: Node2D) -> void:
	_slots = slots
	_tray = tray

func begin_drag(part: PartView) -> void:
	if _dragging != null or part == null or not part.can_interact():
		return
	_dragging = part
	set_process(true)
	part.begin_drag()
	drag_started.emit(part)

func _process(_delta: float) -> void:
	if _dragging == null:
		return
	_dragging.global_position = get_viewport().get_mouse_position()
	_update_hover()

func _unhandled_input(event: InputEvent) -> void:
	if _dragging == null:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_finish_drag()
		get_viewport().set_input_as_handled()

func _update_hover() -> void:
	var next := _find_compatible_slot(_dragging)
	if next == _hover_slot:
		return
	if _hover_slot != null:
		_hover_slot.set_drop_highlight(false, _dragging.part_def.slot_type)
	_hover_slot = next
	if _hover_slot != null:
		_hover_slot.set_drop_highlight(true, _dragging.part_def.slot_type)

func _finish_drag() -> void:
	var part := _dragging
	_dragging = null
	set_process(false)
	if _hover_slot != null:
		_hover_slot.set_drop_highlight(false, part.part_def.slot_type)
	var accepted := false
	var target := _hover_slot
	_hover_slot = null
	if target != null and target.can_accept(part.part_def):
		accepted = target.try_attach(part)
	if not accepted:
		if part.is_attached():
			# Was pulled from a slot but drop failed — reattach to origin slot handled by part
			part.cancel_drag_return()
		else:
			part.return_to_tray()
	drag_ended.emit(part, accepted)

func notify_drag_process_needed() -> void:
	set_process(true)

func _find_compatible_slot(part: PartView) -> CharacterSlot:
	var mouse := get_viewport().get_mouse_position()
	for slot in _slots:
		if slot.can_accept_at(part.part_def, mouse):
			return slot
	return null
