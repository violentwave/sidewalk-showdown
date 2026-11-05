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

@export var moves: Array[MoveData] = []

func find_move(input: MoveData.InputType, stance: MoveData.Stance) -> MoveData:
	for move in moves:
		if move.input == input and move.stance == stance:
			return move
	# stance fallback: air -> stand, crouch -> stand
	if stance != MoveData.Stance.STAND:
		for move in moves:
			if move.input == input and move.stance == MoveData.Stance.STAND:
				return move
	return null
