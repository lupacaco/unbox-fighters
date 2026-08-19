@tool
class_name CompositeResolver
extends RefCounted

## Builds a layered display plan. Parts snap together by magnet points
## (the metal spheres). PNG files stay 200×200. Every part uses the same scale.
##
## The wooden crate is furniture, not a Freak kit. Two drawings stack: the thin
## top rim sits behind the Freak, the box sits in front, so he looks inside.
## The crate bottom sits on the floor. The torso's bottom magnet snaps in.

const PART_WIDTH_PX := 200.0
const PART_HEIGHT_PX := 200.0
const PART_SIZE_PX := 200.0
const CRATE_BACK_PATH := "res://assets/nova-ui/caixote-cima.png"
const CRATE_FRONT_PATH := "res://assets/nova-ui/caixote-baixo.png"
## Wide enough to hold the torso, still inside the card well.
const CRATE_WIDTH := 198.0
## How far the join sits below the crate's top edge, so the Freak looks inside.
const CRATE_JOIN_INSET := 22.0

const DEFAULT_NECK := Vector2(0, -80)
const DEFAULT_SHOULDER_L := Vector2(-64, -46)
const DEFAULT_SHOULDER_R := Vector2(64, -46)
## Bottom of the torso, where it plugs into the crate. Not the crate floor.
const DEFAULT_GROUND := Vector2(0, 22)
const DEFAULT_HEAD_DOWN := Vector2(0, 80)
const DEFAULT_LIMB_UP := Vector2(0, -82)

## Frente: braços um pouco abertos, girando no ímã do ombro (~19°).
const FRONT_ARM_SPREAD := 0.34
## Extra lift above the crate when a head or arm is on the card alone.
const LOOSE_HEAD := Vector2(0, -48)
const LOOSE_ARM_SPREAD := Vector2(52, -24)

static var _crate_back_tex: Texture2D
static var _crate_front_tex: Texture2D

static func display_scale(_texture: Texture2D = null) -> float:
	return PART_SIZE_PX / PART_WIDTH_PX

## Thin top rim. Sits behind the Freak (lower z_index).
static func crate_back_texture() -> Texture2D:
	if _crate_back_tex == null:
		_crate_back_tex = load(CRATE_BACK_PATH) as Texture2D
	return _crate_back_tex

## Box body. Sits in front of the torso (higher z_index).
static func crate_front_texture() -> Texture2D:
	if _crate_front_tex == null:
		_crate_front_tex = load(CRATE_FRONT_PATH) as Texture2D
	return _crate_front_tex

## The main box drawing. Empty cards still need a crate to show.
static func crate_texture() -> Texture2D:
	return crate_front_texture()

static func crate_scale() -> float:
	var width := 1.0
	var back := crate_back_texture()
	var front := crate_front_texture()
	if back != null:
		width = maxf(width, float(back.get_width()))
	if front != null:
		width = maxf(width, float(front.get_width()))
	return CRATE_WIDTH / width

static func crate_size() -> Vector2:
	return Vector2(CRATE_WIDTH, _crate_stack_height())

static func _layer_height(tex: Texture2D) -> float:
	if tex == null:
		return 0.0
	return float(tex.get_height()) * crate_scale()

static func _crate_stack_height() -> float:
	var height := _layer_height(crate_front_texture()) + _layer_height(crate_back_texture())
	return height if height > 0.0 else 154.0

## Center of the stacked crate so its bottom sits on the floor (y = 0).
static func crate_position() -> Vector2:
	return Vector2(0.0, -crate_size().y * 0.5)

## Front box, sitting on the floor.
static func crate_front_position() -> Vector2:
	var height := _layer_height(crate_front_texture())
	if height <= 0.0:
		return crate_position()
	return Vector2(0.0, -height * 0.5)

## Back rim, stacked on top of the front box.
static func crate_back_position() -> Vector2:
	var front_h := _layer_height(crate_front_texture())
	var back_h := _layer_height(crate_back_texture())
	if back_h <= 0.0:
		return crate_position()
	return Vector2(0.0, -(front_h + back_h * 0.5))

## Where the torso's bottom magnet snaps. A little inside the crate's top.
static func crate_join() -> Vector2:
	var top := crate_position().y - crate_size().y * 0.5
	return Vector2(0.0, top + CRATE_JOIN_INSET * crate_scale())

static func crate_back_z(body_z: int) -> int:
	return body_z - 1

static func crate_front_z(body_z: int) -> int:
	return body_z + 1

static func apply_crate_back_to(sprite: Sprite2D, extra_scale: float = 1.0) -> void:
	_apply_crate_layer(sprite, crate_back_texture(), crate_back_position(), extra_scale)

static func apply_crate_front_to(sprite: Sprite2D, extra_scale: float = 1.0) -> void:
	_apply_crate_layer(sprite, crate_front_texture(), crate_front_position(), extra_scale)

static func _apply_crate_layer(
	sprite: Sprite2D, tex: Texture2D, pos: Vector2, extra_scale: float
) -> void:
	if sprite == null:
		return
	sprite.texture = tex
	sprite.visible = tex != null
	sprite.centered = true
	sprite.position = pos * extra_scale
	sprite.scale = Vector2.ONE * crate_scale() * extra_scale

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
	var join := crate_join()
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
		var body_pos := join - _socket(body, "ground", body_tex) * scale
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
		positions[PartSlotType.Value.HEAD] = join + LOOSE_HEAD - _socket(head, "down", head_tex) * scale
		positions[PartSlotType.Value.ARM_L] = (
			join
			+ Vector2(-LOOSE_ARM_SPREAD.x, LOOSE_ARM_SPREAD.y)
			- _socket(arm_l, "up", arm_l_tex) * scale
		)
		positions[PartSlotType.Value.ARM_R] = (
			join + LOOSE_ARM_SPREAD - _socket(arm_r, "up", arm_r_tex) * scale
		)

	return {
		"textures": tex,
		"positions": positions,
		"part_size_px": PART_SIZE_PX,
		"head_pos": positions[PartSlotType.Value.HEAD],
		"body_pos": positions[PartSlotType.Value.BODY],
		"crate_texture": crate_front_texture(),
		"crate_back_texture": crate_back_texture(),
		"crate_front_texture": crate_front_texture(),
		"crate_position": crate_position(),
		"crate_back_position": crate_back_position(),
		"crate_front_position": crate_front_position(),
		"crate_scale": crate_scale(),
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
