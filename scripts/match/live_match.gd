class_name LiveMatch
extends RefCounted

## The whole match in one place, with no drawing in it. Time keeps running:
## money ticks up, Freaks paddle down the belts, and whoever is alone at the tip
## chips away at the other player's life. The screen listens to the signals.

signal money_gained(player: PlayerState)
signal shop_rolled(player: PlayerState)
signal freak_launched(player: PlayerState, runner: BeltLane.Runner)
signal blows_traded(exchange: Duel.Exchange, left: BeltLane.Runner, right: BeltLane.Runner)
signal freak_died(player: PlayerState, runner: BeltLane.Runner)
signal player_chipped(victim: PlayerState, attacker: PlayerState)
signal match_ended(winner: PlayerState)

var player := PlayerState.new()
var opponent := PlayerState.new()
var rng := RandomNumberGenerator.new()
var running: bool = false
var winner: PlayerState = null

var _duel_timer: float = 0.0
var _chip_timer: float = 0.0
var _exchange_open: bool = false

func _init() -> void:
	rng.randomize()
	player.id = &"player"
	player.display_name = MatchRules.PLAYER_NAME
	player.is_bot = false
	opponent.id = &"opponent"
	opponent.display_name = MatchRules.OPPONENT_NAME
	opponent.is_bot = true

func start() -> void:
	winner = null
	_duel_timer = 0.0
	_chip_timer = 0.0
	_exchange_open = false
	for side in [player, opponent]:
		side.reset()
		side.roll_shop(rng)
		shop_rolled.emit(side)
	running = true

func tick(delta: float) -> void:
	if not running:
		return
	for side in [player, opponent]:
		if side.tick_money(delta):
			money_gained.emit(side)
	player.lane.advance(delta)
	opponent.lane.advance(delta)
	_tick_combat(delta)

## Sends a finished card to the belt. Returns null when the belt is full.
func launch(side: PlayerState, loadout: FighterLoadout) -> BeltLane.Runner:
	if not running or side == null or loadout == null:
		return null
	if not loadout.is_complete() or not loadout.stats().is_ready():
		return null
	var runner := side.lane.add(loadout)
	if runner == null:
		return null
	freak_launched.emit(side, runner)
	return runner

func refresh_shop(side: PlayerState, keep: PackedInt32Array = PackedInt32Array()) -> bool:
	if not running or side == null:
		return false
	if not side.refresh_shop(rng, keep):
		return false
	shop_rolled.emit(side)
	return true

func other(side: PlayerState) -> PlayerState:
	return opponent if side == player else player

## Applies one landed hit. Returns true when that Freak just fell.
func apply_hit(side: PlayerState, runner: BeltLane.Runner, amount: int) -> bool:
	if side == null:
		return false
	if not side.lane.take_damage(runner, amount):
		return false
	freak_died.emit(side, runner)
	return true

## Lets the belts move and fight again after the screen has shown the exchange.
func close_exchange() -> void:
	if not _exchange_open:
		return
	player.lane.remove_dead()
	opponent.lane.remove_dead()
	_exchange_open = false
	_duel_timer = 0.0

func _tick_combat(delta: float) -> void:
	if _exchange_open:
		return
	var mine := player.lane.champion()
	var theirs := opponent.lane.champion()
	if mine != null and theirs != null:
		_chip_timer = 0.0
		_tick_duel(delta, mine, theirs)
		return
	_duel_timer = 0.0
	if mine == null and theirs == null:
		_chip_timer = 0.0
		return
	_tick_chip(delta, mine != null)

func _tick_duel(delta: float, mine: BeltLane.Runner, theirs: BeltLane.Runner) -> void:
	_duel_timer += delta
	if _duel_timer < MatchRules.DUEL_INTERVAL:
		return
	_duel_timer = 0.0
	var trade := Duel.exchange(mine.stats, theirs.stats, mine.hp, theirs.hp, rng)
	_exchange_open = true
	if blows_traded.get_connections().is_empty():
		_resolve_quietly(trade, mine, theirs)
		return
	blows_traded.emit(trade, mine, theirs)

func _resolve_quietly(trade: Duel.Exchange, mine: BeltLane.Runner, theirs: BeltLane.Runner) -> void:
	if trade.first_is_left:
		apply_hit(opponent, theirs, trade.damage_to_right)
		if trade.second_happens:
			apply_hit(player, mine, trade.damage_to_left)
	else:
		apply_hit(player, mine, trade.damage_to_left)
		if trade.second_happens:
			apply_hit(opponent, theirs, trade.damage_to_right)
	close_exchange()

func _tick_chip(delta: float, player_leads: bool) -> void:
	_chip_timer += delta
	if _chip_timer < MatchRules.CHIP_INTERVAL:
		return
	_chip_timer -= MatchRules.CHIP_INTERVAL
	var attacker := player if player_leads else opponent
	var victim := other(attacker)
	victim.take_chip_damage()
	player_chipped.emit(victim, attacker)
	if not victim.is_alive():
		_finish(attacker)

func _finish(champion: PlayerState) -> void:
	running = false
	winner = champion
	match_ended.emit(champion)
