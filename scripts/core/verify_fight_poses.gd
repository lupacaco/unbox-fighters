extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var policial: CharacterDef = load("res://data/parts/policial_character.tres")
	var vampiro: CharacterDef = load("res://data/parts/vampiro_character.tres")
	var bruxa: CharacterDef = load("res://data/parts/bruxa_character.tres")
	assert(policial != null and vampiro != null and bruxa != null)
	assert(policial.can_fight())
	assert(vampiro.can_fight())
	assert(bruxa.can_fight())

	var packed: PackedScene = load("res://scenes/assembly/CharacterSlot.tscn")
	var slot := packed.instantiate() as CharacterSlot
	root.add_child(slot)
	slot.setup(null, [policial, vampiro, bruxa])
	assert(slot.get_node("FightButton") != null)
	assert(slot.can_accept(policial.head))
	assert(slot.can_accept(vampiro.head))
	assert(slot.can_accept(bruxa.head))
	assert(not slot.can_fight())
	print("VERIFY_FIGHT_POSES_PASS")
	quit(0)
