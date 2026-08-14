class_name SpringBase
extends Object

## Shared stand under every Freak. Not a shop kit and not a combat part.
## Pressed = something is sitting on it (or the fighter is on the ground).
## Loose = empty card, or the fighter is in the air during a hop.

const TEX_LOOSE := "res://assets/objects/base-mola-solta.png"
const TEX_PRESSED := "res://assets/objects/base-mola-pressionada.png"
## 300px art, scaled to sit under 200px parts.
const SCALE := 0.70
## Magnet (chrome sphere) from the image center. Y negative = up.
const MAGNET_LOOSE := Vector2(0, -112)
const MAGNET_PRESSED := Vector2(0, -48)
const BOTTOM_LOOSE := 143.0
const BOTTOM_PRESSED := 145.0
const GROUND_Y := 128.0
## Draw with the other parts (first in the tree, so it stays behind them).
## Negative Z hid the stand behind the dark card back.
const Z_INDEX := 0
const SHADOW_Z := -1
const SHADOW_COLOR := Color(0.02, 0.02, 0.05, 0.42)

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

static func shadow_position() -> Vector2:
	return Vector2(0.0, GROUND_Y + 6.0)

static func make_shadow(node_name: String = "SpringShadow") -> Polygon2D:
	var poly := Polygon2D.new()
	poly.name = node_name
	style_shadow(poly)
	return poly

static func style_shadow(poly: Polygon2D) -> void:
	poly.polygon = _ellipse(Vector2(150.0, 26.0) * SCALE)
	poly.color = SHADOW_COLOR
	poly.z_index = SHADOW_Z
	poly.position = shadow_position()
	poly.modulate = Color.WHITE

static func hop_shadow_look(lift: float, hop_height: float) -> Dictionary:
	var u := clampf(lift / maxf(hop_height, 1.0), 0.0, 1.0)
	return {
		"scale": Vector2(1.0 - 0.34 * u, 1.0 - 0.22 * u),
		"alpha": 1.0 - 0.48 * u,
	}

static func _ellipse(radius: Vector2, points: int = 18) -> PackedVector2Array:
	var pts := PackedVector2Array()
	pts.resize(points)
	for i in points:
		var a := TAU * float(i) / float(points)
		pts[i] = Vector2(cos(a) * radius.x, sin(a) * radius.y)
	return pts
