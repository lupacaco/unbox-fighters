extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var vampiro: CharacterDef = load("res://data/parts/vampiro_character.tres")
	var empty := CompositeResolver.resolve_slots({})
	if empty.get("spring_texture") == null:
		push_error("VERIFY_FAIL empty card should still show the spring")
		quit(1)
		return
	if empty.get("spring_pressed") != false:
		push_error("VERIFY_FAIL empty spring should be loose")
		quit(1)
		return
	var only_head := CompositeResolver.resolve_slots({PartSlotType.Value.HEAD: vampiro.head})
	if only_head["mode"] != "layered" or only_head["textures"].get(PartSlotType.Value.HEAD) == null:
		push_error("VERIFY_FAIL head-only should be layered with head texture")
		quit(1)
		return
	if only_head.get("spring_pressed") != true:
		push_error("VERIFY_FAIL a part on the spring should press it")
		quit(1)
		return
	var scale := CompositeResolver.display_scale()
	var spring := preload("res://scripts/data/spring_base.gd")
	var sphere: Vector2 = spring.magnet_world(true)
	var head_down := CompositeResolver.socket_of(vampiro.head, "down", vampiro.head.sprite) * scale
	var head_center: Vector2 = only_head["positions"][PartSlotType.Value.HEAD]
	if not head_center.is_equal_approx(sphere - head_down):
		push_error("VERIFY_FAIL head-only should sit on the spring sphere")
		quit(1)
		return
	var body_only := CompositeResolver.resolve_slots({PartSlotType.Value.BODY: vampiro.body})
	var sit := CompositeResolver.socket_of(vampiro.body, "hip_l", vampiro.body.sprite)
	sit = (sit + CompositeResolver.socket_of(vampiro.body, "hip_r", vampiro.body.sprite)) * 0.5 * scale
	var body_center: Vector2 = body_only["positions"][PartSlotType.Value.BODY]
	if not body_center.is_equal_approx(sphere - sit):
		push_error("VERIFY_FAIL torso should sit on the spring sphere")
		quit(1)
		return
	var full := CompositeResolver.resolve(vampiro)
	var textures: Dictionary = full["textures"]
	var positions: Dictionary = full["positions"]
	if textures.get(PartSlotType.Value.BODY) == null or textures.get(PartSlotType.Value.ARM_L) == null:
		push_error("VERIFY_FAIL full vampire missing textures")
		quit(1)
		return
	if textures.get(PartSlotType.Value.LEG_L) != null or textures.get(PartSlotType.Value.LEG_R) != null:
		push_error("VERIFY_FAIL legs should not be drawn")
		quit(1)
		return
	var body_kit := PartKit.expand_shop_part(vampiro.body)
	if body_kit.size() != 1 or not body_kit.has(PartSlotType.Value.BODY):
		push_error("VERIFY_FAIL torso kit should draw only the torso")
		quit(1)
		return
	var arm_kit := PartKit.expand_shop_part(vampiro.arm_l)
	if arm_kit.size() != 1 or not arm_kit.has(PartSlotType.Value.ARM_L):
		push_error("VERIFY_FAIL left arm kit should draw only that arm")
		quit(1)
		return
	if not (positions[PartSlotType.Value.HEAD].y < positions[PartSlotType.Value.BODY].y):
		push_error("VERIFY_FAIL head should sit above the torso")
		quit(1)
		return
	if not (float(full["spring_pos"].y) > positions[PartSlotType.Value.BODY].y):
		push_error("VERIFY_FAIL spring should sit below the torso")
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
