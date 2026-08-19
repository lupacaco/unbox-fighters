class_name CharacterSlot
extends Node2D

## A hanging card where one Freak is built. Two kits go on it: head and body
## (the body already carries both arms). The wooden crate is a fixed base; the
## Freak sits inside it. When both kits are there, LUTAR appears.

signal part_attached(slot: CharacterSlot, part: PartDef)
signal part_detached(slot: CharacterSlot, part: PartDef)
signal assembly_changed(slot: CharacterSlot)
signal fight_requested(slot: CharacterSlot)

## Opponent cards only show what they built. You cannot drop kits on them.
var is_opponent: bool = false
var _shown_parts: Dictionary = {}
var _shown_key: String = ""

## Drop areas in card-local space. A kit may also be dropped anywhere on the card.
const ZONES := {
	PartSlotType.Value.HEAD: [Rect2(-112, -150, 224, 152)],
	PartSlotType.Value.BODY: [Rect2(-126, 2, 252, 210)],
}
const CARD_BOUNDS := Rect2(-150, -300, 300, 600)

var _frame: Sprite2D
var _shadow: Sprite2D
var _glow: Polygon2D
var _display: Node2D
var _crate: Sprite2D
var _hint: Label
var _fight_button: Button
var _banner: Label

var _bound_parts: Dictionary = {}
var _layer_sprites: Dictionary = {}
var _zone_areas: Dictionary = {}
var _pills: Dictionary = {}
var _crossfade_busy: bool = false
var _locked: bool = false
var _drop_hot: bool = false
var _synergy_shown: Synergy.Level = Synergy.Level.NONE
var _glow_pulse: Tween

func setup(as_opponent: bool = false) -> void:
	is_opponent = as_opponent
	_build_frame()
	_build_display()
	_build_pills()
	_build_zones()
	if not is_opponent:
		_build_fight_button()
	_build_banner()
	_refresh_display(false)
	_refresh_pills()

# ---------------------------------------------------------------- state

func to_loadout() -> FighterLoadout:
	var loadout := FighterLoadout.new()
	for slot in PartSlotType.shop_slots():
		loadout.set_part(slot, get_attached_part(slot))
	return loadout

func get_attached_part(slot: PartSlotType.Value) -> PartDef:
	if is_opponent:
		return _shown_parts.get(slot) as PartDef
	if not _bound_parts.has(slot):
		return null
	var view = _bound_parts[slot]
	if view == null or not is_instance_valid(view):
		_bound_parts.erase(slot)
		return null
	return (view as PartView).part_def

func is_complete() -> bool:
	for slot in PartSlotType.shop_slots():
		if get_attached_part(slot) == null:
			return false
	return true

func has_any_part() -> bool:
	for slot in PartSlotType.shop_slots():
		if get_attached_part(slot) != null:
			return true
	return false

func can_fight() -> bool:
	if _locked or not is_complete():
		return false
	for part in PartKit.expand_shop_parts(_shop_parts_map()).values():
		if (part as PartDef).sprite_profile == null:
			return false
	return true

func set_locked(locked: bool) -> void:
	_locked = locked
	for view in _bound_parts.values():
		if view != null and is_instance_valid(view):
			(view as PartView).lock_interaction(locked)
	_refresh_fight_button()

# ---------------------------------------------------------------- drop

func can_accept(part: PartDef) -> bool:
	if is_opponent or _locked or part == null:
		return false
	return PartSlotType.is_shop_slot(part.slot_type)

func can_accept_at(part: PartDef, global_point: Vector2) -> bool:
	if not can_accept(part):
		return false
	return CARD_BOUNDS.has_point(to_local(global_point))

func contains_card_point(global_point: Vector2) -> bool:
	return CARD_BOUNDS.has_point(to_local(global_point))

func find_part_at(global_point: Vector2) -> PartView:
	if is_opponent or _locked:
		return null
	for slot in PartSlotType.shop_slots():
		if _bound_parts.has(slot) and _zone_contains(slot, global_point):
			var view: PartView = _bound_parts[slot]
			if view != null and is_instance_valid(view):
				return view
	return null

