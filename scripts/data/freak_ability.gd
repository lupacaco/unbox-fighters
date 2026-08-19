@tool
class_name FreakAbility
extends Object

## A complete set (head and body of the same Freak) turns this on.
## Mixed kits keep the numbers and never get a power.

enum Value { NONE, MIND_CONTROL, APPEAL }

static func display_name(value: Value) -> String:
	match value:
		Value.MIND_CONTROL:
			return "CONTROLE DE MENTE"
		Value.APPEAL:
			return "RECURSO"
		_:
			return ""


static func from_string(raw: String) -> Value:
	match raw.strip_edges().to_lower():
		"mind_control", "controle_de_mente", "controle de mente":
			return Value.MIND_CONTROL
		"appeal", "recurso":
			return Value.APPEAL
		_:
			return Value.NONE


static func storage_key(value: Value) -> String:
	match value:
		Value.MIND_CONTROL:
			return "mind_control"
		Value.APPEAL:
			return "appeal"
		_:
			return ""
