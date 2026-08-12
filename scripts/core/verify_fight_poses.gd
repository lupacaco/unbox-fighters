extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var policial: CharacterDef = load("res://data/parts/policial_character.tres")
	assert(policial != null)
	assert(policial.can_fight())
	assert(policial.head.sprite_profile != null and policial.head.sprite_attack != null)

	var vampiro: CharacterDef = load("res://data/parts/vampiro_character.tres")
	assert(vampiro != null)
	assert(not vampiro.can_fight())

	var packed: PackedScene = load("res://scenes/assembly/CharacterSlot.tscn")
	var slot := packed.instantiate() as CharacterSlot
	root.add_child(slot)
	slot.setup(null, [policial, vampiro])
	assert(slot.get_node("FightButton") != null)
	assert(slot.get_node("FightButton").visible == true)
	assert(slot.can_accept(policial.head))
	assert(slot.can_accept(vampiro.head))
	assert(not slot.can_fight())
	print("VERIFY_FIGHT_POSES_PASS")
	quit(0)
