extends Node3D

## Tela de teste: 1 carta (policial 3D) + LUTAR no shelf com modelo 3D.

const HEAD_GLB := "res://assets/characters/policial/3d/policial-head-3d.glb"
const BODY_GLB := "res://assets/characters/policial/3d/policial-body-3d.glb"
const LEGS_GLB := "res://assets/characters/policial/3d/policial-legs-3d.glb"

const PX := 100.0
const JUMP_UP := 0.28
const JUMP_DOWN := 0.34
const HOLD_LAND := 0.35
const HOLD_TURN := 0.35
const WALK_STEPS := 5
const WALK_STEP := 0.22
const HOLD_ATTACK := 0.4
const BOOM_OUT := 0.28
const BOOM_BACK := 0.34
const BOOM_DIST := 1.4
const RETURN_UP := 0.26
const RETURN_DOWN := 0.32

@onready var _camera: Camera3D = $Camera3D
@onready var _world: Node3D = $World
@onready var _card_anchor: Node3D = $World/CardAnchor
@onready var _shelf_anchor: Node3D = $World/ShelfAnchor
@onready var _fight_button: Button = $UI/FightButton
@onready var _hint: Label = $UI/Hint

var _card_fighter: Fighter3DPuppet
var _busy: bool = false

func _ready() -> void:
	_setup_camera()
	_setup_background()
	_setup_shelf()
	_setup_card_frame()
	_spawn_card_fighter()
	_fight_button.pressed.connect(_on_fight_pressed)
	_hint.text = "Teste 3D — só policial. Clique LUTAR."

func _px_to_world(pos_2d: Vector2) -> Vector3:
	# Mesma lógica da tela 2D 1920x1080: centro (960,540) = origem.
	return Vector3((pos_2d.x - 960.0) / PX, (540.0 - pos_2d.y) / PX, 0.0)

func _setup_camera() -> void:
	_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_camera.size = 5.4
	_camera.position = Vector3(0.0, 0.0, 8.0)
	_camera.look_at(Vector3.ZERO, Vector3.UP)
	_camera.current = true

func _setup_background() -> void:
	var tex: Texture2D = load("res://assets/ui/bg_premium.png")
	var mesh := QuadMesh.new()
	mesh.size = Vector2(19.2, 10.8)
	var mi := MeshInstance3D.new()
	mi.name = "Background"
	mi.mesh = mesh
	mi.position = Vector3(0.0, 0.0, -2.0)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_texture = tex
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	mi.material_override = mat
	_world.add_child(mi)

func _setup_shelf() -> void:
	_shelf_anchor.position = _px_to_world(Vector2(960.0, 920.0))
	var tex: Texture2D = load("res://assets/ui/shelf_premium.png")
	var mesh := QuadMesh.new()
	mesh.size = Vector2(17.0, 1.7)
	var mi := MeshInstance3D.new()
	mi.name = "Shelf"
	mi.mesh = mesh
	mi.position = Vector3(0.0, -0.58, -0.2)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_texture = tex
	mat.albedo_color = Color(0.9, 0.92, 0.95, 1)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mi.material_override = mat
	_shelf_anchor.add_child(mi)

func _setup_card_frame() -> void:
	_card_anchor.position = _px_to_world(Vector2(960.0, 400.0))
	var tex: Texture2D = load("res://assets/ui/frame_premium.png")
	var mesh := QuadMesh.new()
	mesh.size = Vector2(3.2, 4.5)
	var mi := MeshInstance3D.new()
	mi.name = "CardFrame"
	mi.mesh = mesh
	mi.position = Vector3(0.0, 0.0, -0.35)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_texture = tex
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mi.material_override = mat
	_card_anchor.add_child(mi)

func _spawn_card_fighter() -> void:
	_card_fighter = Fighter3DPuppet.new()
	_card_fighter.name = "CardFighter"
	_card_anchor.add_child(_card_fighter)
	_card_fighter.setup_from_paths(HEAD_GLB, BODY_GLB, LEGS_GLB)
	_card_fighter.position = Vector3(0.0, -0.55, 0.0)
	_card_fighter.scale = Vector3.ONE * 1.15
	_card_fighter.face_front()

