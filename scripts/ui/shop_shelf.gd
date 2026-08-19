class_name ShopShelf
extends Node2D

## The wooden shop board. A kit sits on it already unwrapped, with a price tag.
## Drag it onto a card to pay. A kit you already own (back from a card) stays
## through a refresh.

signal owned_received(shelf: ShopShelf, part: PartView)
signal part_taken(shelf: ShopShelf)

const PART_SCENE := preload("res://scenes/assembly/PartView.tscn")

var index: int = 0
var offer: PartDef = null
var price: int = 0

var _board: Sprite2D
var _part: PartView
var _drag_service: DragDropService

func setup(shelf_index: int, drag_service: DragDropService) -> void:
	index = shelf_index
	_drag_service = drag_service
	position = AssemblyLayout.shelf_center(index)
	scale = Vector2.ONE * AssemblyLayout.SHELF_FIT
	add_to_group("shop_shelf")
	_build_board()

func surface() -> Vector2:
	return AssemblyLayout.shelf_surface(index)

## Puts a fresh for-sale kit on the shelf. A null part leaves it empty.
## A shelf still holding a kit you already paid for is never touched.
func show_offer(part: PartDef, part_price: int) -> void:
	if has_owned_part():
		return
	if part != null and offer == part and has_for_sale_part():
		return
	clear()
	offer = part
	price = part_price
	if part == null:
		return
	_part = PART_SCENE.instantiate() as PartView
	add_child(_part)
	_part.setup(part, _drag_service)
	_part.home_shelf = self
	_part.set_for_sale(part_price)
	_part.stand_on(surface(), AssemblyLayout.SHOP_PART_SCALE / maxf(AssemblyLayout.SHELF_FIT, 0.01))
	_part.play_reveal()
	GameAudio.step()

func set_affordable(can_pay: bool) -> void:
	if _part != null and is_instance_valid(_part):
		_part.set_affordable(can_pay)

func deny() -> void:
	if _part != null and is_instance_valid(_part):
		_part.play_reject()

func has_part() -> bool:
	return _part != null and is_instance_valid(_part) and not _part.is_attached()

func has_owned_part() -> bool:
	return has_part() and not _part.for_sale

func has_for_sale_part() -> bool:
	return has_part() and _part.for_sale

func peek_part() -> PartView:
	return _part if has_part() else null

func take_part() -> void:
	var was_owned := has_owned_part()
	_part = null
	offer = null
	price = 0
	if was_owned:
		part_taken.emit(self)

## A kit that came back from a card sits here as yours. Refresh will not dump it.
func receive_owned(part: PartView) -> void:
	if part == null or not is_instance_valid(part):
		return
	_part = part
	offer = part.part_def
	price = 0
	part.home_shelf = self
	part.for_sale = false
	part.hide_price()
	if part.get_parent() != self:
		var keep := part.global_position
		if part.get_parent() != null:
			part.get_parent().remove_child(part)
		add_child(part)
		part.global_position = keep
	part.stand_on(surface(), AssemblyLayout.SHOP_PART_SCALE / maxf(AssemblyLayout.SHELF_FIT, 0.01))
	owned_received.emit(self, part)

## Sends the for-sale kit in an arc into the gap. An owned kit is never dumped.
func dump_offer(host: Node2D) -> void:
	if not has_for_sale_part():
		return
	var part := _part
	_part = null
	offer = null
	price = 0
	var start := part.global_position
	var end_at := AssemblyLayout.dump_point()
	var peak := Vector2(lerpf(start.x, end_at.x, 0.4), minf(start.y, end_at.y) - 160.0)
	var parent := part.get_parent()
	if parent != null:
		parent.remove_child(part)
	if host == null:
		part.queue_free()
		return
	host.add_child(part)
	part.global_position = start
	GameAudio.wood_slide()
	var tween := part.create_tween()
	tween.tween_method(_follow_dump.bind(part, start, peak, end_at), 0.0, 1.0, 0.48).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(part, "modulate:a", 0.0, 0.2).set_delay(0.28)
	await tween.finished
	if is_instance_valid(part):
		part.queue_free()

func _follow_dump(t: float, part: Node2D, start: Vector2, peak: Vector2, end_at: Vector2) -> void:
	if not is_instance_valid(part):
		return
	part.global_position = _arc(start, peak, end_at, t)
	part.rotation_degrees = lerpf(0.0, 38.0, t)

func clear() -> void:
	offer = null
	price = 0
	if _part != null and is_instance_valid(_part) and not _part.is_attached():
		_part.queue_free()
	_part = null

func _build_board() -> void:
	if _board != null:
		return
	_board = Sprite2D.new()
	_board.name = "Board"
	_board.texture = load(AssemblyLayout.SHELF_TEX)
	_board.centered = true
	_board.z_index = -1
	add_child(_board)

func _arc(start: Vector2, peak: Vector2, finish: Vector2, t: float) -> Vector2:
	var u := 1.0 - t
	return u * u * start + 2.0 * u * t * peak + t * t * finish
