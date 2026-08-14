class_name AssemblyLayout
extends Object

## Screen positions matching the Unity layout, converted to Godot
## (origin top-left, Y grows downward, 1920×1080).

const WIDTH := 1920.0
const HEIGHT := 1080.0

const PREP_LABEL := Vector2(148, 40)
const TIMER := Vector2(960, 34)
const VS := Vector2(960, 108)
const READY := Vector2(1768, 42)
const READY_GAME_OVER := Vector2(960, 580)
const FIELD := Vector2(960, 136)
const REFRESH := Vector2(118, 704)
const FREEZE := Vector2(1802, 628)
const LEVEL := Vector2(118, 628)
const SMASH_BAR := Vector2(1024, 74)
const SMASH_LABEL := Vector2(824, 74)
const SELL_TRAY := Vector2(842, -108)
const TRAY := Vector2(960, 920)
const SLOT_X: Array[float] = [380.0, 960.0, 1540.0]
const SLOT_Y := 400.0
const BELT_TEX := "res://assets/ui/esteira-01.png"
const BELT_HEIGHT := 184.0
## Pixels from the top of the belt art down to the roller walking surface
## (crown of the cylinders, just below the red lip).
const BELT_ROLLER_FROM_TOP := 40.0
## From the crate origin (center) down to the visible 3/4 sit line.
## The front tip of the box tucks a little into the rollers.
const CRATE_SIT_OFFSET := 88.0
const FIGHT_CLASH := Vector2(960, 440)
## Names, HP and VS sit on a screen layer (not the camera). Keep a margin from the top.
const FIGHT_NAME_LEFT := Vector2(320, 88)
const FIGHT_NAME_RIGHT := Vector2(1600, 88)
const FIGHT_HP_LEFT := Vector2(320, 160)
const FIGHT_HP_RIGHT := Vector2(1600, 160)
const FIGHT_VS := Vector2(960, 88)
const CARD_LIFT := 460.0
const CARD_SETTLE := 360.0

static func crate_x(index: int, count: int) -> float:
	var spacing := 250.0
	if count >= 12:
		spacing = 138.0
	elif count >= 9:
		spacing = 165.0
	elif count > 5:
		spacing = 200.0
	var start := -spacing * float(count - 1) * 0.5
	return start + spacing * float(index)


static func smash_dot_center(index: int) -> Vector2:
	return Vector2(SMASH_BAR.x + (float(index) - 4.5) * 26.0, SMASH_BAR.y)


static func belt_world_top() -> float:
	return HEIGHT - BELT_HEIGHT


static func belt_roller_y() -> float:
	return belt_world_top() + BELT_ROLLER_FROM_TOP


static func crate_y() -> float:
	return belt_roller_y() - TRAY.y - CRATE_SIT_OFFSET


static func fight_shelf_y() -> float:
	return belt_roller_y() - TRAY.y - SpringBase.GROUND_Y


static func top_left(center: Vector2, size: Vector2) -> Vector2:
	return center - size * 0.5
