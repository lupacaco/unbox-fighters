class_name MatchRules
extends RefCounted

## Closed numbers for the auto-battle match. Keep presentation code out of here.

const STARTING_HP := 40
const STARTING_GOLD := 3
const MAX_GOLD := 10
const PREP_SECONDS := 60.0
const SHOP_SLOTS := 5
const QUEUE_SIZE := 3
const DAMAGE_CAP_PER_FIGHTER := 12
const SHOP_MAX_TIER := 5
const OPEN_CRATE_COST := 1
const REFRESH_COST := 1
const SELL_REWARD := 1
const HUMAN_COUNT := 1
const BOT_COUNT := 3
const MAX_BOT_REFRESHES := 6

## Cost to go from tier 1→2, 2→3, 3→4, 4→5.
const UPGRADE_COSTS: Array[int] = [4, 5, 6, 7]

const BOT_NAMES: Array[String] = ["Sombra", "Ferrugem", "Névoa"]

static func gold_for_round(round_index: int) -> int:
	return mini(MAX_GOLD, STARTING_GOLD + maxi(round_index, 1) - 1)

static func upgrade_cost(current_tier: int) -> int:
	if current_tier < 1 or current_tier >= SHOP_MAX_TIER:
		return -1
	return UPGRADE_COSTS[current_tier - 1]
