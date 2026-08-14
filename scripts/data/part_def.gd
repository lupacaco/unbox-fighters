@tool
class_name PartDef
extends Resource

@export var id: StringName
@export var display_name: String = ""
@export var slot_type: PartSlotType.Value = PartSlotType.Value.HEAD
@export var set_id: StringName
@export var sprite: Texture2D
## Side view used on the fight stage (pose "-2").
@export var sprite_profile: Texture2D
## Attack pose. Optional; the side view is used if this is empty.
@export var sprite_attack: Texture2D
@export var combat_value: int = 0
@export var tier: int = 1
## 1 = in front. Lower number draws on top of a higher number.
@export var draw_z: int = 0
@export var flip_h: bool = false
@export var flip_h_profile: bool = false
@export var rotation_degrees: int = 0
@export var rotation_degrees_profile: int = 0

## Magnet points in texture pixels, from the sprite CENTER.
## Y negative = up on the image. Y positive = down on the image.
@export var magnet_up: Vector2 = Vector2.ZERO
@export var magnet_down: Vector2 = Vector2.ZERO
@export var magnet_up_profile: Vector2 = Vector2.ZERO
@export var magnet_down_profile: Vector2 = Vector2.ZERO
## Torso hub: neck, two shoulders, two hips.
@export var magnet_neck: Vector2 = Vector2.ZERO
@export var magnet_shoulder_l: Vector2 = Vector2.ZERO
@export var magnet_shoulder_r: Vector2 = Vector2.ZERO
@export var magnet_hip_l: Vector2 = Vector2.ZERO
@export var magnet_hip_r: Vector2 = Vector2.ZERO
@export var magnet_neck_profile: Vector2 = Vector2.ZERO
@export var magnet_shoulder_l_profile: Vector2 = Vector2.ZERO
@export var magnet_shoulder_r_profile: Vector2 = Vector2.ZERO
@export var magnet_hip_l_profile: Vector2 = Vector2.ZERO
@export var magnet_hip_r_profile: Vector2 = Vector2.ZERO

static func tier_for(value: int) -> int:
	if value <= 5:
		return 1
	if value == 6:
		return 2
	if value == 7:
		return 3
	if value == 8:
		return 4
	return 5

func is_torso() -> bool:
	return slot_type == PartSlotType.Value.BODY

func is_legs_kit() -> bool:
	return slot_type == PartSlotType.Value.LEGS

func uses_hub_sockets() -> bool:
	return is_torso() and magnet_neck.length_squared() > 0.01

func uses_magnet_up() -> bool:
	return (
		slot_type == PartSlotType.Value.ARM_L
		or slot_type == PartSlotType.Value.ARM_R
		or slot_type == PartSlotType.Value.LEG_L
		or slot_type == PartSlotType.Value.LEG_R
	)

func uses_magnet_down() -> bool:
	return slot_type == PartSlotType.Value.HEAD

func socket_names() -> PackedStringArray:
	if is_torso():
		return PackedStringArray(["neck", "shoulder_l", "shoulder_r", "hip_l", "hip_r"])
	if slot_type == PartSlotType.Value.HEAD:
		return PackedStringArray(["down"])
	if uses_magnet_up():
		return PackedStringArray(["up"])
	return PackedStringArray()

func has_fight_poses() -> bool:
	if is_legs_kit():
		return true
	return sprite_profile != null

func profile_magnets_marked() -> bool:
	if is_torso():
		return (
			magnet_neck_profile.length_squared() > 0.01
			or magnet_shoulder_l_profile.length_squared() > 0.01
			or magnet_shoulder_r_profile.length_squared() > 0.01
			or magnet_hip_l_profile.length_squared() > 0.01
			or magnet_hip_r_profile.length_squared() > 0.01
		)
	return magnet_up_profile.length_squared() > 0.01 or magnet_down_profile.length_squared() > 0.01

func magnet_up_for(shown: Texture2D) -> Vector2:
	if shown != null and shown == sprite_profile and magnet_up_profile.length_squared() > 0.01:
		return magnet_up_profile
	return magnet_up

func magnet_down_for(shown: Texture2D) -> Vector2:
	if shown != null and shown == sprite_profile and magnet_down_profile.length_squared() > 0.01:
		return magnet_down_profile
	return magnet_down

func socket_for(socket: String, shown: Texture2D) -> Vector2:
	var profile := shown != null and shown == sprite_profile and profile_magnets_marked()
	match socket:
		"up":
			return magnet_up_for(shown)
		"down":
			return magnet_down_for(shown)
		"neck":
			return magnet_neck_profile if profile else magnet_neck
		"shoulder_l":
			return magnet_shoulder_l_profile if profile else magnet_shoulder_l
		"shoulder_r":
			return magnet_shoulder_r_profile if profile else magnet_shoulder_r
		"hip_l":
			return magnet_hip_l_profile if profile else magnet_hip_l
		"hip_r":
			return magnet_hip_r_profile if profile else magnet_hip_r
		_:
			return Vector2.ZERO

