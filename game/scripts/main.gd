# Main flow: The Clip intro, character select, then the match.
extends Node

const CHARACTER_SELECT_SCENE := preload("res://scenes/menus/CharacterSelect.tscn")
const THE_CLIP_SCENE := preload("res://scenes/menus/TheClip.tscn")
const MATCH_SCENE := preload("res://scenes/match/MatchRoot.tscn")
const AUDIO_MANAGER_SCRIPT := preload("res://scripts/audio/audio_manager.gd")
const ROSTER_PATH := "res://resources/match_roster.tres"

var intro: Control
var character_select: Control
var match_root: Node
var audio_manager
var roster: MatchRoster

func _ready() -> void:
	roster = load(ROSTER_PATH) as MatchRoster
	audio_manager = AUDIO_MANAGER_SCRIPT.new()
	add_child(audio_manager)
	_show_intro()

func _show_intro() -> void:
	audio_manager.start_intro_music()
	intro = THE_CLIP_SCENE.instantiate()
	intro.audio_manager = audio_manager
	intro.intro_finished.connect(_on_intro_finished)
	add_child(intro)

func _on_intro_finished() -> void:
	if intro != null:
		intro.queue_free()
		intro = null
	_show_character_select()

func _show_character_select() -> void:
	character_select = CHARACTER_SELECT_SCENE.instantiate()
	character_select.roster = roster
	character_select.match_requested.connect(_start_match)
	character_select.selection_moved.connect(audio_manager.play_ui_move)
	character_select.selection_confirmed.connect(audio_manager.play_ui_confirm)
	add_child(character_select)

func _start_match(p1_data: FighterData, p2_data: FighterData) -> void:
	if match_root != null:
		return
	audio_manager.start_music()
	match_root = MATCH_SCENE.instantiate()
	match_root.roster = roster
	match_root.selected_p1_data = p1_data
	match_root.selected_p2_data = p2_data
	match_root.audio_manager = audio_manager
	add_child(match_root)
	character_select.queue_free()
	character_select = null
