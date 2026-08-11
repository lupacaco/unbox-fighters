extends SceneTree
func _init():
	call_deferred("_run")
func _run():
	var c: CharacterDef = load("res://data/parts/vampiro_character.tres")
	print("CHAR=", c != null)
	if c == null:
		quit(1); return
	print("HEAD=", c.head != null, " sprite=", c.head.sprite != null if c.head else false)
	print("BODY=", c.body != null, " sprite=", c.body.sprite != null if c.body else false)
	print("LEGS=", c.legs != null, " sprite=", c.legs.sprite != null if c.legs else false)
	if c.head and c.head.sprite:
		print("HEAD_SIZE=", c.head.sprite.get_size())
	var tex = load("res://assets/characters/vampiro/head.webp")
	print("DIRECT_HEAD=", tex != null, " size=", tex.get_size() if tex else Vector2.ZERO)
	var part_scene: PackedScene = load("res://scenes/assembly/PartView.tscn")
	var part = part_scene.instantiate()
	root.add_child(part)
	# minimal drag stub
	var drag = Node.new()
	drag.set_script(load("res://scripts/assembly/drag_drop_service.gd"))
	root.add_child(drag)
	part.setup(c.head, drag)
	print("PART_VISIBLE=", part.visible, " scale=", part.scale, " modulate=", part.modulate)
	print("SPRITE_TEX=", part.get_node("Sprite").texture != null)
	print("SPRITE_SCALE=", part.get_node("Sprite").scale)
	print("SPRITE_MOD=", part.get_node("Sprite").modulate)
	quit(0)
