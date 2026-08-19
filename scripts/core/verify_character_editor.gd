extends SceneTree

## Checks that editing a Freak changes the card and puts the files back.

const CharacterEditor := preload("res://addons/part_magnet_editor/character_editor.gd")
const ToolChrome := preload("res://addons/part_magnet_editor/tool_chrome.gd")

const SNAP_PATHS: PackedStringArray = [
	"res://data/parts/bruxa_character.tres",
	"res://data/parts/bruxa_head.tres",
	"res://data/parts/bruxa_body.tres",
	"res://data/parts/bruxa_arm_l.tres",
	"res://data/parts/bruxa_arm_r.tres",
	"res://data/parts/bruxa_arms.tres",
	"res://assets/characters/bruxa/bruxa_slice.json",
]

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var snap := _snapshot()
	if snap.is_empty():
		push_error("VERIFY_FAIL could not read the Bruxa files")
		quit(1)
		return
	var ok := (
		_check_chrome()
		and _check_read()
		and _check_errors()
		and _check_storage_keys()
		and _check_edit_and_magnets()
	)
	_restore(snap)
	ShopPool.reload()
	if not ok:
		quit(1)
		return
	var restored := CharacterEditor.read("bruxa")
	if int(restored.get("attack", 0)) != 8 or int(restored.get("hp", 0)) != 15:
		push_error("VERIFY_FAIL Bruxa should be back to 8 / 15 after the test")
		quit(1)
		return
	print("VERIFY_CHARACTER_EDITOR_PASS")
	quit(0)

func _check_chrome() -> bool:
	if ToolChrome.SIZE != Vector2i(800, 600):
		push_error("VERIFY_FAIL tool windows should be 800x600")
		return false
	return true

func _check_read() -> bool:
	var snap: Dictionary = CharacterEditor.read("bruxa")
	if not String(snap.get("error", "")).is_empty():
		push_error("VERIFY_FAIL read bruxa: %s" % snap["error"])
		return false
	if String(snap["display_name"]) != "Bruxa":
		push_error("VERIFY_FAIL bruxa display name should be Bruxa")
		return false
	if int(snap["attack"]) != 8 or int(snap["hp"]) != 15:
		push_error("VERIFY_FAIL bruxa should start at attack 8 / HP 15")
		return false
	if int(snap["kind"]) != int(FreakKind.Value.SUPERNATURAL):
		push_error("VERIFY_FAIL bruxa should be supernatural")
		return false
	if int(snap["ability"]) != int(FreakAbility.Value.MIND_CONTROL):
		push_error("VERIFY_FAIL bruxa should have mind control")
		return false
	var ids: PackedStringArray = []
	for row in CharacterEditor.list_sets():
		ids.append(String(row["id"]))
	if "bruxa" not in ids or "advogado" not in ids:
		push_error("VERIFY_FAIL list_sets should include bruxa and advogado")
		return false
	return true

func _check_errors() -> bool:
	if CharacterEditor.save("", "X", 8, 15, FreakKind.Value.HUMAN, FreakAbility.Value.NONE).is_empty():
		push_error("VERIFY_FAIL empty id should fail")
		return false
	if CharacterEditor.save("bruxa", "   ", 8, 15, FreakKind.Value.HUMAN, FreakAbility.Value.NONE).is_empty():
		push_error("VERIFY_FAIL empty name should fail")
		return false
	if CharacterEditor.save("zz_nobody", "X", 8, 15, FreakKind.Value.HUMAN, FreakAbility.Value.NONE).is_empty():
		push_error("VERIFY_FAIL missing Freak should fail")
		return false
	return true

func _check_storage_keys() -> bool:
	if FreakKind.storage_key(FreakKind.Value.SUPERNATURAL) != "supernatural":
		push_error("VERIFY_FAIL kind storage_key")
		return false
	if FreakAbility.storage_key(FreakAbility.Value.MIND_CONTROL) != "mind_control":
		push_error("VERIFY_FAIL ability storage_key")
		return false
	if FreakAbility.storage_key(FreakAbility.Value.NONE) != "":
		push_error("VERIFY_FAIL empty ability should store as empty string")
		return false
	return true

