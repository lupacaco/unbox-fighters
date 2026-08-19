class_name AssemblyController
extends Node2D

## The match screen. It builds the furniture (background, cards, one shelf, belts,
## money, tug bar, buttons), runs LiveMatch, and turns what the match says
## into something you can watch.

const CARD_SCENE := preload("res://scenes/assembly/CharacterSlot.tscn")
## Beat after a hit lands, so the number can be read before the answer.
const SWING_STAGGER := 0.18

@onready var _drag_service: DragDropService = $DragDropService

var _match := LiveMatch.new()
var _bot := BotBrain.new()

var _cards: Array[CharacterSlot] = []
var _opponent_cards: Array[CharacterSlot] = []
var _shelves: Array[ShopShelf] = []
var _freaks_root: Node2D
var _dump_host: Node2D
var _money_bar: MoneyBar
var _action_bar: ActionBar
var _tug_bar: TugBar
var _banner: Label

var _player_freaks: Dictionary = {}
var _opponent_freaks: Dictionary = {}
var _pending_deaths: Array[BeltFreak] = []
var _selected: PartView = null
var _fight_busy: bool = false
var _shop_busy: bool = false
var _pending_jump_from := Vector2.ZERO

func _ready() -> void:
	_drag_service.add_to_group("drag_drop_service")
	_build_background()
	_build_belts()
	_build_tug_bar()
	_build_freak_layer()
	_build_cards()
	_build_shelves()
	_build_hud()
	_build_banner()
	_drag_service.setup(_cards, _action_bar)
	_drag_service.sell_requested.connect(_sell)
	_drag_service.part_clicked.connect(_on_part_clicked)
	_drag_service.drag_ended.connect(_on_drag_ended)
	_wire_match()
	_start_match()

func _process(delta: float) -> void:
	if not _match.running:
		return
	_match.tick(delta)
	_bot.tick(delta, _match.opponent, _match)
	_sync_lane(_match.player, _player_freaks)
	_sync_lane(_match.opponent, _opponent_freaks)
	_sync_opponent_cards()

## What is in your wallet right now. Used by the headless checks.
func player_money() -> int:
	return _match.player.money

# ---------------------------------------------------------------- build

func _build_background() -> void:
	var bg := Sprite2D.new()
	bg.name = "Background"
	bg.texture = load(AssemblyLayout.BACKGROUND_TEX)
	bg.centered = false
	bg.z_index = -20
	add_child(bg)

func _build_belts() -> void:
	var belts := Node2D.new()
	belts.name = "Belts"
	belts.z_index = -5
	add_child(belts)
	for is_player in [true, false]:
		var belt := Sprite2D.new()
		belt.name = "BeltPlayer" if is_player else "BeltOpponent"
		belt.texture = load(
			AssemblyLayout.BELT_PLAYER_TEX if is_player else AssemblyLayout.BELT_OPPONENT_TEX
		)
		belt.centered = true
		belt.position = AssemblyLayout.belt_center(is_player)
		belts.add_child(belt)

func _build_tug_bar() -> void:
	_tug_bar = TugBar.new()
	_tug_bar.name = "TugBar"
	_tug_bar.z_index = 16
	add_child(_tug_bar)

func _build_freak_layer() -> void:
	_freaks_root = Node2D.new()
	_freaks_root.name = "Freaks"
	_freaks_root.z_index = 10
	add_child(_freaks_root)
	_dump_host = Node2D.new()
	_dump_host.name = "Dump"
	_dump_host.z_index = 12
	add_child(_dump_host)

func _build_cards() -> void:
	var root := Node2D.new()
	root.name = "Cards"
	root.z_index = 6
	add_child(root)
	for i in MatchRules.CARD_COUNT:
		var card := CARD_SCENE.instantiate() as CharacterSlot
		root.add_child(card)
		card.position = AssemblyLayout.card_center(i)
		card.setup(false)
		card.fight_requested.connect(_on_fight_requested)
		card.play_intro(0.1 * float(i))
		_cards.append(card)

	var theirs := Node2D.new()
	theirs.name = "OpponentCards"
	theirs.z_index = 6
	add_child(theirs)
	for i in MatchRules.CARD_COUNT:
		var card := CARD_SCENE.instantiate() as CharacterSlot
		theirs.add_child(card)
		card.position = AssemblyLayout.opponent_card_center(i)
		card.setup(true)
		card.play_intro(0.1 * float(i))
		_opponent_cards.append(card)

