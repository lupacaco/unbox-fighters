extends SceneTree
func _init(): call_deferred("_run")
func _run() -> void:
	var policial: CharacterDef = load("res://data/parts/policial_character.tres")
	var slot_scene: PackedScene = load("res://scenes/assembly/CharacterSlot.tscn")
	var part_scene: PackedScene = load("res://scenes/assembly/PartView.tscn")
	var slot := slot_scene.instantiate() as CharacterSlot
	root.add_child(slot)
	slot.setup(null, [policial])
	var drag := DragDropService.new()
	root.add_child(drag)
	for part_def in [policial.head, policial.body, policial.legs]:
		var pv := part_scene.instantiate() as PartView
		root.add_child(pv)
		pv.setup(part_def, drag)
		assert(slot.try_attach(pv))
	assert(slot.attached_parts_can_fight())
	var vampiro: CharacterDef = load("res://data/parts/vampiro_character.tres")
	var replacement := part_scene.instantiate() as PartView
	root.add_child(replacement)
	replacement.setup(vampiro.head, drag)
	replacement.tray_home = Vector2(80, 80)
	assert(slot.can_accept(vampiro.head))
	assert(slot.try_attach(replacement))
	assert(slot.get_attached_part(PartSlotType.Value.HEAD) == vampiro.head)
	slot.set_fight_locked(true)
	assert(not slot.can_fight())
	assert(slot.attached_parts_can_fight())
	print("VERIFY_FIGHT_LOCK_PASS")
	quit(0)
