class_name AssemblyLayout
extends Object

## Every position on the match screen, in a 1920×1080 world
## (origin top-left, Y grows downward).
##
## Left: your two hanging cards. Middle: one shop shelf.
## Right: the opponent's two cards (look, do not drop).
## Above the belts: the shared tug bar.

const WIDTH := 1920.0
const HEIGHT := 1080.0
const CENTER_X := WIDTH * 0.5

const BACKGROUND_TEX := "res://assets/nova-ui/fundo.png"
const CARD_TEX := "res://assets/nova-ui/carta.png"
const CARD_OPPONENT_TEX := "res://assets/nova-ui/carta-oponente.png"
const SHELF_TEX := "res://assets/nova-ui/prateleira-loja.png"
const BELT_PLAYER_TEX := "res://assets/nova-ui/esteira-blue.png"
const BELT_OPPONENT_TEX := "res://assets/nova-ui/esteira-red.png"
const REFRESH_TEX := "res://assets/nova-ui/atualizar.png"
const SELL_TEX := "res://assets/nova-ui/vender.png"
const TUG_FRAME_TEX := "res://assets/nova-ui/barra-hp-vazia.png"
const TUG_PLAYER_TEX := "res://assets/nova-ui/liquido-jogador.png"
const TUG_OPPONENT_TEX := "res://assets/nova-ui/liquido-oponente.png"

# ---------------------------------------------------------------- belts
const BELT_SIZE := Vector2(840, 129)
## Pixels from the top of the belt art down to the crown of the rollers.
const BELT_ROLLER_FROM_TOP := 24.0
## How far a Freak stops from the gap, so the two never overlap.
const BELT_TIP_INSET := 40.0
## Where a Freak drops on, measured from the outer end of the belt.
const BELT_ENTRY_INSET := 70.0
const BELT_FREAK_SCALE := 0.62

# ---------------------------------------------------------------- cards
const CARD_SIZE := Vector2(306, 572)
const CARD_CENTER_Y := 350.0
const CARD_X: Array[float] = [188.0, 514.0]
const CARD_OPPONENT_X: Array[float] = [1406.0, 1732.0]
## Local Y of the little wooden ledge inside the card, where the crate rests.
const CARD_FLOOR_Y := 200.0
const CARD_FREAK_SCALE := 0.92
## Inner well of the frame, in card-local coordinates.
const CARD_WELL := Rect2(-124, -246, 248, 458)
## The three stat pills sit in a row on the wooden lip under the well.
const CARD_PILL_Y := 256.0
const CARD_PILL_STEP := 84.0
const FIGHT_BUTTON_SIZE := Vector2(214, 58)
const FIGHT_BUTTON_DROP := 348.0

# ---------------------------------------------------------------- shop
const SHELF_SIZE := Vector2(438, 95)
const SHELF_CENTER := Vector2(1036.0, 508.0)
## From the shelf center up to the wooden surface a crate sits on.
const SHELF_SURFACE_FROM_CENTER := 36.0
const SHOP_CRATE_HEIGHT := 156.0
const SHOP_PART_SCALE := 0.62
const PRICE_TAG_DROP := 96.0

# ---------------------------------------------------------------- buttons and money beside the shelf
const ICON_BUTTON_SIZE := Vector2(128, 128)
const REFRESH_BUTTON := Vector2(1036.0, 338.0)
const SELL_BUTTON := Vector2(742.0, 508.0)
const MONEY_X := 1336.0
const MONEY_LABEL_Y := 292.0
const MONEY_BOTTOM_Y := 620.0
const MONEY_BRICK := Vector2(78, 26)
const MONEY_BRICK_STEP := 34.0

# ---------------------------------------------------------------- tug bar (above the belts)
const TUG_SIZE := Vector2(819, 149)
const TUG_CENTER := Vector2(960.0, 868.0)
const BANNER_CENTER := Vector2(960, 210)

static func belt_top() -> float:
	return HEIGHT - BELT_SIZE.y

## The line the crate base rests on.
static func belt_floor_y() -> float:
	return belt_top() + BELT_ROLLER_FROM_TOP

static func belt_center(player_side: bool) -> Vector2:
	var x := BELT_SIZE.x * 0.5 if player_side else WIDTH - BELT_SIZE.x * 0.5
	return Vector2(x, belt_top() + BELT_SIZE.y * 0.5)

## Where a Freak lands when it leaves the card.
static func belt_entry_x(player_side: bool) -> float:
	return BELT_ENTRY_INSET if player_side else WIDTH - BELT_ENTRY_INSET

## Where a Freak stops and fights, at the inner end of its belt.
static func belt_tip_x(player_side: bool) -> float:
	if player_side:
		return BELT_SIZE.x - BELT_TIP_INSET
	return WIDTH - BELT_SIZE.x + BELT_TIP_INSET

static func belt_travel_px(player_side: bool) -> float:
	return absf(belt_tip_x(player_side) - belt_entry_x(player_side))

## 0 = just dropped on, 1 = at the fighting tip.
static func belt_x_at(player_side: bool, progress: float) -> float:
	return lerpf(belt_entry_x(player_side), belt_tip_x(player_side), clampf(progress, 0.0, 1.0))

## The hole between the two belts, where beaten Freaks fall.
static func gap_center_x() -> float:
	return CENTER_X

## Where a dumped closed crate lands, in the hole between the belts.
static func dump_point() -> Vector2:
	return Vector2(CENTER_X, belt_floor_y() + 80.0)

static func card_center(index: int) -> Vector2:
	var x: float = CARD_X[clampi(index, 0, CARD_X.size() - 1)]
	return Vector2(x, CARD_CENTER_Y)

static func opponent_card_center(index: int) -> Vector2:
	var x: float = CARD_OPPONENT_X[clampi(index, 0, CARD_OPPONENT_X.size() - 1)]
	return Vector2(x, CARD_CENTER_Y)

static func shelf_center(_index: int = 0) -> Vector2:
	return SHELF_CENTER

## Where a crate or a loose part rests on that shelf.
static func shelf_surface(_index: int = 0) -> Vector2:
	var center := shelf_center(_index)
	return Vector2(center.x, center.y - SHELF_SURFACE_FROM_CENTER)

static func money_brick_center(index: int) -> Vector2:
	return Vector2(MONEY_X, MONEY_BOTTOM_Y - MONEY_BRICK.y * 0.5 - float(index) * MONEY_BRICK_STEP)

static func top_left(center: Vector2, size: Vector2) -> Vector2:
	return center - size * 0.5
