# MatchRoster — the single source of truth for the playable cast and stages.
# Character select and the match both read this resource, so adding a fighter or
# stage never requires editing MatchRoot.gd or the select screen.
class_name MatchRoster
extends Resource

const DEFAULT_PATH := "res://resources/match_roster.tres"

@export var fighters: Array[FighterData] = []
@export var stages: Array[StageData] = []


# Shared entry point so a scene run without the main flow (tests, tools) still
# gets the same roster as the game.
static func load_default() -> MatchRoster:
	var res := load(DEFAULT_PATH)
	return res as MatchRoster
