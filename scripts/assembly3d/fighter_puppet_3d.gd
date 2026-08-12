class_name FighterPuppet3D
extends Node2D

## On-stage fighter for the 3D test. Same layout as 2D, models rotate for profile.

const PART_SIZE_PX := 170.0

var _head_def: PartDef
var _body_def: PartDef
var _legs_def: PartDef
var _pose: FighterPuppet.Pose = FighterPuppet.Pose.FRONT

var _legs: Model3DHost
var _body: Model3DHost
var _head: Model3DHost

func setup_parts(head: PartDef, body: PartDef, legs: PartDef) -> void:
	_head_def = head
	_body_def = body
	_legs_def = legs
	_ensure_hosts()
	_pose = FighterPuppet.Pose.FRONT
	_refresh_layout()
	_apply_pose()

func set_pose(pose: FighterPuppet.Pose) -> void:
	_pose = pose
	_apply_pose()

func set_stride_frame(use_attack: bool) -> void:
	_pose = FighterPuppet.Pose.STRIDE
	_apply_pose()
	for host in [_legs, _body, _head]:
		if host != null:
			host.set_stride_lean(use_attack)

func set_attacking(slot: Variant) -> void:
	_apply_pose()
	if slot == null:
		return
	var host := get_part_node(slot as PartSlotType.Value)
	if host != null:
		host.set_stride_lean(true)

func get_part_node(slot: PartSlotType.Value) -> Node2D:
	match slot:
		PartSlotType.Value.HEAD:
			return _head
		PartSlotType.Value.BODY:
			return _body
		_:
			return _legs

func _ensure_hosts() -> void:
	if _legs != null:
		return
	_legs = _make_host(_legs_def, "Legs", 0)
	_body = _make_host(_body_def, "Body", 1)
	_head = _make_host(_head_def, "Head", 2)

func _make_host(part: PartDef, node_name: String, z: int) -> Model3DHost:
	var host := Model3DHost.new()
	host.name = node_name
	host.z_index = z
	add_child(host)
	var path := GlbCatalog.path_for(part)
	if path != "":
		host.setup(path, PART_SIZE_PX)
	return host

func _refresh_layout() -> void:
	var plan := CompositeResolver.resolve_parts(_head_def, _body_def, _legs_def)
	if _legs != null:
		_legs.position = plan["legs_pos"]
		_legs.set_display_px(PART_SIZE_PX)
	if _body != null:
		_body.position = plan["body_pos"]
		_body.set_display_px(PART_SIZE_PX)
	if _head != null:
		_head.position = plan["head_pos"]
		_head.set_display_px(PART_SIZE_PX)

func _apply_pose() -> void:
	var profile := _pose != FighterPuppet.Pose.FRONT
	for host in [_legs, _body, _head]:
		if host != null:
			host.set_profile(profile)
