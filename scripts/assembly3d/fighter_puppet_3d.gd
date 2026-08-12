class_name FighterPuppet3D
extends Node2D

## Lutador da animação LUTAR: Node2D (mesmas posições 2D) + boneco 3D dentro.

const VIEW_W := 360
const VIEW_H := 420

var _subviewport: SubViewport
var _sprite: Sprite2D
var _host: Model3DHost
var _head_def: PartDef
var _body_def: PartDef
var _legs_def: PartDef

func _ready() -> void:
	_ensure_view()

func setup_parts(head: PartDef, body: PartDef, legs: PartDef) -> void:
	_head_def = head
	_body_def = body
	_legs_def = legs
	_ensure_view()
	_host.set_parts(head, body, legs)
	_host.face_front()
	_host.reset_lean()

func set_pose_front() -> void:
	_host.face_front()
	_host.reset_lean()

func set_pose_profile() -> void:
	_host.face_profile_right()
	_host.reset_lean()

func set_stride_frame(use_attack_lean: bool) -> void:
	# Em 3D não troca sprite: só inclina (e mantém perfil).
	_host.face_profile_right()
	_host.set_stride_lean(use_attack_lean)

func get_part_node(slot: PartSlotType.Value) -> Node3D:
	return _host.get_part_node(slot)

func get_yaw() -> float:
	return _host.get_yaw()

func set_yaw(radians: float) -> void:
	_host.set_yaw(radians)

func reset_lean_safe() -> void:
	if _host != null:
		_host.reset_lean()

func _ensure_view() -> void:
	if _subviewport != null:
		return
	_subviewport = SubViewport.new()
	_subviewport.name = "Fight3DViewport"
	_subviewport.size = Vector2i(VIEW_W, VIEW_H)
	_subviewport.transparent_bg = true
	_subviewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_subviewport)

	var world := Node3D.new()
	_subviewport.add_child(world)

	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 2.0
	cam.position = Vector3(0.0, 0.6, 3.4)
	cam.current = true
	world.add_child(cam)

	var light := DirectionalLight3D.new()
	light.light_energy = 1.2
	light.rotation_degrees = Vector3(-38.0, -18.0, 0.0)
	world.add_child(light)

	var fill := OmniLight3D.new()
	fill.light_energy = 0.45
	fill.omni_range = 8.0
	fill.position = Vector3(-1.2, 1.0, 2.0)
	world.add_child(fill)

	_host = Model3DHost.new()
	_host.name = "Host"
	world.add_child(_host)

	_sprite = Sprite2D.new()
	_sprite.name = "Preview"
	_sprite.centered = true
	_sprite.texture = _subviewport.get_texture()
	# Aproxima o tamanho visual do FighterPuppet 2D (~170px por peça / corpo inteiro).
	_sprite.scale = Vector2.ONE * (210.0 / float(VIEW_H))
	add_child(_sprite)
