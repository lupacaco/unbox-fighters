extends Node2D

## Cópia da montagem principal: mesmas mecânicas, 1 carta, só set do policial em 3D.

@onready var _slots_root: Node2D = $Slots
@onready var _tray: Node2D = $Tray
@onready var _shelf: Sprite2D = $Tray/Shelf
@onready var _fx_layer: Node2D = $FxLayer
@onready var _drag_service: DragDropService = $DragDropService
@onready var _title: Label = $HUD/Title
@onready var _subtitle: Label = $HUD/Subtitle

var _part_scene: PackedScene = preload("res://scenes/assembly3d/PartView3D.tscn")
var _crate_scene: PackedScene = preload("res://scenes/assembly/Crate.tscn")
var _slot_scene: PackedScene = preload("res://scenes/assembly3d/CharacterSlot3D.tscn")

var _policial: CharacterDef
var _roster: Array[CharacterDef] = []
var _reward_parts: Array[PartDef] = []
var _slots: Array[CharacterSlot] = []
var _fight_director: FightDirector3D

func _ready() -> void:
	_drag_service.add_to_group("drag_drop_service")
	_fight_director = FightDirector3D.new()
	add_child(_fight_director)
	_build_character_data()
	_setup_tray_visual()
	_spawn_slots()
	_spawn_crates()
	_drag_service.setup(_slots, _tray)
	_play_intro()
	_title.text = "UNBOX FIGHTERS — 3D"
	_subtitle.text = "Mesma montagem · só policial · giro/ataque em 3D · F6 nesta cena"

func _build_character_data() -> void:
	_policial = load("res://data/parts/policial_character.tres") as CharacterDef
	_roster = [_policial]
	_reward_parts = [_policial.head, _policial.body, _policial.legs]

func _setup_tray_visual() -> void:
	_tray.position = Vector2(960, 920)
	var shelf_tex: Texture2D = load("res://assets/ui/shelf_premium.png")
	_shelf.texture = shelf_tex
	_shelf.centered = true
	_shelf.position = Vector2(0, 58)
	var tex_size := shelf_tex.get_size()
	_shelf.scale = Vector2(1700.0 / tex_size.x, 170.0 / tex_size.y)
	_shelf.modulate = Color(0.9, 0.92, 0.95, 1)

func _spawn_slots() -> void:
	var slot := _slot_scene.instantiate() as CharacterSlot3D
	_slots_root.add_child(slot)
	slot.position = Vector2(960, 400)
	slot.setup(null, _roster)
	slot.fight_pressed.connect(_on_slot_fight_pressed)
	slot.play_intro(0.0)
	_slots.append(slot)

func _spawn_crates() -> void:
	var count := _reward_parts.size()
	var spacing := 230.0
	var start_x := -spacing * float(count - 1) * 0.5
	for i in count:
		var crate := _crate_scene.instantiate() as Crate
		_tray.add_child(crate)
		var rest := Vector2(start_x + spacing * float(i), -58)
		crate.position = Vector2(rest.x, rest.y + 24.0)
		crate.modulate.a = 0.0
		crate.setup(_reward_parts[i], _part_scene, _drag_service, _tray)
		crate.set_rest_y(rest.y)
		var tween := create_tween()
		tween.tween_interval(0.2 + 0.08 * float(i))
		tween.tween_property(crate, "modulate:a", 1.0, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(crate, "position:y", rest.y, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _play_intro() -> void:
	_title.modulate.a = 0.0
	_subtitle.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(_title, "modulate:a", 1.0, 0.5).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(_subtitle, "modulate:a", 1.0, 0.65).set_trans(Tween.TRANS_SINE)

func _on_slot_fight_pressed(slot: CharacterSlot) -> void:
	if _fight_director.is_busy():
		return
	if not slot.attached_parts_can_fight():
		return
	for other in _slots:
		if other != slot:
			other.set_fight_locked(true)
	await _fight_director.play(slot, _tray, _fx_layer, _drag_service)
	for other in _slots:
		other.set_fight_locked(false)
