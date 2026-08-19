class_name MatchRules
extends RefCounted

## Closed numbers for the round-based match. Keep presentation code out of here.

enum Phase {
	PREP,
	FIGHT,
	RESOLUTION,
	GAME_OVER,
}

## Each side starts at 50 life. After a fight, the winner deals 5 per living Freak.
const PLAYER_HP := 50
const SURVIVOR_DAMAGE := 5

## Shared preparation clock. The player can skip it for both sides.
const PREP_SECONDS := 60.0
## Pause between one Freak jumping onto the belt and the next.
const DEPLOY_STAGGER := 0.4

const STARTING_MONEY := 10
const MONEY_PER_ROUND := 10
const MAX_MONEY := 50

## Four shelves of kits already unwrapped. Rerolling costs coins.
const SHOP_SLOTS := 4
const REFRESH_COST := 2
## Selling always returns this, no matter what you paid.
const SELL_REFUND := 1

const CARD_COUNT := 3
const BELT_CAPACITY := 3

## Five paddle strokes from the belt entry to the fighting tip.
const STROKES_TO_TIP := 5
## Every Freak waits the same time between strokes.
const STROKE_INTERVAL := 1.0

## Pause between finished exchanges, so the blows can be read.
const DUEL_INTERVAL := 1.1

const OPPONENT_NAME := "Oponente"
const PLAYER_NAME := "Você"

static func stroke_step() -> float:
	return 1.0 / float(STROKES_TO_TIP)

static func stroke_interval() -> float:
	return STROKE_INTERVAL

static func is_ready_loadout(loadout: FighterLoadout) -> bool:
	if loadout == null or not loadout.is_complete():
		return false
	return loadout.stats().is_ready()
