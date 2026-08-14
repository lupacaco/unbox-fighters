extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var leao: CharacterDef = load("res://data/parts/leao_character.tres")
	var only_head := CompositeResolver.resolve_slots({PartSlotType.Value.HEAD: leao.head})
	var full := CompositeResolver.resolve(leao)

	if only_head["mode"] != "layered" or only_head["textures"].get(PartSlotType.Value.HEAD) == null:
		push_error("VERIFY_FAIL head-only should be layered with head texture")
		quit(1)
		return
	var textures: Dictionary = full["textures"]
	var positions: Dictionary = full["positions"]
	if textures.get(PartSlotType.Value.BODY) == null or textures.get(PartSlotType.Value.ARM_L) == null:
		push_error("VERIFY_FAIL full lion missing textures")
		quit(1)
		return
	var body_kit := PartKit.expand_shop_part(leao.body)
	if body_kit.size() != 3:
		push_error("VERIFY_FAIL torso kit should draw torso + 2 arms")
		quit(1)
		return
	var legs_kit := PartKit.expand_shop_part(leao.legs)
	if legs_kit.size() != 2:
		push_error("VERIFY_FAIL legs kit should draw both legs")
		quit(1)
		return
	if not (positions[PartSlotType.Value.HEAD].y < positions[PartSlotType.Value.BODY].y):
		push_error("VERIFY_FAIL head should sit above the torso")
		quit(1)
		return
	if not (positions[PartSlotType.Value.LEG_L].y > positions[PartSlotType.Value.BODY].y):
		push_error("VERIFY_FAIL legs should sit below the torso")
		quit(1)
		return
	print("VERIFY_COMPOSITE_PASS head=", positions[PartSlotType.Value.HEAD], " body=", positions[PartSlotType.Value.BODY])
	quit(0)
