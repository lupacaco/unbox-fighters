class_name PlayerState
extends RefCounted

## One side of the match: a wallet, a shop and a belt.
## Both the human and the bot use this, so the two play by the same rules.
## Match life lives on LiveMatch.tug, not here — it is one shared number.

var id: StringName = &"player"
var display_name: String = MatchRules.PLAYER_NAME
var is_bot: bool = false
var money: int = MatchRules.STARTING_MONEY
var shop_offers: Array[PartDef] = []
## What each shop slot cost, so selling can give half of it back.
var shop_prices: PackedInt32Array = PackedInt32Array()
var lane := BeltLane.new()

var _money_timer: float = 0.0

func _init() -> void:
	reset_shop_slots()

func reset() -> void:
	money = MatchRules.STARTING_MONEY
	_money_timer = 0.0
	lane.clear()
	reset_shop_slots()

func reset_shop_slots() -> void:
	shop_offers.clear()
	shop_prices.resize(MatchRules.SHOP_SLOTS)
	for i in MatchRules.SHOP_SLOTS:
		shop_offers.append(null)
		shop_prices[i] = 0

## Returns true on the ticks where the wallet actually gained a coin.
func tick_money(delta: float) -> bool:
	if money >= MatchRules.MAX_MONEY:
		_money_timer = 0.0
		return false
	_money_timer += delta
	if _money_timer < MatchRules.MONEY_INTERVAL:
		return false
	_money_timer -= MatchRules.MONEY_INTERVAL
	money = mini(MatchRules.MAX_MONEY, money + 1)
	return true

func can_afford(amount: int) -> bool:
	return amount >= 0 and money >= amount

func spend(amount: int) -> bool:
	if not can_afford(amount):
		return false
	money -= amount
	return true

func earn(amount: int) -> void:
	money = mini(MatchRules.MAX_MONEY, money + maxi(0, amount))

## Fills the shelves. Shelves in `keep` still hold a kit you paid for, so a
## reroll leaves them alone instead of throwing your money away.
func roll_shop(rng: RandomNumberGenerator, keep: PackedInt32Array = PackedInt32Array()) -> void:
	var fresh := ShopPool.roll(rng, MatchRules.SHOP_SLOTS)
	shop_prices.resize(MatchRules.SHOP_SLOTS)
	for i in MatchRules.SHOP_SLOTS:
		if i in keep:
			continue
		shop_offers[i] = fresh[i]
		shop_prices[i] = PartStats.price_of(fresh[i])

func refresh_shop(rng: RandomNumberGenerator, keep: PackedInt32Array = PackedInt32Array()) -> bool:
	if MatchRules.REFRESH_COST > 0 and not spend(MatchRules.REFRESH_COST):
		return false
	roll_shop(rng, keep)
	return true

func price_at(index: int) -> int:
	if index < 0 or index >= shop_prices.size():
		return 0
	return shop_prices[index]

## Pays for a crate and empties that shelf. Returns null when it cannot afford it.
func buy(index: int) -> PartDef:
	if index < 0 or index >= shop_offers.size():
		return null
	var part := shop_offers[index]
	if part == null or not spend(price_at(index)):
		return null
	shop_offers[index] = null
	return part
