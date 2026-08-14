class_name PartSlotType
extends Object

enum Value {
	HEAD,
	BODY,
	ARM_L,
	ARM_R,
	LEG_L,
	LEG_R,
}

static func all_slots() -> Array[Value]:
	return [
		Value.HEAD,
		Value.BODY,
		Value.ARM_L,
		Value.ARM_R,
		Value.LEG_L,
		Value.LEG_R,
	]

static func fight_order() -> Array[Value]:
	return [
		Value.HEAD,
		Value.ARM_L,
		Value.ARM_R,
		Value.BODY,
		Value.LEG_L,
		Value.LEG_R,
	]

static func draw_order() -> Array[Value]:
	return [
		Value.LEG_L,
		Value.LEG_R,
		Value.BODY,
		Value.ARM_L,
		Value.ARM_R,
		Value.HEAD,
	]

static func to_string_name(value: Value) -> StringName:
	match value:
		Value.HEAD:
			return &"head"
		Value.BODY:
			return &"body"
		Value.ARM_L:
			return &"arm_l"
		Value.ARM_R:
			return &"arm_r"
		Value.LEG_L:
			return &"leg_l"
		Value.LEG_R:
			return &"leg_r"
		_:
			return &"unknown"

static func display_label(value: Value) -> String:
	match value:
		Value.HEAD:
			return "Cabeça"
		Value.BODY:
			return "Tronco"
		Value.ARM_L:
			return "Braço E"
		Value.ARM_R:
			return "Braço D"
		Value.LEG_L:
			return "Perna E"
		Value.LEG_R:
			return "Perna D"
		_:
			return "Peça"
