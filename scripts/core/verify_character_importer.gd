extends SceneTree

## Checks the include-character pipeline without writing new files.

const SheetSlicer := preload("res://addons/part_magnet_editor/sheet_slicer.gd")
const CharacterImporter := preload("res://addons/part_magnet_editor/character_importer.gd")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	if CharacterImporter.clean_id("Leão") != "leao":
		push_error("VERIFY_FAIL clean_id should turn Leão into leao")
		quit(1)
		return

	for set_id in ["leao", "medico", "vampiro"]:
		var path := "res://data/parts/%s_character.tres" % set_id
		var character := load(path) as CharacterDef
		if character == null:
			push_error("VERIFY_FAIL missing %s" % path)
			quit(1)
			return
		for slot in PartSlotType.visual_slots():
			var part := character.get_part(slot)
			if part == null:
				push_error("VERIFY_FAIL %s missing %s" % [set_id, PartSlotType.to_string_name(slot)])
				quit(1)
				return
			if part.sprite == null or part.sprite_profile == null:
				push_error("VERIFY_FAIL %s %s needs front and profile art" % [set_id, part.id])
				quit(1)
				return

	var tex := load("res://assets/characters/medico/medico.png") as Texture2D
	if tex == null:
		push_error("VERIFY_FAIL could not read the doctor sheet")
		quit(1)
		return
	var sheet := tex.get_image()
	if sheet == null:
		push_error("VERIFY_FAIL doctor sheet has no pixels")
		quit(1)
		return
	if sheet.get_format() != Image.FORMAT_RGBA8:
		sheet.convert(Image.FORMAT_RGBA8)
	var blobs: Array = SheetSlicer._find_blobs(sheet, SheetSlicer._uses_alpha_background(sheet))
	if blobs.size() < 12:
		push_error("VERIFY_FAIL doctor sheet should have at least 12 drawings, got %d" % blobs.size())
		quit(1)
		return
	var named: Dictionary = SheetSlicer._classify(blobs, sheet.get_width(), sheet.get_height())
	if not String(named.get("error", "")).is_empty():
		push_error("VERIFY_FAIL doctor sheet classify: %s" % named["error"])
		quit(1)
		return
	if not named.has("front") or not named.has("profile"):
		push_error("VERIFY_FAIL doctor sheet should split into 6 front + 6 profile")
		quit(1)
		return
	for pose in ["front", "profile"]:
		var group: Dictionary = named[pose]
		if not SheetSlicer._group_complete(group):
			push_error("VERIFY_FAIL doctor sheet did not name all six %s parts" % pose)
			quit(1)
			return
		for slot_name in SheetSlicer.SLOT_NAMES:
			if not group.has(slot_name):
				push_error("VERIFY_FAIL doctor sheet missing %s in %s" % [slot_name, pose])
				quit(1)
				return

	print("VERIFY_CHARACTER_IMPORTER_PASS")
	quit(0)
