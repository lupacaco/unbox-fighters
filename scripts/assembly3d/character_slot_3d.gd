class_name CharacterSlot3D
extends CharacterSlot

## Mesma carta/mecânicas do CharacterSlot, com visual 3D das peças montadas.

var _subviewport: SubViewport
var _host: Model3DHost
var _preview_sprite: Sprite2D

func setup(def: CharacterDef = null, roster: Array[CharacterDef] = []) -> void:
	super.setup(def, roster)
	_ensure_3d_preview()
	_hide_2d_part_sprites()
	_refresh_3d_assembly()

func attached_parts_can_fight() -> bool:
	if not is_complete():
		return false
	for slot in [PartSlotType.Value.HEAD, PartSlotType.Value.BODY, PartSlotType.Value.LEGS]:
		var part := get_attached_part(slot)
		if part == null or not GlbCatalog.has_glb(part.id):
			return false
	return true

func _apply_plan(plan: Dictionary) -> void:
	_hide_2d_part_sprites()
	var complete := is_complete()
	_glow.visible = complete
	_readout.set_complete(complete)
	_empty_hint.visible = not (
		plan.get("head") != null or plan.get("body") != null or plan.get("legs") != null
	)
	_refresh_3d_assembly()

func _hide_2d_part_sprites() -> void:
	_sprite_composite.visible = false
	_sprite_head.visible = false
	_sprite_body.visible = false
	_sprite_legs.visible = false

func _ensure_3d_preview() -> void:
	if _preview_sprite != null:
		return
	_subviewport = SubViewport.new()
	_subviewport.name = "Card3DViewport"
	_subviewport.size = Vector2i(320, 420)
	_subviewport.transparent_bg = true
	_subviewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_subviewport)

	var world := Node3D.new()
	_subviewport.add_child(world)

	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 1.85
	cam.position = Vector3(0.0, 0.55, 3.2)
	cam.current = true
	world.add_child(cam)

	var light := DirectionalLight3D.new()
	light.light_energy = 1.15
	light.rotation_degrees = Vector3(-40.0, -20.0, 0.0)
	world.add_child(light)

	_host = Model3DHost.new()
	_host.name = "Host"
	world.add_child(_host)

	_preview_sprite = Sprite2D.new()
	_preview_sprite.name = "Preview3D"
	_preview_sprite.centered = true
	_preview_sprite.texture = _subviewport.get_texture()
	_preview_sprite.position = Vector2(0, -8)
	_preview_sprite.scale = Vector2.ONE * (150.0 / 160.0)
	_display_root.add_child(_preview_sprite)

func _refresh_3d_assembly() -> void:
	_ensure_3d_preview()
	_host.set_parts(
		get_attached_part(PartSlotType.Value.HEAD),
		get_attached_part(PartSlotType.Value.BODY),
		get_attached_part(PartSlotType.Value.LEGS)
	)
	_host.face_front()
	_preview_sprite.visible = (
		get_attached_part(PartSlotType.Value.HEAD) != null
		or get_attached_part(PartSlotType.Value.BODY) != null
		or get_attached_part(PartSlotType.Value.LEGS) != null
	)
