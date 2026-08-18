class_name DragDropService
extends Node

## Carries a kit from the shelf to a card, or to the VENDER button.
## A short press with no movement counts as a click, which picks the kit
## instead of moving it, so the VENDER button knows what to buy back.

signal drag_started(part: PartView)
signal drag_ended(part: PartView, accepted: bool)
signal sell_requested(part: PartView)
signal part_clicked(part: PartView)

## How far the mouse may wander and still count as a click, not a drag.
const CLICK_SLOP := 8.0

var _dragging: PartView = null
var _cards: Array[CharacterSlot] = []
var _action_bar: ActionBar = null
var _hover_card: CharacterSlot = null
var _locked: bool = false
var _last_mouse := Vector2.ZERO
var _press_at := Vector2.ZERO
var _moved: bool = false
var _over_sell: bool = false

func setup(cards: Array[CharacterSlot], action_bar: ActionBar) -> void:
	_cards = cards
	_action_bar = action_bar

func set_locked(locked: bool) -> void:
	_locked = locked
	if not locked:
		return
	if _dragging != null:
		_dragging.return_home()
	_clear_drag_visuals()

func is_locked() -> bool:
	return _locked

func is_dragging() -> bool:
	return _dragging != null

func begin_drag(part: PartView) -> void:
	if _locked or _dragging != null or part == null or not part.can_interact():
		return
	_dragging = part
	_press_at = get_viewport().get_mouse_position()
	_last_mouse = _press_at
	_moved = false
	set_process(true)
	part.begin_drag()
	GameAudio.part_pickup()
	drag_started.emit(part)

func notify_drag_process_needed() -> void:
	set_process(true)

func _process(_delta: float) -> void:
	if _dragging == null:
		set_process(false)
		return
	var mouse := get_viewport().get_mouse_position()
	if not _moved and mouse.distance_to(_press_at) > CLICK_SLOP:
		_moved = true
	_dragging.apply_drag_tilt(mouse.x - _last_mouse.x)
	_last_mouse = mouse
	_dragging.global_position = mouse
	_update_hover(mouse)

func _unhandled_input(event: InputEvent) -> void:
	if _dragging == null:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_finish_drag()
		get_viewport().set_input_as_handled()

func _update_hover(mouse: Vector2) -> void:
	var sell_hot := _sell_contains(mouse)
	if sell_hot != _over_sell:
		_over_sell = sell_hot
		if _action_bar != null:
			_action_bar.set_drop_hot(sell_hot)
	var next: CharacterSlot = null
	if not sell_hot:
		for card in _cards:
			if card.can_accept_at(_dragging.part_def, mouse):
				next = card
				break
	if next == _hover_card:
		_dragging.set_over_target(next != null or sell_hot)
		return
	if _hover_card != null:
		_hover_card.set_drop_highlight(false)
	_hover_card = next
	if _hover_card != null:
		_hover_card.set_drop_highlight(true)
	_dragging.set_over_target(_hover_card != null or sell_hot)

func _finish_drag() -> void:
	var part := _dragging
	var was_click := not _moved
	var target := _hover_card
	var sold := _over_sell
	_clear_drag_visuals()
	part.set_over_target(false)
	if sold:
		sell_requested.emit(part)
		drag_ended.emit(part, true)
		return
	var accepted := not was_click and target != null and target.try_attach(part)
	if not accepted:
		part.return_home()
		if was_click:
			part_clicked.emit(part)
		else:
			GameAudio.part_reject()
	drag_ended.emit(part, accepted)

func _sell_contains(mouse: Vector2) -> bool:
	if _action_bar == null:
		return false
	return _action_bar.sell_button_rect().has_point(_action_bar.to_local(mouse))

func _clear_drag_visuals() -> void:
	if _hover_card != null:
		_hover_card.set_drop_highlight(false)
		_hover_card = null
	if _over_sell and _action_bar != null:
		_action_bar.set_drop_hot(false)
	_over_sell = false
	_dragging = null
	_moved = false
	set_process(false)
