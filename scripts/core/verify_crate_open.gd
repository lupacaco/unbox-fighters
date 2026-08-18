extends SceneTree

## Buying from a shelf: the crate cracks open, the kit stands on the shelf ready
## to be dragged, and the wallet pays exactly the price printed on the crate.

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed: PackedScene = load("res://scenes/assembly/Assembly.tscn")
	var scene := packed.instantiate()
	root.add_child(scene)
	await create_timer(0.5).timeout

	var shelves := scene.get_node_or_null("Shelves")
	if shelves == null or shelves.get_child_count() == 0:
		push_error("VERIFY_FAIL no shelves")
		quit(1)
		return
	var shelf := shelves.get_child(0) as ShopShelf
	if shelf.offer == null:
		push_error("VERIFY_FAIL the first shelf should hold a crate")
		quit(1)
		return

	var crate := _crate_of(shelf)
	if crate == null:
		push_error("VERIFY_FAIL the crate drawing is missing")
		quit(1)
		return
	var intact: Texture2D = load("res://assets/boxes/box-01.png")
	var sprite := crate.get_node_or_null("Sprite") as Sprite2D
	if sprite == null or sprite.texture != intact:
		push_error("VERIFY_FAIL a fresh crate should be closed")
		quit(1)
		return

	var price := shelf.price
	if price < PartStats.MIN_PRICE:
		push_error("VERIFY_FAIL a crate should never be free")
		quit(1)
		return
	var wallet_before := _wallet(scene)

	shelf.buy_requested.emit(shelf)
	await create_timer(1.2).timeout

	if _wallet(scene) != wallet_before - price:
		push_error("VERIFY_FAIL buying should cost exactly the printed price")
		quit(1)
		return
	if not shelf.has_part():
		push_error("VERIFY_FAIL the kit should stand on the shelf after paying")
		quit(1)
		return
	if _crate_of(shelf) != null:
		push_error("VERIFY_FAIL the opened crate should be gone")
		quit(1)
		return

	var part := _part_of(shelf)
	if part == null or part.paid_price != price:
		push_error("VERIFY_FAIL the kit should remember what you paid")
		quit(1)
		return
	if part.sell_value() != PartStats.sell_price(price):
		push_error("VERIFY_FAIL selling should give back half, rounded up")
		quit(1)
		return
	if absf(part.global_position.y - shelf.surface().y) > 200.0:
		push_error("VERIFY_FAIL the kit should stand on its own shelf")
		quit(1)
		return

	print("VERIFY_CRATE_OPEN_PASS")
	quit(0)

func _crate_of(shelf: ShopShelf) -> Crate:
	for child in shelf.get_children():
		if child is Crate:
			return child
	return null

func _part_of(shelf: ShopShelf) -> PartView:
	for child in shelf.get_children():
		if child is PartView:
			return child
	return null

func _wallet(scene: Node) -> int:
	return (scene as AssemblyController).player_money()
