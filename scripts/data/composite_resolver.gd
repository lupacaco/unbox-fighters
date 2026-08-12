class_name CompositeResolver
extends RefCounted

## Builds a layered display plan. Parts snap together by magnet points
## (magnet_down of the upper part sticks to magnet_up of the lower part).

const BODY_ORIGIN := Vector2(0, -8)
const PART_SIZE_PX := 150.0

static func resolve(character: CharacterDef, has_head: bool, has_body: bool, has_legs: bool) -> Dictionary:
	var empty := {
		"mode": "empty",
		"head": null,
		"body": null,
		"legs": null,
		"head_pos": Vector2.ZERO,
		"body_pos": BODY_ORIGIN,
		"legs_pos": Vector2.ZERO,
		"part_size_px": PART_SIZE_PX,
	}
	if character == null:
		return empty

	var head_tex: Texture2D = character.head.sprite if has_head and character.head != null else null
	var body_tex: Texture2D = character.body.sprite if has_body and character.body != null else null
	var legs_tex: Texture2D = character.legs.sprite if has_legs and character.legs != null else null

	if head_tex == null and body_tex == null and legs_tex == null:
		return empty

	var body_pos := BODY_ORIGIN
	var head_pos := Vector2(0, -138)
	var legs_pos := Vector2(0, 118)

	if body_tex != null and character.body != null:
		var body_scale := _scale_for(body_tex, PART_SIZE_PX)
		if head_tex != null and character.head != null:
			var head_scale := _scale_for(head_tex, PART_SIZE_PX)
			# body.magnet_up snaps to head.magnet_down
			var body_up := character.body.magnet_up * body_scale
			var head_down := character.head.magnet_down * head_scale
			head_pos = body_pos + body_up - head_down
		if legs_tex != null and character.legs != null:
			var legs_scale := _scale_for(legs_tex, PART_SIZE_PX)
			# body.magnet_down snaps to legs.magnet_up
			var body_down := character.body.magnet_down * body_scale
			var legs_up := character.legs.magnet_up * legs_scale
			legs_pos = body_pos + body_down - legs_up
	elif head_tex != null and legs_tex == null:
		head_pos = Vector2(0, -80)
	elif legs_tex != null and head_tex == null:
		legs_pos = Vector2(0, 80)

	return {
		"mode": "layered",
		"head": head_tex,
		"body": body_tex,
		"legs": legs_tex,
		"head_pos": head_pos,
		"body_pos": body_pos,
		"legs_pos": legs_pos,
		"part_size_px": PART_SIZE_PX,
	}

static func _scale_for(texture: Texture2D, target_px: float) -> float:
	var tex_size := texture.get_size()
	return target_px / maxf(maxf(tex_size.x, tex_size.y), 1.0)
