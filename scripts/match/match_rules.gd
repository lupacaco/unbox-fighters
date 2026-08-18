class_name MatchRules
extends RefCounted

## Closed numbers for the live 1-versus-1 match. Keep presentation code out of here.

## One shared tug bar: 0 in the middle, 50 toward you (left) or them (right).
## A Freak alone at the belt tip pushes that number 1 per second.
const TUG_MAX := 50
const CHIP_DAMAGE := 1
const CHIP_INTERVAL := 1.0

## Money ticks up on its own and caps out, so sitting on cash is a waste.
const STARTING_MONEY := 10
const MAX_MONEY := 10
const MONEY_INTERVAL := 2.0

## The shop shows one crate. Rerolling it is free.
const SHOP_SLOTS := 1
const REFRESH_COST := 0

## Two cards, so you can build the next Freak while the first one fights.
const CARD_COUNT := 2
## How many Freaks fit on one belt.
const BELT_CAPACITY := 2

## Five paddle strokes from the belt entry to the fighting tip.
const STROKES_TO_TIP := 5
## Agility 1 waits 3 s between strokes; each extra point shaves 0.5 s, floor 1 s.
const STROKE_INTERVAL_MAX := 3.0
const STROKE_INTERVAL_MIN := 1.0
const STROKE_INTERVAL_STEP := 0.5

## Pause between finished exchanges, so the blows can be read.
const DUEL_INTERVAL := 1.1

const OPPONENT_NAME := "Oponente"
const PLAYER_NAME := "Você"

static func stroke_step() -> float:
	return 1.0 / float(STROKES_TO_TIP)

static func stroke_interval(agility: int) -> float:
	return clampf(
		STROKE_INTERVAL_MAX - STROKE_INTERVAL_STEP * float(maxi(agility, 1) - 1),
		STROKE_INTERVAL_MIN,
		STROKE_INTERVAL_MAX
	)
