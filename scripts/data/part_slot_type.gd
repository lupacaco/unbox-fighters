@tool
class_name PartSlotType
extends Object

## Shop / fight use three kits. Drawing uses six limbs.
enum Value {
	HEAD,
	BODY,
	ARM_L,
	ARM_R,
	LEG_L,
	LEG_R,
	LEGS,
}

static func shop_slots() -> Array[Value]:
	return [Value.HEAD, Value.BODY, Value.LEGS]

static func visual_slots() -> Array[Value]:
	return [
		Value.HEAD,
		Value.BODY,
		Value.ARM_L,
		Value.ARM_R,
		Value.LEG_L,
		Value.LEG_R,
	]

static func all_slots() -> Array[Value]:
	return visual_slots()

static func fight_order() -> Array[Value]:
	return shop_slots()

static func draw_order() -> Array[Value]:
	return draw_order_for({})

static func default_draw_z(slot: Value) -> int:
	match slot:
		Value.HEAD:
			return 1
		Value.ARM_L, Value.ARM_R:
			return 2
		Value.BODY:
			return 2
		Value.LEG_L, Value.LEG_R:
			return 3
		_:
			return 4

static func draw_order_for(parts: Dictionary) -> Array[Value]:
	var slots := visual_slots()
	var ordered: Array[Value] = []
	for slot in slots:
		ordered.append(slot)
	ordered.sort_custom(func(a: Value, b: Value) -> bool:
		var za := _draw_z_of(parts, a)
		var zb := _draw_z_of(parts, b)
		if za != zb:
			return za > zb
		return int(a) < int(b)
	)
	return ordered

static func _draw_z_of(parts: Dictionary, slot: Value) -> int:
	var part: PartDef = parts.get(slot) as PartDef
	if part != null:
		return part.effective_draw_z()
	return default_draw_z(slot)

static func is_shop_slot(value: Value) -> bool:
	return value == Value.HEAD or value == Value.BODY or value == Value.LEGS

static func visual_slots_for(shop_slot: Value) -> Array[Value]:
	match shop_slot:
		Value.HEAD:
			return [Value.HEAD]
		Value.BODY:
			return [Value.BODY, Value.ARM_L, Value.ARM_R]
		Value.LEGS:
			return [Value.LEG_L, Value.LEG_R]
		_:
			return [shop_slot]

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
		Value.LEGS:
			return &"legs"
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
		Value.LEGS:
			return "Pernas"
		_:
			return "Peça"
