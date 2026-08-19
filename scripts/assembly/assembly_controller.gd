class_name AssemblyController
extends Node2D

## The match screen. It builds the furniture, runs a round-based LiveMatch,
## and turns what the match says into something you can watch.

const CARD_SCENE := preload("res://scenes/assembly/CharacterSlot.tscn")
const SIDE_HP_BAR := preload("res://scripts/ui/side_hp_bar.gd")
const PREP_CLOCK := preload("res://scripts/ui/prep_clock.gd")
## Beat after a hit lands, so the number can be read before the answer.
const SWING_STAGGER := 0.18

@onready var _drag_service: DragDropService = $DragDropService

var _match := LiveMatch.new()
var _bot := BotBrain.new()

var _cards: Array[CharacterSlot] = []
var _opponent_cards: Array[CharacterSlot] = []
var _shelves: Array[ShopShelf] = []
var _cards_root: Node2D
var _opponent_root: Node2D
var _shelves_root: Node2D
var _freaks_root: Node2D
var _dump_host: Node2D
var _hud: Node2D
var _money_bar: MoneyBar
var _action_bar: ActionBar
var _player_hp
var _opponent_hp
var _clock
var _banner: Label

var _player_freaks: Dictionary = {}
var _opponent_freaks: Dictionary = {}
var _pending_deaths: Array[BeltFreak] = []
var _selected: PartView = null
var _fight_busy: bool = false
var _shop_busy: bool = false
var _pending_jump_from := Vector2.ZERO
var _resolving: bool = false

func _ready() -> void:
	_drag_service.add_to_group("drag_drop_service")
	_build_background()
	_build_belts()
	_build_hp_bars()
	_build_freak_layer()
	_build_cards()
	_build_shelves()
	_build_hud()
	_build_clock()
	_build_banner()
	_drag_service.setup(_cards, _action_bar)
	_drag_service.sell_requested.connect(_sell)
	_drag_service.part_clicked.connect(_on_part_clicked)
	_drag_service.drag_ended.connect(_on_drag_ended)
	_drag_service.purchase_drop.connect(_on_purchase_drop)
	_wire_match()
	_start_match()

func _process(delta: float) -> void:
	if not _match.running:
		return
	_sync_player_cards()
	if _match.is_prep():
		_bot.tick(delta, _match.opponent, _match)
	_match.tick(delta)
	_sync_lane(_match.player, _player_freaks)
	_sync_lane(_match.opponent, _opponent_freaks)
	if _match.is_fight() or _match.phase == MatchRules.Phase.RESOLUTION:
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

func _build_hp_bars() -> void:
	_player_hp = SIDE_HP_BAR.new()
	_player_hp.name = "PlayerHpBar"
	_player_hp.z_index = 16
	add_child(_player_hp)
	_player_hp.setup(true)
	_opponent_hp = SIDE_HP_BAR.new()
	_opponent_hp.name = "OpponentHpBar"
	_opponent_hp.z_index = 16
	add_child(_opponent_hp)
	_opponent_hp.setup(false)

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
	_cards_root = Node2D.new()
	_cards_root.name = "Cards"
	_cards_root.z_index = 6
	add_child(_cards_root)
	for i in MatchRules.CARD_COUNT:
		var card := CARD_SCENE.instantiate() as CharacterSlot
		_cards_root.add_child(card)
		card.position = AssemblyLayout.card_center(i)
		card.scale = Vector2.ONE * AssemblyLayout.CARD_FIT
		card.setup(false)
		card.play_intro(0.1 * float(i))
		_cards.append(card)

	_opponent_root = Node2D.new()
	_opponent_root.name = "OpponentCards"
	_opponent_root.z_index = 6
	add_child(_opponent_root)
	for i in MatchRules.CARD_COUNT:
		var card := CARD_SCENE.instantiate() as CharacterSlot
		_opponent_root.add_child(card)
		card.position = AssemblyLayout.opponent_card_center(i)
		card.scale = Vector2.ONE * AssemblyLayout.CARD_FIT
		card.setup(true)
		_opponent_cards.append(card)
	_opponent_root.visible = false

