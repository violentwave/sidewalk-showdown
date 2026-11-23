# FighterData — everything that makes a fighter a fighter. The engine is name-agnostic.
class_name FighterData
extends Resource

@export var id: String = "fighter"
@export var display_name: String = "Fighter"
@export var max_health: float = 1000.0
@export var walk_speed_fwd: float = 90.0
@export var walk_speed_back: float = 70.0
@export var jump_speed: float = 270.0
@export var body_width: float = 28.0
@export var body_height: float = 56.0
@export var body_color: Color = Color(0.95, 0.55, 0.15)

@export_group("Knockdown")
# Total frames in WAKE_UP; the invulnerable slice inside it is authored separately.
@export var wakeup_frames: int = 12
# Frames of universal wake-up invulnerability, counted from WAKE_UP frame 0.
@export var wakeup_invuln_frames: int = 6
# Throws stay rejected for this long; raise it if throw loops appear.
@export var wakeup_throw_invuln_frames: int = 8

@export_group("Throw Tech")
# PROPOSALS §2: the defender can break a throw by having a grab buffered within
# this many frames of the throw connecting (measured against input_buffer).
@export var throw_tech_window: int = 7
# Both fighters enter TECH for this long after a successful tech, pushed apart.
@export var throw_tech_recovery: int = 10
# Replaces the grab move's authored recovery when the throw whiffs, so raw
# throws stay punishable. Damage stays unchanged; see KNOWN_ISSUES.md.
@export var throw_whiff_recovery: int = 22

@export_group("METHtality")
# Canon: one unique finisher per fighter, all strings live in the .tres.
@export var meth_name: String = "METHtality"
# The finisher move itself (MoveData.meth = true). Not part of `moves`.
@export var meth_move: MoveData

@export_group("Presentation FX (Phase C)")
# Per-fighter hit/block/whoosh/trail sheet set (docs/FX_AND_METH_DESIGN.md §2).
# Presentation only: the FX layer reads every sheet from here, so a future
# fighter plugs in by authoring its own FxSet resource. Null = no hit FX and
# no combat behavior change.
@export var fx_set: FxSet

# COMBO_SYSTEM_DESIGN §9.3: the combo economics as data. Null falls back to
# the ComboTuning class defaults (identical to the legacy ladder).
@export var combo_tuning: ComboTuning

# Dial-a-combos owned by this fighter (§9.2). Empty = none authored.
@export var macros: Array[MacroData] = []

@export_group("Combo Breaker (Phase 3, §9.4/§11)")
# Decision #1: one free breaker per round, extra breaks cost meter. A defender
# with zero meter still gets the free break — the landed-hits economy never
# pays the defender, so this is the sanctioned "no" button.
@export var breaker_free_per_round: int = 1
@export var breaker_meter_cost: float = 40.0
# 5 s between breaks (fairness rail so the free tier cannot replace blocking).
@export var breaker_cooldown_frames: int = 300
# The two buffered actions that must be live together during hitstun/juggle.
@export var breaker_input: Array[StringName] = [&"grab", &"special"]

@export var moves: Array[MoveData] = []

# PROPOSALS §7: the per-fighter command grab row (input COMMAND_GRAB). Distinct
# lookup from find_move(), so grab resolution never collides with the five
# normal specials or the techable normal throw.
func find_command_grab() -> MoveData:
	for move in moves:
		if move.input == MoveData.InputType.COMMAND_GRAB:
			return move
	return null

func find_move(input: MoveData.InputType, stance: MoveData.Stance) -> MoveData:
	for move in moves:
		if not move.ex and move.input == input and move.stance == stance:
			return move
	# stance fallback: air -> stand, crouch -> stand
	if stance != MoveData.Stance.STAND:
		for move in moves:
			if not move.ex and move.input == input and move.stance == MoveData.Stance.STAND:
				return move
	return null

# EX variants live in the same data array; the base lookup above skips them so
# the normal special input never silently spends meter.
func find_ex_move(input: MoveData.InputType, stance: MoveData.Stance) -> MoveData:
	for move in moves:
		if move.ex and move.input == input and move.stance == stance:
			return move
	if stance != MoveData.Stance.STAND:
		for move in moves:
			if move.ex and move.input == input and move.stance == MoveData.Stance.STAND:
				return move
	return null
