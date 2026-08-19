class_name LiveMatch
extends RefCounted

## Round-based match: a shared preparation clock, then a fight on the belts.
## The screen listens to the signals. Numbers stay here so they can be tested
## without opening the window.

signal money_gained(player: PlayerState)
signal shop_rolled(player: PlayerState)
signal freak_launched(player: PlayerState, runner: BeltLane.Runner)
signal blows_traded(exchange: Duel.Exchange, left: BeltLane.Runner, right: BeltLane.Runner)
signal freak_died(player: PlayerState, runner: BeltLane.Runner)
signal phase_changed(phase: MatchRules.Phase)
signal prep_ticked(seconds_left: float)
signal life_changed
signal fight_resolved(winner: PlayerState, survivors: int, damage: int)
signal match_ended(winner: PlayerState)

var player := PlayerState.new()
var opponent := PlayerState.new()
var rng := RandomNumberGenerator.new()
var running: bool = false
var winner: PlayerState = null
var phase: MatchRules.Phase = MatchRules.Phase.PREP
var prep_left: float = MatchRules.PREP_SECONDS

var _duel_timer: float = 0.0
var _exchange_open: bool = false
var _pending_player: Array[FighterLoadout] = []
var _pending_opponent: Array[FighterLoadout] = []
var _deploy_timer: float = 0.0
var _last_fight_winner: PlayerState = null
var _last_survivors: int = 0
var _last_damage: int = 0

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
	running = true
	_duel_timer = 0.0
	_exchange_open = false
	_clear_deploy()
	for side in [player, opponent]:
		side.reset()
		side.roll_shop(rng)
		shop_rolled.emit(side)
	_enter_prep(true)

func tick(delta: float) -> void:
	if not running:
		return
	match phase:
		MatchRules.Phase.PREP:
			_tick_prep(delta)
		MatchRules.Phase.FIGHT:
			_tick_fight(delta)
		MatchRules.Phase.RESOLUTION, MatchRules.Phase.GAME_OVER:
			pass

func is_prep() -> bool:
	return running and phase == MatchRules.Phase.PREP

func is_fight() -> bool:
	return running and phase == MatchRules.Phase.FIGHT

func skip_prep() -> void:
	if not is_prep():
		return
	prep_left = 0.0
	prep_ticked.emit(0.0)
	_begin_fight()

## Opens the fight with empty belts so checks can launch Freaks by hand.
func enter_fight() -> void:
	if not running or phase == MatchRules.Phase.GAME_OVER:
		return
	phase = MatchRules.Phase.FIGHT
	_clear_deploy()
	_exchange_open = false
	_duel_timer = 0.0
	player.lane.clear()
	opponent.lane.clear()
	phase_changed.emit(phase)

## Sends a finished card copy to the belt. The card itself stays filled.
func launch(side: PlayerState, loadout: FighterLoadout) -> BeltLane.Runner:
	if not is_fight() or side == null or loadout == null:
		return null
	if not MatchRules.is_ready_loadout(loadout):
		return null
	var runner := side.lane.add(loadout)
	if runner == null:
		return null
	freak_launched.emit(side, runner)
	return runner

func refresh_shop(side: PlayerState, keep: PackedInt32Array = PackedInt32Array()) -> bool:
	if not is_prep() or side == null:
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

## Called by the screen after the Freaks have jumped back to their cards.
func finish_resolution() -> void:
	if not running or phase != MatchRules.Phase.RESOLUTION:
		return
	_enter_prep(false)

func _enter_prep(opening: bool) -> void:
	phase = MatchRules.Phase.PREP
	prep_left = MatchRules.PREP_SECONDS
	player.lane.clear()
	opponent.lane.clear()
	_clear_deploy()
	_exchange_open = false
	_duel_timer = 0.0
	if not opening:
		player.grant_round_income()
		opponent.grant_round_income()
		money_gained.emit(player)
		money_gained.emit(opponent)
		for side in [player, opponent]:
			side.roll_shop(rng, side.owned_keep())
			shop_rolled.emit(side)
	phase_changed.emit(phase)
	prep_ticked.emit(prep_left)
	life_changed.emit()

func _tick_prep(delta: float) -> void:
	prep_left = maxf(0.0, prep_left - delta)
	prep_ticked.emit(prep_left)
	if prep_left <= 0.0:
		_begin_fight()

func _begin_fight() -> void:
	if phase != MatchRules.Phase.PREP:
		return
	phase = MatchRules.Phase.FIGHT
	_clear_deploy()
	_pending_player = _ready_loadouts(player)
	_pending_opponent = _ready_loadouts(opponent)
	phase_changed.emit(phase)
	if _pending_player.is_empty() and _pending_opponent.is_empty():
		_resolve_fight(null, 0)
		return
	_deploy_timer = MatchRules.DEPLOY_STAGGER
	_tick_deploy(MatchRules.DEPLOY_STAGGER)

func _tick_fight(delta: float) -> void:
	_tick_deploy(delta)
	player.lane.advance(delta)
	opponent.lane.advance(delta)
	_tick_combat(delta)
	_try_resolve_fight()

func _tick_deploy(delta: float) -> void:
	if _pending_player.is_empty() and _pending_opponent.is_empty():
		return
	_deploy_timer += delta
	if _deploy_timer < MatchRules.DEPLOY_STAGGER:
		return
	_deploy_timer = 0.0
	if not _pending_player.is_empty():
		var mine: FighterLoadout = _pending_player[0]
		_pending_player.remove_at(0)
		launch(player, mine)
	if not _pending_opponent.is_empty():
		var theirs: FighterLoadout = _pending_opponent[0]
		_pending_opponent.remove_at(0)
		launch(opponent, theirs)

