extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var leao: CharacterDef = load("res://data/parts/leao_character.tres")
	assert(leao != null)
	assert(leao.can_fight())

	var packed: PackedScene = load("res://scenes/assembly/CharacterSlot.tscn")
	var slot := packed.instantiate() as CharacterSlot
	root.add_child(slot)
	slot.setup(null, [leao])
	assert(slot.get_node("FightButton") != null)
	assert(slot.can_accept(leao.head))
	assert(slot.can_accept(leao.arm_l))
	assert(slot.can_accept(leao.leg_r))
	assert(not slot.can_fight())
	print("VERIFY_FIGHT_POSES_PASS")
	quit(0)
