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
	if not await _check_crate_stays_same_size(scene):
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
	var crate := cards.get_child(0).get_node_or_null("Display/CrateBase") as Sprite2D
	if crate == null or crate.texture == null:
		push_error("VERIFY_FAIL every card should show the shared crate")
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
	if hud == null or hud.get_node_or_null("MoneyBar") == null or hud.get_node_or_null("ActionBar") == null:
		push_error("VERIFY_FAIL money and the round buttons should sit in the HUD")
		return false
	var tug := scene.get_node_or_null("TugBar") as TugBar
	if tug == null:
		push_error("VERIFY_FAIL the tug bar should sit on the match screen, not in the HUD")
		return false
	if AssemblyLayout.TUG_CENTER.y > 100.0:
		push_error("VERIFY_FAIL the tug bar should sit at the top of the screen")
		return false
	if absf(tug.position.y - AssemblyLayout.TUG_CENTER.y) > 1.0:
		push_error("VERIFY_FAIL the tug bar should use the layout center")
		return false
	var freaks := scene.get_node_or_null("Freaks") as Node2D
	if freaks == null:
		push_error("VERIFY_FAIL missing Freaks layer")
		return false
	if not tug.has_side_captions():
		push_error("VERIFY_FAIL the tug bar should read JOGADOR on the left and OPONENTE on the right")
		return false
	if absf(AssemblyLayout.CARD_CENTER_Y - AssemblyLayout.CARD_SIZE.y * 0.5) > 1.0:
		push_error("VERIFY_FAIL the four cards should hang flush with the top of the screen")
		return false
	if AssemblyLayout.BELT_FREAK_SCALE < 0.8:
		push_error("VERIFY_FAIL Freaks on the belts should be close to card size")
		return false
	tug.set_tug(-25, false)
	if not tug.player_fill_visible() or tug.opponent_fill_visible():
		push_error("VERIFY_FAIL your side of the bar should fill left from the middle")
		return false
	tug.set_tug(25, false)
	if not tug.opponent_fill_visible() or tug.player_fill_visible():
		push_error("VERIFY_FAIL their side of the bar should fill right from the middle")
		return false
	tug.set_tug(0, false)
	if absf(AssemblyLayout.SHELF_CENTER.x - AssemblyLayout.CENTER_X) > 0.5:
		push_error("VERIFY_FAIL the shop shelf should sit on the screen center")
		return false
	if absf(AssemblyLayout.CARD_X[0] + AssemblyLayout.CARD_OPPONENT_X[1] - AssemblyLayout.WIDTH) > 1.0:
		push_error("VERIFY_FAIL the outer cards should mirror each other")
		return false
	if absf(AssemblyLayout.CARD_X[1] + AssemblyLayout.CARD_OPPONENT_X[0] - AssemblyLayout.WIDTH) > 1.0:
		push_error("VERIFY_FAIL the inner cards should mirror each other")
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

func _check_crate_stays_same_size(scene: Node) -> bool:
	var cards := scene.get_node_or_null("Cards")
	if cards == null or cards.get_child_count() < 2:
		push_error("VERIFY_FAIL need two player cards to compare the crate")
		return false
	var empty := cards.get_child(0) as CharacterSlot
	var occupied := cards.get_child(1) as CharacterSlot
	var rest := Vector2.ONE * AssemblyLayout.CARD_FREAK_SCALE
	var empty_display := empty.get_node_or_null("Display") as Node2D
	if empty_display == null or not empty_display.scale.is_equal_approx(rest):
		push_error("VERIFY_FAIL an empty card should keep the crate at card size")
		return false
	var bruxa: CharacterDef = load("res://data/parts/bruxa_character.tres")
	var packed: PackedScene = load("res://scenes/assembly/PartView.tscn")
	if bruxa == null or bruxa.body == null or packed == null:
		push_error("VERIFY_FAIL missing a body kit to drop on a card")
		return false
	var view := packed.instantiate() as PartView
	scene.add_child(view)
	view.setup(bruxa.body, null)
	if not occupied.try_attach(view):
		push_error("VERIFY_FAIL could not drop a body on a card")
		return false
	await create_timer(0.3).timeout
	var occupied_display := occupied.get_node_or_null("Display") as Node2D
	if occupied_display == null or not occupied_display.scale.is_equal_approx(rest):
		push_error("VERIFY_FAIL dropping a kit should not grow the crate")
		return false
	var empty_crate := empty.get_node_or_null("Display/CrateBase") as Sprite2D
	var occupied_crate := occupied.get_node_or_null("Display/CrateBase") as Sprite2D
	if empty_crate == null or occupied_crate == null:
		push_error("VERIFY_FAIL both cards should show the shared crate")
		return false
	if not empty_crate.global_scale.is_equal_approx(occupied_crate.global_scale):
		push_error("VERIFY_FAIL the crate must be the same size empty or filled")
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
