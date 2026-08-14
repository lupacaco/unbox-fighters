class_name SpringBase
extends Object

## Shared stand under every Freak. Not a shop kit and not a combat part.
## Pressed = something is sitting on it (or the fighter is on the ground).
## Loose = empty card, or the fighter is in the air during a hop.

const TEX_LOOSE := "res://assets/objects/base-mola-solta.png"
const TEX_PRESSED := "res://assets/objects/base-mola-pressionada.png"
## 300px art, scaled to sit under 200px parts.
const SCALE := 0.78
## Magnet (chrome sphere) from the image center. Y negative = up.
const MAGNET_LOOSE := Vector2(0, -112)
const MAGNET_PRESSED := Vector2(0, -48)
const BOTTOM_LOOSE := 143.0
const BOTTOM_PRESSED := 145.0
const GROUND_Y := 118.0
## Draw with the other parts (first in the tree, so it stays behind them).
## Negative Z hid the stand behind the dark card back.
const Z_INDEX := 0

static func texture(pressed: bool) -> Texture2D:
	return load(TEX_PRESSED if pressed else TEX_LOOSE) as Texture2D

static func magnet_px(pressed: bool) -> Vector2:
	return MAGNET_PRESSED if pressed else MAGNET_LOOSE

static func bottom_px(pressed: bool) -> float:
	return BOTTOM_PRESSED if pressed else BOTTOM_LOOSE

static func center_on_ground(pressed: bool) -> Vector2:
	return Vector2(0.0, GROUND_Y - bottom_px(pressed) * SCALE)

static func magnet_world(pressed: bool) -> Vector2:
	return center_on_ground(pressed) + magnet_px(pressed) * SCALE
