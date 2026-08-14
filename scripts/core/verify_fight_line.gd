extends SceneTree

## Every fighter in the queue uses the same floor Y and the same scale.

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var tray := Node2D.new()
	tray.position = AssemblyLayout.TRAY
	root.add_child(tray)
	var floor_y := tray.global_position.y - 148.0

	var chars: Array[CharacterDef] = [
		load("res://data/parts/policial_character.tres"),
		load("res://data/parts/vampiro_character.tres"),
		load("res://data/parts/medico_character.tres"),
		load("res://data/parts/cachorro_character.tres"),
	]
	var ys: Array[float] = []
	var scales: Array[float] = []
	for i in chars.size():
		var puppet := FighterPuppet.new()
		root.add_child(puppet)
		puppet.setup_parts(chars[i].head, chars[i].body, chars[i].legs)
		puppet.global_position = Vector2(200.0 * float(i), floor_y)
		ys.append(puppet.global_position.y)
		scales.append(puppet.get_part_node(PartSlotType.Value.BODY).scale.x)

	for i in range(1, ys.size()):
		assert(is_equal_approx(ys[0], ys[i]), "Queue Y mismatch: %s vs %s" % [ys[0], ys[i]])
		assert(is_equal_approx(scales[0], scales[i]), "Scale mismatch: %s vs %s" % [scales[0], scales[i]])
		assert(is_equal_approx(scales[i], CompositeResolver.display_scale()))
	print("VERIFY_FIGHT_LINE_PASS y=", ys[0], " scale=", scales[0])
	quit(0)
