class_name AssemblyController
extends Node2D

@onready var _slots_root: Node2D = $Slots
@onready var _tray: Node2D = $Tray
@onready var _shelf: Sprite2D = $Tray/Shelf
@onready var _fx_layer: Node2D = $FxLayer
@onready var _drag_service: DragDropService = $DragDropService
@onready var _hud: CanvasLayer = $HUD
@onready var _title: Label = $HUD/Title
@onready var _subtitle: Label = $HUD/Subtitle

var _part_scene: PackedScene = preload("res://scenes/assembly/PartView.tscn")
var _crate_scene: PackedScene = preload("res://scenes/assembly/Crate.tscn")
var _slot_scene: PackedScene = preload("res://scenes/assembly/CharacterSlot.tscn")

var _roster: Array[CharacterDef] = []
var _slots: Array[CharacterSlot] = []
var _fight_director: FightDirector
var _match: MatchState
var _prep_hud: PrepHud
var _shop_bar: ShopBar
var _sell_zone: SellZone
var _crates: Array[Crate] = []
var _waiting_for_fight: bool = false

func _ready() -> void:
	_drag_service.add_to_group("drag_drop_service")
	_fight_director = FightDirector.new()
	add_child(_fight_director)
	_roster = ShopPool.roster()
	_title.visible = false
	_subtitle.visible = false
	_setup_tray_visual()
	_build_hud()
	_spawn_slots()
	_spawn_sell_zone()
	_drag_service.setup(_slots, _tray, _sell_zone)
	_drag_service.part_sold.connect(_on_part_sold)
	_drag_service.card_sold.connect(_on_card_sold)
	_drag_service.cards_swapped.connect(_on_cards_swapped)
	_match = MatchState.new()
	_match.start_match()
	_refresh_shop_crates()
	_refresh_hud()

func _process(delta: float) -> void:
	if _match == null or _match.phase != MatchState.Phase.PREP or _waiting_for_fight:
		return
	if _match.tick_prep(delta):
		_begin_fight()
	else:
		_prep_hud.set_time(_match.prep_time_left)

func _build_hud() -> void:
	_prep_hud = PrepHud.new()
	_hud.add_child(_prep_hud)
	_prep_hud.ready_pressed.connect(_on_ready_pressed)
	_shop_bar = ShopBar.new()
	_hud.add_child(_shop_bar)
	_shop_bar.refresh_pressed.connect(_on_refresh_pressed)
	_shop_bar.freeze_pressed.connect(_on_freeze_pressed)
	_shop_bar.upgrade_pressed.connect(_on_upgrade_pressed)

func _setup_tray_visual() -> void:
	_tray.position = AssemblyLayout.TRAY
	var shelf_tex: Texture2D = load("res://assets/ui/shelf_premium.png")
	_shelf.texture = shelf_tex
	_shelf.centered = true
	_shelf.position = Vector2(0, 58)
	var tex_size := shelf_tex.get_size()
	_shelf.scale = Vector2(1700.0 / tex_size.x, 170.0 / tex_size.y)
	_shelf.modulate = Color(0.9, 0.92, 0.95, 1)

func _spawn_slots() -> void:
	var ranks := [3, 2, 1]
	var existing: Array[CharacterSlot] = []
	for child in _slots_root.get_children():
		if child is CharacterSlot:
			existing.append(child as CharacterSlot)
	for i in AssemblyLayout.SLOT_X.size():
		var slot: CharacterSlot
		if i < existing.size():
			slot = existing[i]
		else:
			slot = _slot_scene.instantiate() as CharacterSlot
			_slots_root.add_child(slot)
		slot.position = Vector2(AssemblyLayout.SLOT_X[i], AssemblyLayout.SLOT_Y)
		slot.setup(null, _roster)
		slot.set_queue_rank(ranks[i])
		slot.card_drag_requested.connect(_on_card_drag_requested)
		slot.play_intro(0.12 * float(i))
		_slots.append(slot)

func _spawn_sell_zone() -> void:
	_sell_zone = SellZone.new()
	_tray.add_child(_sell_zone)
	_sell_zone.setup()

func _refresh_shop_crates() -> void:
	for crate in _crates:
		if is_instance_valid(crate):
			crate.queue_free()
	_crates.clear()
	for child in _tray.get_children():
		if child is Crate:
			child.queue_free()
	var human := _match.human()
	var count := MatchRules.SHOP_SLOTS
	for i in count:
		var part: PartDef = human.shop_offers[i] if i < human.shop_offers.size() else null
		if part == null:
			continue
		var crate: Crate = _crate_scene.instantiate() as Crate
		_tray.add_child(crate)
		var rest := Vector2(AssemblyLayout.crate_x(i, count), AssemblyLayout.CRATE_Y)
		crate.position = rest
		crate.shop_index = i
		crate.can_afford = func() -> bool: return _match.human().gold >= MatchRules.OPEN_CRATE_COST
		crate.on_paid_open = _pay_for_crate
		crate.setup(part, _part_scene, _drag_service, _tray)
		crate.set_rest_y(rest.y)
		crate.set_frozen_look(human.frozen)
		_crates.append(crate)

func _pay_for_crate(crate: Crate) -> bool:
	if not _match.try_spend(_match.human(), MatchRules.OPEN_CRATE_COST):
		return false
	if crate.shop_index >= 0 and crate.shop_index < _match.human().shop_offers.size():
		_match.human().shop_offers[crate.shop_index] = null
	_refresh_hud()
	return true

