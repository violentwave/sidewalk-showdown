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
