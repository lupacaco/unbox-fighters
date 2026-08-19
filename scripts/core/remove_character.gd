@tool
extends SceneTree

## Deletes one Freak completely (drawings, folder, shop cards).
##
##     godot --headless --path . --script scripts/core/remove_character.gd -- medico

const CharacterRemover := preload("res://addons/part_magnet_editor/character_remover.gd")

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		push_error("usage: godot --headless --path . --script scripts/core/remove_character.gd -- SET_ID")
		quit(1)
		return
	var set_id := String(args[0])
	var err := CharacterRemover.remove(set_id)
	if not err.is_empty():
		push_error("REMOVE_FAIL %s: %s" % [set_id, err])
		quit(1)
		return
	print("removed %s" % set_id)
	quit(0)
