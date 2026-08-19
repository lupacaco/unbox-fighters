class_name CharacterSlot
extends Node2D

## A hanging card where one Freak is built. Two kits go on it: head and body
## (the body already carries both arms). The wooden crate is a fixed base; the
## Freak sits inside it. When both kits are there, PRONTO appears under the card.

signal part_attached(slot: CharacterSlot, part: PartDef)
signal part_detached(slot: CharacterSlot, part: PartDef)
signal assembly_changed(slot: CharacterSlot)

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
var _crate_back: Sprite2D
var _crate_front: Sprite2D
var _plaque: CratePlaque
var _hint: Label
var _ready_label: Label
var _banner: Label

var _bound_parts: Dictionary = {}
var _layer_sprites: Dictionary = {}
var _zone_areas: Dictionary = {}
var _crossfade_busy: bool = false
var _locked: bool = false
var _drop_hot: bool = false
var _synergy_shown: Synergy.Level = Synergy.Level.NONE
var _glow_pulse: Tween
var _on_belt: bool = false

func setup(as_opponent: bool = false) -> void:
	is_opponent = as_opponent
	_build_frame()
	_build_display()
	_build_zones()
	_build_ready_label()
	_build_banner()
	_refresh_display(false)
	_refresh_plaque()

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
	if _on_belt or not is_complete():
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
	_refresh_ready_label()

func set_on_belt(away: bool) -> void:
	_on_belt = away
	if _display != null:
		_display.visible = not away
	_refresh_ready_label()

func is_on_belt() -> bool:
	return _on_belt

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
	_refresh_plaque()
	_pulse_attach()
	GameAudio.part_place()
	var loadout := to_loadout()
	if loadout.is_complete_set() and not before_set:
		_celebrate_power(loadout.stats().ability)
	elif Synergy.kinds_match(loadout.parts_array()) and not before_kind:
		_celebrate_synergy(Synergy.Level.KIND, Synergy.kind_of(part_view.part_def))
	if is_complete():
		GameAudio.fighter_complete()
	_refresh_ready_label()
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
		_refresh_plaque()
	_refresh_ready_label()
	part_detached.emit(self, part_view.part_def)
	assembly_changed.emit(self)
	return part_view

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
	_refresh_plaque()
	_refresh_ready_label()
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
	_display.scale = _display_rest_scale()
	_display.z_index = 1
	add_child(_display)
	_crate_back = _make_crate_sprite("CrateBack")
	_crate_front = _make_crate_sprite("CrateFront")
	_display.add_child(_crate_back)
	_display.add_child(_crate_front)
	CompositeResolver.apply_crate_back_to(_crate_back)
	CompositeResolver.apply_crate_front_to(_crate_front)
	_plaque = CratePlaque.new()
	_plaque.name = "CratePlaque"
	_display.add_child(_plaque)
	for slot in PartSlotType.draw_order():
		var sprite := Sprite2D.new()
		sprite.name = String(PartSlotType.to_string_name(slot))
		sprite.centered = true
		sprite.visible = false
		_display.add_child(sprite)
		_layer_sprites[slot] = sprite

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

func _build_ready_label() -> void:
	if _ready_label != null:
		return
	_ready_label = GameTheme.make_label(
		"PRONTO",
		32,
		Vector2(0.0, AssemblyLayout.READY_LABEL_DROP),
		AssemblyLayout.READY_LABEL_SIZE,
		ThemeTokens.GOLD
	)
	_ready_label.z_index = 8
	add_child(_ready_label)
	_refresh_ready_label()

func _build_banner() -> void:
	if _banner != null:
		return
	_banner = GameTheme.make_label("", 30, Vector2(0, -216), Vector2(280, 44), ThemeTokens.GOLD)
	_banner.z_index = 9
	_banner.modulate.a = 0.0
	add_child(_banner)

func _refresh_ready_label() -> void:
	if _ready_label == null:
		return
	var ready := can_fight()
	_ready_label.visible = ready
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
	if _display == null or _crate_back == null or _crate_front == null:
		return
	CompositeResolver.apply_crate_back_to(_crate_back)
	CompositeResolver.apply_crate_front_to(_crate_front)
	var body: Sprite2D = _layer_sprites.get(PartSlotType.Value.BODY)
	const BODY_Z := 0
	_crate_back.z_index = CompositeResolver.crate_back_z(BODY_Z)
	_crate_front.z_index = CompositeResolver.crate_front_z(BODY_Z)
	var next := 0
	_display.move_child(_crate_back, next)
	next += 1
	if body != null:
		body.z_index = BODY_Z
		_display.move_child(body, next)
		next += 1
	_display.move_child(_crate_front, next)
	next += 1
	if _plaque != null:
		_plaque.position = CompositeResolver.crate_front_position()
		_plaque.z_index = CompositeResolver.crate_plaque_z(BODY_Z)
		_display.move_child(_plaque, next)
		next += 1
	for slot in [PartSlotType.Value.ARM_L, PartSlotType.Value.ARM_R, PartSlotType.Value.HEAD]:
		var sprite: Sprite2D = _layer_sprites.get(slot)
		if sprite == null:
			continue
		sprite.z_index = 2 if PartSlotType.is_arm(slot) else 3
		_display.move_child(sprite, mini(next, _display.get_child_count() - 1))
		next += 1

func _make_crate_sprite(node_name: String) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.name = node_name
	sprite.centered = true
	return sprite

func _refresh_plaque() -> void:
	if _plaque == null:
		return
	_plaque.show_loadout(to_loadout())

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
	if _plaque != null:
		_plaque.play_pulse()

func _display_rest_scale() -> Vector2:
	return Vector2.ONE * AssemblyLayout.CARD_FREAK_SCALE

func _pulse_attach() -> void:
	var rest := _display_rest_scale()
	Feel.punch(_display, rest * Vector2(1.08, 0.92), rest)
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
