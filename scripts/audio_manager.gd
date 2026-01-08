extends Node

@export var master_volume_db: float = -10.0
@export var sfx_volume_db: float = -6.0
@export var music_volume_db: float = -14.0

var _sfx_player: AudioStreamPlayer
var _sfx_generator: AudioStreamGenerator
var _sfx_playback: AudioStreamGeneratorPlayback

var _music_player: AudioStreamPlayer
var _music_generator: AudioStreamGenerator
var _music_playback: AudioStreamGeneratorPlayback
var _music_phase: float = 0.0

func _ready() -> void:
	_setup_sfx()
	_setup_music()

func _process(delta: float) -> void:
	_play_music(delta)

func _setup_sfx() -> void:
	_sfx_generator = AudioStreamGenerator.new()
	_sfx_generator.mix_rate = 44100
	_sfx_generator.buffer_length = 0.2
	_sfx_player = AudioStreamPlayer.new()
	_sfx_player.stream = _sfx_generator
	_sfx_player.volume_db = master_volume_db + sfx_volume_db
	add_child(_sfx_player)
	_sfx_player.play()
	_sfx_playback = _sfx_player.get_stream_playback()

func _setup_music() -> void:
	_music_generator = AudioStreamGenerator.new()
	_music_generator.mix_rate = 44100
	_music_generator.buffer_length = 0.4
	_music_player = AudioStreamPlayer.new()
	_music_player.stream = _music_generator
	_music_player.volume_db = master_volume_db + music_volume_db
	add_child(_music_player)
	_music_player.play()
	_music_playback = _music_player.get_stream_playback()

func _play_music(delta: float) -> void:
	if _music_playback == null:
		return
	var frames = int(_music_generator.mix_rate * delta)
	for i in range(frames):
		_music_phase += 1.0 / _music_generator.mix_rate
		var chord = sin(TAU * 220.0 * _music_phase) * 0.08
		chord += sin(TAU * 277.18 * _music_phase) * 0.06
		chord += sin(TAU * 329.63 * _music_phase) * 0.05
		_music_playback.push_frame(Vector2(chord, chord))

func play_blip(frequency: float, duration: float = 0.12) -> void:
	if _sfx_playback == null:
		return
	var frames = int(_sfx_generator.mix_rate * duration)
	for i in range(frames):
		var t = float(i) / _sfx_generator.mix_rate
		var envelope = lerp(1.0, 0.0, t / duration)
		var sample = sin(TAU * frequency * t) * 0.22 * envelope
		_sfx_playback.push_frame(Vector2(sample, sample))

func set_master_volume(value_db: float) -> void:
	master_volume_db = value_db
	_sfx_player.volume_db = master_volume_db + sfx_volume_db
	_music_player.volume_db = master_volume_db + music_volume_db

func set_sfx_volume(value_db: float) -> void:
	sfx_volume_db = value_db
	_sfx_player.volume_db = master_volume_db + sfx_volume_db

func set_music_volume(value_db: float) -> void:
	music_volume_db = value_db
	_music_player.volume_db = master_volume_db + music_volume_db
