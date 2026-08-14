class_name Feel
extends Object

## Shared motion for hover, press, drag. No debug rectangles.

const HIDDEN_SHAPE := Color(0, 0, 0, 0)

static func kill_scale(node: Node) -> void:
	if node == null:
		return
	_kill_meta_tween(node, "feel_scale_tween")

static func hide_collision_debug(shape: CollisionShape2D) -> void:
	if shape == null:
		return
	shape.debug_color = HIDDEN_SHAPE

static func to_scale(node: Node, target: Vector2, duration: float = 0.12) -> void:
	if node == null or not is_instance_valid(node):
		return
	_kill_meta_tween(node, "feel_scale_tween")
	var tween := node.create_tween()
	node.set_meta("feel_scale_tween", tween)
	tween.tween_property(node, "scale", target, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

static func punch(node: Node, squash: Vector2 = Vector2(1.14, 0.86), rest: Vector2 = Vector2.ONE) -> void:
	if node == null or not is_instance_valid(node):
		return
	_kill_meta_tween(node, "feel_scale_tween")
	var tween := node.create_tween()
	node.set_meta("feel_scale_tween", tween)
	tween.tween_property(node, "scale", squash, 0.06).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "scale", rest, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

static func wire_button(button: Button) -> void:
	if button == null or bool(button.get_meta("feel_wired", false)):
		return
	button.set_meta("feel_wired", true)
	button.pivot_offset = button.size * 0.5
	button.resized.connect(func() -> void:
		button.pivot_offset = button.size * 0.5
	)
	button.mouse_entered.connect(func() -> void:
		if button.disabled:
			return
		to_scale(button, Vector2.ONE * 1.06, 0.1)
	)
	button.mouse_exited.connect(func() -> void:
		to_scale(button, Vector2.ONE, 0.1)
	)
	button.button_down.connect(func() -> void:
		to_scale(button, Vector2(0.94, 0.94), 0.05)
		GameAudio.ui_click()
	)
	button.button_up.connect(func() -> void:
		to_scale(button, Vector2.ONE * 1.04, 0.08)
	)

static func _kill_meta_tween(node: Node, key: String) -> void:
	var prev: Variant = node.get_meta(key, null)
	if prev is Tween and (prev as Tween).is_valid():
		(prev as Tween).kill()
