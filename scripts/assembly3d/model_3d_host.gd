class_name Model3DHost
extends Node2D

## Draws one GLB as a 2D picture: a tiny private 3D room is photographed
## into a sprite. Front faces the camera. Profile yaws toward screen-right.

const VIEW_PX := 192
const FRONT_YAW := PI
const PROFILE_YAW := PI * 0.5

var _viewport: SubViewport
var _sprite: Sprite2D
var _pivot: Node3D
var _display_px: float = 150.0
var _profile: bool = false

func setup(glb_path: String, display_px: float) -> void:
	_display_px = display_px
	_ensure_view()
	_clear_model()
	var model := _instantiate_glb(glb_path)
	if model == null:
		push_error("Model3DHost: could not load %s" % glb_path)
		return
	model.name = "Model"
	_pivot.add_child(model)
	_strip_colliders(model)
	_prepare_model(model)
	set_profile(false)
	_apply_sprite_scale()
	_sync_update_mode()

func set_display_px(display_px: float) -> void:
	_display_px = display_px
	_apply_sprite_scale()

func set_profile(enabled: bool) -> void:
	_profile = enabled
	if _pivot == null:
		return
	_pivot.rotation.y = PROFILE_YAW if enabled else FRONT_YAW
	_pivot.rotation.x = 0.0

func set_stride_lean(use_attack: bool) -> void:
	if _pivot == null:
		return
	_pivot.rotation.y = PROFILE_YAW
	_pivot.rotation.x = 0.18 if use_attack else -0.08

func _ensure_view() -> void:
	if _viewport != null:
		return
	_viewport = SubViewport.new()
	_viewport.name = "View"
	_viewport.size = Vector2i(VIEW_PX, VIEW_PX)
	_viewport.transparent_bg = true
	_viewport.own_world_3d = true
	_viewport.disable_3d = false
	_viewport.handle_input_locally = false
	_viewport.msaa_3d = Viewport.MSAA_DISABLED
	_viewport.positional_shadow_atlas_size = 0
	_viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	add_child(_viewport)

	var world := Node3D.new()
	world.name = "World"
	_viewport.add_child(world)

	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0, 0, 0, 0)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color.WHITE
	env.ambient_light_energy = 1.0
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	world.add_child(world_env)

	_pivot = Node3D.new()
	_pivot.name = "Pivot"
	world.add_child(_pivot)

	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 1.15
	camera.position = Vector3(0, 0, 3)
	camera.current = true
	camera.environment = env
	world.add_child(camera)

	_sprite = Sprite2D.new()
	_sprite.name = "Blit"
	_sprite.centered = true
	_sprite.texture = _viewport.get_texture()
	add_child(_sprite)

func _apply_sprite_scale() -> void:
	if _sprite == null:
		return
	var s := _display_px / float(VIEW_PX)
	_sprite.scale = Vector2.ONE * s

func _clear_model() -> void:
	if _pivot == null:
		return
	for child in _pivot.get_children():
		_pivot.remove_child(child)
		child.free()

func _instantiate_glb(path: String) -> Node3D:
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
		return null
	var scene := doc.generate_scene(state)
	return scene as Node3D

func _strip_colliders(root: Node) -> void:
	for child in root.get_children():
		_strip_colliders(child)
	if root is CollisionObject3D:
		(root as CollisionObject3D).collision_layer = 0
		(root as CollisionObject3D).collision_mask = 0

func _prepare_model(root: Node) -> void:
	if root is MeshInstance3D:
		var mi := root as MeshInstance3D
		mi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_ensure_normals(mi)
		_apply_unshaded(mi)
	for child in root.get_children():
		_prepare_model(child)

func _ensure_normals(mi: MeshInstance3D) -> void:
	var mesh := mi.mesh
	if mesh == null:
		return
	var out := ArrayMesh.new()
	var st := SurfaceTool.new()
	for i in mesh.get_surface_count():
		st.clear()
		st.create_from(mesh, i)
		st.generate_normals()
		st.commit(out)
	mi.mesh = out

func _apply_unshaded(mi: MeshInstance3D) -> void:
	var mesh := mi.mesh
	if mesh == null:
		return
	for i in mesh.get_surface_count():
		mi.set_surface_override_material(i, _to_unshaded(mi.get_active_material(i)))

func _to_unshaded(src: Material) -> Material:
	var out := StandardMaterial3D.new()
	out.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	out.cull_mode = BaseMaterial3D.CULL_BACK
	out.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	out.albedo_color = Color.WHITE
	out.metallic = 0.0
	out.roughness = 1.0
	var tex := _albedo_tex(src)
	if tex != null:
		out.albedo_texture = tex
	var color := _albedo_color(src)
	if color != Color.WHITE:
		out.albedo_color = color
	return out

func _albedo_tex(src: Material) -> Texture2D:
	if src is BaseMaterial3D:
		return (src as BaseMaterial3D).albedo_texture
	if src is ShaderMaterial:
		var sm := src as ShaderMaterial
		for key in ["texture_albedo", "albedo_texture", "base_color_texture"]:
			var value: Variant = sm.get_shader_parameter(key)
			if value is Texture2D:
				return value as Texture2D
	return null

func _albedo_color(src: Material) -> Color:
	if src is BaseMaterial3D:
		return (src as BaseMaterial3D).albedo_color
	if src is ShaderMaterial:
		var sm := src as ShaderMaterial
		for key in ["albedo", "base_color"]:
			var value: Variant = sm.get_shader_parameter(key)
			if value is Color:
				return value as Color
	return Color.WHITE

func _sync_update_mode() -> void:
	if _viewport == null:
		return
	_viewport.render_target_update_mode = (
		SubViewport.UPDATE_WHEN_VISIBLE if is_visible_in_tree() else SubViewport.UPDATE_DISABLED
	)

func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED:
		_sync_update_mode()
