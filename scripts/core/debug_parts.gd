extends SceneTree
func _init():
	call_deferred("_run")
func _run():
	var c: CharacterDef = load("res://data/parts/vampiro_character.tres")
	print("CHAR=", c != null)
	if c == null:
		quit(1); return
	for slot in PartSlotType.all_slots():
		var part := c.get_part(slot)
		print(PartSlotType.to_string_name(slot), "=", part != null, " sprite=", part.sprite != null if part else false)
	if c.head and c.head.sprite:
		print("HEAD_SIZE=", c.head.sprite.get_size())
	var part_scene: PackedScene = load("res://scenes/assembly/PartView.tscn")
	var part = part_scene.instantiate()
	root.add_child(part)
	var drag = Node.new()
	drag.set_script(load("res://scripts/assembly/drag_drop_service.gd"))
	root.add_child(drag)
	part.setup(c.head, drag)
	print("PART_VISIBLE=", part.visible, " scale=", part.scale, " modulate=", part.modulate)
	print("SPRITE_TEX=", part.get_node("Sprite").texture != null)
	print("SPRITE_SCALE=", part.get_node("Sprite").scale)
	print("SPRITE_MOD=", part.get_node("Sprite").modulate)
	quit(0)
