class_name AssemblyLayout
extends Object

## Every position on the match screen, in a 1920×1080 world
## (origin top-left, Y grows downward).
##
## Preparation: three hanging cards on the left, a 2×2 shop on the right.
## Fight: the shop hides and three opponent cards take that space.
## Life bars stand on the far left and right. The prep clock sits in the gap.

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
const HP_FRAME_TEX := "res://assets/nova-ui/barra-hp-vazia.png"
const HP_PLAYER_TEX := "res://assets/nova-ui/liquido-jogador.png"
const HP_OPPONENT_TEX := "res://assets/nova-ui/liquido-oponente.png"

# ---------------------------------------------------------------- belts
const BELT_SIZE := Vector2(840, 129)
## Pixels from the top of the belt art down to the crown of the rollers.
const BELT_ROLLER_FROM_TOP := 24.0
## Empty wood left between the crate's inner edge and the hole.
const BELT_TIP_MARGIN := 48.0
## Empty wood left between the crate's outer edge and the far end.
const BELT_ENTRY_MARGIN := 20.0
## Empty air between two crates waiting on the same belt.
const BELT_QUEUE_AIR := 64.0
const BELT_FREAK_SCALE := 0.85

# ---------------------------------------------------------------- cards
const CARD_SIZE := Vector2(306, 572)
## Hang almost at art size. The three still fit left of the shop.
const CARD_FIT := 0.96
## Half the drawn card, so the chain hooks sit flush with the top of the screen.
const CARD_CENTER_Y := CARD_SIZE.y * 0.5 * CARD_FIT
## Centers 310 px apart (art 306 × 0.96 + 16 gap).
const CARD_X: Array[float] = [155.0, 465.0, 775.0]
const CARD_OPPONENT_X: Array[float] = [1145.0, 1455.0, 1765.0]
## Local Y of the little wooden ledge inside the card, where the crate rests.
const CARD_FLOOR_Y := 240.0
const CARD_FREAK_SCALE := 0.80
## Inner well of the frame, in card-local coordinates.
const CARD_WELL := Rect2(-124, -246, 248, 498)
const READY_LABEL_SIZE := Vector2(214, 48)
const READY_LABEL_DROP := 348.0

# ---------------------------------------------------------------- shop (2×2 on the right during preparation)
const SHELF_SIZE := Vector2(438, 95)
const SHELF_FIT := 0.62
const SHELF_ORIGIN := Vector2(1080.0, 250.0)
const SHELF_STEP := Vector2(310.0, 210.0)
## From the shelf center up to the wooden surface a kit sits on.
const SHELF_SURFACE_FROM_CENTER := 54.0
const SHOP_PART_SCALE := 0.72
const PRICE_TAG_DROP := 78.0
## Kept for the unused crate drawing, so that script still compiles.
const SHOP_CRATE_HEIGHT := 280.0

# ---------------------------------------------------------------- buttons and money, right of the 2×2 shop
## Outer size of the gold coin and the two round buttons. They must match.
const HUD_DISC := 110.0
const ICON_BUTTON_SIZE := Vector2(HUD_DISC, HUD_DISC)
const MONEY_CENTER := Vector2(1720.0, 168.0)
const MONEY_EDGE := 5.0
const MONEY_RADIUS := HUD_DISC * 0.5 - MONEY_EDGE
const REFRESH_BUTTON := Vector2(1720.0, 344.0)
const SELL_BUTTON := Vector2(1720.0, 520.0)

# ---------------------------------------------------------------- life bars (vertical tubes on the far sides)
const HP_SIZE := Vector2(819, 149)
const HP_SCALE := 0.42
## Inner glass of barra-hp-vazia.png, in frame-local pixels (sprite is centered).
const HP_GLASS := Rect2(-348.0, -33.0, 696.0, 66.0)
## Distance from the left/right edge of the screen to the tube center.
const HP_GUTTER := 52.0
## Height of the tube center, between the hanging cards and the belts.
const HP_STAGE_Y := 780.0
## Turns the horizontal art into a thermometer. Fill still grows along local X.
const HP_TUBE_ROTATION := -PI / 2.0

