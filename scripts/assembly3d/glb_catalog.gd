class_name GlbCatalog
extends RefCounted

## Maps part ids to GLB files. Only the policial 3D test uses this.

const HEAD := "res://assets/characters/policial/3d/policial-head-3d.glb"
const BODY := "res://assets/characters/policial/3d/policial-body-3d.glb"
const LEGS := "res://assets/characters/policial/3d/policial-legs-3d.glb"

static func path_for(part: PartDef) -> String:
	if part == null:
		return ""
	match String(part.id):
		"policial_head":
			return HEAD
		"policial_body":
			return BODY
		"policial_legs":
			return LEGS
		_:
			return ""

static func has_model(part: PartDef) -> bool:
	return path_for(part) != ""
