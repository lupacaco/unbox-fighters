extends SceneTree

## The magnets on the kits and the order the pieces are drawn in.

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	if not _check_magnets():
		quit(1)
		return
	if not _check_draw_order():
		quit(1)
		return
	if not _check_importer_paths():
		quit(1)
		return
	print("VERIFY_PART_MAGNETS_PASS")
	quit(0)

func _check_magnets() -> bool:
	var head: PartDef = load("res://data/parts/bruxa_head.tres")
	if head == null or head.sprite_profile == null:
		push_error("VERIFY_FAIL missing bruxa head")
		return false
	if head.uses_magnet_up() or head.is_torso():
		push_error("VERIFY_FAIL a head only uses the magnet underneath")
		return false
	if head.magnet_down.y <= 0:
		push_error("VERIFY_FAIL the head magnet should sit at the bottom")
		return false
	if head.texture_for_pose(1) != head.sprite_profile:
		push_error("VERIFY_FAIL pose 1 should be the side view")
		return false

	var body: PartDef = load("res://data/parts/bruxa_body.tres")
	if body == null or not body.is_torso():
		push_error("VERIFY_FAIL the bruxa torso should be a torso")
		return false
	if body.socket_names().size() != 4:
		push_error("VERIFY_FAIL a torso has neck, two shoulders and the crate join")
		return false
	if not body.uses_hub_sockets():
		push_error("VERIFY_FAIL the torso magnets were never marked")
		return false
	if body.magnet_ground.y <= 0.0:
		push_error("VERIFY_FAIL the crate magnet should sit under the torso")
		return false
	if body.magnet_ground.y > 50.0:
		push_error("VERIFY_FAIL the crate magnet is the torso bottom, not the old crate floor")
		return false
	if body.magnet_neck.y >= body.magnet_ground.y:
		push_error("VERIFY_FAIL the neck should be above the floor")
		return false

	var arms: PartDef = load("res://data/parts/bruxa_arms.tres")
	if arms == null or not arms.is_bundle() or arms.kit_parts.size() != 2:
		push_error("VERIFY_FAIL the arm crate should carry both arms")
		return false

	var probe: PartDef = head.duplicate()
	probe.flip_h = false
	probe.rotation_degrees = 0
	if not probe.magnet_to_visual(Vector2(12, 8), 0).is_equal_approx(Vector2(12, 8)):
		push_error("VERIFY_FAIL a magnet with no flip or turn should stay put")
		return false
	probe.flip_h = true
	if not probe.magnet_to_visual(Vector2(12, 8), 0).is_equal_approx(Vector2(-12, 8)):
		push_error("VERIFY_FAIL flipping should mirror the magnet")
		return false
	if not probe.visual_to_magnet(Vector2(-12, 8), 0).is_equal_approx(Vector2(12, 8)):
		push_error("VERIFY_FAIL unflipping should bring the magnet back")
		return false
	return true

func _check_draw_order() -> bool:
	if PartSlotType.default_draw_z(PartSlotType.Value.HEAD) != 1:
		push_error("VERIFY_FAIL the head draws in front")
		return false
	if PartSlotType.default_draw_z(PartSlotType.Value.BODY) != 2:
		push_error("VERIFY_FAIL the torso draws at layer 2")
		return false
	var order := PartSlotType.draw_order()
	if order.is_empty() or order[order.size() - 1] != PartSlotType.Value.HEAD:
		push_error("VERIFY_FAIL the head should be drawn last, on top")
		return false

	var front := [
		PartSlotType.Value.HEAD,
		PartSlotType.Value.ARM_L,
		PartSlotType.Value.ARM_R,
		PartSlotType.Value.BODY,
	]
	for i in range(front.size() - 1):
		if PartSlotType.fight_z_index(front[i], false) <= PartSlotType.fight_z_index(front[i + 1], false):
			push_error("VERIFY_FAIL front order should be head, left arm, right arm, torso")
			return false
	var profile := [
		PartSlotType.Value.ARM_R,
		PartSlotType.Value.HEAD,
		PartSlotType.Value.BODY,
		PartSlotType.Value.ARM_L,
	]
	for i in range(profile.size() - 1):
		if PartSlotType.fight_z_index(profile[i], true) <= PartSlotType.fight_z_index(profile[i + 1], true):
			push_error("VERIFY_FAIL side order should be right arm, head, torso, left arm")
			return false
	return true

func _check_importer_paths() -> bool:
	var Importer := load("res://addons/part_magnet_editor/character_importer.gd")
	var canvas := Image.create(400, 100, false, Image.FORMAT_RGBA8)
	canvas.fill(Color.WHITE)
	var fitted: Image = Importer.fit_to_square(canvas, 200)
	if fitted == null or fitted.get_width() != 200 or fitted.get_height() != 200:
		push_error("VERIFY_FAIL a swapped drawing should become 200x200")
		return false
	var res := "res://assets/characters/bruxa/bruxa_head-1.png"
	if Importer.to_project_path(res) != res:
		push_error("VERIFY_FAIL a project path should stay a res:// path")
		return false
	if Importer.to_project_path(ProjectSettings.globalize_path(res)) != res:
		push_error("VERIFY_FAIL a disk path should map back to res://")
		return false
	if not String(Importer.to_project_path("C:/not-unbox-fighters/x.png")).is_empty():
		push_error("VERIFY_FAIL files outside the project must not be mapped")
		return false
	if Importer.character_art_folder("bruxa") != "res://assets/characters/bruxa":
		push_error("VERIFY_FAIL the art folder should follow the set id")
		return false
	return true
