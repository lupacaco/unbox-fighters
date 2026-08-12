class_name PartView3D
extends PartView

## Igual ao PartView (arrastar/soltar), mas o desenho é o GLB 3D de frente.

var _subviewport: SubViewport
var _host: Model3DHost

func setup(def: PartDef, drag_service: DragDropService) -> void:
	part_def = def
	_drag_service = drag_service
	_ensure_viewport()
	_host.set_single_part(def)
	_sprite.texture = _subviewport.get_texture()
	_shadow.texture = _subviewport.get_texture()
	_shadow.modulate = Color(0, 0, 0, 0.35)
	_shadow.position = Vector2(8, 14)
	_fit_visuals_3d()
	_start_idle_float()

func _fit_visuals_3d() -> void:
	var target := 168.0
	var s := target / 256.0
	_sprite.scale = Vector2.ONE * s
	_shadow.scale = Vector2.ONE * s
	var shape := RectangleShape2D.new()
	shape.size = Vector2(target, target) * 0.82
	_collision.shape = shape
	_plate.polygon = PackedVector2Array([
		Vector2(-58, 48), Vector2(58, 48), Vector2(48, 68), Vector2(-48, 68)
	])
	_plate.color = Color(0, 0, 0, 0.3)
	_glow.polygon = PackedVector2Array([
		Vector2(-70, -70), Vector2(70, -70), Vector2(70, 70), Vector2(-70, 70)
	])
	_glow.color = Color(0.77, 0.12, 0.23, 0.0)

func _ensure_viewport() -> void:
	if _subviewport != null:
		return
	_subviewport = SubViewport.new()
	_subviewport.name = "Part3DViewport"
	_subviewport.size = Vector2i(256, 256)
	_subviewport.transparent_bg = true
	_subviewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_subviewport)

	var world := Node3D.new()
	world.name = "World"
	_subviewport.add_child(world)

	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 1.15
	cam.position = Vector3(0.0, 0.35, 2.5)
	cam.current = true
	world.add_child(cam)

	var light := DirectionalLight3D.new()
	light.light_energy = 1.1
	light.rotation_degrees = Vector3(-35.0, -25.0, 0.0)
	world.add_child(light)

	_host = Model3DHost.new()
	_host.name = "Host"
	_host.position = Vector3(0.0, 0.0, 0.0)
	world.add_child(_host)