func _build_shelves() -> void:
	_shelves_root = Node2D.new()
	_shelves_root.name = "Shelves"
	_shelves_root.z_index = 8
	add_child(_shelves_root)
	for i in MatchRules.SHOP_SLOTS:
		var shelf := ShopShelf.new()
		_shelves_root.add_child(shelf)
		shelf.setup(i, _drag_service)
		shelf.owned_received.connect(_on_owned_received)
		shelf.part_taken.connect(_on_part_taken)
		_shelves.append(shelf)

func _build_hud() -> void:
	_hud = Node2D.new()
	_hud.name = "Hud"
	_hud.z_index = 20
	add_child(_hud)

	_money_bar = MoneyBar.new()
	_money_bar.name = "MoneyBar"
	_hud.add_child(_money_bar)

	_action_bar = ActionBar.new()
	_action_bar.name = "ActionBar"
	_hud.add_child(_action_bar)
	_action_bar.refresh_pressed.connect(_on_refresh_pressed)
	_action_bar.sell_pressed.connect(_on_sell_pressed)

func _build_clock() -> void:
	_clock = PREP_CLOCK.new()
	_clock.name = "PrepClock"
	_clock.z_index = 21
	add_child(_clock)
	_clock.skip_pressed.connect(_on_skip_pressed)

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
	_match.phase_changed.connect(_on_phase_changed)
	_match.prep_ticked.connect(_on_prep_ticked)
	_match.life_changed.connect(_on_life_changed)
	_match.fight_resolved.connect(_on_fight_resolved)
	_match.match_ended.connect(_on_match_ended)

func _start_match() -> void:
	_match.player.lane.travel_px = AssemblyLayout.belt_travel_px(true)
	_match.opponent.lane.travel_px = AssemblyLayout.belt_travel_px(false)
	_match.player.lane.queue_gap_px = AssemblyLayout.belt_queue_gap_px()
	_match.opponent.lane.queue_gap_px = AssemblyLayout.belt_queue_gap_px()
	_bot.reset()
	_match.start()
	_money_bar.set_amount(_match.player.money, false)
	_on_life_changed()
	_apply_phase_visibility()
	_refresh_affordability()

func _sync_player_cards() -> void:
	for i in _cards.size():
		if i >= _match.player.cards.size():
			break
		_match.player.cards[i] = _cards[i].to_loadout()

# ---------------------------------------------------------------- shop

func _on_shop_rolled(side: PlayerState) -> void:
	if side != _match.player:
		return
	for shelf in _shelves:
		if shelf.has_owned_part():
			continue
		shelf.show_offer(side.shop_offers[shelf.index], side.price_at(shelf.index))
	_refresh_affordability()

func _on_purchase_drop(part: PartView, card: CharacterSlot) -> void:
	if part == null or card == null or not part.for_sale:
		return
	if not _match.is_prep():
		part.return_home()
		return
	var shelf := part.home_shelf
	if shelf == null or not _match.player.can_afford(part.sale_price):
		if shelf != null:
			shelf.deny()
		_money_bar.deny()
		part.return_home()
		return
	var bought := _match.player.buy(shelf.index)
	if bought == null:
		shelf.deny()
		_money_bar.deny()
		part.return_home()
		return
	part.mark_purchased()
	_money_bar.set_amount(_match.player.money)
	_refresh_affordability()
	if not card.try_attach(part):
		_park_owned(part)

func _on_refresh_pressed() -> void:
	if not _match.is_prep() or _shop_busy:
		return
	if not _match.player.can_afford(MatchRules.REFRESH_COST):
		_money_bar.deny()
		return
	var keep := _owned_shelves()
	if keep.size() >= _shelves.size():
		return
	_shop_busy = true
	_action_bar.set_can_refresh(false)
	for shelf in _shelves:
		await shelf.dump_offer(_dump_host)
	if not _match.refresh_shop(_match.player, keep):
		_money_bar.deny()
	_money_bar.set_amount(_match.player.money)
	_shop_busy = false
	_refresh_affordability()

func _owned_shelves() -> PackedInt32Array:
	var busy := PackedInt32Array()
	for shelf in _shelves:
		if shelf.has_owned_part():
			busy.append(shelf.index)
	return busy

