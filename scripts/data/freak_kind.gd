@tool
class_name FreakKind
extends Object

## Every Freak belongs to one family. Two kits of the same family on a card
## raise Attack and HP by half (rounded up).

enum Value { HUMAN, SUPERNATURAL, ANIMAL }

static func label(value: Value) -> String:
	match value:
		Value.HUMAN:
			return "Humano"
		Value.SUPERNATURAL:
			return "Sobrenatural"
		Value.ANIMAL:
			return "Animal"
		_:
			return ""


static func from_string(raw: String) -> Value:
	match raw.strip_edges().to_lower():
		"humano", "human":
			return Value.HUMAN
		"sobrenatural", "supernatural":
			return Value.SUPERNATURAL
		"animal":
			return Value.ANIMAL
		_:
			return Value.HUMAN


static func storage_key(value: Value) -> String:
	match value:
		Value.SUPERNATURAL:
			return "supernatural"
		Value.ANIMAL:
			return "animal"
		_:
			return "human"
