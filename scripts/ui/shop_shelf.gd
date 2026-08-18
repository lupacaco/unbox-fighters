class_name ShopShelf
extends Node2D

## The wooden shop board. It holds a closed crate with a price, and after you
## pay, the kit that came out of it. Refresh dumps the closed crate into the
## gap; a kit you already paid for stays put.

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
	if part != null and offer == part and _crate != null and is_instance_valid(_crate):
		return
	clear()
	offer = part
	price = part_price
	if part == null:
		return
	_crate = CRATE_SCENE.instantiate() as Crate
	add_child(_crate)
	var rest := to_local(surface())
	_crate.position = rest + Vector2(0.0, -180.0)
	_crate.clicked.connect(func(_c: Crate) -> void: buy_requested.emit(self))
	_crate.setup(part_price)
	_crate.scale = Vector2(0.88, 0.88)
	var tween := _crate.create_tween()
	tween.tween_property(_crate, "position", rest, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(_crate, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func() -> void:
		if is_instance_valid(_crate):
			Feel.punch(_crate, Vector2(1.08, 0.9), Vector2.ONE)
			GameAudio.step()
	)

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

## Sends the closed crate in an arc into the gap. A paid kit is never dumped.
func dump_closed(host: Node2D) -> void:
	if has_part() or _crate == null or not is_instance_valid(_crate):
		return
	var crate := _crate
	_crate = null
	offer = null
	price = 0
	var start := crate.global_position
	var end_at := AssemblyLayout.dump_point()
	var peak := Vector2(lerpf(start.x, end_at.x, 0.4), minf(start.y, end_at.y) - 160.0)
	var parent := crate.get_parent()
	if parent != null:
		parent.remove_child(crate)
	if host == null:
		crate.queue_free()
		return
	host.add_child(crate)
	crate.global_position = start
	GameAudio.wood_slide()
	var tween := crate.create_tween()
	tween.tween_method(_follow_dump.bind(crate, start, peak, end_at), 0.0, 1.0, 0.48).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(crate, "modulate:a", 0.0, 0.2).set_delay(0.28)
	await tween.finished
	if is_instance_valid(crate):
		crate.queue_free()

func _follow_dump(t: float, crate: Node2D, start: Vector2, peak: Vector2, end_at: Vector2) -> void:
	if not is_instance_valid(crate):
		return
	crate.global_position = _arc(start, peak, end_at, t)
	crate.rotation_degrees = lerpf(0.0, 38.0, t)

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

func _arc(start: Vector2, peak: Vector2, finish: Vector2, t: float) -> Vector2:
	var u := 1.0 - t
	return u * u * start + 2.0 * u * t * peak + t * t * finish
