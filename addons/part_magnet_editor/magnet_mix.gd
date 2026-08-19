@tool
extends Control

## Assembled preview: the shared crate on the floor, Freak snapped into it.

const FLOOR_FROM_BOTTOM := 18.0

var parts: Dictionary = {}
var pose: int = 0
var caption: String = ""

func _ready() -> void:
	custom_minimum_size = Vector2(170, 200)
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
	var plan := CompositeResolver.resolve_slots(parts, textures)
	var side := minf(box.size.x - 24.0, box.size.y - 36.0)
	var s := clampf(side / 420.0, 0.32, 1.05)
	var floor_point := Vector2(box.size.x * 0.5, box.size.y - FLOOR_FROM_BOTTOM)
	draw_line(
		Vector2(12.0, floor_point.y), Vector2(box.size.x - 12.0, floor_point.y),
		Color(0.30, 0.32, 0.38, 1), 1.0
	)
	var positions: Dictionary = plan.get("positions", {})
	var has_body: Texture2D = textures.get(PartSlotType.Value.BODY)
	if has_body == null:
		_draw_crate(s, floor_point)
	for slot in PartSlotType.draw_order_for(parts):
		_draw_part(
			slot, parts.get(slot) as PartDef, textures.get(slot),
			positions.get(slot, Vector2.ZERO), s, floor_point
		)
		if slot == PartSlotType.Value.BODY:
			_draw_crate(s, floor_point)

func _tex_for(part: PartDef) -> Texture2D:
	if part == null:
		return null
	var tex := part.texture_for_pose(pose)
	return tex if tex != null else part.sprite

func _draw_part(
	slot: PartSlotType.Value,
	part: PartDef,
	tex: Texture2D,
	image_pos: Vector2,
	scale: float,
	origin: Vector2
) -> void:
	if tex == null:
		return
	var extra := 0.0
	if pose == 0:
		var spread: Dictionary = CompositeResolver.spread_front_arm(slot, part, tex, image_pos, 1.0)
		image_pos = spread["center"]
		extra = float(spread["extra"])
	var draw_size := tex.get_size() * scale
	var r := Rect2(origin + image_pos * scale - draw_size * 0.5, draw_size)
	if part != null:
		part.draw_transformed(self, tex, r, pose, extra)
	else:
		draw_texture_rect(tex, r, false)

func _draw_crate(scale: float, origin: Vector2) -> void:
	var tex := CompositeResolver.crate_texture()
	if tex == null:
		return
	var draw_size := CompositeResolver.crate_size() * scale
	var r := Rect2(origin + CompositeResolver.crate_position() * scale - draw_size * 0.5, draw_size)
	draw_texture_rect(tex, r, false)
