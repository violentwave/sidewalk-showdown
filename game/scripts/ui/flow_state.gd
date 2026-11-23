# FlowState — the single home for front-end flow context (docs/UI_SCREENS.md).
# Pure presentation bookkeeping; nothing here enters the simulation or
# MatchRoot.serialize()/load(). Owned by main.gd, carried by ScreenRouter.
class_name FlowState
extends RefCounted

# Solo (1P vs CPU) or local versus.
var solo_mode := false
# Training (GDD 6.4): entered from the main menu's TRAINING slat. P1 picks
# both fighters solo-style, the match runs under training rules, and the
# flag routes the flow's back/hand-off paths.
var training_mode := false
# CPU level for solo mode (0 EASY / 1 NORMAL / 2 HARD); kept across
# matches like the other flow choices.
var cpu_level := 1
# Matchup of the last match, restored when returning to character select.
var last_p1_choice := -1
var last_p2_choice := -1
# Stable StageData id of the last pick, including a resolved RANDOM result.
var last_stage_id := ""
# Fighters picked on character select, waiting for the stage choice.
var pending_p1_data: FighterData
var pending_p2_data: FighterData
# The stage confirmed on stage select (or kept for a rematch), waiting for
# the match. The VS bumper and the rematch path both read it.
var pending_stage: StageData
