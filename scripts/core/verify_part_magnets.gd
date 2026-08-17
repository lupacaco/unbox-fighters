extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var head: PartDef = load("res://data/parts/vampiro_head.tres")
	if head == null or head.sprite_profile == null:
		push_error("VERIFY_FAIL missing vampire head")
		quit(1)
		return
	if head.uses_magnet_up() or head.is_torso():
		push_error("VERIFY_FAIL head should only use magnet_down")
		quit(1)
		return
	if head.magnet_down.y <= 0:
		push_error("VERIFY_FAIL vampire head magnet should sit at the bottom")
		quit(1)
		return
	if head.texture_for_pose(1) != head.sprite_profile:
		push_error("VERIFY_FAIL pose 1 should be profile")
		quit(1)
		return

	var body: PartDef = load("res://data/parts/vampiro_body.tres")
	if body == null or not body.is_torso():
		push_error("VERIFY_FAIL vampire body should be the torso")
		quit(1)
		return
	if body.socket_names().size() != 5:
		push_error("VERIFY_FAIL torso should have 5 magnets")
		quit(1)
		return
	if not body.uses_hub_sockets():
		push_error("VERIFY_FAIL torso magnets were not marked")
		quit(1)
		return

	var probe: PartDef = head.duplicate()
	probe.flip_h = false
	probe.rotation_degrees = 0
	if not probe.magnet_to_visual(Vector2(12, 8), 0).is_equal_approx(Vector2(12, 8)):
		push_error("VERIFY_FAIL magnet without flip/rotate should stay put")
		quit(1)
		return
	probe.flip_h = true
	if not probe.magnet_to_visual(Vector2(12, 8), 0).is_equal_approx(Vector2(-12, 8)):
		push_error("VERIFY_FAIL flip should mirror magnet X")
		quit(1)
		return
	if not probe.visual_to_magnet(Vector2(-12, 8), 0).is_equal_approx(Vector2(12, 8)):
		push_error("VERIFY_FAIL unflip should restore magnet")
		quit(1)
		return
	if PartSlotType.default_draw_z(PartSlotType.Value.HEAD) != 1:
		push_error("VERIFY_FAIL head should default to Z 1 (in front)")
		quit(1)
		return
	if PartSlotType.default_draw_z(PartSlotType.Value.BODY) != 2:
		push_error("VERIFY_FAIL torso should default to Z 2")
		quit(1)
		return
	var order := PartSlotType.draw_order()
	if order.is_empty() or order[order.size() - 1] != PartSlotType.Value.HEAD:
		push_error("VERIFY_FAIL head should draw last (on top)")
		quit(1)
		return
	var fight_front := [
		PartSlotType.Value.HEAD,
		PartSlotType.Value.ARM_L,
		PartSlotType.Value.ARM_R,
		PartSlotType.Value.BODY,
	]
	for i in range(fight_front.size() - 1):
		var front: PartSlotType.Value = fight_front[i]
		var behind: PartSlotType.Value = fight_front[i + 1]
		if PartSlotType.fight_z_index(front, false) <= PartSlotType.fight_z_index(behind, false):
			push_error("VERIFY_FAIL front fight Z should be head, left arm, right arm, torso")
			quit(1)
			return
	var fight_profile := [
		PartSlotType.Value.ARM_R,
		PartSlotType.Value.BODY,
		PartSlotType.Value.HEAD,
		PartSlotType.Value.ARM_L,
	]
	for i in range(fight_profile.size() - 1):
		var front: PartSlotType.Value = fight_profile[i]
		var behind: PartSlotType.Value = fight_profile[i + 1]
		if PartSlotType.fight_z_index(front, true) <= PartSlotType.fight_z_index(behind, true):
			push_error("VERIFY_FAIL profile fight Z should be right arm, torso, head, left arm")
			quit(1)
			return
	if PartSlotType.fight_spring_z_index() >= PartSlotType.fight_z_index(PartSlotType.Value.ARM_L, true):
		push_error("VERIFY_FAIL spring should stay behind the parts")
		quit(1)
		return

	var Importer := load("res://addons/part_magnet_editor/character_importer.gd")
	var canvas := Image.create(400, 100, false, Image.FORMAT_RGBA8)
	canvas.fill(Color.WHITE)
	var fitted: Image = Importer.fit_to_square(canvas, 200)
	if fitted == null or fitted.get_width() != 200 or fitted.get_height() != 200:
		push_error("VERIFY_FAIL swapped art should become 200x200")
		quit(1)
		return
	var res := "res://assets/characters/vampiro/vampiro_head-1.png"
	if Importer.to_project_path(res) != res:
		push_error("VERIFY_FAIL project image path should stay a res:// path")
		quit(1)
		return
	var abs_path := ProjectSettings.globalize_path(res)
	if Importer.to_project_path(abs_path) != res:
		push_error("VERIFY_FAIL disk path should map back to res://")
		quit(1)
		return
	if not String(Importer.to_project_path("C:/not-unbox-fighters/x.png")).is_empty():
		push_error("VERIFY_FAIL files outside the project must not be mapped")
		quit(1)
		return
	if Importer.character_art_folder("vampiro") != "res://assets/characters/vampiro":
		push_error("VERIFY_FAIL character folder should follow the set id")
		quit(1)
		return

	print("VERIFY_PART_MAGNETS_PASS")
	quit(0)
