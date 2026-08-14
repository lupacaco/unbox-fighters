extends SceneTree
func _init(): call_deferred("_run")
func _run() -> void:
	var leao: CharacterDef = load("res://data/parts/leao_character.tres")
	var slot_scene: PackedScene = load("res://scenes/assembly/CharacterSlot.tscn")
	var part_scene: PackedScene = load("res://scenes/assembly/PartView.tscn")
	var slot := slot_scene.instantiate() as CharacterSlot
	root.add_child(slot)
	slot.setup(null, [leao])
	var drag := DragDropService.new()
	root.add_child(drag)
	for part_def in leao.all_parts():
		var pv := part_scene.instantiate() as PartView
		root.add_child(pv)
		pv.setup(part_def, drag)
		assert(slot.try_attach(pv))
	assert(slot.is_complete())
	assert(slot.attached_parts_can_fight())
	var extra_head := part_scene.instantiate() as PartView
	root.add_child(extra_head)
	extra_head.setup(leao.head, drag)
	extra_head.tray_home = Vector2(80, 80)
	assert(slot.can_accept(leao.head))
	assert(slot.try_attach(extra_head))
	assert(slot.get_attached_part(PartSlotType.Value.HEAD) == leao.head)
	slot.set_fight_locked(true)
	assert(not slot.can_fight())
	assert(slot.attached_parts_can_fight())
	print("VERIFY_FIGHT_LOCK_PASS")
	quit(0)
