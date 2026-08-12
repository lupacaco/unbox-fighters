class_name CharacterDef
extends Resource

@export var id: StringName
@export var display_name: String = "???"
@export var head: PartDef
@export var body: PartDef
@export var legs: PartDef

func get_part(slot: PartSlotType.Value) -> PartDef:
	match slot:
		PartSlotType.Value.HEAD:
			return head
		PartSlotType.Value.BODY:
			return body
		PartSlotType.Value.LEGS:
			return legs
		_:
			return null
