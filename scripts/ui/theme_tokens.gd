class_name ThemeTokens
extends RefCounted

const BG := Color("0B0C10")
const STEEL := Color("8B9BB4")
const STEEL_DIM := Color("5C6B82")
const PANEL := Color("12141A")
const PANEL_EDGE := Color("2A303C")
const TEXT := Color("E6EAF0")
const TEXT_DIM := Color("8A93A3")
const ACCENT := Color("C41E3A")
const ACCENT_SOFT := Color(0.77, 0.12, 0.23, 0.35)
const COMPLETE := Color(0.96, 0.78, 0.36)
const SHADOW := Color(0, 0, 0, 0.45)
const PREP_ORANGE := Color(0.96, 0.78, 0.36)
const GOLD := Color(0.96, 0.78, 0.36)
const GOLD_DEEP := Color(0.62, 0.42, 0.14)
const CREAM := Color(0.96, 0.93, 0.86)
const BLOOD_HOT := Color(0.92, 0.16, 0.20)
const ICE := Color(0.55, 0.82, 0.95)
const WOOD := Color(0.55, 0.34, 0.18)
const INK := Color(0.05, 0.04, 0.07)
const MUTE := Color(0.72, 0.68, 0.62)
const THREAT := Color(0.38, 0.68, 1.0)
const MIGHT := Color(0.72, 0.42, 0.95)
const AGILITY := Color(0.38, 0.86, 0.52)
const X_RED := Color(0.92, 0.16, 0.20)
const DOT_EMPTY := Color(0.2, 0.18, 0.16, 0.7)
const MONEY_EMPTY := Color(0.13, 0.11, 0.09, 0.85)
const BELT_PLAYER := Color(0.36, 0.68, 0.95)
const BELT_OPPONENT := Color(0.93, 0.33, 0.33)
const REFRESH_BLUE := Color(0.16, 0.34, 0.58)
const SELL_RED := Color(0.52, 0.14, 0.16)

## Poder é vermelho, Resistência é roxo, Agilidade é verde.
static func color_for_slot(slot: PartSlotType.Value) -> Color:
	match slot:
		PartSlotType.Value.HEAD:
			return Color(0.95, 0.42, 0.30)
		PartSlotType.Value.BODY:
			return MIGHT
		_:
			return AGILITY
