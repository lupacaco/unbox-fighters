extends SceneTree

## How the pieces snap together: the shared crate sits on the floor, the torso
## plugs into it, the head sits on the neck magnet, the arms hang from the shoulders.

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var bruxa: CharacterDef = load("res://data/parts/bruxa_character.tres")
	if bruxa == null:
		push_error("VERIFY_FAIL missing bruxa")
		quit(1)
		return
	if not _check_crate():
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

func _check_crate() -> bool:
	if CompositeResolver.crate_back_texture() == null or CompositeResolver.crate_front_texture() == null:
		push_error("VERIFY_FAIL missing the two crate drawings")
		return false
	if CompositeResolver.crate_back_z(0) >= 0:
		push_error("VERIFY_FAIL the crate top rim should sit behind the Freak")
		return false
	if CompositeResolver.crate_front_z(0) <= 0:
		push_error("VERIFY_FAIL the crate front should sit in front of the torso")
		return false
	if CompositeResolver.crate_back_position().y >= CompositeResolver.crate_front_position().y:
		push_error("VERIFY_FAIL the top rim should sit above the front of the crate")
		return false
	var size := CompositeResolver.crate_size()
	if size.x < 180.0 or size.y < 80.0:
		push_error("VERIFY_FAIL the crate should be wide enough to hold a Freak")
		return false
	var pos := CompositeResolver.crate_position()
	if not is_equal_approx(pos.y + size.y * 0.5, 0.0):
		push_error("VERIFY_FAIL the crate bottom should sit on the floor line")
		return false
	if CompositeResolver.crate_join().y >= 0.0:
		push_error("VERIFY_FAIL the torso should plug in at the top of the crate")
		return false
	return true

func _check_anchor(bruxa: CharacterDef) -> bool:
	var empty := CompositeResolver.resolve_slots({})
	for slot in PartSlotType.visual_slots():
		if empty["textures"].get(slot) != null:
			push_error("VERIFY_FAIL an empty card draws no Freak pieces")
			return false
	if empty.get("crate_back_texture") == null or empty.get("crate_front_texture") == null:
		push_error("VERIFY_FAIL an empty card still shows both crate pieces")
		return false

	var scale := CompositeResolver.display_scale()
	var body_only := CompositeResolver.resolve_slots({PartSlotType.Value.BODY: bruxa.body})
	var ground := CompositeResolver.socket_of(bruxa.body, "ground", bruxa.body.sprite) * scale
	var body_center: Vector2 = body_only["positions"][PartSlotType.Value.BODY]
	if not body_center.is_equal_approx(CompositeResolver.crate_join() - ground):
		push_error("VERIFY_FAIL the torso bottom magnet should snap into the crate")
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
