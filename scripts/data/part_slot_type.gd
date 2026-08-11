class_name PartSlotType
extends Object

enum Value {
	HEAD,
	BODY,
	LEGS,
}

static func to_string_name(value: Value) -> StringName:
	match value:
		Value.HEAD:
			return &"head"
		Value.BODY:
			return &"body"
		Value.LEGS:
			return &"legs"
		_:
			return &"unknown"