func _build_shelves() -> void:
	var root := Node2D.new()
	root.name = "Shelves"
	root.z_index = 8
	add_child(root)
	for i in MatchRules.SHOP_SLOTS:
		var shelf := ShopShelf.new()
		root.add_child(shelf)
		shelf.setup(i, _drag_service)
		shelf.buy_requested.connect(_on_buy_requested)
		_shelves.append(shelf)

func _build_hud() -> void:
	var root := Node2D.new()
	root.name = "Hud"
	root.z_index = 20
	add_child(root)

	_money_bar = MoneyBar.new()
	_money_bar.name = "MoneyBar"
	root.add_child(_money_bar)

	_action_bar = ActionBar.new()
	_action_bar.name = "ActionBar"
	root.add_child(_action_bar)
	_action_bar.refresh_pressed.connect(_on_refresh_pressed)
	_action_bar.sell_pressed.connect(_on_sell_pressed)

func _build_banner() -> void:
	_banner = GameTheme.make_label(
		"", 96, AssemblyLayout.BANNER_CENTER, Vector2(1000, 130), ThemeTokens.GOLD
	)
	_banner.z_index = 40
	_banner.modulate.a = 0.0
	add_child(_banner)

# ---------------------------------------------------------------- match wiring

func _wire_match() -> void:
	_match.money_gained.connect(_on_money_gained)
	_match.shop_rolled.connect(_on_shop_rolled)
	_match.freak_launched.connect(_on_freak_launched)
	_match.blows_traded.connect(_on_blows_traded)
	_match.freak_died.connect(_on_freak_died)
	_match.tug_changed.connect(_on_tug_changed)
	_match.match_ended.connect(_on_match_ended)

func _start_match() -> void:
	_match.player.lane.travel_px = AssemblyLayout.belt_travel_px(true)
	_match.opponent.lane.travel_px = AssemblyLayout.belt_travel_px(false)
	_match.player.lane.queue_gap_px = AssemblyLayout.belt_queue_gap_px()
	_match.opponent.lane.queue_gap_px = AssemblyLayout.belt_queue_gap_px()
	_bot.reset()
	_match.start()
	_money_bar.set_amount(_match.player.money, false)
	_tug_bar.set_tug(0, false)
	_refresh_affordability()

# ---------------------------------------------------------------- shop

func _on_shop_rolled(side: PlayerState) -> void:
	if side != _match.player:
		return
	for shelf in _shelves:
		shelf.show_offer(side.shop_offers[shelf.index], side.price_at(shelf.index))
	_refresh_affordability()

func _on_buy_requested(shelf: ShopShelf) -> void:
	var side := _match.player
	if not _match.running or shelf.offer == null:
		return
	if not side.can_afford(side.price_at(shelf.index)):
		shelf.deny()
		_money_bar.deny()
		return
	var part := side.buy(shelf.index)
	if part == null:
		shelf.deny()
		return
	_money_bar.set_amount(side.money)
	_refresh_affordability()
	await shelf.open()

func _on_refresh_pressed() -> void:
	if not _match.running or _shop_busy:
		return
	var keep := _busy_shelves()
	if keep.size() >= _shelves.size():
		return
	_shop_busy = true
	_action_bar.set_can_refresh(false)
	for shelf in _shelves:
		await shelf.dump_closed(_dump_host)
	if not _match.refresh_shop(_match.player, keep):
		_money_bar.deny()
	_money_bar.set_amount(_match.player.money)
	_shop_busy = false
	_refresh_affordability()

## Shelves still holding a kit you paid for. A reroll must leave them alone.
func _busy_shelves() -> PackedInt32Array:
	var busy := PackedInt32Array()
	for shelf in _shelves:
		if shelf.has_part():
			busy.append(shelf.index)
	return busy

func _keep_offers() -> PackedInt32Array:
	var keep := _busy_shelves()
	for shelf in _shelves:
		if shelf.offer != null and shelf.index not in keep:
			keep.append(shelf.index)
	return keep

func _restock_player_shop() -> void:
	if not _match.running:
		return
	_match.restock_shop(_match.player, _keep_offers())

func _refresh_affordability() -> void:
	var side := _match.player
	for shelf in _shelves:
		shelf.set_affordable(side.can_afford(side.price_at(shelf.index)))
	_action_bar.set_can_refresh(not _shop_busy and side.can_afford(MatchRules.REFRESH_COST))

