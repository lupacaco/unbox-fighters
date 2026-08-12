class_name Model3DHost
extends Node3D

## Empilha até 3 partes GLB. Usado na carta, na peça da prateleira e na luta.

const PART_SCALE := 0.58
const BODY_Y := 0.52
const HEAD_Y := 1.05

var _head: Node3D
var _body: Node3D
var _legs: Node3D
var _yaw_root: Node3D

func _ready() -> void:
	if _yaw_root == null:
		_ensure_yaw_root()

func _ensure_yaw_root() -> void:
	_yaw_root = Node3D.new()
	_yaw_root.name = "YawRoot"
	add_child(_yaw_root)

func clear_parts() -> void:
	_ensure_yaw_root()
	var kids: Array = _yaw_root.get_children()
	for child in kids:
		_yaw_root.remove_child(child)
		child.free()
	_head = null
	_body = null
	_legs = null

func set_parts(head: PartDef, body: PartDef, legs: PartDef) -> void:
	_ensure_yaw_root()
	clear_parts()
	if legs != null:
		_legs = _add_part(legs, "Legs", Vector3(0.0, 0.0, 0.0))
	if body != null:
		_body = _add_part(body, "Body", Vector3(0.0, BODY_Y, 0.0))
	if head != null:
		_head = _add_part(head, "Head", Vector3(0.0, HEAD_Y, 0.0))
	face_front()

func set_single_part(part: PartDef) -> void:
	_ensure_yaw_root()
	clear_parts()
	if part == null:
		return
	var node := _add_part(part, "Part", Vector3.ZERO)
	match part.slot_type:
		PartSlotType.Value.HEAD:
			_head = node
		PartSlotType.Value.BODY:
			_body = node
		_:
			_legs = node
	face_front()

func _add_part(part: PartDef, node_name: String, local_pos: Vector3) -> Node3D:
	var path := GlbCatalog.path_for_part_id(part.id)
	var model := GlbCatalog.instantiate_model(path)
	var slot := Node3D.new()
	slot.name = node_name
	slot.position = local_pos
	slot.scale = Vector3.ONE * PART_SCALE
	_yaw_root.add_child(slot)
	if model != null:
		model.name = "Model"
		slot.add_child(model)
	return slot

func face_front() -> void:
	_ensure_yaw_root()
	_yaw_root.rotation.y = 0.0

func face_profile_right() -> void:
	_ensure_yaw_root()
	_yaw_root.rotation.y = -PI * 0.5

func set_yaw(radians: float) -> void:
	_ensure_yaw_root()
	_yaw_root.rotation.y = radians

func get_yaw() -> float:
	_ensure_yaw_root()
	return _yaw_root.rotation.y

func get_part_node(slot: PartSlotType.Value) -> Node3D:
	match slot:
		PartSlotType.Value.HEAD:
			return _head
		PartSlotType.Value.BODY:
			return _body
		_:
			return _legs

func set_stride_lean(use_attack_lean: bool) -> void:
	var lean := 0.14 if use_attack_lean else -0.1
	if _body != null:
		_body.rotation.x = lean
	if _legs != null:
		_legs.rotation.x = -lean * 0.45
	if _head != null:
		_head.rotation.x = lean * 0.3

func reset_lean() -> void:
	for part in [_head, _body, _legs]:
		if part != null:
			part.rotation = Vector3.ZERO
