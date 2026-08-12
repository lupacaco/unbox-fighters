class_name Model3DHost
extends Node2D

## Renders one GLB into a 2D sprite via a private 3D viewport.
## Front = looking at the camera. Profile = yaw so the model faces screen-right.

const VIEW_PX := 256
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
	_viewport.msaa_3d = Viewport.MSAA_2X
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_viewport)

	var world := Node3D.new()
	world.name = "World"
	_viewport.add_child(world)

	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0, 0, 0, 0)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.78, 0.8, 0.84)
	env.ambient_light_energy = 0.65
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	world.add_child(world_env)

	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-35, 40, 0)
	light.light_energy = 1.15
	light.shadow_enabled = false
	world.add_child(light)

	var fill := OmniLight3D.new()
	fill.position = Vector3(-1.2, 0.8, 1.6)
	fill.light_energy = 0.45
	fill.omni_range = 8.0
	world.add_child(fill)

	_pivot = Node3D.new()
	_pivot.name = "Pivot"
	world.add_child(_pivot)

	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 1.2
	camera.position = Vector3(0, 0, 3)
	camera.look_at(Vector3.ZERO, Vector3.UP)
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

func _sync_update_mode() -> void:
	if _viewport == null:
		return
	_viewport.render_target_update_mode = (
		SubViewport.UPDATE_ALWAYS if is_visible_in_tree() else SubViewport.UPDATE_DISABLED
	)

func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED:
		_sync_update_mode()
