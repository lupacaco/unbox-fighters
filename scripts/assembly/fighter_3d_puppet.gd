class_name Fighter3DPuppet
extends Node3D

## Monta cabeça + tronco + pernas 3D e anima poses simples (sem skeleton).

const PART_SCALE := 0.58
const BODY_Y := 0.52
const HEAD_Y := 1.05

var _head: Node3D
var _body: Node3D
var _legs: Node3D
var _facing_yaw: float = 0.0

func setup_from_paths(head_path: String, body_path: String, legs_path: String) -> void:
	_clear_children()
	_legs = _load_part(legs_path, "Legs")
	_body = _load_part(body_path, "Body")
	_head = _load_part(head_path, "Head")
	_legs.position = Vector3(0.0, 0.0, 0.0)
	_body.position = Vector3(0.0, BODY_Y, 0.0)
	_head.position = Vector3(0.0, HEAD_Y, 0.0)
	face_front()

func _load_part(path: String, part_name: String) -> Node3D:
	var wrapper := Node3D.new()
	wrapper.name = part_name
	add_child(wrapper)
	var model := _instantiate_gltf(path)
	if model == null:
		push_error("Fighter3DPuppet: falha ao carregar %s" % path)
		return wrapper
	model.name = "Model"
	wrapper.add_child(model)
	wrapper.scale = Vector3.ONE * PART_SCALE
	return wrapper

func _instantiate_gltf(path: String) -> Node3D:
	# Carrega .glb em tempo de execução (não depende do import do editor).
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	var err := doc.append_from_file(path, state)
	if err != OK:
		push_error("GLTF append_from_file failed (%s): %s" % [str(err), path])
		return null
	var scene := doc.generate_scene(state)
	return scene as Node3D

func _clear_children() -> void:
	for child in get_children():
		child.queue_free()

func face_front() -> void:
	_facing_yaw = 0.0
	rotation.y = _facing_yaw

func face_right() -> void:
	# Vira para a direita da tela (+X) para caminhar no shelf.
	_facing_yaw = -PI * 0.5
	rotation.y = _facing_yaw

func get_part_node(slot: String) -> Node3D:
	match slot:
		"head":
			return _head
		"body":
			return _body
		"legs":
			return _legs
		_:
			return null

func set_stride_pose(use_attack_lean: bool) -> void:
	# Sem animação no GLB: inclina leve para simular passo.
	var lean := 0.12 if use_attack_lean else -0.08
	if _body != null:
		_body.rotation.x = lean
	if _legs != null:
		_legs.rotation.x = -lean * 0.5
	if _head != null:
		_head.rotation.x = lean * 0.35

func reset_pose_tilt() -> void:
	for part in [_head, _body, _legs]:
		if part != null:
			part.rotation = Vector3.ZERO
