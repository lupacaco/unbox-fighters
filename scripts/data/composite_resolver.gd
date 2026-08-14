@tool
class_name CompositeResolver
extends RefCounted

## Builds a layered display plan. Parts snap together by magnet points
## (the metal spheres). PNG files stay 200×200. Every part uses the same scale.

const PART_WIDTH_PX := 200.0
const PART_HEIGHT_PX := 200.0
const PART_SIZE_PX := 200.0
const BODY_ORIGIN := Vector2(0, -8)
const _Spring := preload("res://scripts/data/spring_base.gd")

const DEFAULT_NECK := Vector2(0, -70)
const DEFAULT_SHOULDER_L := Vector2(-70, -40)
const DEFAULT_SHOULDER_R := Vector2(70, -40)
const DEFAULT_HIP_L := Vector2(-40, 70)
const DEFAULT_HIP_R := Vector2(40, 70)
const DEFAULT_HEAD_DOWN := Vector2(0, 80)
const DEFAULT_LIMB_UP := Vector2(0, -90)

## Frente: braços um pouco abertos, girando no ímã do ombro (~19°).
const FRONT_ARM_SPREAD := 0.34

static func display_scale(_texture: Texture2D = null) -> float:
	return PART_SIZE_PX / PART_WIDTH_PX

static func resolve(character: CharacterDef, attached: Dictionary = {}) -> Dictionary:
	if character == null:
		return resolve_slots({})
	var parts := {}
	for slot in PartSlotType.visual_slots():
		var include := true
		if attached.has(slot):
			include = bool(attached[slot])
		if include:
			parts[slot] = character.get_part(slot)
	return resolve_slots(parts)

static func resolve_slots(
	parts: Dictionary,
	textures: Dictionary = {},
	spring_pressed: Variant = null
) -> Dictionary:
	var tex := {}
	for slot in PartSlotType.visual_slots():
		if slot == PartSlotType.Value.LEG_L or slot == PartSlotType.Value.LEG_R:
			tex[slot] = null
			continue
		var part: PartDef = parts.get(slot)
		var shown: Texture2D = textures.get(slot)
		if shown == null and part != null:
			shown = part.sprite
		tex[slot] = shown

	var has_part := false
	for slot in tex.keys():
		if tex[slot] != null:
			has_part = true
			break
	var pressed := has_part if spring_pressed == null else bool(spring_pressed)
	var scale := display_scale()
	var spring_pos := _Spring.center_on_ground(pressed)
	var magnet := _Spring.magnet_world(pressed)
	var body: PartDef = parts.get(PartSlotType.Value.BODY)
	var body_tex: Texture2D = tex.get(PartSlotType.Value.BODY)
	var head: PartDef = parts.get(PartSlotType.Value.HEAD)
	var head_tex: Texture2D = tex.get(PartSlotType.Value.HEAD)
	var body_pos := BODY_ORIGIN
	var positions := {
		PartSlotType.Value.BODY: body_pos,
		PartSlotType.Value.HEAD: body_pos,
		PartSlotType.Value.ARM_L: body_pos,
		PartSlotType.Value.ARM_R: body_pos,
		PartSlotType.Value.LEG_L: body_pos,
		PartSlotType.Value.LEG_R: body_pos,
	}
	if body_tex != null:
		body_pos = magnet - _body_sit_offset(body, body_tex) * scale
		positions[PartSlotType.Value.BODY] = body_pos
		positions[PartSlotType.Value.HEAD] = body_pos + (_socket(body, "neck", body_tex) - _socket(head, "down", head_tex)) * scale
		positions[PartSlotType.Value.ARM_L] = body_pos + (_socket(body, "shoulder_l", body_tex) - _socket(parts.get(PartSlotType.Value.ARM_L), "up", tex.get(PartSlotType.Value.ARM_L))) * scale
		positions[PartSlotType.Value.ARM_R] = body_pos + (_socket(body, "shoulder_r", body_tex) - _socket(parts.get(PartSlotType.Value.ARM_R), "up", tex.get(PartSlotType.Value.ARM_R))) * scale
	elif head_tex != null:
		positions[PartSlotType.Value.HEAD] = magnet - _socket(head, "down", head_tex) * scale

	return {
		"mode": "layered",
		"textures": tex,
		"positions": positions,
		"part_size_px": PART_SIZE_PX,
		"head": head_tex,
		"body": body_tex,
		"legs": null,
		"head_pos": positions[PartSlotType.Value.HEAD],
		"body_pos": positions[PartSlotType.Value.BODY],
		"legs_pos": spring_pos,
		"spring_pressed": pressed,
		"spring_pos": spring_pos,
		"spring_scale": _Spring.SCALE,
		"spring_texture": _Spring.texture(pressed),
	}


static func _body_sit_offset(body: PartDef, body_tex: Texture2D) -> Vector2:
	return (_socket(body, "hip_l", body_tex) + _socket(body, "hip_r", body_tex)) * 0.5

static func socket_of(part: PartDef, socket: String, shown: Texture2D) -> Vector2:
	return _socket(part, socket, shown)

static func front_arm_spread(slot: PartSlotType.Value) -> float:
	match slot:
		PartSlotType.Value.ARM_L:
			return FRONT_ARM_SPREAD
		PartSlotType.Value.ARM_R:
			return -FRONT_ARM_SPREAD
		_:
			return 0.0

static func center_after_pivot(center: Vector2, magnet_from_center: Vector2, extra_radians: float) -> Vector2:
	if is_zero_approx(extra_radians):
		return center
	return center + magnet_from_center - magnet_from_center.rotated(extra_radians)

static func spread_front_arm(
	slot: PartSlotType.Value,
	part: PartDef,
	shown: Texture2D,
	center: Vector2,
	scale: float
) -> Dictionary:
	var extra := front_arm_spread(slot)
	if is_zero_approx(extra):
		return {"center": center, "extra": 0.0}
	var magnet := _socket(part, "up", shown) * scale
	return {
		"center": center_after_pivot(center, magnet, extra),
		"extra": extra,
	}

static func _socket(part: PartDef, socket: String, shown: Texture2D) -> Vector2:
	var raw := Vector2.ZERO
	var marked := false
	if part != null:
		var magnet := part.socket_for(socket, shown)
		if magnet.length_squared() > 0.01:
			raw = magnet
			marked = true
	if not marked:
		match socket:
			"neck":
				raw = DEFAULT_NECK
			"shoulder_l":
				raw = DEFAULT_SHOULDER_L
			"shoulder_r":
				raw = DEFAULT_SHOULDER_R
			"hip_l":
				raw = DEFAULT_HIP_L
			"hip_r":
				raw = DEFAULT_HIP_R
			"down":
				raw = DEFAULT_HEAD_DOWN
			_:
				raw = DEFAULT_LIMB_UP
	if part != null:
		return part.magnet_to_visual(raw, part.pose_for_texture(shown))
	return raw