func _on_money_gained(side: PlayerState) -> void:
	if side != _match.player:
		return
	_money_bar.set_amount(side.money)
	_refresh_affordability()

# ---------------------------------------------------------------- selling

## A kit standing on a shelf can be picked so VENDER knows what to buy back.
## A kit already on a card is sold by dragging it onto the button instead.
func _on_part_clicked(part: PartView) -> void:
	if part == null or part.is_attached():
		return
	_select(null if part == _selected else part)

func _on_drag_ended(part: PartView, accepted: bool) -> void:
	if accepted and part == _selected:
		_select(null)
	if accepted:
		_restock_player_shop()

func _on_sell_pressed() -> void:
	if _selected == null:
		return
	_sell(_selected)

func _sell(part: PartView) -> void:
	if part == null or not is_instance_valid(part):
		return
	if part == _selected:
		_select(null)
	part.unbind_from_card()
	if part.home_shelf != null:
		part.home_shelf.take_part()
	_match.player.earn(part.sell_value())
	part.queue_free()
	_money_bar.set_amount(_match.player.money)
	_action_bar.play_sold()
	_action_bar.set_sell_target(0)
	_refresh_affordability()
	GameAudio.part_place()
	_restock_player_shop()

func _select(part: PartView) -> void:
	if _selected != null and is_instance_valid(_selected):
		_selected.set_selected(false)
	_selected = part
	if _selected == null:
		_action_bar.set_sell_target(0)
		return
	_selected.set_selected(true)
	_action_bar.set_sell_target(_selected.sell_value())

# ---------------------------------------------------------------- cards

func _on_fight_requested(card: CharacterSlot) -> void:
	if not _match.running or not card.can_fight():
		return
	if not _match.player.lane.can_accept():
		card.play_launch_swing()
		GameAudio.part_reject()
		return
	_pending_jump_from = card.global_floor_point()
	if _match.launch(_match.player, card.to_loadout()) == null:
		_pending_jump_from = Vector2.ZERO
		return
	if _selected != null and _selected.attached_slot() == card:
		_select(null)
	card.play_launch_swing()
	card.clear_after_launch()

# ---------------------------------------------------------------- belts

func _on_freak_launched(side: PlayerState, runner: BeltLane.Runner) -> void:
	var is_player := side == _match.player
	var freak := BeltFreak.new()
	_freaks_root.add_child(freak)
	freak.setup(runner.loadout, runner, is_player)
	freak.play_jump_from(_jump_origin(is_player, runner))
	_views_of(is_player)[runner.id] = freak

func _jump_origin(is_player: bool, runner: BeltLane.Runner) -> Vector2:
	if is_player and _pending_jump_from != Vector2.ZERO:
		var from := _pending_jump_from
		_pending_jump_from = Vector2.ZERO
		return from
	if not is_player:
		var card := _opponent_card_for(runner)
		if card != null:
			card.play_launch_swing()
			return card.global_floor_point()
	return Vector2(
		AssemblyLayout.belt_entry_x(is_player),
		AssemblyLayout.belt_floor_y() - 280.0
	)

func _opponent_card_for(runner: BeltLane.Runner) -> CharacterSlot:
	if runner == null or runner.loadout == null:
		return null
	for card in _opponent_cards:
		if _same_loadout(card.to_loadout(), runner.loadout):
			return card
	for card in _opponent_cards:
		if card.is_complete():
			return card
	return null

func _same_loadout(a: FighterLoadout, b: FighterLoadout) -> bool:
	if a == null or b == null:
		return false
	for slot in PartSlotType.shop_slots():
		if a.get_part(slot) != b.get_part(slot):
			return false
	return true

func _sync_opponent_cards() -> void:
	for i in _opponent_cards.size():
		var loadout := _bot.cards[i] if i < _bot.cards.size() else null
		_opponent_cards[i].show_loadout(loadout)

func _sync_lane(side: PlayerState, views: Dictionary) -> void:
	for runner in side.lane.runners:
		var freak: BeltFreak = views.get(runner.id)
		if freak == null or not is_instance_valid(freak):
			continue
		freak.follow_runner()

func _views_of(is_player: bool) -> Dictionary:
	return _player_freaks if is_player else _opponent_freaks

