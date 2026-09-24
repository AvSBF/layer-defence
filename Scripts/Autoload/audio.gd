extends Node

## Tiny pooled SFX player. Sounds are procedurally generated 8-bit wavs, so
## there is no music/streaming machinery here - just fire and forget.

const DIR := "res://Aseprites/Sound/"
const VOICES := 12

var _players : Array[AudioStreamPlayer] = []
var _next : int = 0
var _cache : Dictionary = {}
var _volume_db : float = -6.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in VOICES:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_players.append(p)

func play(sound : String, pitch_variation : float = 0.08, volume_db : float = 0.0) -> void:
	var stream := _get_stream(sound)
	if stream == null:
		return
	var p := _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = stream
	p.pitch_scale = clampf(1.0 + randf_range(-pitch_variation, pitch_variation), 0.4, 2.0)
	p.volume_db = _volume_db + volume_db
	p.play()

func play_pitched(sound : String, pitch : float, volume_db : float = 0.0) -> void:
	var stream := _get_stream(sound)
	if stream == null:
		return
	var p := _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = stream
	p.pitch_scale = clampf(pitch, 0.4, 2.0)
	p.volume_db = _volume_db + volume_db
	p.play()

func _get_stream(sound : String) -> AudioStream:
	if _cache.has(sound):
		return _cache[sound]
	var path := DIR + sound
	if not path.ends_with(".wav"):
		path += ".wav"
	if not ResourceLoader.exists(path):
		push_warning("[Audio] missing " + path)
		return null
	var stream : AudioStream = load(path)
	_cache[sound] = stream
	return stream
