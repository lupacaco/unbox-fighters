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
	if CompositeResolver.front_arm_spread(PartSlotType.Value.ARM_L) <= 0.0:
		push_error("VERIFY_FAIL front left arm should open outward")
		quit(1)
		return
	if not is_equal_approx(
		CompositeResolver.front_arm_spread(PartSlotType.Value.ARM_R),
		-CompositeResolver.front_arm_spread(PartSlotType.Value.ARM_L)
	):
		push_error("VERIFY_FAIL front arms should open as a pair")
		quit(1)
		return
	var center := Vector2(10, 20)
	var magnet := Vector2(0, -50)
	var extra := CompositeResolver.FRONT_ARM_SPREAD
	var pivoted := CompositeResolver.center_after_pivot(center, magnet, extra)
	var old_joint := center + magnet
	var new_joint := pivoted + magnet.rotated(extra)
	if not old_joint.is_equal_approx(new_joint):
		push_error("VERIFY_FAIL arm spread should keep the shoulder magnet")
		quit(1)
		return
	print("VERIFY_COMPOSITE_PASS head=", positions[PartSlotType.Value.HEAD], " body=", positions[PartSlotType.Value.BODY])
	quit(0)