func try_attach(part_view: PartView) -> bool:
	if is_opponent or _locked or part_view == null or part_view.part_def == null:
		return false
	if not can_accept(part_view.part_def):
		return false
	var slot := part_view.part_def.slot_type
	var displaced: PartView = null
	if _bound_parts.has(slot):
		displaced = detach_part(slot, false)
	var before_kind := Synergy.kinds_match(to_loadout().parts_array())
	var before_set := to_loadout().is_complete_set()
	_bound_parts[slot] = part_view
	part_view.set_attached_slot(self)
	part_view.snap_hide_for_slot()
	_refresh_display(true)
	_refresh_pills()
	_pulse_attach()
	GameAudio.part_place()
	var loadout := to_loadout()
	if loadout.is_complete_set() and not before_set:
		_celebrate_power(loadout.stats().ability)
	elif Synergy.kinds_match(loadout.parts_array()) and not before_kind:
		_celebrate_synergy(Synergy.Level.KIND, Synergy.kind_of(part_view.part_def))
	if is_complete():
		GameAudio.fighter_complete()
	_refresh_fight_button()
	part_attached.emit(self, part_view.part_def)
	assembly_changed.emit(self)
	if displaced != null:
		displaced.return_home()
	return true

func detach_part(slot: PartSlotType.Value, refresh: bool = true) -> PartView:
	if _locked or not _bound_parts.has(slot):
		return null
	var part_view: PartView = _bound_parts[slot]
	_bound_parts.erase(slot)
	part_view.set_attached_slot(null)
	if refresh:
		_refresh_display(true)
		_refresh_pills()
	_refresh_fight_button()
	part_detached.emit(self, part_view.part_def)
	assembly_changed.emit(self)
	return part_view

func steal_all_parts() -> Dictionary:
	var stolen := {}
	for slot in PartSlotType.shop_slots():
		if not _bound_parts.has(slot):
			continue
		var view: PartView = _bound_parts[slot]
		_bound_parts.erase(slot)
		if view != null and is_instance_valid(view):
			view.set_attached_slot(null)
			stolen[slot] = view
	_refresh_display(false)
	_refresh_pills()
	_refresh_fight_button()
	assembly_changed.emit(self)
	return stolen

## Empties the card after the Freak jumped onto the belt.
func clear_after_launch() -> void:
	for view in _bound_parts.values():
		if view != null and is_instance_valid(view):
			(view as PartView).queue_free()
	_bound_parts.clear()
	_synergy_shown = Synergy.Level.NONE
	_refresh_display(false)
	_refresh_pills()
	_refresh_fight_button()
	assembly_changed.emit(self)

## Paints the kits the opponent has placed. No dragging on this card.
func show_loadout(loadout: FighterLoadout) -> void:
	if not is_opponent:
		return
	var next := {}
	if loadout != null:
		for slot in PartSlotType.shop_slots():
			var part := loadout.get_part(slot)
			if part != null:
				next[slot] = part
	var key := _parts_key(next)
	if key == _shown_key:
		return
	var grew := next.size() > _shown_parts.size()
	_shown_parts = next
	_shown_key = key
	_refresh_display(grew)
	_refresh_pills()
	if grew:
		_pulse_attach()

func _parts_key(parts: Dictionary) -> String:
	var bits: PackedStringArray = []
	for slot in PartSlotType.shop_slots():
		var part: PartDef = parts.get(slot)
		bits.append("" if part == null else String(part.id))
	return "|".join(bits)

func set_drop_highlight(enabled: bool, _slot: PartSlotType.Value = PartSlotType.Value.BODY) -> void:
	if is_opponent or _locked:
		enabled = false
	if _drop_hot == enabled:
		return
	_drop_hot = enabled
	Feel.to_scale(self, Vector2.ONE * (1.045 if enabled else 1.0), 0.12)
	var tween := create_tween()
	tween.tween_property(
		_frame, "modulate", Color(1.22, 1.14, 0.92, 1) if enabled else Color.WHITE, 0.12
	).set_trans(Tween.TRANS_SINE)

