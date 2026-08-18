extends Node

## Global one-shot sound effects (autoload node name: Sfx).
## Prefer calling via GameAudio from gameplay scripts.

const POOL_SIZE := 12
const SFX_BUS := &"SFX"

const PATHS := {
	"hammer_hit": "res://assets/audio/sfx/hammer_hit.wav",
	"crate_crack": "res://assets/audio/sfx/crate_crack.wav",
	"crate_break": "res://assets/audio/sfx/crate_break.wav",
	"part_pickup": "res://assets/audio/sfx/part_pickup.wav",
	"part_place": "res://assets/audio/sfx/part_place.wav",
	"part_reject": "res://assets/audio/sfx/part_reject.wav",
	"fighter_complete": "res://assets/audio/sfx/fighter_complete.wav",
	"impact": "res://assets/audio/sfx/impact.wav",
	"step": "res://assets/audio/sfx/step.wav",
	"wood_slide": "res://assets/audio/sfx/wood_slide.wav",
}

var _streams: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _next: int = 0
var _master_db: float = -1.0

func _ready() -> void:
	_ensure_sfx_bus()
	_load_streams()
	for i in POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.name = "SfxPlayer_%d" % i
		player.bus = SFX_BUS
		add_child(player)
		_players.append(player)

func _ensure_sfx_bus() -> void:
	if AudioServer.get_bus_index(SFX_BUS) >= 0:
		return
	var idx := AudioServer.bus_count
	AudioServer.add_bus(idx)
	AudioServer.set_bus_name(idx, SFX_BUS)
	AudioServer.set_bus_send(idx, &"Master")
	var compressor := AudioEffectCompressor.new()
	compressor.threshold = -12.0
	compressor.ratio = 2.5
	compressor.attack_us = 40.0
	compressor.release_ms = 90.0
	compressor.mix = 0.7
	AudioServer.add_bus_effect(idx, compressor)
	var limiter := AudioEffectLimiter.new()
	limiter.ceiling_db = -0.5
	limiter.threshold_db = -2.0
	AudioServer.add_bus_effect(idx, limiter)

func _load_streams() -> void:
	for key in PATHS.keys():
		var path: String = PATHS[key]
		if not ResourceLoader.exists(path):
			push_warning("Sfx file missing: %s" % path)
			continue
		var stream := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REUSE) as AudioStream
		if stream == null:
			push_warning("Sfx failed to load: %s" % path)
			continue
		if stream is AudioStreamWAV:
			(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_DISABLED
		_streams[key] = stream

func play(id: StringName, volume_db: float = 0.0, pitch_scale: float = 1.0) -> void:
	var key := String(id)
	if not _streams.has(key):
		return
	if _players.is_empty():
		return
	var player := _players[_next]
	_next = (_next + 1) % _players.size()
	player.stop()
	player.stream = _streams[key]
	player.volume_db = _master_db + volume_db
	player.pitch_scale = clampf(pitch_scale, 0.7, 1.4)
	player.play()

func hammer_hit() -> void:
	play(&"hammer_hit", -2.0, randf_range(0.97, 1.04))

func crate_crack() -> void:
	play(&"crate_crack", -3.0, randf_range(0.96, 1.05))

func crate_break() -> void:
	play(&"crate_break", -3.5, randf_range(0.96, 1.03))

func open_crate() -> void:
	hammer_hit()
	var tree := get_tree()
	if tree == null:
		crate_break()
		return
	tree.create_timer(0.05).timeout.connect(crate_break)

func part_pickup() -> void:
	play(&"part_pickup", -7.0, randf_range(0.97, 1.08))

func part_place() -> void:
	play(&"part_place", -5.0, randf_range(0.97, 1.04))

func part_reject() -> void:
	play(&"part_reject", -7.0, randf_range(0.96, 1.03))

func fighter_complete() -> void:
	play(&"fighter_complete", -4.0, 1.0)

func impact() -> void:
	play(&"impact", -1.5, randf_range(0.93, 1.06))

func step() -> void:
	play(&"step", -11.0, randf_range(0.92, 1.1))

func wood_slide() -> void:
	play(&"wood_slide", -7.0, randf_range(0.92, 1.08))

func ui_click() -> void:
	play(&"part_pickup", -11.0, randf_range(1.1, 1.22))
