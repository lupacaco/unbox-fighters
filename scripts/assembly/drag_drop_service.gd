class_name DragDropService
extends Node

signal drag_started(part: PartView)
signal drag_ended(part: PartView, accepted: bool)
signal part_sold(part: PartView)
signal card_sold(slot: CharacterSlot)
signal cards_swapped(a: CharacterSlot, b: CharacterSlot)

var _dragging: PartView = null
var _dragging_card: CharacterSlot = null
var _slots: Array[CharacterSlot] = []
var _tray: Node2D = null
var _hover_slot: CharacterSlot = null
var _locked: bool = false
var _sell_zone: Area2D = null

func setup(slots: Array[CharacterSlot], tray: Node2D, sell_zone: Area2D = null) -> void:
	_slots = slots
	_tray = tray
	_sell_zone = sell_zone

func set_locked(locked: bool) -> void:
	_locked = locked
	if locked:
		if _dragging != null:
			_dragging.cancel_drag_return()
			_dragging = null
		_dragging_card = null
		_set_sell_highlight(false)
		set_process(false)

func is_locked() -> bool:
	return _locked

func begin_drag(part: PartView) -> void:
	if _locked or _dragging != null or _dragging_card != null or part == null or not part.can_interact():
		return
	_dragging = part
	set_process(true)
	part.begin_drag()
	GameAudio.part_pickup()
	drag_started.emit(part)

func begin_card_drag(slot: CharacterSlot) -> void:
	if _locked or _dragging != null or _dragging_card != null or slot == null:
		return
	_dragging_card = slot
	set_process(true)
	GameAudio.part_pickup()

func _process(_delta: float) -> void:
	if _dragging != null:
		_dragging.global_position = get_viewport().get_mouse_position()
		_update_hover()
		_update_sell_highlight()
	elif _dragging_card != null:
		_update_card_hover()
		_update_sell_highlight()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		if not _locked:
			_try_sell_under_mouse()
			get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		if _dragging != null:
			_finish_drag()
			get_viewport().set_input_as_handled()
		elif _dragging_card != null:
			_finish_card_drag()
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

func _update_card_hover() -> void:
	var next := _find_card_under_mouse()
	if next == _hover_slot:
		return
	if _hover_slot != null:
		_hover_slot.set_drop_highlight(false, PartSlotType.Value.BODY)
	_hover_slot = next
	if _hover_slot != null and _hover_slot != _dragging_card:
		_hover_slot.set_drop_highlight(true, PartSlotType.Value.BODY)

func _finish_drag() -> void:
	var part := _dragging
	_dragging = null
	set_process(false)
	if _hover_slot != null:
		_hover_slot.set_drop_highlight(false, part.part_def.slot_type)
	var target := _hover_slot
	_hover_slot = null
	_set_sell_highlight(false)
	if _is_over_sell():
		part_sold.emit(part)
		drag_ended.emit(part, true)
		return
	var accepted := false
	if target != null and target.can_accept(part.part_def):
		accepted = target.try_attach(part)
	if not accepted:
		if part.is_attached():
			part.cancel_drag_return()
		else:
			part.return_to_tray()
		GameAudio.part_reject()
	drag_ended.emit(part, accepted)

func _finish_card_drag() -> void:
	var card := _dragging_card
	_dragging_card = null
	set_process(false)
	if _hover_slot != null:
		_hover_slot.set_drop_highlight(false, PartSlotType.Value.BODY)
	var target := _hover_slot
	_hover_slot = null
	_set_sell_highlight(false)
	if _is_over_sell():
		card_sold.emit(card)
		return
	if target != null and target != card:
		cards_swapped.emit(card, target)
		return
	GameAudio.part_reject()

func notify_drag_process_needed() -> void:
	set_process(true)

func _is_over_sell() -> bool:
	if _sell_zone == null:
		return false
	var mouse := get_viewport().get_mouse_position()
	var rect: Rect2 = _sell_zone.get_meta("rect", Rect2())
	return rect.has_point(_sell_zone.to_local(mouse))

func _update_sell_highlight() -> void:
	_set_sell_highlight(_is_over_sell())

func _set_sell_highlight(on: bool) -> void:
	if _sell_zone != null and _sell_zone.has_method("set_highlight"):
		_sell_zone.set_highlight(on)

func _find_compatible_slot(part: PartView) -> CharacterSlot:
	var mouse := get_viewport().get_mouse_position()
	for slot in _slots:
		if slot.can_accept_at(part.part_def, mouse):
			return slot
	return null

func _find_card_under_mouse() -> CharacterSlot:
	var mouse := get_viewport().get_mouse_position()
	for slot in _slots:
		if slot.contains_card_point(mouse):
			return slot
	return null

func _try_sell_under_mouse() -> void:
	if _dragging != null:
		var dragged := _dragging
		_clear_drag_visuals()
		part_sold.emit(dragged)
		return
	if _dragging_card != null:
		return
	var mouse := get_viewport().get_mouse_position()
	var loose := _find_loose_part_at(mouse)
	if loose != null:
		part_sold.emit(loose)
		return
	for slot in _slots:
		var on_card := slot.find_part_at(mouse)
		if on_card != null:
			on_card.unbind_from_card()
			part_sold.emit(on_card)
			return

func _find_loose_part_at(mouse: Vector2) -> PartView:
	if _tray == null:
		return null
	for child in _tray.get_children():
		if child is PartView:
			var part := child as PartView
			if part.can_interact() and not part.is_attached() and part.contains_point(mouse):
				return part
	return null

func _clear_drag_visuals() -> void:
	if _hover_slot != null:
		_hover_slot.set_drop_highlight(false, PartSlotType.Value.BODY)
		_hover_slot = null
	_dragging = null
	_dragging_card = null
	_set_sell_highlight(false)
	set_process(false)
