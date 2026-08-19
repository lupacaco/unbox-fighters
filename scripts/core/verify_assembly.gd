extends SceneTree

## Opens the match screen and checks the furniture: three cards of yours,
## three of theirs (hidden in prep), four shelves with kits already unwrapped,
## two life bars, the prep clock, two belts.

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
	var crate_back := cards.get_child(0).get_node_or_null("Display/CrateBack") as Sprite2D
	var crate_front := cards.get_child(0).get_node_or_null("Display/CrateFront") as Sprite2D
	if crate_back == null or crate_back.texture == null or crate_front == null or crate_front.texture == null:
		push_error("VERIFY_FAIL every card should show both crate pieces")
		return false
	var opponent_cards := scene.get_node_or_null("OpponentCards")
	if opponent_cards == null or opponent_cards.get_child_count() != MatchRules.CARD_COUNT:
		push_error("VERIFY_FAIL expected %d opponent cards" % MatchRules.CARD_COUNT)
		return false
	if opponent_cards.visible:
		push_error("VERIFY_FAIL opponent cards stay hidden during preparation")
		return false
	for card in opponent_cards.get_children():
		if not (card as CharacterSlot).is_opponent:
			push_error("VERIFY_FAIL the red cards should be marked as the opponent's")
			return false
	var shelves := scene.get_node_or_null("Shelves")
	if shelves == null or shelves.get_child_count() != MatchRules.SHOP_SLOTS:
		push_error("VERIFY_FAIL expected %d shelves" % MatchRules.SHOP_SLOTS)
		return false
	var seen := {}
	for shelf in shelves.get_children():
		var board := shelf as ShopShelf
		if board.offer == null:
			push_error("VERIFY_FAIL every shelf should open with a kit on it")
			return false
		if board.has_part() == false:
			push_error("VERIFY_FAIL the kit should already be unwrapped on the shelf")
			return false
		var key := "%d,%d" % [int(board.position.x), int(board.position.y)]
		if seen.has(key):
			push_error("VERIFY_FAIL the four shelves should not sit on top of each other")
			return false
		seen[key] = true
	var hud := scene.get_node_or_null("Hud")
	if hud == null or hud.get_node_or_null("MoneyBar") == null or hud.get_node_or_null("ActionBar") == null:
		push_error("VERIFY_FAIL money and the round buttons should sit in the HUD")
		return false
	var player_hp := scene.get_node_or_null("PlayerHpBar")
	var opponent_hp := scene.get_node_or_null("OpponentHpBar")
	if player_hp == null or opponent_hp == null:
		push_error("VERIFY_FAIL each side should have a life bar on the far edge")
		return false
	if player_hp.position.x > 100.0:
		push_error("VERIFY_FAIL your life bar should stand on the left edge")
		return false
	if opponent_hp.position.x < AssemblyLayout.WIDTH - 100.0:
		push_error("VERIFY_FAIL their life bar should stand on the right edge")
		return false
	if int(player_hp.shown_hp()) != MatchRules.PLAYER_HP or int(opponent_hp.shown_hp()) != MatchRules.PLAYER_HP:
		push_error("VERIFY_FAIL both life bars start full")
		return false
	player_hp.set_hp(25, false)
	if not player_hp.fill_visible():
		push_error("VERIFY_FAIL your life bar should show liquid while you still have life")
		return false
	player_hp.set_hp(MatchRules.PLAYER_HP, false)
	if absf((AssemblyLayout.MONEY_RADIUS + AssemblyLayout.MONEY_EDGE) * 2.0 - AssemblyLayout.HUD_DISC) > 0.5:
		push_error("VERIFY_FAIL the gold coin should be the same size as the round buttons")
		return false
	if not AssemblyLayout.ICON_BUTTON_SIZE.is_equal_approx(Vector2(AssemblyLayout.HUD_DISC, AssemblyLayout.HUD_DISC)):
		push_error("VERIFY_FAIL refresh and sell should use the gold-coin size")
		return false
	var first_card := cards.get_child(0) as CharacterSlot
	var hung := first_card.scale
	first_card.set_drop_highlight(true)
	if not first_card.scale.is_equal_approx(hung):
		push_error("VERIFY_FAIL hanging cards should not grow when a kit hovers them")
		return false
	first_card.set_drop_highlight(false)
	if not first_card.scale.is_equal_approx(Vector2.ONE * AssemblyLayout.CARD_FIT):
		push_error("VERIFY_FAIL hanging cards should stay at their hung size")
		return false
	if scene.get_node_or_null("PrepClock") == null:
		push_error("VERIFY_FAIL the preparation clock should sit between the belts")
		return false
	var freaks := scene.get_node_or_null("Freaks") as Node2D
	if freaks == null:
		push_error("VERIFY_FAIL missing Freaks layer")
		return false
	if absf(AssemblyLayout.CARD_CENTER_Y - AssemblyLayout.CARD_SIZE.y * 0.5 * AssemblyLayout.CARD_FIT) > 1.0:
		push_error("VERIFY_FAIL the cards should hang flush with the top of the screen")
		return false
	if AssemblyLayout.BELT_FREAK_SCALE < 0.8:
		push_error("VERIFY_FAIL Freaks on the belts should be close to card size")
		return false
	if absf(AssemblyLayout.CARD_X[0] + AssemblyLayout.CARD_OPPONENT_X[2] - AssemblyLayout.WIDTH) > 1.0:
		push_error("VERIFY_FAIL the outer cards should mirror each other")
		return false
	if absf(AssemblyLayout.CARD_X[1] + AssemblyLayout.CARD_OPPONENT_X[1] - AssemblyLayout.WIDTH) > 1.0:
		push_error("VERIFY_FAIL the middle cards should mirror each other")
		return false
	if absf(AssemblyLayout.CARD_X[2] + AssemblyLayout.CARD_OPPONENT_X[0] - AssemblyLayout.WIDTH) > 1.0:
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
	var empty_back := empty.get_node_or_null("Display/CrateBack") as Sprite2D
	var empty_front := empty.get_node_or_null("Display/CrateFront") as Sprite2D
	var occupied_back := occupied.get_node_or_null("Display/CrateBack") as Sprite2D
	var occupied_front := occupied.get_node_or_null("Display/CrateFront") as Sprite2D
	if empty_back == null or empty_front == null or occupied_back == null or occupied_front == null:
		push_error("VERIFY_FAIL both cards should show both crate pieces")
		return false
	if not empty_back.global_scale.is_equal_approx(occupied_back.global_scale):
		push_error("VERIFY_FAIL the crate back must be the same size empty or filled")
		return false
	if not empty_front.global_scale.is_equal_approx(occupied_front.global_scale):
		push_error("VERIFY_FAIL the crate front must be the same size empty or filled")
		return false
	var body := occupied.get_node_or_null("Display/body") as Sprite2D
	if body == null or not body.visible:
		push_error("VERIFY_FAIL the filled card should show the torso")
		return false
	if occupied_back.z_index >= body.z_index:
		push_error("VERIFY_FAIL the crate top rim should sit behind the Freak")
		return false
	if occupied_front.z_index <= body.z_index:
		push_error("VERIFY_FAIL the crate front should sit in front of the torso")
		return false
	var empty_plaque := empty.get_node_or_null("Display/CratePlaque") as CratePlaque
	if empty_plaque == null or empty_plaque.visible:
		push_error("VERIFY_FAIL an empty crate should not show a name")
		return false
	var plaque := occupied.get_node_or_null("Display/CratePlaque") as CratePlaque
	if plaque == null or not plaque.visible:
		push_error("VERIFY_FAIL a filled crate should show the name and numbers")
		return false
	if plaque.shown_title() != "FREAK":
		push_error("VERIFY_FAIL a body alone should still read FREAK")
		return false
	if plaque.shown_hp() != bruxa.body.stat_value:
		push_error("VERIFY_FAIL the crate should show the body's HP")
		return false
	if load("res://assets/nova-ui/ataque.png") == null or load("res://assets/nova-ui/hp.png") == null:
		push_error("VERIFY_FAIL missing attack or HP icons for the crate")
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
	var half := AssemblyLayout.belt_freak_width() * 0.5
	var blue_inner := AssemblyLayout.belt_tip_x(true) + half
	if blue_inner > AssemblyLayout.BELT_SIZE.x - AssemblyLayout.BELT_TIP_MARGIN + 0.5:
		push_error("VERIFY_FAIL the blue Freak should stop on the rollers, not over the hole")
		return false
	var red_start := AssemblyLayout.WIDTH - AssemblyLayout.BELT_SIZE.x
	var red_inner := AssemblyLayout.belt_tip_x(false) - half
	if red_inner < red_start + AssemblyLayout.BELT_TIP_MARGIN - 0.5:
		push_error("VERIFY_FAIL the red Freak should stop on the rollers, not over the hole")
		return false
	var wait_x := AssemblyLayout.belt_x_at(true, 1.0 - AssemblyLayout.belt_queue_gap(true))
	var lead_x := AssemblyLayout.belt_x_at(true, 1.0)
	if absf(lead_x - wait_x) + 0.5 < AssemblyLayout.belt_freak_width():
		push_error("VERIFY_FAIL two Freaks on a belt should keep a crate-width of space")
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