func _on_blows_traded(
	exchange: Duel.Exchange, left: BeltLane.Runner, right: BeltLane.Runner
) -> void:
	_fight_busy = true
	var mine: BeltFreak = _player_freaks.get(left.id)
	var theirs: BeltFreak = _opponent_freaks.get(right.id)
	var visuals_ok := (
		mine != null and theirs != null and is_instance_valid(mine) and is_instance_valid(theirs)
	)
	if visuals_ok:
		var first := mine if exchange.first_is_left else theirs
		var second := theirs if exchange.first_is_left else mine
		var first_side := _match.player if exchange.first_is_left else _match.opponent
		var second_side := _match.opponent if exchange.first_is_left else _match.player
		var first_runner := left if exchange.first_is_left else right
		var second_runner := right if exchange.first_is_left else left
		await _play_blow(first, first_runner, first_side, second, second_runner, second_side)
		if exchange.second_happens:
			await get_tree().create_timer(SWING_STAGGER).timeout
			await _play_blow(second, second_runner, second_side, first, first_runner, first_side)
	else:
		_apply_exchange_hits(exchange, left, right)
	_match.close_exchange()
	_fight_busy = false
	_play_pending_deaths()

func _apply_exchange_hits(
	exchange: Duel.Exchange, left: BeltLane.Runner, right: BeltLane.Runner
) -> void:
	if exchange.first_is_left:
		_match.apply_blow(left, right, _match.player, _match.opponent)
		if exchange.second_happens:
			_match.apply_blow(right, left, _match.opponent, _match.player)
	else:
		_match.apply_blow(right, left, _match.opponent, _match.player)
		if exchange.second_happens:
			_match.apply_blow(left, right, _match.player, _match.opponent)

func _play_blow(
	attacker: BeltFreak,
	attacker_runner: BeltLane.Runner,
	attacker_side: PlayerState,
	defender: BeltFreak,
	defender_runner: BeltLane.Runner,
	defender_side: PlayerState
) -> void:
	var plan := _match.plan_blow(attacker_runner, defender_runner, attacker_side, defender_side)
	var victim_runner: BeltLane.Runner = plan["victim"]
	var victim_side: PlayerState = plan["victim_side"]
	var victim_view := _freak_view(victim_side, victim_runner)
	if not is_instance_valid(attacker):
		_match.apply_blow(attacker_runner, defender_runner, attacker_side, defender_side)
		return
	await attacker.attack(
		func() -> Vector2:
			if is_instance_valid(victim_view):
				return victim_view.head_global_position()
			if is_instance_valid(defender):
				return defender.head_global_position()
			return attacker.global_position,
		func() -> void:
			_match.apply_blow(attacker_runner, defender_runner, attacker_side, defender_side)
			if is_instance_valid(victim_view):
				victim_view.flash_hit(int(plan["damage"]))
	)

func _freak_view(side: PlayerState, runner: BeltLane.Runner) -> BeltFreak:
	if side == null or runner == null:
		return null
	return _views_of(side == _match.player).get(runner.id) as BeltFreak

func _on_freak_died(side: PlayerState, runner: BeltLane.Runner) -> void:
	var views := _views_of(side == _match.player)
	var freak: BeltFreak = views.get(runner.id)
	views.erase(runner.id)
	if freak == null or not is_instance_valid(freak):
		return
	_pending_deaths.append(freak)
	if not _fight_busy:
		_play_pending_deaths()

func _play_pending_deaths() -> void:
	if _pending_deaths.is_empty():
		return
	var dying := _pending_deaths.duplicate()
	_pending_deaths.clear()
	for freak in dying:
		if is_instance_valid(freak):
			freak.play_death()
	GameAudio.crate_break()

# ---------------------------------------------------------------- life

func _on_tug_changed(value: int, _attacker: PlayerState) -> void:
	_tug_bar.set_tug(value)

func _on_match_ended(winner: PlayerState) -> void:
	_drag_service.set_locked(true)
	for card in _cards:
		card.set_locked(true)
	for card in _opponent_cards:
		card.set_locked(true)
	var won := winner == _match.player
	_banner.text = "VOCÊ VENCEU" if won else "VOCÊ PERDEU"
	_banner.add_theme_color_override(
		"font_color", ThemeTokens.GOLD if won else ThemeTokens.X_RED
	)
	_banner.scale = Vector2(0.6, 0.6)
	_banner.pivot_offset = _banner.size * 0.5
	var tween := create_tween()
	tween.tween_property(_banner, "modulate:a", 1.0, 0.2)
	tween.parallel().tween_property(_banner, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	GameAudio.fighter_complete()
