@tool
extends Control

## Assembled preview of the six drawings snapped at the magnets.

var parts: Dictionary = {}
var pose: int = 0
var caption: String = ""

func _ready() -> void:
	custom_minimum_size = Vector2(280, 260)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func set_mix(next_parts: Dictionary, next_pose: int, next_caption: String) -> void:
	parts = next_parts
	pose = next_pose
	caption = next_caption
	queue_redraw()

func _draw() -> void:
	var box := Rect2(Vector2.ZERO, size)
	draw_rect(box, Color(0.07, 0.07, 0.09, 1), true)
	if not caption.is_empty():
		draw_string(
			ThemeDB.fallback_font,
			Vector2(10, 18),
			caption,
			HORIZONTAL_ALIGNMENT_LEFT,
			size.x - 20,
			13,
			Color(0.82, 0.84, 0.88, 1)
		)
	var textures := {}
	for slot in PartSlotType.visual_slots():
		textures[slot] = _tex_for(parts.get(slot) as PartDef)
	var any := false
	for slot in textures.keys():
		if textures[slot] != null:
			any = true
			break
	if not any:
		return
	var plan := CompositeResolver.resolve_slots(parts, textures)
	var s := 0.55
	var origin := box.get_center() + Vector2(0, 16)
	var positions: Dictionary = plan.get("positions", {})
	for slot in PartSlotType.draw_order():
		_draw_part(textures.get(slot), positions.get(slot, Vector2.ZERO), s, origin, box)

func _tex_for(part: PartDef) -> Texture2D:
	if part == null:
		return null
	var tex := part.texture_for_pose(pose)
	return tex if tex != null else part.sprite

func _draw_part(tex: Texture2D, image_pos: Vector2, scale: float, origin: Vector2, box: Rect2) -> void:
	if tex == null:
		return
	var size := tex.get_size() * scale
	var r := Rect2(origin + image_pos * scale - size * 0.5, size)
	if not box.intersects(r):
		return
	draw_texture_rect(tex, r, false)
