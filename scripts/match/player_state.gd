class_name PlayerState
extends RefCounted

## One side of the match: a wallet, a shop, three cards and a belt.
## Both the human and the bot use this, so the two play by the same rules.

var id: StringName = &"player"
var display_name: String = MatchRules.PLAYER_NAME
var is_bot: bool = false
var money: int = MatchRules.STARTING_MONEY
var life: int = MatchRules.PLAYER_HP
var shop_offers: Array[PartDef] = []
## What each shop slot costs while it is for sale.
var shop_prices: PackedInt32Array = PackedInt32Array()
## True when that shelf holds a kit you already paid for (it came back from a card).
var shop_owned: Array[bool] = []
var cards: Array[FighterLoadout] = []
var lane := BeltLane.new()

func _init() -> void:
	reset_shop_slots()
	reset_cards()

func reset() -> void:
	money = MatchRules.STARTING_MONEY
	life = MatchRules.PLAYER_HP
	lane.clear()
	reset_shop_slots()
	reset_cards()

func reset_shop_slots() -> void:
	shop_offers.clear()
	shop_owned.clear()
	shop_prices.resize(MatchRules.SHOP_SLOTS)
	for i in MatchRules.SHOP_SLOTS:
		shop_offers.append(null)
		shop_owned.append(false)
		shop_prices[i] = 0

func reset_cards() -> void:
	cards.clear()
	for _i in MatchRules.CARD_COUNT:
		cards.append(FighterLoadout.new())

func can_afford(amount: int) -> bool:
	return amount >= 0 and money >= amount

func spend(amount: int) -> bool:
	if not can_afford(amount):
		return false
	money -= amount
	return true

func earn(amount: int) -> void:
	money = mini(MatchRules.MAX_MONEY, money + maxi(0, amount))

func grant_round_income() -> void:
	earn(MatchRules.MONEY_PER_ROUND)

func take_life_damage(amount: int) -> void:
	life = maxi(0, life - maxi(0, amount))

## Fills the shelves. Owned kits that came back from a card stay put.
func roll_shop(rng: RandomNumberGenerator, keep: PackedInt32Array = PackedInt32Array()) -> void:
	var fresh := ShopPool.roll(rng, MatchRules.SHOP_SLOTS)
	shop_prices.resize(MatchRules.SHOP_SLOTS)
	shop_owned.resize(MatchRules.SHOP_SLOTS)
	for i in MatchRules.SHOP_SLOTS:
		if i in keep or (i < shop_owned.size() and shop_owned[i]):
			continue
		shop_offers[i] = fresh[i]
		shop_prices[i] = PartStats.price_of(fresh[i])
		shop_owned[i] = false

func refresh_shop(rng: RandomNumberGenerator, keep: PackedInt32Array = PackedInt32Array()) -> bool:
	if MatchRules.REFRESH_COST > 0 and not spend(MatchRules.REFRESH_COST):
		return false
	roll_shop(rng, keep)
	return true

func owned_keep() -> PackedInt32Array:
	var keep := PackedInt32Array()
	for i in shop_owned.size():
		if shop_owned[i]:
			keep.append(i)
	return keep

func price_at(index: int) -> int:
	if index < 0 or index >= shop_prices.size():
		return 0
	if index < shop_owned.size() and shop_owned[index]:
		return 0
	return shop_prices[index]

## Pays for a for-sale kit and empties that shelf. Returns null when it cannot afford it.
func buy(index: int) -> PartDef:
	if index < 0 or index >= shop_offers.size():
		return null
	if index < shop_owned.size() and shop_owned[index]:
		return null
	var part := shop_offers[index]
	if part == null or not spend(price_at(index)):
		return null
	clear_slot(index)
	return part

func clear_slot(index: int) -> void:
	if index < 0 or index >= shop_offers.size():
		return
	shop_offers[index] = null
	shop_prices[index] = 0
	if index < shop_owned.size():
		shop_owned[index] = false

## Puts a kit you already paid for back onto an empty shelf.
func return_owned(index: int, part: PartDef) -> bool:
	if part == null or index < 0 or index >= shop_offers.size():
		return false
	if shop_offers[index] != null:
		return false
	shop_offers[index] = part
	shop_prices[index] = 0
	shop_owned[index] = true
	return true

func first_empty_slot() -> int:
	for i in shop_offers.size():
		if shop_offers[i] == null:
			return i
	return -1