func _shop_nodes() -> Array:
	var nodes: Array = []
	for crate in _crates:
		if is_instance_valid(crate):
			nodes.append(crate)
	for child in _tray.get_children():
		if child is PartView and not (child as PartView).is_attached():
			nodes.append(child)
	nodes.append(_sell_zone)
	return nodes

func _refresh_hud() -> void:
	_prep_hud.refresh_players(_match)
	_prep_hud.set_time(_match.prep_time_left)
	_shop_bar.refresh(_match.human(), _match.round_index)
	if _match.phase == MatchState.Phase.PREP:
		_prep_hud.show_prep()
		_shop_bar.set_fight_style(false)

func _on_ready_pressed() -> void:
	if _match.phase == MatchState.Phase.GAME_OVER:
		_restart_match()
		return
	if _match.phase != MatchState.Phase.PREP or _waiting_for_fight:
		return
	_match.ready_up()
	_begin_fight()

func _restart_match() -> void:
	_drag_service.set_locked(false)
	_clear_player_pieces()
	_match.start_match()
	_refresh_shop_crates()
	_refresh_hud()

func _clear_player_pieces() -> void:
	for slot in _slots:
		slot.set_fight_locked(false)
		slot.visible = true
		slot.modulate.a = 1.0
		slot.scale = Vector2.ONE
		var stolen := slot.steal_all_parts()
		for key in stolen.keys():
			var view: PartView = stolen[key]
			if is_instance_valid(view):
				view.queue_free()
	for child in _tray.get_children():
		if child is PartView:
			child.queue_free()

func _on_refresh_pressed() -> void:
	if _match.phase != MatchState.Phase.PREP:
		return
	if _match.refresh_shop(_match.human()):
		_refresh_shop_crates()
		_refresh_hud()

func _on_freeze_pressed() -> void:
	if _match.phase != MatchState.Phase.PREP:
		return
	_match.toggle_freeze(_match.human())
	var frozen := _match.human().frozen
	for crate in _crates:
		if is_instance_valid(crate):
			crate.set_frozen_look(frozen)
	_refresh_hud()

func _on_upgrade_pressed() -> void:
	if _match.phase != MatchState.Phase.PREP:
		return
	if _match.upgrade_shop(_match.human()):
		_refresh_hud()

func _on_card_drag_requested(slot: CharacterSlot) -> void:
	_drag_service.begin_card_drag(slot)

func _on_part_sold(part: PartView) -> void:
	if part == null or not is_instance_valid(part):
		return
	part.unbind_from_card()
	_match.grant_sell(_match.human())
	part.queue_free()
	_refresh_hud()
	GameAudio.part_place()

func _on_card_sold(slot: CharacterSlot) -> void:
	var stolen := slot.steal_all_parts()
	for key in stolen.keys():
		var view: PartView = stolen[key]
		if is_instance_valid(view):
			view.queue_free()
	_match.grant_sell(_match.human())
	_refresh_hud()
	GameAudio.part_place()

func _on_cards_swapped(a: CharacterSlot, b: CharacterSlot) -> void:
	var from_a := a.steal_all_parts()
	var from_b := b.steal_all_parts()
	a.receive_parts(from_b)
	b.receive_parts(from_a)
	GameAudio.part_place()

func _snapshot_player_board() -> BoardLoadout:
	var board := BoardLoadout.new()
	board.fighters[0] = _slots[2].to_loadout()
	board.fighters[1] = _slots[1].to_loadout()
	board.fighters[2] = _slots[0].to_loadout()
	return board

func _begin_fight() -> void:
	if _waiting_for_fight or _match.phase == MatchState.Phase.GAME_OVER:
		return
	_waiting_for_fight = true
	_match.phase = MatchState.Phase.FIGHT
	_shop_bar.set_fight_style(true)
	_shop_bar.refresh(_match.human(), _match.round_index)
	_prep_hud.show_fight(_match.round_index)
	_prep_hud.refresh_players(_match)
	var human := _match.human()
	human.board = _snapshot_player_board()
	var opponent := _match.opponent_of(human)
	var opponent_board := opponent.board.duplicate_board() if opponent != null else BoardLoadout.new()
	var player_result := CombatSim.simulate(human.board.duplicate_board(), opponent_board)
	var other_results: Array = []
	for pair in _match.pairings:
		if pair.left == human:
			continue
		var sim := CombatSim.simulate(pair.left.board.duplicate_board(), pair.right.board.duplicate_board())
		other_results.append({"pair": pair, "result": sim})
	await _fight_director.play(
		player_result,
		_slots,
		opponent_board,
		_tray,
		_fx_layer,
		_drag_service,
		_shop_nodes(),
		human.display_name,
		opponent.display_name if opponent != null else "",
		human.hp,
		opponent.hp if opponent != null else 0
	)
	_match.apply_result(human, opponent, player_result)
	for packed in other_results:
		var pair: FightPair = packed["pair"]
		_match.apply_result(pair.left, pair.right, packed["result"], pair.right_is_ghost)
	_waiting_for_fight = false
	_match.finish_round()
	if _match.phase == MatchState.Phase.GAME_OVER:
		_drag_service.set_locked(true)
		_shop_bar.set_fight_style(true)
		_prep_hud.show_game_over(_match.winner_id == human.id)
		return
	_refresh_shop_crates()
	_refresh_hud()
