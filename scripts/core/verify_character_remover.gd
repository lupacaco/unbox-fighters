extends SceneTree

## Checks the remove-character pipeline without deleting a real Freak.

const CharacterRemover := preload("res://addons/part_magnet_editor/character_remover.gd")
const TEST_ID := "zz_rmtest"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_cleanup_test_set()
	if not _check_real_roster():
		_cleanup_test_set()
		quit(1)
		return
	if not _check_prefix_safety():
		_cleanup_test_set()
		quit(1)
		return
	if not _check_empty_id():
		_cleanup_test_set()
		quit(1)
		return
	if not _check_temp_delete():
		_cleanup_test_set()
		quit(1)
		return
	_cleanup_test_set()
	print("VERIFY_CHARACTER_REMOVER_PASS")
	quit(0)

func _check_real_roster() -> bool:
	var ids: PackedStringArray = []
	for row in CharacterRemover.list_sets():
		ids.append(String(row["id"]))
	if "bruxa" not in ids:
		push_error("VERIFY_FAIL list_sets should include bruxa")
		return false
	var paths := CharacterRemover.collect_paths("bruxa")
	if "res://data/parts/bruxa_character.tres" not in paths:
		push_error("VERIFY_FAIL collect_paths should include bruxa_character.tres")
		return false
	var art := "res://assets/characters/bruxa/bruxa_head-1.png"
	if art not in paths:
		push_error("VERIFY_FAIL collect_paths should include %s" % art)
		return false
	if CharacterRemover.scripts_that_mention("bruxa").is_empty():
		push_error("VERIFY_FAIL tests that load bruxa_character.tres should be listed")
		return false
	return true

func _check_prefix_safety() -> bool:
	for path in CharacterRemover.collect_paths("bru"):
		if path.contains("bruxa"):
			push_error("VERIFY_FAIL deleting bru must not collect bruxa files: %s" % path)
			return false
	return true

func _check_empty_id() -> bool:
	var err := CharacterRemover.remove("")
	if err.is_empty():
		push_error("VERIFY_FAIL remove with empty id should fail")
		return false
	return true

func _check_temp_delete() -> bool:
	if not _write_test_set():
		push_error("VERIFY_FAIL could not write the temporary Freak files")
		return false
	var before := CharacterRemover.collect_paths(TEST_ID)
	if before.size() < 4:
		push_error("VERIFY_FAIL temp Freak should have several files, got %d" % before.size())
		return false
	var listed := false
	for row in CharacterRemover.list_sets():
		if String(row["id"]) == TEST_ID:
			listed = true
			break
	if not listed:
		push_error("VERIFY_FAIL list_sets should include an incomplete folder Freak")
		return false
	var err := CharacterRemover.remove(TEST_ID)
	if not err.is_empty():
		push_error("VERIFY_FAIL remove temp Freak: %s" % err)
		return false
	var leftover := CharacterRemover.collect_paths(TEST_ID)
	if not leftover.is_empty():
		push_error("VERIFY_FAIL temp Freak files remained: %s" % ", ".join(leftover))
		return false
	if FileAccess.file_exists("res://data/parts/bruxa_character.tres") == false:
		push_error("VERIFY_FAIL removing the temp Freak must not touch bruxa")
		return false
	if not FileAccess.file_exists("res://assets/characters/bruxa/bruxa_head-1.png"):
		push_error("VERIFY_FAIL bruxa art must still be there")
		return false
	return true

func _write_test_set() -> bool:
	var folder := "res://assets/characters/%s" % TEST_ID
	var abs_folder := ProjectSettings.globalize_path(folder)
	if DirAccess.make_dir_recursive_absolute(abs_folder) != OK:
		return false
	if not _write_text("%s/marker.txt" % folder, "temp"):
		return false
	if not _write_text("%s/%s_slice.json" % [folder, TEST_ID], "{}"):
		return false
	if not _write_text("res://data/parts/%s_head.tres" % TEST_ID, "[gd_resource type=\"Resource\" format=3]\n\n[resource]\n"):
		return false
	if not _write_text("res://assets/characters/%s.jpg" % TEST_ID, "temp"):
		return false
	if not _write_text("res://tools/checks/%s_head-1.png" % TEST_ID, "temp"):
		return false
	return true

func _write_text(path: String, body: String) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(body)
	return true

func _cleanup_test_set() -> void:
	CharacterRemover.remove(TEST_ID)
	for extra in [
		"res://assets/characters/%s.jpg" % TEST_ID,
		"res://data/parts/%s_head.tres" % TEST_ID,
		"res://tools/checks/%s_head-1.png" % TEST_ID,
	]:
		if FileAccess.file_exists(extra):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(extra))
	var folder := ProjectSettings.globalize_path("res://assets/characters/%s" % TEST_ID)
	if DirAccess.dir_exists_absolute(folder):
		var dir := DirAccess.open(folder)
		if dir != null:
			dir.list_dir_begin()
			var fname := dir.get_next()
			while fname != "":
				if fname != "." and fname != "..":
					DirAccess.remove_absolute(folder.path_join(fname))
				fname = dir.get_next()
		DirAccess.remove_absolute(folder)
