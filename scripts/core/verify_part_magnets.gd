extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var head: PartDef = load("res://data/parts/cachorro_head.tres")
	if head == null or head.sprite_profile == null:
		push_error("VERIFY_FAIL missing dog head")
		quit(1)
		return
	if head.uses_weapon_magnet() or head.uses_magnet_up():
		push_error("VERIFY_FAIL head should only use magnet_down")
		quit(1)
		return
	var front_down := head.magnet_down_for(head.sprite)
	var side_down := head.magnet_down_for(head.sprite_profile)
	if front_down != Vector2(1, 71):
		push_error("VERIFY_FAIL dog head front magnet %s" % front_down)
		quit(1)
		return
	if side_down != Vector2(-43, 49):
		push_error("VERIFY_FAIL dog head profile magnet should stay off-center, got %s" % side_down)
		quit(1)
		return
	if head.texture_for_pose(1) != head.sprite_profile:
		push_error("VERIFY_FAIL pose 1 should be profile")
		quit(1)
		return
	if head.texture_for_pose(2) != head.sprite_attack:
		push_error("VERIFY_FAIL pose 2 should be attack")
		quit(1)
		return

	var body: PartDef = load("res://data/parts/medico_body.tres")
	if body == null or not body.uses_weapon_magnet():
		push_error("VERIFY_FAIL body should use weapon magnet")
		quit(1)
		return
	var character: CharacterDef = load("res://data/parts/medico_character.tres")
	var plan := CompositeResolver.resolve(character, true, true, true)
	if not plan.has("weapon_pos"):
		push_error("VERIFY_FAIL composite plan missing weapon_pos")
		quit(1)
		return
	print("VERIFY_PART_MAGNETS_PASS")
	quit(0)
