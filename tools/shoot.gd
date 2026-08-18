@tool
extends SceneTree

## Opens the match screen in a real window and saves a picture of it, so the
## layout can be looked at without playing. Not part of the game.
##
##     godot --path . --script tools/shoot.gd -- 2.5 tools/checks/screen.png

const DEFAULT_WAIT := 1.5
const DEFAULT_OUT := "res://tools/checks/screen.png"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var wait := float(args[0]) if args.size() > 0 else DEFAULT_WAIT
	var out := String(args[1]) if args.size() > 1 else DEFAULT_OUT
	var packed: PackedScene = load("res://scenes/assembly/Assembly.tscn")
	root.add_child(packed.instantiate())
	await create_timer(wait).timeout
	await process_frame
	var image := root.get_texture().get_image()
	var err := image.save_png(out)
	if err != OK:
		push_error("SHOOT_FAIL %d writing %s" % [err, out])
		quit(1)
		return
	print("SHOOT_OK %s" % out)
	quit(0)