func _refresh_affordability() -> void:
	var side := _match.player
	for shelf in _shelves:
		if shelf.has_for_sale_part():
			shelf.set_affordable(side.can_afford(side.price_at(shelf.index)))
	_action_bar.set_can_refresh(
		_match.is_prep() and not _shop_busy and side.can_afford(MatchRules.REFRESH_COST)
	)
	if _clock != null:
		_clock.set_skip_enabled(_match.is_prep() and not _shop_busy)

func _on_money_gained(side: PlayerState) -> void:
	if side != _match.player:
		return
	_money_bar.set_amount(side.money)
	_refresh_affordability()

func _on_part_taken(shelf: ShopShelf) -> void:
	if shelf == null:
		return
	_match.player.clear_slot(shelf.index)

func _on_owned_received(shelf: ShopShelf, part: PartView) -> void:
	if shelf == null or part == null or part.part_def == null:
		return
	_match.player.return_owned(shelf.index, part.part_def)

func _park_owned(part: PartView) -> void:
	if part == null or not is_instance_valid(part):
		return
	var shelf := part.home_shelf
	if shelf == null or shelf.has_part():
		shelf = _first_empty_shelf()
	if shelf == null:
		part.return_home()
		return
	_match.player.return_owned(shelf.index, part.part_def)
	shelf.receive_owned(part)

func _first_empty_shelf() -> ShopShelf:
	for shelf in _shelves:
		if not shelf.has_part():
			return shelf
	return null

# ---------------------------------------------------------------- selling

func _on_part_clicked(part: PartView) -> void:
	if part == null or part.is_attached() or part.for_sale:
		return
	_select(null if part == _selected else part)

func _on_drag_ended(part: PartView, accepted: bool) -> void:
	if accepted and part == _selected:
		_select(null)

func _on_sell_pressed() -> void:
	if _selected == null:
		return
	_sell(_selected)

func _sell(part: PartView) -> void:
	if part == null or not is_instance_valid(part) or part.for_sale:
		return
	if not _match.is_prep():
		return
	if part == _selected:
		_select(null)
	part.unbind_from_card()
	if part.home_shelf != null:
		_match.player.clear_slot(part.home_shelf.index)
		part.home_shelf.take_part()
	_match.player.earn(part.sell_value())
	part.queue_free()
	_money_bar.set_amount(_match.player.money)
	_action_bar.play_sold()
	_action_bar.set_sell_target(0)
	_refresh_affordability()
	GameAudio.part_place()

func _select(part: PartView) -> void:
	if _selected != null and is_instance_valid(_selected):
		_selected.set_selected(false)
	_selected = part
	if _selected == null:
		_action_bar.set_sell_target(0)
		return
	_selected.set_selected(true)
	_action_bar.set_sell_target(_selected.sell_value())

# ---------------------------------------------------------------- phases

func _on_skip_pressed() -> void:
	if not _match.is_prep() or _shop_busy:
		return
	_sync_player_cards()
	_match.skip_prep()

func _on_prep_ticked(seconds_left: float) -> void:
	if _clock == null or not _match.is_prep():
		return
	_clock.set_seconds(seconds_left)

func _on_phase_changed(phase: MatchRules.Phase) -> void:
	_apply_phase_visibility()
	match phase:
		MatchRules.Phase.PREP:
			_resolving = false
			_clock.set_prep_mode()
			_unlock_cards()
			_clear_belt_flags()
			_refresh_affordability()
		MatchRules.Phase.FIGHT:
			_clock.set_fight_mode()
			_lock_cards()
			_drag_service.set_locked(true)
		MatchRules.Phase.RESOLUTION, MatchRules.Phase.GAME_OVER:
			_clock.set_fight_mode()
			_lock_cards()

func _apply_phase_visibility() -> void:
	var prep := _match.phase == MatchRules.Phase.PREP
	if _shelves_root != null:
		_shelves_root.visible = prep
	if _hud != null:
		_hud.visible = prep
	if _opponent_root != null:
		_opponent_root.visible = not prep
	if prep:
		_drag_service.set_locked(false)

func _lock_cards() -> void:
	for card in _cards:
		card.set_locked(true)
	for card in _opponent_cards:
		card.set_locked(true)