# ---------------------------------------------------------------- looks

func global_floor_point() -> Vector2:
	return to_global(Vector2(0.0, AssemblyLayout.CARD_FLOOR_Y))

func freak_layers() -> Dictionary:
	return _layer_sprites

func play_intro(delay: float) -> void:
	modulate.a = 0.0
	var rest := position.y
	position.y = rest - 40.0
	var tween := create_tween()
	tween.tween_interval(delay)
	tween.tween_property(self, "modulate:a", 1.0, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "position:y", rest, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func play_launch_swing() -> void:
	var tween := create_tween()
	tween.tween_property(self, "rotation_degrees", 3.0, 0.1).set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "rotation_degrees", -2.0, 0.16).set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "rotation_degrees", 0.0, 0.22).set_trans(Tween.TRANS_SINE)

func _build_frame() -> void:
	if _frame != null:
		return
	var tex: Texture2D = load(
		AssemblyLayout.CARD_OPPONENT_TEX if is_opponent else AssemblyLayout.CARD_TEX
	)
	_shadow = Sprite2D.new()
	_shadow.name = "CardShadow"
	_shadow.texture = tex
	_shadow.centered = true
	_shadow.position = Vector2(10, 16)
	_shadow.modulate = Color(0, 0, 0, 0.45)
	_shadow.z_index = -3
	add_child(_shadow)

	_glow = Polygon2D.new()
	_glow.name = "CompleteGlow"
	var well := AssemblyLayout.CARD_WELL.grow(16.0)
	_glow.polygon = PackedVector2Array([
		well.position, well.position + Vector2(well.size.x, 0),
		well.end, well.position + Vector2(0, well.size.y),
	])
	_glow.color = Color(0.98, 0.79, 0.33, 0.0)
	_glow.z_index = -2
	add_child(_glow)

	_frame = Sprite2D.new()
	_frame.name = "CardFrame"
	_frame.texture = tex
	_frame.centered = true
	add_child(_frame)

	if not is_opponent:
		_hint = GameTheme.make_label(
			"monte 2 peças", 30, Vector2(0, -40), Vector2(240, 48), Color(0.62, 0.56, 0.46, 0.55)
		)
		_hint.z_index = 2
		add_child(_hint)

func _build_display() -> void:
	if _display != null:
		return
	_display = Node2D.new()
	_display.name = "Display"
	_display.position = Vector2(0.0, AssemblyLayout.CARD_FLOOR_Y)
	_display.scale = Vector2.ONE * AssemblyLayout.CARD_FREAK_SCALE
	_display.z_index = 1
	add_child(_display)
	_crate = Sprite2D.new()
	_crate.name = "CrateBase"
	_crate.centered = true
	_crate.z_index = 1
	_display.add_child(_crate)
	CompositeResolver.apply_crate_to(_crate)
	for slot in PartSlotType.draw_order():
		var sprite := Sprite2D.new()
		sprite.name = String(PartSlotType.to_string_name(slot))
		sprite.centered = true
		sprite.visible = false
		_display.add_child(sprite)
		_layer_sprites[slot] = sprite

func _build_pills() -> void:
	if not _pills.is_empty():
		return
	var slots := PartSlotType.shop_slots()
	for i in slots.size():
		var pill := StatTag.new()
		pill.position = Vector2(
			(float(i) - float(slots.size() - 1) * 0.5) * AssemblyLayout.CARD_PILL_STEP,
			AssemblyLayout.CARD_PILL_Y
		)
		pill.z_index = 6
		add_child(pill)
		_pills[slots[i]] = pill