func set_socket(socket: String, pose: int, magnet: Vector2) -> void:
	var profile := pose == 1
	match socket:
		"up":
			if profile:
				magnet_up_profile = magnet
			else:
				magnet_up = magnet
		"down":
			if profile:
				magnet_down_profile = magnet
			else:
				magnet_down = magnet
		"neck":
			if profile:
				magnet_neck_profile = magnet
			else:
				magnet_neck = magnet
		"shoulder_l":
			if profile:
				magnet_shoulder_l_profile = magnet
			else:
				magnet_shoulder_l = magnet
		"shoulder_r":
			if profile:
				magnet_shoulder_r_profile = magnet
			else:
				magnet_shoulder_r = magnet
		"hip_l":
			if profile:
				magnet_hip_l_profile = magnet
			else:
				magnet_hip_l = magnet
		"hip_r":
			if profile:
				magnet_hip_r_profile = magnet
			else:
				magnet_hip_r = magnet

func texture_for_pose(pose: int) -> Texture2D:
	if pose == 1:
		return sprite_profile
	if pose == 2:
		return sprite_attack
	return sprite

func pose_for_texture(shown: Texture2D) -> int:
	if shown != null and shown == sprite_profile:
		return 1
	return 0

func flip_h_for(pose: int) -> bool:
	return flip_h_profile if pose == 1 else flip_h

func set_flip_h_for(pose: int, on: bool) -> void:
	if pose == 1:
		flip_h_profile = on
	else:
		flip_h = on

func rotation_for(pose: int) -> int:
	var raw := rotation_degrees_profile if pose == 1 else rotation_degrees
	return posmod(raw, 360)

func rotate_cw_90(pose: int) -> void:
	if pose == 1:
		rotation_degrees_profile = posmod(rotation_degrees_profile + 90, 360)
	else:
		rotation_degrees = posmod(rotation_degrees + 90, 360)

func effective_draw_z() -> int:
	if draw_z >= 1:
		return clampi(draw_z, 1, 9)
	return PartSlotType.default_draw_z(slot_type)

func godot_z() -> int:
	return 16 - effective_draw_z()

func magnet_to_visual(magnet: Vector2, pose: int) -> Vector2:
	var visual := magnet
	if flip_h_for(pose):
		visual.x = -visual.x
	var deg := rotation_for(pose)
	if deg != 0:
		visual = visual.rotated(deg_to_rad(float(deg)))
	return visual

func visual_to_magnet(visual: Vector2, pose: int) -> Vector2:
	var magnet := visual
	var deg := rotation_for(pose)
	if deg != 0:
		magnet = magnet.rotated(-deg_to_rad(float(deg)))
	if flip_h_for(pose):
		magnet.x = -magnet.x
	return magnet

func apply_to_sprite(sprite: Sprite2D, shown: Texture2D) -> void:
	if sprite == null:
		return
	var pose := pose_for_texture(shown)
	sprite.flip_h = flip_h_for(pose)
	sprite.rotation_degrees = float(rotation_for(pose))
	sprite.z_index = godot_z()

func draw_transformed(ci: CanvasItem, tex: Texture2D, dest: Rect2, pose: int) -> void:
	if ci == null or tex == null:
		return
	var xf := Transform2D(0.0, dest.get_center())
	xf *= Transform2D(deg_to_rad(float(rotation_for(pose))), Vector2.ZERO)
	if flip_h_for(pose):
		xf *= Transform2D(Vector2(-1, 0), Vector2(0, 1), Vector2.ZERO)
	ci.draw_set_transform_matrix(xf)
	ci.draw_texture_rect(tex, Rect2(-dest.size * 0.5, dest.size), false)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _validate_property(property: Dictionary) -> void:
	var name := String(property.name)
	if is_legs_kit() and (name.begins_with("magnet_") or name.begins_with("sprite")):
		property.usage = PROPERTY_USAGE_NO_EDITOR
		return
	if name.begins_with("magnet_") and name.contains("profile"):
		property.usage = PROPERTY_USAGE_NO_EDITOR
		return
	if name in ["flip_h_profile", "rotation_degrees_profile"]:
		property.usage = PROPERTY_USAGE_NO_EDITOR
		return
	if name in ["magnet_neck", "magnet_shoulder_l", "magnet_shoulder_r", "magnet_hip_l", "magnet_hip_r"]:
		if not is_torso():
			property.usage = PROPERTY_USAGE_NO_EDITOR
		return
	match name:
		"magnet_up":
			if slot_type == PartSlotType.Value.HEAD or is_torso():
				property.usage = PROPERTY_USAGE_NO_EDITOR
		"magnet_down":
			if slot_type != PartSlotType.Value.HEAD:
				property.usage = PROPERTY_USAGE_NO_EDITOR
