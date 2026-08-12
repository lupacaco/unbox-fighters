class_name CharacterSlot3D
extends CharacterSlot

## Same card as 2D. Mounted parts are drawn as 3D models (front on the card).

var _hosts: Dictionary = {}

func attached_parts_can_fight() -> bool:
	if not is_complete():
		return false
	for slot in [PartSlotType.Value.HEAD, PartSlotType.Value.BODY, PartSlotType.Value.LEGS]:
		var part := get_attached_part(slot)
		if part == null:
			return false
		if GlbCatalog.has_model(part) or part.has_fight_poses():
			continue
		return false
	return true

func _apply_plan(plan: Dictionary) -> void:
	_sprite_composite.visible = false
	_sprite_head.visible = false
	_sprite_body.visible = false
	_sprite_legs.visible = false
	var size_px: float = float(plan.get("part_size_px", PART_SIZE_PX))
	_place_3d(PartSlotType.Value.LEGS, get_attached_part(PartSlotType.Value.LEGS), plan["legs_pos"], size_px, 0)
	_place_3d(PartSlotType.Value.BODY, get_attached_part(PartSlotType.Value.BODY), plan["body_pos"], size_px, 1)
	_place_3d(PartSlotType.Value.HEAD, get_attached_part(PartSlotType.Value.HEAD), plan["head_pos"], size_px, 2)

func _place_3d(slot: PartSlotType.Value, part: PartDef, pos: Vector2, size_px: float, z: int) -> void:
	var path := GlbCatalog.path_for(part)
	if path == "":
		if _hosts.has(slot):
			(_hosts[slot] as Model3DHost).visible = false
		return
	var host: Model3DHost = _hosts.get(slot) as Model3DHost
	if host == null:
		host = Model3DHost.new()
		host.name = "Host_%s" % str(slot)
		_display_root.add_child(host)
		_hosts[slot] = host
		host.setup(path, size_px)
	host.visible = true
	host.z_index = z
	host.position = pos
	host.set_display_px(size_px)
	host.set_profile(false)
