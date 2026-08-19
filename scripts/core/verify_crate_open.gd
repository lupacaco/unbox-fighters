extends SceneTree

## Buying from a shelf: the kit is already unwrapped, with a price tag, ready
## to drag onto a card. There is no closed crate to crack.

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
		push_error("VERIFY_FAIL the first shelf should hold a kit")
		quit(1)
		return
	if _crate_of(shelf) != null:
		push_error("VERIFY_FAIL the shop should not show a closed crate")
		quit(1)
		return

	var price := shelf.price
	if price < PartStats.MIN_PRICE:
		push_error("VERIFY_FAIL a kit should never be free")
		quit(1)
		return
	var part := _part_of(shelf)
	if part == null:
		push_error("VERIFY_FAIL the kit should stand on the shelf already unwrapped")
		quit(1)
		return
	if not part.for_sale:
		push_error("VERIFY_FAIL a fresh kit is for sale until you drop it on a card")
		quit(1)
		return
	if part.sale_price != price:
		push_error("VERIFY_FAIL the kit should remember the printed price")
		quit(1)
		return
	if part.sell_value() != 0:
		push_error("VERIFY_FAIL you cannot sell a kit you have not paid for")
		quit(1)
		return
	if absf(part.global_position.y - shelf.surface().y) > 220.0:
		push_error("VERIFY_FAIL the kit should stand on its own shelf")
		quit(1)
		return
	if PartStats.sell_price(price) != MatchRules.SELL_REFUND:
		push_error("VERIFY_FAIL selling a paid kit should give $%d" % MatchRules.SELL_REFUND)
		quit(1)
		return

	print("VERIFY_CRATE_OPEN_PASS")
	quit(0)

func _crate_of(shelf: ShopShelf) -> Node:
	for child in shelf.get_children():
		if child is Crate:
			return child
	return null

func _part_of(shelf: ShopShelf) -> PartView:
	for child in shelf.get_children():
		if child is PartView:
			return child
	return null
