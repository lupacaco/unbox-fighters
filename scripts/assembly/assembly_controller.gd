class_name AssemblyController
extends Node2D

@onready var _slots_root: Node2D = $Slots
@onready var _tray: Node2D = $Tray
@onready var _shelf: Sprite2D = $Tray/Shelf
@onready var _drag_service: DragDropService = $DragDropService
@onready var _title: Label = $HUD/Title
@onready var _subtitle: Label = $HUD/Subtitle

var _part_scene: PackedScene = preload("res://scenes/assembly/PartView.tscn")
var _crate_scene: PackedScene = preload("res://scenes/assembly/Crate.tscn")
var _slot_scene: PackedScene = preload("res://scenes/assembly/CharacterSlot.tscn")

var _vampiro: CharacterDef
var _policial: CharacterDef
var _card_characters: Array[CharacterDef] = []
var _reward_parts: Array[PartDef] = []
var _slots: Array[CharacterSlot] = []

func _ready() -> void:
	_drag_service.add_to_group("drag_drop_service")
	_build_character_data()
	_setup_tray_visual()
	_spawn_slots()
	_spawn_crates()
	_drag_service.setup(_slots, _tray)
	_play_intro()

func _build_character_data() -> void:
	_vampiro = load("res://data/parts/vampiro_character.tres") as CharacterDef
	_policial = load("res://data/parts/policial_character.tres") as CharacterDef
	# Left / center / right cards: vampiro, policial, vampiro
	_card_characters = [_vampiro, _policial, _vampiro]
	# 6 crates = full set for vampiro + full set for policial
	_reward_parts = [
		_vampiro.head,
		_vampiro.body,
		_vampiro.legs,
		_policial.head,
		_policial.body,
		_policial.legs,
	]

func _setup_tray_visual() -> void:
	_tray.position = Vector2(960, 920)
	var shelf_tex: Texture2D = load("res://assets/ui/shelf_premium.png")
	_shelf.texture = shelf_tex
	_shelf.centered = true
	_shelf.position = Vector2(0, 58)
	var tex_size := shelf_tex.get_size()
	_shelf.scale = Vector2(1480.0 / tex_size.x, 170.0 / tex_size.y)
	_shelf.modulate = Color(0.9, 0.92, 0.95, 1)

func _spawn_slots() -> void:
	var xs := [380.0, 960.0, 1540.0]
	for i in xs.size():
		var slot := _slot_scene.instantiate() as CharacterSlot
		_slots_root.add_child(slot)
		slot.position = Vector2(xs[i], 400)
		slot.setup(_card_characters[i])
		slot.play_intro(0.12 * float(i))
		_slots.append(slot)

func _spawn_crates() -> void:
	var count := _reward_parts.size()
	var spacing := 200.0 if count > 5 else 230.0
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
