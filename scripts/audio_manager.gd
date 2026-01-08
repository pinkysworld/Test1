extends Node

@export var master_volume_db: float = -6.0
@export var sfx_volume_db: float = -3.0

var _player: AudioStreamPlayer
var _generator: AudioStreamGenerator
var _playback: AudioStreamGeneratorPlayback

func _ready() -> void:
	_generator = AudioStreamGenerator.new()
	_generator.mix_rate = 44100
	_generator.buffer_length = 0.3
	_player = AudioStreamPlayer.new()
	_player.stream = _generator
	_player.volume_db = master_volume_db + sfx_volume_db
	add_child(_player)
	_player.play()
	_playback = _player.get_stream_playback()

func play_blip(frequency: float, duration: float = 0.12) -> void:
	if _playback == null:
		return
	var frames = int(_generator.mix_rate * duration)
	for i in range(frames):
		var t = float(i) / _generator.mix_rate
		var sample = sin(TAU * frequency * t) * 0.2
		_playback.push_frame(Vector2(sample, sample))

func set_master_volume(value_db: float) -> void:
	master_volume_db = value_db
	_player.volume_db = master_volume_db + sfx_volume_db

func set_sfx_volume(value_db: float) -> void:
	sfx_volume_db = value_db
	_player.volume_db = master_volume_db + sfx_volume_db
