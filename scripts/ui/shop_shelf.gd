class_name ShopShelf
extends Node2D

## One of the four wooden shelves. It holds a closed crate with a price, and
## after you pay, the kit that came out of it, waiting to be dragged to a card.

signal buy_requested(shelf: ShopShelf)

const CRATE_SCENE := preload("res://scenes/assembly/Crate.tscn")
const PART_SCENE := preload("res://scenes/assembly/PartView.tscn")

var index: int = 0
var offer: PartDef = null
var price: int = 0

var _board: Sprite2D
var _crate: Crate
var _part: PartView
var _drag_service: DragDropService

func setup(shelf_index: int, drag_service: DragDropService) -> void:
	index = shelf_index
	_drag_service = drag_service
	position = AssemblyLayout.shelf_center(index)
	_build_board()

func surface() -> Vector2:
	return AssemblyLayout.shelf_surface(index)

## Puts a fresh closed crate on the shelf. A null part leaves it empty.
## A shelf still holding a kit you paid for is never touched.
func show_offer(part: PartDef, part_price: int) -> void:
	if has_part():
		return
	clear()
	offer = part
	price = part_price
	if part == null:
		return
	_crate = CRATE_SCENE.instantiate() as Crate
	add_child(_crate)
	_crate.position = to_local(surface())
	_crate.clicked.connect(func(_c: Crate) -> void: buy_requested.emit(self))
	_crate.setup(part_price)
	_crate.scale = Vector2(0.6, 0.6)
	_crate.modulate.a = 0.0
	var tween := _crate.create_tween()
	tween.tween_property(_crate, "modulate:a", 1.0, 0.16)
	tween.parallel().tween_property(_crate, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func set_affordable(can_pay: bool) -> void:
	if _crate != null and is_instance_valid(_crate):
		_crate.set_affordable(can_pay)

func deny() -> void:
	if _crate != null and is_instance_valid(_crate):
		_crate.play_reject()

## Cracks the crate and stands the kit on the shelf. Returns the new piece.
func open() -> PartView:
	if _crate == null or not is_instance_valid(_crate) or offer == null:
		return null
	var crate := _crate
	_crate = null
	await crate.play_open()
	if is_instance_valid(crate):
		crate.queue_free()
	_part = PART_SCENE.instantiate() as PartView
	add_child(_part)
	_part.setup(offer, _drag_service)
	_part.paid_price = price
	_part.home_shelf = self
	_part.stand_on(surface(), AssemblyLayout.SHOP_PART_SCALE)
	_part.play_reveal()
	offer = null
	return _part

func has_part() -> bool:
	return _part != null and is_instance_valid(_part) and not _part.is_attached()

func take_part() -> void:
	_part = null

## Takes the closed crate away. A kit you already paid for is never thrown out.
func clear() -> void:
	offer = null
	price = 0
	if _crate != null and is_instance_valid(_crate):
		_crate.queue_free()
	_crate = null

func _build_board() -> void:
	if _board != null:
		return
	_board = Sprite2D.new()
	_board.name = "Board"
	_board.texture = load(AssemblyLayout.SHELF_TEX)
	_board.centered = true
	_board.z_index = -1
	add_child(_board)
