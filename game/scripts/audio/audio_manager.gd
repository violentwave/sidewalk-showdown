# Minimal Phase 2 mixer for temporary prototype audio assets.
extends Node

const MUSIC_PATH := "res://audio/temporary/music_bus_stop_loop_temp.ogg"
const INTRO_MUSIC_PATH := "res://audio/temporary/intro.mp3"
const SFX_PATHS: Dictionary = {
	"hit_light": "res://audio/temporary/sfx_hit_light_temp.ogg",
	"hit_heavy": "res://audio/temporary/sfx_hit_heavy_temp.ogg",
	"block": "res://audio/temporary/sfx_block_temp.ogg",
	"meth": "res://audio/temporary/sfx_meth_temp.ogg",
	"ko": "res://audio/temporary/sfx_ko_temp.ogg",
	"round_start": "res://audio/temporary/sfx_round_start_temp.ogg",
	"menu_move": "res://audio/temporary/sfx_menu_move_temp.ogg",
	"menu_confirm": "res://audio/temporary/sfx_menu_confirm_temp.ogg",
}
const SFX_PLAYER_COUNT := 12

var music_player: AudioStreamPlayer
var intro_music_stream: AudioStreamMP3
var match_music_stream: AudioStreamOggVorbis
var sfx_players: Array[AudioStreamPlayer] = []
var _sfx_streams: Dictionary = {}
var _next_sfx_player := 0

func _ready() -> void:
	intro_music_stream = load(INTRO_MUSIC_PATH) as AudioStreamMP3
	if intro_music_stream:
		intro_music_stream.loop = true
	match_music_stream = load(MUSIC_PATH) as AudioStreamOggVorbis
	if match_music_stream:
		match_music_stream.loop = true
	music_player = AudioStreamPlayer.new()
	music_player.name = "TemporaryMusic"
	music_player.stream = intro_music_stream
	music_player.volume_db = -15.0
	add_child(music_player)
	for sound_id in SFX_PATHS:
		_sfx_streams[sound_id] = load(SFX_PATHS[sound_id])

	for index in SFX_PLAYER_COUNT:
		var player := AudioStreamPlayer.new()
		player.name = "SFXPlayer%d" % index
		player.volume_db = -5.0
		add_child(player)
		sfx_players.append(player)

func _exit_tree() -> void:
	stop_all()
	_sfx_streams.clear()

func start_music() -> void:
	if music_player and match_music_stream:
		if music_player.stream != match_music_stream:
			music_player.stop()
			music_player.stream = match_music_stream
		if not music_player.playing:
			music_player.play()

func start_intro_music() -> void:
	if music_player and intro_music_stream:
		if music_player.stream != intro_music_stream:
			music_player.stop()
			music_player.stream = intro_music_stream
		if not music_player.playing:
			music_player.play()

func play_ui_move() -> void:
	play_sfx("menu_move")

func play_ui_confirm() -> void:
	play_sfx("menu_confirm")

func stop_all() -> void:
	if music_player:
		music_player.stop()
		music_player.stream = null
	for player in sfx_players:
		player.stop()
		player.stream = null

func play_sfx(sound_id: String) -> void:
	if not _sfx_streams.has(sound_id):
		return
	var player := _acquire_sfx_player()
	player.stream = _sfx_streams[sound_id]
	player.volume_db = -9.0 if sound_id in ["menu_move", "menu_confirm"] else -4.0
	player.play()

func has_active_sfx() -> bool:
	for player in sfx_players:
		if player.playing:
			return true
	return false

func _acquire_sfx_player() -> AudioStreamPlayer:
	for offset in sfx_players.size():
		var index := (_next_sfx_player + offset) % sfx_players.size()
		if not sfx_players[index].playing:
			_next_sfx_player = (index + 1) % sfx_players.size()
			return sfx_players[index]
	var reused := sfx_players[_next_sfx_player]
	reused.stop()
	_next_sfx_player = (_next_sfx_player + 1) % sfx_players.size()
	return reused
