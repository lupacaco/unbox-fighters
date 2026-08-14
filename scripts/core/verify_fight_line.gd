extends SceneTree

## All fighters on the shelf share one floor line and the same size.

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var tray := Node2D.new()
	tray.position = AssemblyLayout.TRAY
	root.add_child(tray)

	var chars: Array[CharacterDef] = [
		load("res://data/parts/policial_character.tres"),
		load("res://data/parts/vampiro_character.tres"),
		load("res://data/parts/bruxa_character.tres"),
	]
	var bottoms: Array[float] = []
	var scales: Array[float] = []
	for i in chars.size():
		var puppet := FighterPuppet.new()
		root.add_child(puppet)
		puppet.setup_parts(chars[i].head, chars[i].body, chars[i].legs)
		puppet.global_position = tray.global_position + Vector2(-250.0 - 180.0 * float(i), -148.0)
		var target_feet := tray.global_position.y - 148.0 + CompositeResolver.FEET_DROP_PX
		puppet.global_position.y += target_feet - puppet.visual_bottom_y()
		bottoms.append(puppet.visual_bottom_y())
		scales.append(puppet.get_part_node(PartSlotType.Value.BODY).scale.x)

	assert(bottoms.size() == 3)
	for i in range(1, bottoms.size()):
		assert(is_equal_approx(bottoms[0], bottoms[i]), "Feet off the line: %s vs %s" % [bottoms[0], bottoms[i]])
		assert(is_equal_approx(scales[0], scales[i]), "Scale mismatch: %s vs %s" % [scales[0], scales[i]])
		assert(is_equal_approx(scales[i], CompositeResolver.display_scale()))
	print("VERIFY_FIGHT_LINE_PASS feet_y=", bottoms[0], " scale=", scales[0])
	quit(0)
