class_name CompositeResolver
extends RefCounted

## Builds a layered display plan. Parts snap together by magnet points
## (magnet_down of the upper part sticks to magnet_up of the lower part).
## PNG files stay 300×200. PART_SIZE_PX is how big they appear in the game.
## Every part uses the same scale so they all grow equally.

const PART_WIDTH_PX := 300.0
const PART_HEIGHT_PX := 200.0
const PART_SIZE_PX := 250.0
const FEET_DROP_PX := 90.0 * PART_SIZE_PX / 150.0
const BODY_ORIGIN := Vector2(0, -22)

const DEFAULT_BODY_UP := Vector2(0, -70)
const DEFAULT_BODY_DOWN := Vector2(0, 64)
const DEFAULT_HEAD_DOWN := Vector2(0, 74)
const DEFAULT_LEGS_UP := Vector2(0, -68)

static func display_scale(_texture: Texture2D = null) -> float:
	return PART_SIZE_PX / PART_WIDTH_PX

static func resolve(character: CharacterDef, has_head: bool, has_body: bool, has_legs: bool) -> Dictionary:
	if character == null:
		return resolve_parts(null, null, null)
	return resolve_parts(
		character.head if has_head else null,
		character.body if has_body else null,
		character.legs if has_legs else null
	)

static func resolve_parts(
	head: PartDef,
	body: PartDef,
	legs: PartDef,
	head_tex: Texture2D = null,
	body_tex: Texture2D = null,
	legs_tex: Texture2D = null
) -> Dictionary:
	var empty := {
		"mode": "empty",
		"head": null,
		"body": null,
		"legs": null,
		"head_pos": Vector2.ZERO,
		"body_pos": BODY_ORIGIN,
		"legs_pos": Vector2.ZERO,
		"weapon_pos": BODY_ORIGIN,
		"part_size_px": PART_SIZE_PX,
	}

	if head_tex == null and head != null:
		head_tex = head.sprite
	if body_tex == null and body != null:
		body_tex = body.sprite
	if legs_tex == null and legs != null:
		legs_tex = legs.sprite

	if head_tex == null and body_tex == null and legs_tex == null:
		return empty

	var scale := display_scale()
	var body_pos := BODY_ORIGIN
	var body_up := _magnet_up(body, body_tex) * scale
	var body_down := _magnet_down(body, body_tex) * scale
	var head_down := _head_magnet_down(head, head_tex) * scale
	var legs_up := _legs_magnet_up(legs, legs_tex) * scale
	var weapon := _magnet_weapon(body, body_tex) * scale

	return {
		"mode": "layered",
		"head": head_tex,
		"body": body_tex,
		"legs": legs_tex,
		"head_pos": body_pos + body_up - head_down,
		"body_pos": body_pos,
		"legs_pos": body_pos + body_down - legs_up,
		"weapon_pos": body_pos + weapon,
		"part_size_px": PART_SIZE_PX,
	}

static func _magnet_up(body: PartDef, shown: Texture2D) -> Vector2:
	if body != null:
		return body.magnet_up_for(shown)
	return DEFAULT_BODY_UP

static func _magnet_down(body: PartDef, shown: Texture2D) -> Vector2:
	if body != null:
		return body.magnet_down_for(shown)
	return DEFAULT_BODY_DOWN

static func _head_magnet_down(head: PartDef, shown: Texture2D) -> Vector2:
	if head != null:
		return head.magnet_down_for(shown)
	return DEFAULT_HEAD_DOWN

static func _legs_magnet_up(legs: PartDef, shown: Texture2D) -> Vector2:
	if legs != null:
		return legs.magnet_up_for(shown)
	return DEFAULT_LEGS_UP

static func _magnet_weapon(body: PartDef, shown: Texture2D) -> Vector2:
	if body != null:
		return body.magnet_weapon_for(shown)
	return Vector2.ZERO
