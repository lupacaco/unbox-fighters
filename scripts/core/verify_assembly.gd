extends SceneTree

## Opens the match screen for real and checks the furniture is all there and in
## the right place: two cards of yours, two of theirs, one shelf, two belts,
## money, the tug bar and the round buttons.

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed: PackedScene = load("res://scenes/assembly/Assembly.tscn")
	if packed == null:
		push_error("VERIFY_FAIL load Assembly.tscn")
		quit(1)
		return
	var scene := packed.instantiate()
	root.add_child(scene)
	await create_timer(0.5).timeout
	if not _check_furniture(scene):
		quit(1)
		return
	if not _check_belts(scene):
		quit(1)
		return
	if not _check_fonts():
		quit(1)
		return
	print("VERIFY_PASS")
	quit(0)

func _check_furniture(scene: Node) -> bool:
	var cards := scene.get_node_or_null("Cards")
	if cards == null or cards.get_child_count() != MatchRules.CARD_COUNT:
		push_error("VERIFY_FAIL expected %d cards" % MatchRules.CARD_COUNT)
		return false
	var opponent_cards := scene.get_node_or_null("OpponentCards")
	if opponent_cards == null or opponent_cards.get_child_count() != MatchRules.CARD_COUNT:
		push_error("VERIFY_FAIL expected %d opponent cards" % MatchRules.CARD_COUNT)
		return false
	for card in opponent_cards.get_children():
		if not (card as CharacterSlot).is_opponent:
			push_error("VERIFY_FAIL the red cards should be marked as the opponent's")
			return false
	var shelves := scene.get_node_or_null("Shelves")
	if shelves == null or shelves.get_child_count() != MatchRules.SHOP_SLOTS:
		push_error("VERIFY_FAIL expected %d shelves" % MatchRules.SHOP_SLOTS)
		return false
	for shelf in shelves.get_children():
		if (shelf as ShopShelf).offer == null:
			push_error("VERIFY_FAIL every shelf should open with a crate on it")
			return false
	var hud := scene.get_node_or_null("Hud")
	if hud == null or hud.get_node_or_null("TugBar") == null:
		push_error("VERIFY_FAIL the screen needs money, buttons and the tug bar")
		return false
	if hud.get_node_or_null("MoneyBar") == null or hud.get_node_or_null("ActionBar") == null:
		push_error("VERIFY_FAIL money and the round buttons should sit in the HUD")
		return false
	var background := scene.get_node_or_null("Background") as Sprite2D
	if background == null or background.texture == null:
		push_error("VERIFY_FAIL missing background")
		return false
	var cam := scene.get_node_or_null("Camera2D") as Camera2D
	if cam == null or not cam.zoom.is_equal_approx(Vector2.ONE):
		push_error("VERIFY_FAIL camera should stay at rest so the screen does not jump")
		return false
	return true

func _check_belts(scene: Node) -> bool:
	var belts := scene.get_node_or_null("Belts")
	if belts == null or belts.get_child_count() != 2:
		push_error("VERIFY_FAIL there should be two belts")
		return false
	var blue := belts.get_node_or_null("BeltPlayer") as Sprite2D
	var red := belts.get_node_or_null("BeltOpponent") as Sprite2D
	if blue == null or red == null or blue.texture == null or red.texture == null:
		push_error("VERIFY_FAIL missing belt art")
		return false
	if blue.position.x >= red.position.x:
		push_error("VERIFY_FAIL the blue belt is on the left, the red one on the right")
		return false
	var bottom := AssemblyLayout.belt_top() + AssemblyLayout.BELT_SIZE.y
	if absf(bottom - AssemblyLayout.HEIGHT) > 1.0:
		push_error("VERIFY_FAIL the belts should touch the bottom of the screen")
		return false
	if AssemblyLayout.belt_tip_x(true) >= AssemblyLayout.gap_center_x():
		push_error("VERIFY_FAIL the blue tip should stop before the gap")
		return false
	if AssemblyLayout.belt_tip_x(false) <= AssemblyLayout.gap_center_x():
		push_error("VERIFY_FAIL the red tip should stop after the gap")
		return false
	if AssemblyLayout.belt_travel_px(true) <= 0.0:
		push_error("VERIFY_FAIL a belt needs room to slide on")
		return false
	return true

func _check_fonts() -> bool:
	if not FileAccess.file_exists("res://assets/fonts/BebasNeue-Regular.ttf"):
		push_error("VERIFY_FAIL missing display font")
		return false
	if not FileAccess.file_exists("res://assets/fonts/Oswald-Variable.ttf"):
		push_error("VERIFY_FAIL missing body font")
		return false
	return true