func _check_edit_and_magnets() -> bool:
	var head := load("res://data/parts/bruxa_head.tres") as PartDef
	var body := load("res://data/parts/bruxa_body.tres") as PartDef
	if head == null or body == null:
		push_error("VERIFY_FAIL missing Bruxa parts")
		return false
	var magnet_down := head.magnet_down
	var magnet_neck := body.magnet_neck
	var err := CharacterEditor.save(
		"bruxa",
		"Bruxona",
		9,
		16,
		FreakKind.Value.ANIMAL,
		FreakAbility.Value.APPEAL
	)
	if not err.is_empty():
		push_error("VERIFY_FAIL save: %s" % err)
		return false
	var snap: Dictionary = CharacterEditor.read("bruxa")
	if String(snap["display_name"]) != "Bruxona":
		push_error("VERIFY_FAIL name should become Bruxona")
		return false
	if int(snap["attack"]) != 9 or int(snap["hp"]) != 16:
		push_error("VERIFY_FAIL numbers should become 9 / 16")
		return false
	if int(snap["kind"]) != int(FreakKind.Value.ANIMAL):
		push_error("VERIFY_FAIL kind should become animal")
		return false
	if int(snap["ability"]) != int(FreakAbility.Value.APPEAL):
		push_error("VERIFY_FAIL power should become Recurso")
		return false
	head = ResourceLoader.load("res://data/parts/bruxa_head.tres", "", ResourceLoader.CACHE_MODE_REPLACE) as PartDef
	body = ResourceLoader.load("res://data/parts/bruxa_body.tres", "", ResourceLoader.CACHE_MODE_REPLACE) as PartDef
	if head.display_name != "Bruxona Cabeça":
		push_error("VERIFY_FAIL head label should follow the card name")
		return false
	if head.magnet_down != magnet_down:
		push_error("VERIFY_FAIL editing must not move the head magnet")
		return false
	if body.magnet_neck != magnet_neck:
		push_error("VERIFY_FAIL editing must not move the neck magnet")
		return false
	if head.stat_value != 9 or body.stat_value != 16:
		push_error("VERIFY_FAIL part numbers should match the card")
		return false
	var report := _slice_stats()
	if int(report.get("attack", 0)) != 9 or int(report.get("hp", 0)) != 16:
		push_error("VERIFY_FAIL slice.json should follow the new numbers")
		return false
	err = CharacterEditor.save(
		"bruxa", "Bruxa", 99, 3, FreakKind.Value.SUPERNATURAL, FreakAbility.Value.MIND_CONTROL
	)
	if not err.is_empty():
		push_error("VERIFY_FAIL clamp save: %s" % err)
		return false
	snap = CharacterEditor.read("bruxa")
	if int(snap["attack"]) != PartStats.ATTACK_MAX or int(snap["hp"]) != PartStats.HP_MIN:
		push_error("VERIFY_FAIL numbers outside the range should clamp")
		return false
	var line := CharacterEditor.price_line(8, 15)
	if not line.contains("$8") or not line.contains("$5"):
		push_error("VERIFY_FAIL price line should show $8 and $5 for 8/15, got %s" % line)
		return false
	return true

func _slice_stats() -> Dictionary:
	var path := "res://assets/characters/bruxa/bruxa_slice.json"
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	var stats: Variant = (parsed as Dictionary).get("stats", {})
	if typeof(stats) != TYPE_DICTIONARY:
		return {}
	return stats

func _snapshot() -> Dictionary:
	var snap := {}
	for path in SNAP_PATHS:
		if not FileAccess.file_exists(path):
			return {}
		snap[path] = FileAccess.get_file_as_bytes(path)
	return snap

func _restore(snap: Dictionary) -> void:
	for path in snap.keys():
		var file := FileAccess.open(path, FileAccess.WRITE)
		if file == null:
			push_error("VERIFY_FAIL could not restore %s" % path)
			continue
		file.store_buffer(snap[path])
