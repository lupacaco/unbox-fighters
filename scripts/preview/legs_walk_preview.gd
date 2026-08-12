extends Node3D

## Opens the rigged police legs and plays the walk loop.
## This is a preview scene, not the main 2D assembly screen.

const LEGS_GLB := "res://assets/characters/policial/3d/policial-legs-3d-walk.glb"
const ORBIT_SPEED := 0.32
const ORBIT_RADIUS := 1.9
const LOOK_AT := Vector3(0.0, 0.08, 0.0)
const GROUND_Y := -0.498

var _camera: Camera3D
var _angle := 0.0

func _ready() -> void:
	_build_stage()
	_spawn_legs()

func _process(delta: float) -> void:
	if _camera == null:
		return
	_angle += delta * ORBIT_SPEED
	_camera.position = Vector3(
		sin(_angle) * ORBIT_RADIUS,
		0.42,
		cos(_angle) * ORBIT_RADIUS
	)
	_camera.look_at(LOOK_AT)


func _build_stage() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.07, 0.08, 0.10)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.78, 0.80, 0.86)
	env.ambient_light_energy = 0.7
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)

	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-38.0, 42.0, 0.0)
	key.light_energy = 1.2
	key.shadow_enabled = false
	add_child(key)

	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-20.0, -120.0, 0.0)
	fill.light_energy = 0.35
	fill.shadow_enabled = false
	add_child(fill)

	_camera = Camera3D.new()
	_camera.fov = 42.0
	add_child(_camera)

	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(6.0, 6.0)
	ground.mesh = plane
	ground.position = Vector3(0.0, GROUND_Y, 0.0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.12, 0.13, 0.15)
	mat.roughness = 0.92
	ground.material_override = mat
	add_child(ground)

	var label := Label3D.new()
	label.text = "Pernas do policial — passos"
	label.font_size = 42
	label.position = Vector3(0.0, 0.72, 0.0)
	label.modulate = Color(0.92, 0.94, 0.96)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)


func _spawn_legs() -> void:
	var packed := load(LEGS_GLB) as PackedScene
	if packed == null:
		push_error("Could not load %s" % LEGS_GLB)
		return
	var model := packed.instantiate()
	model.name = "Legs"
	add_child(model)
	var player := _find_animation_player(model)
	if player == null:
		push_error("Walk preview: no AnimationPlayer in %s" % LEGS_GLB)
		return
	var anim_name := _pick_walk_name(player)
	if anim_name.is_empty():
		push_error("Walk preview: no animations in %s" % LEGS_GLB)
		return
	player.play(anim_name)
	print("LEGS_WALK playing ", anim_name)


func _pick_walk_name(player: AnimationPlayer) -> String:
	var names := player.get_animation_list()
	for candidate in ["walk", "Walk", "animation://walk"]:
		if player.has_animation(candidate):
			return candidate
	for anim_name in names:
		if "walk" in anim_name.to_lower():
			return anim_name
	if names.size() > 0:
		return names[0]
	return ""


func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child in node.get_children():
		var found := _find_animation_player(child)
		if found != null:
			return found
	return null
