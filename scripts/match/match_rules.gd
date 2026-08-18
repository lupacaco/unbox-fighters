class_name MatchRules
extends RefCounted

## Closed numbers for the live 1-versus-1 match. Keep presentation code out of here.

## Each player has a life bar. A Freak alone at the end of the belt drains it.
const STARTING_HP := 100
const CHIP_DAMAGE := 1
const CHIP_INTERVAL := 1.0

## Money ticks up on its own and caps out, so sitting on cash is a waste.
const STARTING_MONEY := 10
const MAX_MONEY := 10
const MONEY_INTERVAL := 2.0

## The shop shows four crates at once and rerolling all four costs a coin.
const SHOP_SLOTS := 4
const REFRESH_COST := 1

## Two cards, so you can build the next Freak while the first one fights.
const CARD_COUNT := 2
## How many Freaks fit on one belt.
const BELT_CAPACITY := 2

## Sliding speed in pixels per second: agility 1 is a crawl, agility 5 flies.
const BELT_BASE_SPEED := 120.0
const BELT_SPEED_PER_AGILITY := 60.0

## One exchange of blows, then both sides take their damage.
const DUEL_INTERVAL := 1.1

const OPPONENT_NAME := "Oponente"
const PLAYER_NAME := "Você"

static func belt_speed(agility: int) -> float:
	return BELT_BASE_SPEED + float(maxi(agility, 0)) * BELT_SPEED_PER_AGILITY
