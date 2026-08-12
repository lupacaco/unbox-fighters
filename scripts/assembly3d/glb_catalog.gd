class_name GlbCatalog
extends RefCounted

## Mapa id da peça → arquivo GLB (teste 3D do policial).

const HEAD := "res://assets/characters/policial/3d/policial-head-3d.glb"
const BODY := "res://assets/characters/policial/3d/policial-body-3d.glb"
const LEGS := "res://assets/characters/policial/3d/policial-legs-3d.glb"

static func path_for_part_id(part_id: StringName) -> String:
	match String(part_id):
		"policial_head":
			return HEAD
		"policial_body":
			return BODY
		"policial_legs":
			return LEGS
		_:
			return ""

static func has_glb(part_id: StringName) -> bool:
	return not path_for_part_id(part_id).is_empty()

static func instantiate_model(path: String) -> Node3D:
	if path.is_empty():
		return null
	var packed: Variant = load(path)
	if packed is PackedScene:
		var inst: Node = (packed as PackedScene).instantiate()
		if inst is Node3D:
			return inst as Node3D
		var wrap := Node3D.new()
		wrap.add_child(inst)
		return wrap
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	if doc.append_from_file(path, state) != OK:
		push_error("GlbCatalog: falha ao ler %s" % path)
		return null
	var scene := doc.generate_scene(state)
	if scene is Node3D:
		return scene as Node3D
	if scene != null:
		var wrap2 := Node3D.new()
		wrap2.add_child(scene)
		return wrap2
	return null