# ---------------------------------------------------------------- clock between the belts
const TIMER_CENTER := Vector2(CENTER_X, 992.0)
const SKIP_CENTER := Vector2(CENTER_X, 760.0)
const SKIP_SIZE := Vector2(280, 64)
const BANNER_CENTER := Vector2(CENTER_X, 210.0)

static func belt_top() -> float:
	return HEIGHT - BELT_SIZE.y

## The line the crate base rests on.
static func belt_floor_y() -> float:
	return belt_top() + BELT_ROLLER_FROM_TOP

static func belt_center(player_side: bool) -> Vector2:
	var x := BELT_SIZE.x * 0.5 if player_side else WIDTH - BELT_SIZE.x * 0.5
	return Vector2(x, belt_top() + BELT_SIZE.y * 0.5)

## How wide a Freak's crate is on the belt.
static func belt_freak_width() -> float:
	return CompositeResolver.crate_size().x * BELT_FREAK_SCALE

static func belt_entry_inset() -> float:
	return belt_freak_width() * 0.5 + BELT_ENTRY_MARGIN

static func belt_tip_inset() -> float:
	return belt_freak_width() * 0.5 + BELT_TIP_MARGIN

## Space from one crate center to the next, so the boxes do not touch.
static func belt_queue_gap_px() -> float:
	return belt_freak_width() + BELT_QUEUE_AIR

static func belt_queue_gap(player_side: bool) -> float:
	return belt_queue_gap_px() / maxf(belt_travel_px(player_side), 1.0)

## Where a Freak lands when it leaves the card.
static func belt_entry_x(player_side: bool) -> float:
	var inset := belt_entry_inset()
	return inset if player_side else WIDTH - inset

## Where a Freak stops and fights, at the inner end of its belt.
static func belt_tip_x(player_side: bool) -> float:
	var inset := belt_tip_inset()
	if player_side:
		return BELT_SIZE.x - inset
	return WIDTH - BELT_SIZE.x + inset

static func belt_travel_px(player_side: bool) -> float:
	return absf(belt_tip_x(player_side) - belt_entry_x(player_side))

## 0 = just dropped on, 1 = at the fighting tip.
static func belt_x_at(player_side: bool, progress: float) -> float:
	return lerpf(belt_entry_x(player_side), belt_tip_x(player_side), clampf(progress, 0.0, 1.0))

## The hole between the two belts.
static func gap_center_x() -> float:
	return CENTER_X

## Where a dumped shop kit lands, in the hole between the belts.
static func dump_point() -> Vector2:
	return Vector2(CENTER_X, belt_floor_y() + 80.0)

static func card_center(index: int) -> Vector2:
	var x: float = CARD_X[clampi(index, 0, CARD_X.size() - 1)]
	return Vector2(x, CARD_CENTER_Y)

static func opponent_card_center(index: int) -> Vector2:
	var x: float = CARD_OPPONENT_X[clampi(index, 0, CARD_OPPONENT_X.size() - 1)]
	return Vector2(x, CARD_CENTER_Y)

static func shelf_center(index: int = 0) -> Vector2:
	var i := clampi(index, 0, MatchRules.SHOP_SLOTS - 1)
	var col := i % 2
	var row := int(i / 2)
	return SHELF_ORIGIN + Vector2(float(col) * SHELF_STEP.x, float(row) * SHELF_STEP.y)

## Where a loose part rests on that shelf.
static func shelf_surface(index: int = 0) -> Vector2:
	var center := shelf_center(index)
	return Vector2(center.x, center.y - SHELF_SURFACE_FROM_CENTER * SHELF_FIT)

static func hp_bar_center(player_side: bool) -> Vector2:
	var x := HP_GUTTER if player_side else WIDTH - HP_GUTTER
	return Vector2(x, HP_STAGE_Y)

static func top_left(center: Vector2, size: Vector2) -> Vector2:
	return center - size * 0.5
