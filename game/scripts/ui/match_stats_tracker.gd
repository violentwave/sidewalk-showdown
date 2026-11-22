# MatchStatsTracker — the Results screen's presentation-only stats source
# (UI Phase 3b, docs/UI_SCREENS.md). It READS match state and fighter
# signals; it never writes a single byte of simulation state, never joins
# serialize()/load(), and pausing the tree freezes it with everything
# else. Stats not recorded anywhere by MatchRoot are listed here instead
# of being invented:
#   - per-round win-type letters (K/T/M/D): MatchRoot only distinguishes
#     the CURRENT round's KO/timeout; no history exists — the Results
#     panel shows the plain rounds-won tally instead.
#   - damage dealt: MatchRoot only keeps round_damage, reset every round;
#     the tracker accumulates the deltas into match totals.
class_name MatchStatsTracker
extends Node

var wins: Array[int] = [0, 0]
# Match-total damage dealt per side (accumulated from round_damage deltas).
var damage: Array[float] = [0.0, 0.0]
var max_combo: Array[int] = [0, 0]
var meth_used: Array[bool] = [false, false]
# Frames left on the final round's clock when the match ended.
var time_left_frames := 0

var _match_root: Node
var _last_round_damage: Array[float] = [0.0, 0.0]


func attach(match_root: Node) -> void:
	# MatchRoot builds its fighters in _ready; if the match has not entered
	# the tree yet, retry the attach at the end of the frame.
	var p1: FighterBase = match_root.p1
	if p1 == null or match_root.p2 == null:
		call_deferred("attach", match_root)
		return
	_match_root = match_root
	var p2: FighterBase = match_root.p2
	p1.combo_changed.connect(func(count: int):
		max_combo[0] = maxi(max_combo[0], count))
	p2.combo_changed.connect(func(count: int):
		max_combo[1] = maxi(max_combo[1], count))
	p1.meth_started.connect(func(_move_name: String): meth_used[0] = true)
	p2.meth_started.connect(func(_move_name: String): meth_used[1] = true)


func snapshot() -> Dictionary:
	# Read the live match state once, at match end.
	if _match_root != null:
		wins[0] = _match_root.wins[0]
		wins[1] = _match_root.wins[1]
		time_left_frames = _match_root.timer_frames
	return {
		"wins": [wins[0], wins[1]],
		"winner": 0 if wins[0] > wins[1] else 1,
		"damage": [damage[0], damage[1]],
		"max_combo": [max_combo[0], max_combo[1]],
		"meth_used": [meth_used[0], meth_used[1]],
		"time_left_frames": time_left_frames,
	}


func _physics_process(_delta: float) -> void:
	# Accumulate per-side damage from MatchRoot's per-round counter: the
	# value grows within a round and resets to zero at each round start;
	# a drop is a reset, not negative damage.
	if _match_root == null or not is_instance_valid(_match_root):
		return
	for side in 2:
		var current: float = _match_root.round_damage[side]
		var delta: float = current - _last_round_damage[side]
		if delta > 0.0:
			damage[side] += delta
		_last_round_damage[side] = current
