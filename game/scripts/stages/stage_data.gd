# StageData — registry entry for a playable stage. The match builds its stage
# from `scene`; `display_name` is the label shown in menus. `id` is the stable
# key stored by the front-end flow (never a roster index), and `thumbnail` is
# the 80x45 selector preview. Adding a stage means adding a .tscn plus one of
# these to the roster, with no MatchRoot changes.
class_name StageData
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var thumbnail: Texture2D
@export var scene: PackedScene
