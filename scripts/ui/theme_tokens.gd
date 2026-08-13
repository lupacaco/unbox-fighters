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
const COMPLETE := Color("C9B37E")
const SHADOW := Color(0, 0, 0, 0.45)
const PREP_ORANGE := Color("E85D04")
const THREAT := Color("3D7EFF")
const MIGHT := Color("7B4DFF")
const AGILITY := Color("3DCC7A")
const PANCADA_RED := Color("E11D2E")
const X_RED := Color("FF2A2A")

static func color_for_slot(slot: PartSlotType.Value) -> Color:
	match slot:
		PartSlotType.Value.HEAD:
			return THREAT
		PartSlotType.Value.BODY:
			return MIGHT
		_:
			return AGILITY
