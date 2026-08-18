@tool
class_name CompositeResolver
extends RefCounted

## Builds a layered display plan. Parts snap together by magnet points
## (the metal spheres). PNG files stay 200×200. Every part uses the same scale.
##
## The floor anchor is the base of the torso crate, so the Freak stands wherever
## the caller asks: on the card ledge, on the belt rollers, anywhere.

const PART_WIDTH_PX := 200.0
const PART_HEIGHT_PX := 200.0
const PART_SIZE_PX := 200.0

const DEFAULT_NECK := Vector2(0, -80)
const DEFAULT_SHOULDER_L := Vector2(-64, -46)
const DEFAULT_SHOULDER_R := Vector2(64, -46)
## The crate rests on the bottom edge of the 200×200 drawing.
const DEFAULT_GROUND := Vector2(0, 99)
const DEFAULT_HEAD_DOWN := Vector2(0, 80)
const DEFAULT_LIMB_UP := Vector2(0, -82)

## Frente: braços um pouco abertos, girando no ímã do ombro (~19°).
const FRONT_ARM_SPREAD := 0.34
## Where a lone head or a lone arm hangs when there is no torso yet.
const LOOSE_HEAD := Vector2(0, -60)
const LOOSE_ARM_SPREAD := Vector2(52, -30)

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

## `parts` and `textures` are keyed by PartSlotType.Value.
## Positions come back relative to the point where the crate touches the floor.
static func resolve_slots(parts: Dictionary, textures: Dictionary = {}) -> Dictionary:
	var tex := {}
	for slot in PartSlotType.visual_slots():
		var part: PartDef = parts.get(slot)
		var shown: Texture2D = textures.get(slot)
		if shown == null and part != null:
			shown = part.sprite
		tex[slot] = shown

	var scale := display_scale()
	var body: PartDef = parts.get(PartSlotType.Value.BODY)
	var body_tex: Texture2D = tex.get(PartSlotType.Value.BODY)
	var head: PartDef = parts.get(PartSlotType.Value.HEAD)
	var head_tex: Texture2D = tex.get(PartSlotType.Value.HEAD)
	var arm_l: PartDef = parts.get(PartSlotType.Value.ARM_L)
	var arm_r: PartDef = parts.get(PartSlotType.Value.ARM_R)
	var arm_l_tex: Texture2D = tex.get(PartSlotType.Value.ARM_L)
	var arm_r_tex: Texture2D = tex.get(PartSlotType.Value.ARM_R)

	var positions := {}
	if body_tex != null:
		var body_pos := -_socket(body, "ground", body_tex) * scale
		positions[PartSlotType.Value.BODY] = body_pos
		positions[PartSlotType.Value.HEAD] = body_pos + (
			_socket(body, "neck", body_tex) - _socket(head, "down", head_tex)
		) * scale
		positions[PartSlotType.Value.ARM_L] = body_pos + (
			_socket(body, "shoulder_l", body_tex) - _socket(arm_l, "up", arm_l_tex)
		) * scale
		positions[PartSlotType.Value.ARM_R] = body_pos + (
			_socket(body, "shoulder_r", body_tex) - _socket(arm_r, "up", arm_r_tex)
		) * scale
	else:
		positions[PartSlotType.Value.BODY] = Vector2.ZERO
		positions[PartSlotType.Value.HEAD] = LOOSE_HEAD - _socket(head, "down", head_tex) * scale
		positions[PartSlotType.Value.ARM_L] = (
			Vector2(-LOOSE_ARM_SPREAD.x, LOOSE_ARM_SPREAD.y)
			- _socket(arm_l, "up", arm_l_tex) * scale
		)
		positions[PartSlotType.Value.ARM_R] = (
			LOOSE_ARM_SPREAD - _socket(arm_r, "up", arm_r_tex) * scale
		)

	return {
		"textures": tex,
		"positions": positions,
		"part_size_px": PART_SIZE_PX,
		"head_pos": positions[PartSlotType.Value.HEAD],
		"body_pos": positions[PartSlotType.Value.BODY],
	}

## Top of the assembled Freak, measured up from the floor. Used to fit a card.
static func stack_height(parts: Dictionary, textures: Dictionary = {}) -> float:
	var plan := resolve_slots(parts, textures)
	var tex: Dictionary = plan["textures"]
	var positions: Dictionary = plan["positions"]
	var top := 0.0
	var bottom := 0.0
	var any := false
	var half := PART_SIZE_PX * display_scale() * 0.5
	for slot in PartSlotType.visual_slots():
		if tex.get(slot) == null:
			continue
		var centre: Vector2 = positions.get(slot, Vector2.ZERO)
		top = minf(top, centre.y - half) if any else centre.y - half
		bottom = maxf(bottom, centre.y + half) if any else centre.y + half
		any = true
	return bottom - top if any else 0.0

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

static func default_socket(socket: String) -> Vector2:
	match socket:
		"neck":
			return DEFAULT_NECK
		"shoulder_l":
			return DEFAULT_SHOULDER_L
		"shoulder_r":
			return DEFAULT_SHOULDER_R
		"ground":
			return DEFAULT_GROUND
		"down":
			return DEFAULT_HEAD_DOWN
		_:
			return DEFAULT_LIMB_UP

static func _socket(part: PartDef, socket: String, shown: Texture2D) -> Vector2:
	var raw := default_socket(socket)
	if part != null:
		var magnet := part.socket_for(socket, shown)
		if magnet.length_squared() > 0.01:
			raw = magnet
		return part.magnet_to_visual(raw, part.pose_for_texture(shown))
	return raw
