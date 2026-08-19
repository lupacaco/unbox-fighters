@tool
class_name PartSlotType
extends Object

## The shop sells two kits: head and body. The body draws as the torso plus both
## arms. The wooden crate is a shared base, not a kit.
enum Value {
	HEAD,
	BODY,
	ARM_L,
	ARM_R,
	ARMS,
}

static func shop_slots() -> Array[Value]:
	return [Value.HEAD, Value.BODY]

static func visual_slots() -> Array[Value]:
	return [Value.HEAD, Value.BODY, Value.ARM_L, Value.ARM_R]

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
		Value.ARM_L, Value.ARM_R, Value.BODY:
			return 2
		_:
			return 3

## Palco: 1 fica na frente (igual à carta). Godot desenha o número maior por cima, então invertemos.
## Perfil: braço D, tronco, cabeça, braço E. Frente: cabeça, braço E, braço D, tronco.
static func fight_z_index(slot: Value, profile: bool = true) -> int:
	return _fight_godot_z(_fight_rank(slot, profile))

static func _fight_rank(slot: Value, profile: bool) -> int:
	if profile:
		match slot:
			Value.ARM_R:
				return 1
			Value.BODY:
				return 2
			Value.HEAD:
				return 3
			Value.ARM_L:
				return 4
			_:
				return 5
	match slot:
		Value.HEAD:
			return 1
		Value.ARM_L:
			return 2
		Value.ARM_R:
			return 3
		Value.BODY:
			return 4
		_:
			return 5

static func _fight_godot_z(rank: int) -> int:
	return 6 - rank

static func draw_order_for(parts: Dictionary) -> Array[Value]:
	var ordered: Array[Value] = []
	for slot in visual_slots():
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
	return value == Value.HEAD or value == Value.BODY

static func is_arm(value: Value) -> bool:
	return value == Value.ARM_L or value == Value.ARM_R

## Which drawings a shop kit puts on screen. The body kit brings both arms.
static func visual_slots_for(shop_slot: Value) -> Array[Value]:
	if shop_slot == Value.BODY:
		return [Value.BODY, Value.ARM_L, Value.ARM_R]
	if shop_slot == Value.ARMS:
		return [Value.ARM_L, Value.ARM_R]
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
		Value.ARMS:
			return &"arms"
		_:
			return &"unknown"

static func display_label(value: Value) -> String:
	match value:
		Value.HEAD:
			return "Cabeça"
		Value.BODY:
			return "Corpo"
		Value.ARM_L:
			return "Braço E"
		Value.ARM_R:
			return "Braço D"
		Value.ARMS:
			return "Braços"
		_:
			return "Peça"