func _unlock_cards() -> void:
	for card in _cards:
		card.set_locked(false)
		card.set_on_belt(false)
	for card in _opponent_cards:
		card.set_locked(true)
		card.set_on_belt(false)

func _clear_belt_flags() -> void:
	for card in _cards:
		card.set_on_belt(false)
	for card in _opponent_cards:
		card.set_on_belt(false)

func _on_life_changed() -> void:
	if _player_hp != null:
		_player_hp.set_hp(_match.player.life)
	if _opponent_hp != null:
		_opponent_hp.set_hp(_match.opponent.life)

# ---------------------------------------------------------------- belts

func _on_freak_launched(side: PlayerState, runner: BeltLane.Runner) -> void:
	var is_player := side == _match.player
	var card := _card_for(is_player, runner)
	if card != null:
		card.play_launch_swing()
		card.set_on_belt(true)
		_pending_jump_from = card.global_floor_point()
	var freak := BeltFreak.new()
	_freaks_root.add_child(freak)
	freak.setup(runner.loadout, runner, is_player)
	freak.play_jump_from(_jump_origin(is_player))
	_views_of(is_player)[runner.id] = freak

func _jump_origin(is_player: bool) -> Vector2:
	if _pending_jump_from != Vector2.ZERO:
		var from := _pending_jump_from
		_pending_jump_from = Vector2.ZERO
		return from
	return Vector2(
		AssemblyLayout.belt_entry_x(is_player),
		AssemblyLayout.belt_floor_y() - 280.0
	)

func _card_for(is_player: bool, runner: BeltLane.Runner) -> CharacterSlot:
	if runner == null or runner.loadout == null:
		return null
	var list := _cards if is_player else _opponent_cards
	for card in list:
		if card.is_on_belt():
			continue
		if _same_loadout(card.to_loadout(), runner.loadout):
			return card
	for card in list:
		if not card.is_on_belt() and card.is_complete():
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
		var loadout := _match.opponent.cards[i] if i < _match.opponent.cards.size() else null
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
	_play_pending_knockouts()

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
	if freak == null or not is_instance_valid(freak):
		return
	_pending_deaths.append(freak)
	if not _fight_busy:
		_play_pending_knockouts()

func _play_pending_knockouts() -> void:
	if _pending_deaths.is_empty():
		return
	var dying := _pending_deaths.duplicate()
	_pending_deaths.clear()
	for freak in dying:
		if is_instance_valid(freak):
			freak.play_knockout()
	GameAudio.crate_break()

func _on_fight_resolved(_winner: PlayerState, _survivors: int, _damage: int) -> void:
	if _resolving:
		return
	_resolving = true
	await _return_freaks_home()
	if _match.running and _match.phase == MatchRules.Phase.RESOLUTION:
		_match.finish_resolution()

func _return_freaks_home() -> void:
	var jobs: Array = []
	jobs.append_array(_return_side(_cards, _player_freaks))
	jobs.append_array(_return_side(_opponent_cards, _opponent_freaks))
	_player_freaks.clear()
	_opponent_freaks.clear()
	for job in jobs:
		if job is BeltFreak and is_instance_valid(job):
			await job.tree_exited
	await get_tree().create_timer(0.12).timeout

func _return_side(cards: Array[CharacterSlot], views: Dictionary) -> Array:
	var waiting: Array = []
	for freak in views.values():
		if freak == null or not is_instance_valid(freak):
			continue
		var target := _home_for_freak(freak, cards)
		freak.play_return_to(target)
		waiting.append(freak)
	return waiting

func _home_for_freak(freak: BeltFreak, cards: Array[CharacterSlot]) -> Vector2:
	if freak.runner != null and freak.runner.loadout != null:
		for card in cards:
			if _same_loadout(card.to_loadout(), freak.runner.loadout):
				return card.global_floor_point()
	if not cards.is_empty():
		return cards[0].global_floor_point()
	return Vector2(AssemblyLayout.belt_entry_x(freak.player_side), AssemblyLayout.belt_floor_y() - 200.0)

# ---------------------------------------------------------------- life

func _on_match_ended(winner: PlayerState) -> void:
	_drag_service.set_locked(true)
	_lock_cards()
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
