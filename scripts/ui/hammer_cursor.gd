class_name HammerCursor
extends Object

## Shared hammer mouse cursor for crate hover / hit.
## Hover → hammer-01. Hit → hammer-02 for HIT_SEC, then back to hover or default.

const TEX_IDLE := preload("res://assets/objects/hammer-01.png")
const TEX_HIT := preload("res://assets/objects/hammer-02.png")
## Click point near the hammer head (top-left of the sprite).
const HOTSPOT := Vector2(30, 26)
const HIT_SEC := 0.2

static var _hover_count: int = 0
static var _hitting: bool = false
static var _hit_token: int = 0

static func enter_crate() -> void:
	_hover_count += 1
	_refresh()

static func exit_crate() -> void:
	_hover_count = maxi(_hover_count - 1, 0)
	_refresh()

static func strike() -> void:
	_hitting = true
	_hit_token += 1
	var token := _hit_token
	_apply(TEX_HIT)
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		_hitting = false
		_refresh()
		return
	tree.create_timer(HIT_SEC).timeout.connect(func() -> void:
		if token != _hit_token:
			return
		_hitting = false
		_refresh()
	)

static func clear() -> void:
	_hover_count = 0
	_hitting = false
	_hit_token += 1
	Input.set_custom_mouse_cursor(null)

static func _refresh() -> void:
	if _hitting:
		return
	if _hover_count > 0:
		_apply(TEX_IDLE)
	else:
		Input.set_custom_mouse_cursor(null)

static func _apply(tex: Texture2D) -> void:
	Input.set_custom_mouse_cursor(tex, Input.CURSOR_ARROW, HOTSPOT)
