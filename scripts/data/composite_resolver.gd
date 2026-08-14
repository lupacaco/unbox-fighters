class_name CompositeResolver
extends RefCounted

## Builds a layered display plan. Parts snap together by magnet points
## (the metal spheres). PNG files stay 200×200. Every part uses the same scale.

const PART_WIDTH_PX := 200.0
const PART_HEIGHT_PX := 200.0
const PART_SIZE_PX := 200.0
const FEET_DROP_PX := 90.0 * PART_SIZE_PX / 150.0
const BODY_ORIGIN := Vector2(0, -8)

const DEFAULT_NECK := Vector2(0, -70)
const DEFAULT_SHOULDER_L := Vector2(-70, -40)
const DEFAULT_SHOULDER_R := Vector2(70, -40)
const DEFAULT_HIP_L := Vector2(-40, 70)
const DEFAULT_HIP_R := Vector2(40, 70)
const DEFAULT_HEAD_DOWN := Vector2(0, 80)
const DEFAULT_LIMB_UP := Vector2(0, -90)

static func display_scale(_texture: Texture2D = null) -> float:
	return PART_SIZE_PX / PART_WIDTH_PX

static func resolve(character: CharacterDef, attached: Dictionary = {}) -> Dictionary:
	if character == null:
		return resolve_slots({})
	var parts := {}
	for slot in PartSlotType.all_slots():
		var include := true
		if attached.has(slot):
			include = bool(attached[slot])
		if include:
			parts[slot] = character.get_part(slot)
	return resolve_slots(parts)

static func resolve_slots(parts: Dictionary, textures: Dictionary = {}) -> Dictionary:
	var empty := {
		"mode": "empty",
		"textures": {},
		"positions": {},
		"part_size_px": PART_SIZE_PX,
	}
	var tex := {}
	for slot in PartSlotType.all_slots():
		var part: PartDef = parts.get(slot)
		var shown: Texture2D = textures.get(slot)
		if shown == null and part != null:
			shown = part.sprite
		tex[slot] = shown

	var any := false
	for slot in tex.keys():
		if tex[slot] != null:
			any = true
			break
	if not any:
		return empty

	var scale := display_scale()
	var body: PartDef = parts.get(PartSlotType.Value.BODY)
	var body_tex: Texture2D = tex.get(PartSlotType.Value.BODY)
	var body_pos := BODY_ORIGIN
	var positions := {PartSlotType.Value.BODY: body_pos}

	positions[PartSlotType.Value.HEAD] = body_pos + (_socket(body, "neck", body_tex) - _socket(parts.get(PartSlotType.Value.HEAD), "down", tex.get(PartSlotType.Value.HEAD))) * scale
	positions[PartSlotType.Value.ARM_L] = body_pos + (_socket(body, "shoulder_l", body_tex) - _socket(parts.get(PartSlotType.Value.ARM_L), "up", tex.get(PartSlotType.Value.ARM_L))) * scale
	positions[PartSlotType.Value.ARM_R] = body_pos + (_socket(body, "shoulder_r", body_tex) - _socket(parts.get(PartSlotType.Value.ARM_R), "up", tex.get(PartSlotType.Value.ARM_R))) * scale
	positions[PartSlotType.Value.LEG_L] = body_pos + (_socket(body, "hip_l", body_tex) - _socket(parts.get(PartSlotType.Value.LEG_L), "up", tex.get(PartSlotType.Value.LEG_L))) * scale
	positions[PartSlotType.Value.LEG_R] = body_pos + (_socket(body, "hip_r", body_tex) - _socket(parts.get(PartSlotType.Value.LEG_R), "up", tex.get(PartSlotType.Value.LEG_R))) * scale

	return {
		"mode": "layered",
		"textures": tex,
		"positions": positions,
		"part_size_px": PART_SIZE_PX,
		"head": tex.get(PartSlotType.Value.HEAD),
		"body": tex.get(PartSlotType.Value.BODY),
		"legs": tex.get(PartSlotType.Value.LEG_L),
		"head_pos": positions[PartSlotType.Value.HEAD],
		"body_pos": body_pos,
		"legs_pos": positions[PartSlotType.Value.LEG_L],
	}

static func _socket(part: PartDef, socket: String, shown: Texture2D) -> Vector2:
	if part != null:
		var magnet := part.socket_for(socket, shown)
		if magnet.length_squared() > 0.01:
			return magnet
	match socket:
		"neck":
			return DEFAULT_NECK
		"shoulder_l":
			return DEFAULT_SHOULDER_L
		"shoulder_r":
			return DEFAULT_SHOULDER_R
		"hip_l":
			return DEFAULT_HIP_L
		"hip_r":
			return DEFAULT_HIP_R
		"down":
			return DEFAULT_HEAD_DOWN
		_:
			return DEFAULT_LIMB_UP
