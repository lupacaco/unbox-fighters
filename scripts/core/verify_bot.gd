extends SceneTree

## The opponent plays by the same rules and the same hands: it waits for money,
## spends the time to open a crate and place a kit, and cannot launch a Freak
## in the first seconds of a match.

const TRAVEL := 700.0
const RUN_SECONDS := 120.0
const STEP := 0.1

var _launched: int = 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var live := LiveMatch.new()
	live.player.lane.travel_px = TRAVEL
	live.opponent.lane.travel_px = TRAVEL
	live.start()
	var bot := BotBrain.new()
	bot.reset()
	if bot.cards.size() != MatchRules.CARD_COUNT:
		push_error("VERIFY_FAIL the bot should get %d cards" % MatchRules.CARD_COUNT)
		quit(1)
		return

	live.freak_launched.connect(_count_launch)
	var spent_something := false
	var earliest := BotBrain.earliest_launch_time()
	for i in int(RUN_SECONDS / STEP):
		var elapsed := float(i) * STEP
		live.tick(STEP)
		bot.tick(STEP, live.opponent, live)
		if live.opponent.money < MatchRules.MAX_MONEY:
			spent_something = true
		if elapsed + 0.001 < earliest and _launched > 0:
			push_error("VERIFY_FAIL the bot launched at %.1fs; a player cannot assemble that fast" % elapsed)
			quit(1)
			return
		if not live.running:
			break

	if not spent_something:
		push_error("VERIFY_FAIL the bot never spent a coin")
		quit(1)
		return
	if _launched <= 0:
		push_error("VERIFY_FAIL the bot never sent a Freak to fight")
		quit(1)
		return
	if live.opponent.money < 0 or live.opponent.money > MatchRules.MAX_MONEY:
		push_error("VERIFY_FAIL the bot's wallet left the allowed range")
		quit(1)
		return
	if not live.running and live.winner != live.opponent:
		push_error("VERIFY_FAIL nobody stops the bot, so it should win")
		quit(1)
		return
	if not _check_taste():
		quit(1)
		return
	if BotBrain.earliest_launch_time() < 6.0:
		push_error("VERIFY_FAIL assembling three kits must take several seconds")
		quit(1)
		return

	print("VERIFY_BOT_PASS launched=%d" % _launched)
	quit(0)

## A kit that completes a set has to beat a bigger lone number.
func _check_taste() -> bool:
	var bruxa: CharacterDef = load("res://data/parts/bruxa_character.tres")
	var advogado: CharacterDef = load("res://data/parts/advogado_character.tres")
	var bot := BotBrain.new()
	var card := FighterLoadout.new()
	card.set_part(PartSlotType.Value.HEAD, bruxa.head)
	var matching: int = bot._score(card, bruxa.body)
	var stranger: int = bot._score(card, advogado.body)
	if matching <= stranger:
		push_error("VERIFY_FAIL finishing a set should be worth more")
		return false
	if bot._score(card, advogado.head) != 0:
		push_error("VERIFY_FAIL a busy slot should be worth nothing")
		return false
	return true

func _count_launch(_side: PlayerState, _runner: BeltLane.Runner) -> void:
	_launched += 1
