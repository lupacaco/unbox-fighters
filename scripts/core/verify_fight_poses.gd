extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var vampiro: CharacterDef = load("res://data/parts/vampiro_character.tres")
	assert(vampiro != null)
	assert(vampiro.can_fight())

	var packed: PackedScene = load("res://scenes/assembly/CharacterSlot.tscn")
	var slot := packed.instantiate() as CharacterSlot
	root.add_child(slot)
	slot.setup(null, [vampiro])
	assert(slot.get_node("FightButton") != null)
	assert(slot.get_node_or_null("StatReadout") == null, "Card should not show the name plate under the frame")
	assert(is_equal_approx((slot.get_node("Display") as Node2D).position.y, CharacterSlot.TOY_Y))
	assert(CharacterSlot.TOY_Y >= 50.0, "Freak should sit lower in the card frame")
	assert(slot.can_accept(vampiro.head))
	assert(slot.can_accept(vampiro.body))
	assert(slot.can_accept(vampiro.arm_l))
	assert(slot.can_accept(vampiro.arm_r))
	assert(not slot.can_accept(vampiro.legs))
	assert(not slot.can_accept(vampiro.leg_r))
	assert(not slot.can_fight())
	var spring := slot.get_node("Display/Spring") as Sprite2D
	assert(spring != null and spring.visible and spring.texture != null, "Empty card should show the spring")
	var shade := slot.get_node_or_null("Display/SpringShadow") as Polygon2D
	assert(shade != null and shade.visible, "Card spring should cast a ground shadow")
	print("VERIFY_FIGHT_POSES_PASS")
	quit(0)
