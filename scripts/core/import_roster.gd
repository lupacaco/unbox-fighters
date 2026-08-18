@tool
extends SceneTree

## Rebuilds data/parts from what is already in assets/characters.
##
## Every Freak folder with a `<id>_slice.json` becomes five kit files plus the
## character card. Run it after cutting a new sheet with tools/slice_character_sheet.py:
##
##     godot --headless --path . --script scripts/core/import_roster.gd

const CharacterImporter := preload("res://addons/part_magnet_editor/character_importer.gd")
const CHARACTERS_DIR := "res://assets/characters"

func _init() -> void:
	var reports := _find_reports()
	if reports.is_empty():
		push_error("IMPORT_FAIL no *_slice.json under %s" % CHARACTERS_DIR)
		quit(1)
		return
	var failures := 0
	for report in reports:
		var err := _import(report)
		if err.is_empty():
			print("ok %s" % report["id"])
		else:
			push_error("IMPORT_FAIL %s: %s" % [report["id"], err])
			failures += 1
	print("imported %d of %d" % [reports.size() - failures, reports.size()])
	quit(1 if failures > 0 else 0)

func _find_reports() -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	var dir := DirAccess.open(CHARACTERS_DIR)
	if dir == null:
		return found
	for set_id in dir.get_directories():
		var path := "%s/%s/%s_slice.json" % [CHARACTERS_DIR, set_id, set_id]
		if not FileAccess.file_exists(path):
			continue
		var file := FileAccess.open(path, FileAccess.READ)
		if file == null:
			continue
		var parsed: Variant = JSON.parse_string(file.get_as_text())
		if typeof(parsed) != TYPE_DICTIONARY:
			push_error("IMPORT_FAIL unreadable %s" % path)
			continue
		var report: Dictionary = parsed
		report["id"] = set_id
		found.append(report)
	found.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return String(a["id"]) < String(b["id"])
	)
	return found

func _import(report: Dictionary) -> String:
	var set_id := String(report["id"])
	var display_name := String(report.get("display_name", set_id.capitalize()))
	var stats: Dictionary = report.get("stats", {})
	var values := [
		int(stats.get("power", PartStats.POWER_MIN)),
		int(stats.get("toughness", PartStats.TOUGHNESS_MIN)),
		int(stats.get("agility", PartStats.AGILITY_MIN)),
	]
	return CharacterImporter.write_defs(set_id, display_name, values)
