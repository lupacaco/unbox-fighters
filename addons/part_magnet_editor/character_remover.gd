@tool
extends RefCounted

## Finds every file that belongs to one Freak and deletes it: shop cards,
## drawings, the character folder, leftover sheets, and check overlays.
##
## The shop then stops selling that Freak on the next Play. Docs and tests
## that still name the Freak are not rewritten here.

const CharacterImporter := preload("res://addons/part_magnet_editor/character_importer.gd")

const PARTS_DIR := "res://data/parts"
const CHARACTERS_DIR := "res://assets/characters"
const CHECKS_DIR := "res://tools/checks"
const LOOSE_SHEET_EXTS: PackedStringArray = ["png", "webp", "jpg", "jpeg"]
const FILE_STEMS: PackedStringArray = ["head", "body", "arm_l", "arm_r", "arms", "character"]


static func list_sets() -> Array[Dictionary]:
	var by_id := {}
	for set_id in _ids_from_character_files():
		by_id[set_id] = _describe_set(set_id)
	for set_id in _ids_from_art_folders():
		if not by_id.has(set_id):
			by_id[set_id] = _describe_set(set_id)
	var rows: Array[Dictionary] = []
	for set_id in by_id.keys():
		rows.append(by_id[set_id])
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return String(a["display_name"]) < String(b["display_name"])
	)
	return rows


static func collect_paths(set_id: String) -> PackedStringArray:
	set_id = CharacterImporter.clean_id(set_id)
	var found: PackedStringArray = []
	if set_id.is_empty():
		return found
	_collect_prefixed_files(PARTS_DIR, set_id, found)
	_collect_art_tree(set_id, found)
	_collect_loose_sheets(set_id, found)
	_collect_prefixed_files(CHECKS_DIR, set_id, found)
	found.sort()
	return found


## Human list of what will vanish. Empty when there is nothing to delete.
static func summarize(set_id: String) -> String:
	set_id = CharacterImporter.clean_id(set_id)
	var paths := collect_paths(set_id)
	if paths.is_empty():
		return "Não achei nenhum arquivo deste Freak."
	var parts_n := 0
	var art_n := 0
	var loose_n := 0
	var check_n := 0
	for path in paths:
		var p := path.replace("\\", "/")
		if p.begins_with(PARTS_DIR + "/"):
			parts_n += 1
		elif p.begins_with("%s/%s/" % [CHARACTERS_DIR, set_id]):
			art_n += 1
		elif p.begins_with(CHECKS_DIR + "/"):
			check_n += 1
		else:
			loose_n += 1
	var lines: PackedStringArray = []
	if parts_n > 0:
		lines.append("Fichas da loja: %d arquivo(s)" % parts_n)
	if art_n > 0:
		lines.append("Pasta de desenhos: assets/characters/%s/ (%d arquivo(s))" % [set_id, art_n])
	if loose_n > 0:
		lines.append("Folha solta na pasta de personagens: %d arquivo(s)" % loose_n)
	if check_n > 0:
		lines.append("Fotos de conferência: %d arquivo(s)" % check_n)
	lines.append("Total: %d arquivo(s)" % paths.size())
	return "\n".join(lines)


static func scripts_that_mention(set_id: String) -> PackedStringArray:
	set_id = CharacterImporter.clean_id(set_id)
	var hits: PackedStringArray = []
	if set_id.is_empty():
		return hits
	var needle := "%s_character.tres" % set_id
	var folder_needle := "/characters/%s/" % set_id
	_scan_scripts_for("res://scripts/core", needle, folder_needle, hits)
	hits.sort()
	return hits


## Returns "" when every file of this Freak is gone.
static func remove(set_id: String) -> String:
	set_id = CharacterImporter.clean_id(set_id)
	if set_id.is_empty():
		return "Escolha um Freak da lista."
	var paths := collect_paths(set_id)
	if paths.is_empty():
		return "Não achei nenhum arquivo deste Freak. Talvez já tenha sido apagado."
	ShopPool.drop_cache()
	var failed: PackedStringArray = []
	for path in paths:
		if not _belongs_to_set(path, set_id):
			failed.append(path)
			continue
		_delete_file(path, failed)
	_delete_dir_if_empty("%s/%s" % [CHARACTERS_DIR, set_id], failed)
	var leftover := collect_paths(set_id)
	if not leftover.is_empty():
		for path in leftover:
			if path not in failed:
				failed.append(path)
	ShopPool.reload()
	if failed.is_empty():
		return ""
	return "Não consegui apagar tudo. Ficaram: %s" % ", ".join(failed)


static func _describe_set(set_id: String) -> Dictionary:
	var character := _load_character(set_id)
	var in_shop := character != null
	var display := set_id.capitalize()
	var kind_label := ""
	if character != null:
		if not character.display_name.strip_edges().is_empty():
			display = character.display_name
		kind_label = FreakKind.label(character.kind)
	elif DirAccess.dir_exists_absolute(
		ProjectSettings.globalize_path("%s/%s" % [CHARACTERS_DIR, set_id])
	):
		display = "%s (incompleto)" % set_id.capitalize()
	return {
		"id": set_id,
		"display_name": display,
		"kind_label": kind_label,
		"in_shop": in_shop,
		"file_count": collect_paths(set_id).size(),
	}


static func _load_character(set_id: String) -> CharacterDef:
	var path := "%s/%s_character.tres" % [PARTS_DIR, set_id]
	if not FileAccess.file_exists(path):
		return null
	return load(path) as CharacterDef


