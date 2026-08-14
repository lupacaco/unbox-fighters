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
	assert(slot.can_accept(leao.body))
	assert(slot.can_accept(leao.arm_l))
	assert(slot.can_accept(leao.arm_r))
	assert(not slot.can_accept(leao.legs))
	assert(not slot.can_accept(leao.leg_r))
	assert(not slot.can_fight())
	var spring := slot.get_node("Display/Spring") as Sprite2D
	assert(spring != null and spring.visible and spring.texture != null, "Empty card should show the spring")
	var shade := slot.get_node_or_null("Display/SpringShadow") as Polygon2D
	assert(shade != null and shade.visible, "Card spring should cast a ground shadow")
	print("VERIFY_FIGHT_POSES_PASS")
	quit(0)
