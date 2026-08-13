extends Node

## Global one-shot sound effects (autoload node name: Sfx).
## Prefer calling via GameAudio from gameplay scripts.

const POOL_SIZE := 8

const PATHS := {
	"hammer_hit": "res://assets/audio/sfx/hammer_hit.wav",
	"crate_crack": "res://assets/audio/sfx/crate_crack.wav",
	"crate_break": "res://assets/audio/sfx/crate_break.wav",
	"part_pickup": "res://assets/audio/sfx/part_pickup.wav",
	"part_place": "res://assets/audio/sfx/part_place.wav",
	"part_reject": "res://assets/audio/sfx/part_reject.wav",
	"fighter_complete": "res://assets/audio/sfx/fighter_complete.wav",
}

var _streams: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _next: int = 0
var _master_db: float = -2.0

func _ready() -> void:
	_load_streams()
	for i in POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.name = "SfxPlayer_%d" % i
		player.bus = &"Master"
		add_child(player)
		_players.append(player)

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
	play(&"hammer_hit", 0.0, randf_range(0.96, 1.04))

func crate_crack() -> void:
	play(&"crate_crack", -1.0, randf_range(0.97, 1.05))

func crate_break() -> void:
	play(&"crate_break", 1.0, randf_range(0.95, 1.03))

func part_pickup() -> void:
	play(&"part_pickup", -2.0, randf_range(0.98, 1.06))

func part_place() -> void:
	play(&"part_place", -1.0, randf_range(0.98, 1.04))

func part_reject() -> void:
	play(&"part_reject", -3.0, randf_range(0.95, 1.02))

func fighter_complete() -> void:
	play(&"fighter_complete", 0.0, 1.0)

func impact() -> void:
	play(&"fighter_complete", 2.0, 0.86)

func land() -> void:
	play(&"hammer_hit", -4.0, 0.82)

func step() -> void:
	play(&"part_place", -8.0, randf_range(1.12, 1.28))

func whoosh() -> void:
	play(&"part_pickup", -6.0, randf_range(0.78, 0.9))
