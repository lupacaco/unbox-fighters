extends SceneTree

## Checks that policial GLBs load with visible (unshaded + textured) materials.

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var paths := [
		"res://assets/characters/policial/3d/policial-head-3d.glb",
		"res://assets/characters/policial/3d/policial-body-3d.glb",
		"res://assets/characters/policial/3d/policial-legs-3d.glb",
	]
	for path in paths:
		if not ResourceLoader.exists(path):
			push_error("VERIFY_FAIL missing %s" % path)
			quit(1)
			return
		var host := Model3DHost.new()
		root.add_child(host)
		host.setup(path, 168.0)
		await process_frame
		await process_frame
		var mi := _first_mesh(host)
		if mi == null:
			push_error("VERIFY_FAIL no mesh in %s" % path)
			quit(1)
			return
		var mat := mi.get_active_material(0)
		if mat == null:
			push_error("VERIFY_FAIL no material in %s" % path)
			quit(1)
			return
		if not (mat is BaseMaterial3D):
			push_error("VERIFY_FAIL material is not BaseMaterial3D in %s" % path)
			quit(1)
			return
		var base := mat as BaseMaterial3D
		if base.shading_mode != BaseMaterial3D.SHADING_MODE_UNSHADED:
			push_error("VERIFY_FAIL expected unshaded material in %s" % path)
			quit(1)
			return
		if base.albedo_texture == null:
			push_error("VERIFY_FAIL missing albedo texture in %s" % path)
			quit(1)
			return
		print("VERIFY_OK ", path.get_file(), " verts~", _vertex_hint(mi))
		host.queue_free()
	print("VERIFY_PASS")
	quit(0)

func _first_mesh(root: Node) -> MeshInstance3D:
	if root is MeshInstance3D:
		return root as MeshInstance3D
	for child in root.get_children():
		var found := _first_mesh(child)
		if found != null:
			return found
	return null

func _vertex_hint(mi: MeshInstance3D) -> int:
	if mi.mesh == null:
		return 0
	return mi.mesh.get_faces().size()
