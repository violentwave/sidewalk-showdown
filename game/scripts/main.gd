# Main flow: choose the vertical-slice fighters, then start the match.
extends Node

const CHARACTER_SELECT_SCENE := preload("res://scenes/menus/CharacterSelect.tscn")
const MATCH_SCENE := preload("res://scenes/match/MatchRoot.tscn")

var character_select: Control
var match_root: Node

func _ready() -> void:
	_show_character_select()

func _show_character_select() -> void:
	character_select = CHARACTER_SELECT_SCENE.instantiate()
	character_select.match_requested.connect(_start_match)
	add_child(character_select)

func _start_match(p1_data: FighterData, p2_data: FighterData) -> void:
	if match_root != null:
		return
	match_root = MATCH_SCENE.instantiate()
	match_root.selected_p1_data = p1_data
	match_root.selected_p2_data = p2_data
	add_child(match_root)
	character_select.queue_free()
	character_select = null
