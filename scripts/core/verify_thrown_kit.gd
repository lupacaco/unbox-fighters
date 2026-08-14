extends SceneTree

## Thrown kits copy the puppet sprites, hide the kit, and stand farther apart.

const KitThrow := preload("res://scripts/assembly/thrown_kit.gd")
const FightDir := preload("res://scripts/assembly/fight_director.gd")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	assert(FightDir.DUEL_X >= 260.0, "Duelists should stand farther apart for a throw")
	var leao: CharacterDef = load("res://data/parts/leao_character.tres")
	var puppet := FighterPuppet.new()
	root.add_child(puppet)
	puppet.setup_loadout(FighterLoadout.from_character(leao), false)
	puppet.set_pose(FighterPuppet.Pose.PROFILE)
	var head := puppet.sprite_of(PartSlotType.Value.HEAD)
	assert(head != null and head.visible)
	var kit := KitThrow.new()
	root.add_child(kit)
	kit.setup_from_puppet(puppet, PartSlotType.Value.HEAD, false)
	assert(kit.sprite_count() >= 1, "Thrown kit should copy the head drawing")
	puppet.detach_kit(PartSlotType.Value.HEAD)
	assert(not head.visible, "Detached head should leave the body")
	puppet.attach_kit(PartSlotType.Value.HEAD)
	assert(head.visible, "Caught head should return to the body")
	var body_kit := KitThrow.new()
	root.add_child(body_kit)
	body_kit.setup_from_puppet(puppet, PartSlotType.Value.BODY, false)
	assert(body_kit.sprite_count() == 1, "Thrown torso should be only the torso")
	var arm_kit := KitThrow.new()
	root.add_child(arm_kit)
	arm_kit.setup_from_puppet(puppet, PartSlotType.Value.ARM_L, false)
	assert(arm_kit.sprite_count() == 1, "Thrown arm should be only that arm")
	print("VERIFY_THROWN_KIT_PASS duel_x=", FightDir.DUEL_X)
	quit(0)