func _on_fight_pressed() -> void:
	if _busy:
		return
	_busy = true
	_fight_button.disabled = true
	await _play_fight()
	_fight_button.disabled = false
	_busy = false

func _play_fight() -> void:
	_card_fighter.visible = false

	var puppet := Fighter3DPuppet.new()
	_world.add_child(puppet)
	puppet.setup_from_paths(HEAD_GLB, BODY_GLB, LEGS_GLB)
	puppet.global_position = _card_fighter.global_position
	puppet.scale = _card_fighter.scale
	puppet.face_front()

	var left_pos := _shelf_anchor.global_position + Vector3(-5.2, 1.5, 0.0)
	var mid_pos := _shelf_anchor.global_position + Vector3(0.0, 1.5, 0.0)
	var start := puppet.global_position
	var peak := Vector3(
		lerpf(start.x, left_pos.x, 0.5),
		maxf(start.y, left_pos.y) + 2.2,
		0.0
	)

	var leap := create_tween()
	leap.tween_property(puppet, "global_position", peak, JUMP_UP).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	leap.tween_property(puppet, "global_position", left_pos, JUMP_DOWN).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await leap.finished
	await _land_squash(puppet)
	await get_tree().create_timer(HOLD_LAND).timeout

	# Vira em 3D para a direita (em vez de trocar sprite de perfil).
	var turn := create_tween()
	turn.tween_method(func(yaw: float): puppet.rotation.y = yaw, 0.0, -PI * 0.5, 0.28).set_trans(Tween.TRANS_SINE)
	await turn.finished
	await get_tree().create_timer(HOLD_TURN).timeout

	await _walk_to_center(puppet, left_pos, mid_pos)
	await get_tree().create_timer(HOLD_ATTACK).timeout

	for part_name in ["head", "body", "legs"]:
		await _boomerang(puppet, part_name)

	var ret := _card_fighter.global_position
	var ret_peak := Vector3(
		lerpf(puppet.global_position.x, ret.x, 0.5),
		maxf(puppet.global_position.y, ret.y) + 2.2,
		0.0
	)
	var face_front := create_tween()
	face_front.tween_method(func(yaw: float): puppet.rotation.y = yaw, puppet.rotation.y, 0.0, 0.2)
	await face_front.finished

	var back := create_tween()
	back.tween_property(puppet, "global_position", ret_peak, RETURN_UP).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	back.tween_property(puppet, "global_position", ret, RETURN_DOWN).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await back.finished

	puppet.queue_free()
	_card_fighter.visible = true

func _walk_to_center(puppet: Fighter3DPuppet, from_pos: Vector3, to_pos: Vector3) -> void:
	for i in WALK_STEPS:
		var t := float(i + 1) / float(WALK_STEPS)
		var next_pos := from_pos.lerp(to_pos, t)
		puppet.set_stride_pose((i % 2) == 0)
		var bob := next_pos + Vector3(0.0, 0.12 if (i % 2) == 0 else 0.0, 0.0)
		var step := create_tween()
		step.tween_property(puppet, "global_position", bob, WALK_STEP * 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		step.tween_property(puppet, "global_position", next_pos, WALK_STEP * 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		await step.finished
	puppet.reset_pose_tilt()
	puppet.global_position = to_pos

func _boomerang(puppet: Fighter3DPuppet, part_name: String) -> void:
	var part := puppet.get_part_node(part_name)
	if part == null:
		return
	var home := part.position
	# Para frente do personagem (direita da tela enquanto yaw = -90°).
	var outward := home + Vector3(BOOM_DIST, 0.08, 0.0)
	var tween := create_tween()
	tween.tween_property(part, "position", outward, BOOM_OUT).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(part, "position", home, BOOM_BACK).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	await tween.finished

func _land_squash(puppet: Node3D) -> void:
	var base := puppet.scale
	var tween := create_tween()
	tween.tween_property(puppet, "scale", base * Vector3(1.15, 0.78, 1.15), 0.06)
	tween.tween_property(puppet, "scale", base * Vector3(0.95, 1.08, 0.95), 0.08)
	tween.tween_property(puppet, "scale", base, 0.12)
	await tween.finished