func _ready_loadouts(side: PlayerState) -> Array[FighterLoadout]:
	var ready: Array[FighterLoadout] = []
	for card in side.cards:
		if MatchRules.is_ready_loadout(card):
			ready.append(card.duplicate_loadout())
	return ready

func _still_deploying() -> bool:
	return not _pending_player.is_empty() or not _pending_opponent.is_empty()

func _try_resolve_fight() -> void:
	if phase != MatchRules.Phase.FIGHT or _exchange_open or _still_deploying():
		return
	var mine := player.lane.alive_count()
	var theirs := opponent.lane.alive_count()
	if mine > 0 and theirs > 0:
		return
	if mine == 0 and theirs == 0:
		_resolve_fight(null, 0)
		return
	var leader := player if mine > 0 else opponent
	if leader.lane.champion() == null:
		return
	_resolve_fight(leader, leader.lane.alive_count())

func _resolve_fight(leader: PlayerState, survivors: int) -> void:
	if phase != MatchRules.Phase.FIGHT:
		return
	phase = MatchRules.Phase.RESOLUTION
	var damage := 0
	if leader != null and survivors > 0:
		damage = survivors * MatchRules.SURVIVOR_DAMAGE
		other(leader).take_life_damage(damage)
		life_changed.emit()
	_last_fight_winner = leader
	_last_survivors = survivors
	_last_damage = damage
	phase_changed.emit(phase)
	fight_resolved.emit(leader, survivors, damage)
	if player.life <= 0 or opponent.life <= 0:
		var champion := player if opponent.life <= 0 else opponent
		if player.life <= 0 and opponent.life <= 0:
			champion = leader if leader != null else player
		_finish(champion)
		return
	if fight_resolved.get_connections().is_empty():
		finish_resolution()

func _clear_deploy() -> void:
	_pending_player.clear()
	_pending_opponent.clear()
	_deploy_timer = 0.0

func _tick_combat(delta: float) -> void:
	if _exchange_open:
		return
	var mine := player.lane.champion()
	var theirs := opponent.lane.champion()
	if mine == null or theirs == null:
		_duel_timer = 0.0
		return
	_tick_duel(delta, mine, theirs)

func _tick_duel(delta: float, mine: BeltLane.Runner, theirs: BeltLane.Runner) -> void:
	_duel_timer += delta
	if _duel_timer < MatchRules.DUEL_INTERVAL:
		return
	_duel_timer = 0.0
	var trade := Duel.exchange(
		mine.stats,
		theirs.stats,
		mine.hp,
		theirs.hp,
		rng,
		mine.appeal_ready(),
		theirs.appeal_ready()
	)
	_exchange_open = true
	if blows_traded.get_connections().is_empty():
		_resolve_quietly(trade, mine, theirs)
		return
	blows_traded.emit(trade, mine, theirs)

func _resolve_quietly(trade: Duel.Exchange, mine: BeltLane.Runner, theirs: BeltLane.Runner) -> void:
	if trade.first_is_left:
		apply_blow(mine, theirs, player, opponent)
		if trade.second_happens:
			apply_blow(theirs, mine, opponent, player)
	else:
		apply_blow(theirs, mine, opponent, player)
		if trade.second_happens:
			apply_blow(mine, theirs, player, opponent)
	close_exchange()

## Who this blow actually hits. Mind control can send it to the attacker's ally.
func plan_blow(
	attacker: BeltLane.Runner,
	defender: BeltLane.Runner,
	attacker_side: PlayerState,
	defender_side: PlayerState
) -> Dictionary:
	var waiter := attacker_side.lane.waiter() if attacker_side != null else null
	if attacker != null and attacker.redirect_next and waiter != null:
		return {
			"victim": waiter,
			"victim_side": attacker_side,
			"damage": maxi(0, attacker.stats.attack),
			"redirected": true,
		}
	return {
		"victim": defender,
		"victim_side": defender_side,
		"damage": maxi(0, attacker.stats.attack) if attacker != null and attacker.stats != null else 0,
		"redirected": false,
	}

## Lands one swing: maybe onto an ally, then maybe marks the victim for mind control.
func apply_blow(
	attacker: BeltLane.Runner,
	defender: BeltLane.Runner,
	attacker_side: PlayerState,
	defender_side: PlayerState
) -> bool:
	var plan := plan_blow(attacker, defender, attacker_side, defender_side)
	var victim: BeltLane.Runner = plan["victim"]
	var victim_side: PlayerState = plan["victim_side"]
	var damage: int = int(plan["damage"])
	if bool(plan["redirected"]):
		attacker.redirect_next = false
		if attacker.mc_source != null:
			attacker.mc_source.mc_available = false
			attacker.mc_source = null
		return apply_hit(victim_side, victim, damage)
	var died := apply_hit(victim_side, victim, damage)
	if (
		attacker != null
		and attacker.stats != null
		and attacker.stats.ability == FreakAbility.Value.MIND_CONTROL
		and attacker.mc_available
		and defender_side != null
		and defender_side.lane.waiter() != null
		and defender != null
		and defender.alive
	):
		defender.redirect_next = true
		defender.mc_source = attacker
	return died

func _finish(champion: PlayerState) -> void:
	running = false
	phase = MatchRules.Phase.GAME_OVER
	winner = champion
	phase_changed.emit(phase)
	match_ended.emit(champion)
