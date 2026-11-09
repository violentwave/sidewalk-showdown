# CancelRule — one authored hit-confirm cancel route on a MoveData (PROPOSALS §6).
# Frames are simulation frames from move start; both bounds are inclusive.
# METHtality is not a rule target: its full-meter availability check stays
# global in FighterBase.
class_name CancelRule
extends Resource

enum Target { LIGHT, HEAVY, SPECIAL, EX }
enum Kind { CHAIN, CANCEL }
enum Condition { HIT, COUNTER_HIT, BLOCK, WHIFF }

@export var target: Target = Target.LIGHT
@export var kind: Kind = Kind.CHAIN
@export var condition: Condition = Condition.HIT
@export var from_frame: int = 0
@export var to_frame: int = 0

func window_open(frame: int) -> bool:
	return frame >= from_frame and frame <= to_frame

# Returns "" when the rule is legal to author. BLOCK and WHIFF are reserved until
# the resolver reports those outcomes; they are rejected rather than inferred.
func validate() -> String:
	if condition == Condition.BLOCK or condition == Condition.WHIFF:
		return "condition %s is reserved until the resolver reports it" % Condition.keys()[condition]
	if from_frame > to_frame:
		return "empty cancel window %d..%d" % [from_frame, to_frame]
	if kind == Kind.CHAIN and target != Target.LIGHT and target != Target.HEAVY:
		return "CHAIN must target a normal, not a special"
	if kind == Kind.CANCEL and target == Target.LIGHT:
		return "CANCEL must target a special or an EX special"
	return ""
