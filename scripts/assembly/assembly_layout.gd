class_name AssemblyLayout
extends Object

## Screen positions matching the Unity layout, converted to Godot
## (origin top-left, Y grows downward, 1920×1080).

const WIDTH := 1920.0
const HEIGHT := 1080.0

const PREP_LABEL := Vector2(220, 36)
const TIMER := Vector2(960, 36)
const VS := Vector2(960, 78)
const READY := Vector2(1700, 40)
const FIELD := Vector2(960, 100)
const REFRESH := Vector2(168, 912)
const FREEZE := Vector2(1752, 912)
const LEVEL := Vector2(400, 802)
const SMASH_BAR := Vector2(960, 802)
const SMASH_LABEL := Vector2(960, 774)
const SELL_TRAY := Vector2(792, -150)
const TRAY := Vector2(960, 920)
const SLOT_X: Array[float] = [380.0, 960.0, 1540.0]
const SLOT_Y := 400.0
const CRATE_Y := -58.0
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
	return Vector2(SMASH_BAR.x + (float(index) - 4.5) * 28.0, SMASH_BAR.y)


static func top_left(center: Vector2, size: Vector2) -> Vector2:
	return center - size * 0.5
