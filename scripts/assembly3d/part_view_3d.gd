class_name PartView3D
extends PartView

## Same tray piece as 2D, but the picture is a 3D model.

var _host: Model3DHost

func setup(def: PartDef, drag_service: DragDropService) -> void:
	super.setup(def, drag_service)
	_sprite.visible = false
	if _host != null:
		_host.queue_free()
		_host = null
	var path := GlbCatalog.path_for(def)
	if path == "":
		_sprite.visible = true
		return
	_host = Model3DHost.new()
	_host.name = "Model3D"
	add_child(_host)
	_host.setup(path, 168.0)
	_start_idle_float()

func _start_idle_float() -> void:
	_stop_idle_float()
	if not visible or _dragging:
		return
	var target: Node2D = _host if _host != null else _sprite
	_float_tween = create_tween().set_loops()
	_float_tween.tween_property(target, "position:y", -2.5, 1.6).set_trans(Tween.TRANS_SINE)
	_float_tween.tween_property(target, "position:y", 2.5, 1.6).set_trans(Tween.TRANS_SINE)

func _stop_idle_float() -> void:
	if _float_tween != null and _float_tween.is_valid():
		_float_tween.kill()
	if _host != null:
		_host.position.y = 0.0
	if _sprite != null:
		_sprite.position.y = 0.0