func _build_zones() -> void:
	if not _zone_areas.is_empty():
		return
	var root := Node2D.new()
	root.name = "Zones"
	add_child(root)
	for slot in PartSlotType.shop_slots():
		var area := Area2D.new()
		area.name = String(PartSlotType.to_string_name(slot))
		area.collision_layer = 2
		area.collision_mask = 0
		area.monitoring = false
		area.monitorable = false
		area.input_pickable = true
		for rect in ZONES[slot]:
			var shape := CollisionShape2D.new()
			var box := RectangleShape2D.new()
			box.size = (rect as Rect2).size
			shape.shape = box
			shape.position = (rect as Rect2).get_center()
			Feel.hide_collision_debug(shape)
			area.add_child(shape)
		area.input_event.connect(_on_zone_input.bind(slot))
		root.add_child(area)
		_zone_areas[slot] = area

func _build_fight_button() -> void:
	if _fight_button != null:
		return
	_fight_button = GameTheme.make_button(
		"LUTAR",
		Vector2(0.0, AssemblyLayout.FIGHT_BUTTON_DROP),
		AssemblyLayout.FIGHT_BUTTON_SIZE,
		ThemeTokens.SELL_RED,
		32
	)
	_fight_button.pressed.connect(func() -> void: fight_requested.emit(self))
	add_child(_fight_button)
	_refresh_fight_button()

func _build_banner() -> void:
	if _banner != null:
		return
	_banner = GameTheme.make_label("", 30, Vector2(0, -216), Vector2(280, 44), ThemeTokens.GOLD)
	_banner.z_index = 9
	_banner.modulate.a = 0.0
	add_child(_banner)

func _refresh_fight_button() -> void:
	if _fight_button == null:
		return
	var ready := can_fight()
	_fight_button.visible = ready
	_fight_button.disabled = not ready
	_fight_button.mouse_filter = Control.MOUSE_FILTER_STOP if ready else Control.MOUSE_FILTER_IGNORE
	if ready and _glow_pulse == null:
		_start_glow()
	elif not ready:
		_stop_glow()

func _start_glow() -> void:
	_glow_pulse = create_tween().set_loops()
	_glow_pulse.tween_property(_glow, "color:a", 0.26, 0.6).set_trans(Tween.TRANS_SINE)
	_glow_pulse.tween_property(_glow, "color:a", 0.06, 0.6).set_trans(Tween.TRANS_SINE)

func _stop_glow() -> void:
	if _glow_pulse != null and _glow_pulse.is_valid():
		_glow_pulse.kill()
	_glow_pulse = null
	if _glow != null:
		_glow.color.a = 0.0

func _shop_parts_map() -> Dictionary:
	var shop := {}
	for slot in PartSlotType.shop_slots():
		var part := get_attached_part(slot)
		if part != null:
			shop[slot] = part
	return shop

func _refresh_display(animate: bool) -> void:
	if _display == null:
		return
	if _hint != null:
		_hint.visible = not has_any_part()
	if not animate or _crossfade_busy:
		_apply_plan()
		return
	_crossfade_busy = true
	var tween := create_tween()
	tween.tween_property(_display, "modulate:a", 0.0, 0.09).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(_apply_plan)
	tween.tween_property(_display, "modulate:a", 1.0, 0.17).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(func() -> void: _crossfade_busy = false)

func _apply_plan() -> void:
	var expanded := PartKit.expand_shop_parts(_shop_parts_map())
	var plan := CompositeResolver.resolve_slots(expanded)
	var textures: Dictionary = plan["textures"]
	var positions: Dictionary = plan["positions"]
	var order := PartSlotType.draw_order_for(expanded)
	for i in order.size():
		var slot: PartSlotType.Value = order[i]
		var sprite: Sprite2D = _layer_sprites.get(slot)
		if sprite == null:
			continue
		_display.move_child(sprite, i)
		var texture: Texture2D = textures.get(slot)
		if texture == null:
			sprite.texture = null
			sprite.visible = false
			continue
		sprite.texture = texture
		sprite.visible = true
		sprite.centered = true
		sprite.position = positions.get(slot, Vector2.ZERO)
		sprite.scale = Vector2.ONE * CompositeResolver.display_scale()
		sprite.flip_h = false
		sprite.rotation = 0.0
		var part := expanded.get(slot) as PartDef
		if part != null:
			part.apply_to_sprite(sprite, texture, false)
		var spread: Dictionary = CompositeResolver.spread_front_arm(
			slot, part, texture, sprite.position, CompositeResolver.display_scale()
		)
		sprite.position = spread["center"]
		sprite.rotation += float(spread["extra"])
	_restack_crate()

