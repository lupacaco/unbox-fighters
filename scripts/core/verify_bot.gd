extends SceneTree

## The opponent shops on the shared clock: it spends, places kits, and never
## sends a Freak until preparation ends.

const TRAVEL := 700.0
const PREP_SECONDS := 60.0
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
	if not _stock_finishable_shop(live.opponent):
		push_error("VERIFY_FAIL could not stock a shop the bot can finish")
		quit(1)
		return
	if live.opponent.cards.size() != MatchRules.CARD_COUNT:
		push_error("VERIFY_FAIL the bot should get %d cards" % MatchRules.CARD_COUNT)
		quit(1)
		return

	live.freak_launched.connect(_count_launch)
	var spent_something := false
	for i in int(PREP_SECONDS / STEP):
		live.tick(STEP)
		bot.tick(STEP, live.opponent, live)
		if live.opponent.money < MatchRules.STARTING_MONEY:
			spent_something = true
		if live.phase == MatchRules.Phase.PREP and _launched > 0:
			push_error("VERIFY_FAIL the bot launched during preparation")
			quit(1)
			return
		if live.phase != MatchRules.Phase.PREP:
			break

	if not spent_something:
		push_error("VERIFY_FAIL the bot never spent a coin")
		quit(1)
		return
	var assembled := 0
	for card in live.opponent.cards:
		if card.is_complete():
			assembled += 1
	if assembled <= 0:
		push_error("VERIFY_FAIL the bot never finished a Freak")
		quit(1)
		return

	if live.phase == MatchRules.Phase.PREP:
		live.skip_prep()
	for _i in 80:
		live.tick(STEP)
		if live.phase != MatchRules.Phase.FIGHT:
			break
	if _launched <= 0:
		push_error("VERIFY_FAIL ready Freaks should jump when the fight starts")
		quit(1)
		return
	if live.opponent.money < 0 or live.opponent.money > MatchRules.MAX_MONEY:
		push_error("VERIFY_FAIL the bot's wallet left the allowed range")
		quit(1)
		return
	if not _check_taste():
		quit(1)
		return
	if not _check_thrift():
		quit(1)
		return

	print("VERIFY_BOT_PASS launched=%d assembled=%d" % [_launched, assembled])
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


## Puts a cheap head and body on the shelves so the bot can finish on $10.
func _stock_finishable_shop(side: PlayerState) -> bool:
	var bruxa: CharacterDef = load("res://data/parts/bruxa_character.tres")
	var advogado: CharacterDef = load("res://data/parts/advogado_character.tres")
	if bruxa == null or bruxa.head == null or bruxa.body == null:
		return false
	if advogado == null or advogado.head == null or advogado.body == null:
		return false
	var parts: Array[PartDef] = [advogado.head, bruxa.body, bruxa.head, advogado.body]
	for i in side.shop_offers.size():
		side.shop_offers[i] = parts[i]
		side.shop_prices[i] = PartStats.price_of(parts[i])
		side.shop_owned[i] = false
	return true


## A kit that cannot finish a card this shop must stay on the shelf.
func _check_thrift() -> bool:
	var side := PlayerState.new()
	side.money = MatchRules.STARTING_MONEY
	var bruxa: CharacterDef = load("res://data/parts/bruxa_character.tres")
	var advogado: CharacterDef = load("res://data/parts/advogado_character.tres")
	if bruxa == null or advogado == null:
		push_error("VERIFY_FAIL missing Freaks for the thrift check")
		return false
	side.shop_offers[0] = advogado.body
	side.shop_prices[0] = PartStats.price_of(advogado.body)
	side.shop_owned[0] = false
	side.shop_offers[1] = bruxa.head
	side.shop_prices[1] = PartStats.price_of(bruxa.head)
	side.shop_owned[1] = false
	for i in range(2, side.shop_offers.size()):
		side.shop_offers[i] = null
		side.shop_prices[i] = 0
		side.shop_owned[i] = false
	var bot := BotBrain.new()
	if bot._try_buy(side):
		push_error("VERIFY_FAIL the bot should not buy a kit it cannot pair")
		return false
	return true
