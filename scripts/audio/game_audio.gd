class_name GameAudio
extends Object

## Stable access to the Sfx autoload from any script.

static func _sfx() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	return tree.root.get_node_or_null("Sfx")

static func hammer_hit() -> void:
	var s := _sfx()
	if s:
		s.call("hammer_hit")

static func crate_crack() -> void:
	var s := _sfx()
	if s:
		s.call("crate_crack")

static func crate_break() -> void:
	var s := _sfx()
	if s:
		s.call("crate_break")

static func open_crate() -> void:
	var s := _sfx()
	if s:
		s.call("open_crate")

static func part_pickup() -> void:
	var s := _sfx()
	if s:
		s.call("part_pickup")

static func part_place() -> void:
	var s := _sfx()
	if s:
		s.call("part_place")

static func part_reject() -> void:
	var s := _sfx()
	if s:
		s.call("part_reject")

static func fighter_complete() -> void:
	var s := _sfx()
	if s:
		s.call("fighter_complete")

static func impact() -> void:
	var s := _sfx()
	if s:
		s.call("impact")

static func land() -> void:
	var s := _sfx()
	if s:
		s.call("land")

static func step() -> void:
	var s := _sfx()
	if s:
		s.call("step")

static func whoosh() -> void:
	var s := _sfx()
	if s:
		s.call("whoosh")