func _restack_crate() -> void:
	if _display == null or _crate == null:
		return
	CompositeResolver.apply_crate_to(_crate)
	var body: Sprite2D = _layer_sprites.get(PartSlotType.Value.BODY)
	if body != null:
		body.z_index = 0
		_display.move_child(body, 0)
	_crate.z_index = 1
	_display.move_child(_crate, mini(1, _display.get_child_count() - 1))
	var next := 2
	for slot in [PartSlotType.Value.ARM_L, PartSlotType.Value.ARM_R, PartSlotType.Value.HEAD]:
		var sprite: Sprite2D = _layer_sprites.get(slot)
		if sprite == null:
			continue
		sprite.z_index = 2 if PartSlotType.is_arm(slot) else 3
		_display.move_child(sprite, mini(next, _display.get_child_count() - 1))
		next += 1

func _refresh_pills() -> void:
	var loadout := to_loadout()
	var parts := loadout.parts_array()
	for slot in _pills.keys():
		var pill: StatTag = _pills[slot]
		var boosted := Synergy.kinds_match(parts)
		pill.setup(loadout.stat_of(slot), ThemeTokens.color_for_slot(slot), boosted)

func _celebrate_power(ability: FreakAbility.Value) -> void:
	var title := FreakAbility.display_name(ability)
	if title.is_empty():
		title = "SET COMPLETO"
	_flash_banner(title)

func _celebrate_synergy(level: Synergy.Level, kind: FreakKind.Value = FreakKind.Value.HUMAN) -> void:
	_synergy_shown = level
	_flash_banner(Synergy.level_name(level, kind))

func _flash_banner(text: String) -> void:
	_banner.text = text
	_banner.modulate.a = 0.0
	_banner.scale = Vector2(0.7, 0.7)
	_banner.pivot_offset = _banner.size * 0.5
	var tween := create_tween()
	tween.tween_property(_banner, "modulate:a", 1.0, 0.14)
	tween.parallel().tween_property(_banner, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_interval(0.85)
	tween.tween_property(_banner, "modulate:a", 0.0, 0.3)
	var flash := create_tween()
	flash.tween_property(_glow, "color:a", 0.55, 0.1)
	flash.tween_property(_glow, "color:a", 0.08, 0.5).set_trans(Tween.TRANS_SINE)
	for pill in _pills.values():
		(pill as StatTag).play_boost()

func _pulse_attach() -> void:
	Feel.punch(_display, Vector2(1.08, 0.92), Vector2.ONE)
	var tween := create_tween()
	tween.tween_property(_frame, "modulate", Color(1.2, 1.14, 0.95, 1), 0.08)
	tween.tween_property(_frame, "modulate", Color.WHITE, 0.28).set_trans(Tween.TRANS_SINE)

func _zone_contains(slot: PartSlotType.Value, global_point: Vector2) -> bool:
	var local := to_local(global_point)
	for rect in ZONES.get(slot, []):
		if (rect as Rect2).has_point(local):
			return true
	return false

func _on_zone_input(_viewport: Node, event: InputEvent, _shape_idx: int, slot: PartSlotType.Value) -> void:
	if is_opponent or _locked:
		return
	if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
		return
	if not _bound_parts.has(slot):
		return
	var part_view: PartView = detach_part(slot, true)
	if part_view == null:
		return
	part_view.visible = true
	part_view.global_position = get_viewport().get_mouse_position()
	var drag: DragDropService = get_tree().get_first_node_in_group("drag_drop_service") as DragDropService
	if drag != null:
		drag.begin_drag(part_view)
	get_viewport().set_input_as_handled()
