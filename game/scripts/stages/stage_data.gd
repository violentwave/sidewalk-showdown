# StageData — registry entry for a playable stage. The match builds its stage
# from `scene`; `display_name` is the label shown in menus. Adding a stage means
# adding a .tscn plus one of these to the roster, with no MatchRoot changes.
class_name StageData
extends Resource

@export var display_name: String = ""
@export var scene: PackedScene
