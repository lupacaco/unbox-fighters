class_name MumiaFighter3D
extends Node2D

## Renders the three mummy GLBs in a private 3D view and shows them as a 2D sprite.

const HEAD_GLB := "res://assets/characters/mumia/3d/mumia-head-rig.glb"
const BODY_GLB := "res://assets/characters/mumia/3d/mumia-body-rig.glb"
const LEGS_GLB := "res://assets/characters/mumia/3d/mumia-legs-rig.glb"

const VIEW_PX := Vector2i(384, 512)
const FRONT_YAW := 0.0
const PROFILE_RIGHT_YAW := PI * 0.5
const PROFILE_LEFT_YAW := -PI * 0.5
const DISPLAY_HEIGHT_PX := 340.0
const PART_OVERLAP := 0.10

var _viewport: SubViewport
var _sprite: Sprite2D
var _pivot: Node3D
var _players: Array[AnimationPlayer] = []

var yaw: float:
	get:
		return get_yaw()
	set(value):
		set_yaw(value)

func _ready() -> void:
	_build_view()
	_spawn_parts()
	set_yaw(FRONT_YAW)
	play("idle")


func set_yaw(yaw: float) -> void:
	if _pivot != null:
		_pivot.rotation.y = yaw


func get_yaw() -> float:
	if _pivot == null:
		return FRONT_YAW
	return _pivot.rotation.y


func play(anim_name: String) -> void:
	for player in _players:
		if player.has_animation(anim_name):
			player.play(anim_name)


func _build_view() -> void:
	_viewport = SubViewport.new()
	_viewport.name = "View"
	_viewport.size = VIEW_PX
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
	env.ambient_light_color = Color(0.78, 0.80, 0.86)
	env.ambient_light_energy = 0.7
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	world.add_child(world_env)

	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-35.0, 40.0, 0.0)
	key.light_energy = 1.2
	world.add_child(key)

	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-15.0, -110.0, 0.0)
	fill.light_energy = 0.32
	world.add_child(fill)

	_pivot = Node3D.new()
	_pivot.name = "Pivot"
	world.add_child(_pivot)

	var camera := Camera3D.new()
	camera.fov = 38.0
	camera.position = Vector3(0.0, 0.95, 3.15)
	world.add_child(camera)
	camera.look_at(Vector3(0.0, 0.85, 0.0))

	_sprite = Sprite2D.new()
	_sprite.centered = true
	_sprite.texture = _viewport.get_texture()
	add_child(_sprite)
	var s := DISPLAY_HEIGHT_PX / float(VIEW_PX.y)
	_sprite.scale = Vector2(s, s)


func _spawn_parts() -> void:
	var legs := _instance_glb(LEGS_GLB, "Legs")
	var body := _instance_glb(BODY_GLB, "Body")
	var head := _instance_glb(HEAD_GLB, "Head")
	if legs == null or body == null or head == null:
		push_error("MumiaFighter3D: missing GLB part")
		return
	_pivot.add_child(legs)
	_pivot.add_child(body)
	_pivot.add_child(head)
	_stack(legs, body, head)
	_collect_players(_pivot)


func _instance_glb(path: String, node_name: String) -> Node3D:
	var packed := load(path) as PackedScene
	if packed == null:
		push_error("MumiaFighter3D: could not load %s" % path)
		return null
	var model := packed.instantiate() as Node3D
	model.name = node_name
	return model


func _stack(legs: Node3D, body: Node3D, head: Node3D) -> void:
	var legs_box := _combined_aabb(legs)
	var body_box := _combined_aabb(body)
	var head_box := _combined_aabb(head)
	if legs_box.size.y < 0.05:
		legs_box = AABB(Vector3(-0.43, -0.50, -0.21), Vector3(0.87, 1.00, 0.42))
	if body_box.size.y < 0.05:
		body_box = AABB(Vector3(-0.50, -0.34, -0.13), Vector3(1.00, 0.68, 0.27))
	if head_box.size.y < 0.05:
		head_box = AABB(Vector3(-0.39, -0.50, -0.29), Vector3(0.78, 1.00, 0.58))
	legs.position.y = -legs_box.position.y
	var legs_top := legs.position.y + legs_box.position.y + legs_box.size.y
	body.position.y = legs_top - PART_OVERLAP - body_box.position.y
	var body_top := body.position.y + body_box.position.y + body_box.size.y
	head.scale = Vector3.ONE * 0.72
	head.position.y = body_top - PART_OVERLAP * 0.6 - head_box.position.y * 0.72


func _combined_aabb(node: Node) -> AABB:
	var found := false
	var box := AABB()
	var stack: Array[Node] = [node]
	while not stack.is_empty():
		var current: Node = stack.pop_back()
		if current is MeshInstance3D:
			var mesh_node := current as MeshInstance3D
			var local := mesh_node.get_aabb()
			if not found:
				box = local
				found = true
			else:
				box = box.merge(local)
		for child in current.get_children():
			stack.append(child)
	if not found:
		return AABB(Vector3(-0.5, -0.5, -0.5), Vector3.ONE)
	return box


func _collect_players(node: Node) -> void:
	if node is AnimationPlayer:
		_players.append(node as AnimationPlayer)
	for child in node.get_children():
		_collect_players(child)
