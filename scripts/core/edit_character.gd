@tool
extends SceneTree

## Prints or updates one Freak card (name, type, power, Attack, HP).
##
##     godot --headless --path . --script scripts/core/edit_character.gd -- bruxa
##     godot --headless --path . --script scripts/core/edit_character.gd -- bruxa --attack 9 --hp 16

const CharacterEditor := preload("res://addons/part_magnet_editor/character_editor.gd")

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		push_error("usage: godot --headless --path . --script scripts/core/edit_character.gd -- SET_ID [--name N] [--attack N] [--hp N] [--kind human|supernatural|animal] [--ability none|mind_control|appeal]")
		quit(1)
		return
	var set_id := String(args[0])
	var current := CharacterEditor.read(set_id)
	var err := String(current.get("error", ""))
	if not err.is_empty():
		push_error("EDIT_FAIL %s: %s" % [set_id, err])
		quit(1)
		return
	var flags := _parse_flags(args)
	if flags.is_empty():
		print("%s | %s | %s | ATK %d | HP %d | %s" % [
			current["id"],
			current["display_name"],
			current["kind_label"],
			int(current["attack"]),
			int(current["hp"]),
			current["ability_label"],
		])
		quit(0)
		return
	var name := String(flags.get("name", current["display_name"]))
	var attack := int(flags.get("attack", current["attack"]))
	var hp := int(flags.get("hp", current["hp"]))
	var kind_key := FreakKind.storage_key(int(current["kind"]) as FreakKind.Value)
	if flags.has("kind"):
		kind_key = String(flags["kind"])
	var ability_key := FreakAbility.storage_key(int(current["ability"]) as FreakAbility.Value)
	if flags.has("ability"):
		ability_key = String(flags["ability"])
	var err2 := CharacterEditor.save(
		set_id, name, attack, hp, FreakKind.from_string(kind_key), FreakAbility.from_string(ability_key)
	)
	if not err2.is_empty():
		push_error("EDIT_FAIL %s: %s" % [set_id, err2])
		quit(1)
		return
	print("edited %s" % set_id)
	quit(0)

func _parse_flags(args: PackedStringArray) -> Dictionary:
	var flags := {}
	var i := 1
	while i < args.size():
		var key := String(args[i])
		if not key.begins_with("--") or i + 1 >= args.size():
			i += 1
			continue
		flags[key.trim_prefix("--")] = String(args[i + 1])
		i += 2
	return flags
