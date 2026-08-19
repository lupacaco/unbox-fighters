extends SceneTree

## How the pieces snap together: the crate base is the floor, the head sits on
## the neck magnet, the arms hang from the shoulder magnets and open outward.

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var bruxa: CharacterDef = load("res://data/parts/bruxa_character.tres")
	if bruxa == null:
		push_error("VERIFY_FAIL missing bruxa")
		quit(1)
		return
	if not _check_anchor(bruxa):
		quit(1)
		return
	if not _check_stack(bruxa):
		quit(1)
		return
	if not _check_arms(bruxa):
		quit(1)
		return
	print("VERIFY_COMPOSITE_PASS")
	quit(0)

func _check_anchor(bruxa: CharacterDef) -> bool:
	var empty := CompositeResolver.resolve_slots({})
	for slot in PartSlotType.visual_slots():
		if empty["textures"].get(slot) != null:
			push_error("VERIFY_FAIL an empty card draws nothing")
			return false

	var scale := CompositeResolver.display_scale()
	var body_only := CompositeResolver.resolve_slots({PartSlotType.Value.BODY: bruxa.body})
	var ground := CompositeResolver.socket_of(bruxa.body, "ground", bruxa.body.sprite) * scale
	var body_center: Vector2 = body_only["positions"][PartSlotType.Value.BODY]
	if not body_center.is_equal_approx(-ground):
		push_error("VERIFY_FAIL the crate base should land on the floor line")
		return false

	var head_only := CompositeResolver.resolve_slots({PartSlotType.Value.HEAD: bruxa.head})
	if head_only["textures"].get(PartSlotType.Value.HEAD) == null:
		push_error("VERIFY_FAIL a lone head should still be drawn")
		return false
	if head_only["positions"][PartSlotType.Value.HEAD].y >= 0.0:
		push_error("VERIFY_FAIL a lone head floats above the floor line")
		return false
	return true

func _check_stack(bruxa: CharacterDef) -> bool:
	var full := CompositeResolver.resolve(bruxa)
	var textures: Dictionary = full["textures"]
	var positions: Dictionary = full["positions"]
	for slot in PartSlotType.visual_slots():
		if textures.get(slot) == null:
			push_error("VERIFY_FAIL a whole Freak draws all four pieces")
			return false
	if positions[PartSlotType.Value.HEAD].y >= positions[PartSlotType.Value.BODY].y:
		push_error("VERIFY_FAIL the head sits above the torso")
		return false

	var scale := CompositeResolver.display_scale()
	var neck: Vector2 = positions[PartSlotType.Value.BODY] + CompositeResolver.socket_of(
		bruxa.body, "neck", bruxa.body.sprite
	) * scale
	var head_joint: Vector2 = positions[PartSlotType.Value.HEAD] + CompositeResolver.socket_of(
		bruxa.head, "down", bruxa.head.sprite
	) * scale
	if not neck.is_equal_approx(head_joint):
		push_error("VERIFY_FAIL the head magnet should meet the neck magnet")
		return false
	return true

func _check_arms(bruxa: CharacterDef) -> bool:
	var body_kit := PartKit.expand_shop_part(bruxa.body)
	if body_kit.size() != 3:
		push_error("VERIFY_FAIL a body crate draws the torso plus both arms")
		return false
	if not body_kit.has(PartSlotType.Value.BODY):
		push_error("VERIFY_FAIL a body crate still draws the torso")
		return false
	if not body_kit.has(PartSlotType.Value.ARM_L) or not body_kit.has(PartSlotType.Value.ARM_R):
		push_error("VERIFY_FAIL a body crate should bring both arms")
		return false

	if CompositeResolver.front_arm_spread(PartSlotType.Value.ARM_L) <= 0.0:
		push_error("VERIFY_FAIL the front left arm should open outward")
		return false
	if not is_equal_approx(
		CompositeResolver.front_arm_spread(PartSlotType.Value.ARM_R),
		-CompositeResolver.front_arm_spread(PartSlotType.Value.ARM_L)
	):
		push_error("VERIFY_FAIL the front arms should open as a pair")
		return false

	var center := Vector2(10, 20)
	var magnet := Vector2(0, -50)
	var extra := CompositeResolver.FRONT_ARM_SPREAD
	var pivoted := CompositeResolver.center_after_pivot(center, magnet, extra)
	if not (center + magnet).is_equal_approx(pivoted + magnet.rotated(extra)):
		push_error("VERIFY_FAIL opening an arm should keep the shoulder magnet in place")
		return false
	return true