static func _ids_from_character_files() -> PackedStringArray:
	var ids: PackedStringArray = []
	var dir := DirAccess.open(PARTS_DIR)
	if dir == null:
		return ids
	dir.list_dir_begin()
	var fname := dir.get_next()
	while fname != "":
		if not dir.current_is_dir() and fname.ends_with("_character.tres"):
			var set_id := CharacterImporter.clean_id(fname.trim_suffix("_character.tres"))
			if not set_id.is_empty() and set_id not in ids:
				ids.append(set_id)
		fname = dir.get_next()
	return ids


static func _ids_from_art_folders() -> PackedStringArray:
	var ids: PackedStringArray = []
	var dir := DirAccess.open(CHARACTERS_DIR)
	if dir == null:
		return ids
	for folder in dir.get_directories():
		var set_id := CharacterImporter.clean_id(folder)
		if set_id == folder and not set_id.is_empty() and set_id not in ids:
			ids.append(set_id)
	return ids


static func _collect_prefixed_files(folder: String, set_id: String, into: PackedStringArray) -> void:
	var dir := DirAccess.open(folder)
	if dir == null:
		return
	dir.include_hidden = true
	dir.list_dir_begin()
	var fname := dir.get_next()
	while fname != "":
		if not dir.current_is_dir() and _file_belongs_prefixed(fname, set_id):
			_append_unique("%s/%s" % [folder, fname], into)
		fname = dir.get_next()


static func _collect_art_tree(set_id: String, into: PackedStringArray) -> void:
	var folder := "%s/%s" % [CHARACTERS_DIR, set_id]
	var abs_folder := ProjectSettings.globalize_path(folder)
	if not DirAccess.dir_exists_absolute(abs_folder):
		return
	_collect_dir_recursive(folder, into)


static func _collect_dir_recursive(folder: String, into: PackedStringArray) -> void:
	var dir := DirAccess.open(folder)
	if dir == null:
		return
	dir.include_hidden = true
	dir.list_dir_begin()
	var fname := dir.get_next()
	while fname != "":
		if fname != "." and fname != "..":
			var child := "%s/%s" % [folder, fname]
			if dir.current_is_dir():
				_collect_dir_recursive(child, into)
			else:
				_append_unique(child, into)
		fname = dir.get_next()


static func _collect_loose_sheets(set_id: String, into: PackedStringArray) -> void:
	for ext in LOOSE_SHEET_EXTS:
		var path := "%s/%s.%s" % [CHARACTERS_DIR, set_id, ext]
		if FileAccess.file_exists(path):
			_append_unique(path, into)
		var sidecar := "%s.import" % path
		if FileAccess.file_exists(sidecar):
			_append_unique(sidecar, into)


static func _append_unique(path: String, into: PackedStringArray) -> void:
	var clean := path.replace("\\", "/")
	if clean not in into:
		into.append(clean)


static func _file_belongs_prefixed(fname: String, set_id: String) -> bool:
	var prefix := "%s_" % set_id
	if not fname.begins_with(prefix):
		return false
	var rest := fname.substr(prefix.length())
	for stem in FILE_STEMS:
		if rest == stem or rest.begins_with(stem + ".") or rest.begins_with(stem + "-"):
			return true
	return false


static func _belongs_to_set(res_path: String, set_id: String) -> bool:
	var p := res_path.replace("\\", "/")
	if not p.begins_with("res://"):
		return false
	var file := p.get_file()
	if p.begins_with(PARTS_DIR + "/"):
		return _file_belongs_prefixed(file, set_id)
	if p.begins_with(CHECKS_DIR + "/"):
		return _file_belongs_prefixed(file, set_id)
	var art_folder := "%s/%s" % [CHARACTERS_DIR, set_id]
	if p == art_folder or p.begins_with(art_folder + "/"):
		return true
	if p.get_base_dir() == CHARACTERS_DIR:
		return file == set_id or file.begins_with("%s." % set_id)
	return false


static func _delete_file(res_path: String, failed: PackedStringArray) -> void:
	var abs_path := ProjectSettings.globalize_path(res_path)
	if not FileAccess.file_exists(abs_path):
		return
	if DirAccess.remove_absolute(abs_path) != OK:
		failed.append(res_path)


static func _delete_dir_if_empty(res_path: String, failed: PackedStringArray) -> void:
	var abs_path := ProjectSettings.globalize_path(res_path)
	if not DirAccess.dir_exists_absolute(abs_path):
		return
	_delete_empty_dirs_recursive(abs_path, failed)


static func _delete_empty_dirs_recursive(abs_path: String, failed: PackedStringArray) -> void:
	var dir := DirAccess.open(abs_path)
	if dir == null:
		failed.append(abs_path)
		return
	dir.include_hidden = true
	dir.list_dir_begin()
	var fname := dir.get_next()
	var leftovers: PackedStringArray = []
	while fname != "":
		if fname != "." and fname != "..":
			var child := abs_path.path_join(fname)
			if dir.current_is_dir():
				_delete_empty_dirs_recursive(child, failed)
				if DirAccess.dir_exists_absolute(child):
					leftovers.append(fname)
			else:
				leftovers.append(fname)
		fname = dir.get_next()
	if not leftovers.is_empty():
		return
	if DirAccess.remove_absolute(abs_path) != OK:
		failed.append(abs_path)


static func _scan_scripts_for(
	folder: String, needle: String, folder_needle: String, into: PackedStringArray
) -> void:
	var dir := DirAccess.open(folder)
	if dir == null:
		return
	dir.list_dir_begin()
	var fname := dir.get_next()
	while fname != "":
		var child := "%s/%s" % [folder, fname]
		if dir.current_is_dir() and fname != "." and fname != "..":
			_scan_scripts_for(child, needle, folder_needle, into)
		elif fname.ends_with(".gd"):
			var body := FileAccess.get_file_as_string(child)
			if body.contains(needle) or body.contains(folder_needle):
				_append_unique(child, into)
		fname = dir.get_next()
