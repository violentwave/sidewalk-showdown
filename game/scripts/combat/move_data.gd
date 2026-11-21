# MoveData — one attack's frame data. All timings are simulation frames (60Hz).
class_name MoveData
extends Resource

enum InputType { LIGHT, HEAVY, SPECIAL_NEUTRAL, SPECIAL_FWD, SPECIAL_DOWN, SPECIAL_BACK, SPECIAL_AIR, GRAB, COMMAND_GRAB }
enum Stance { STAND, CROUCH, AIR }
enum Level { MID, LOW, OVERHEAD, THROW }
enum Invuln { NONE, STRIKE, THROW, FULL }

@export var id: String = "move"
@export var input: InputType = InputType.LIGHT
@export var stance: Stance = Stance.STAND
@export var level: Level = Level.MID

@export_group("Timing")
@export var startup: int = 4
@export var active: int = 2
@export var recovery: int = 8

@export_group("Throw")
# Per-row whiff-recovery override (PROPOSALS §7): 0 keeps FighterData's
# throw_whiff_recovery; a positive value overrides it for this row only (the
# command grabs author 24/26 so their whiffs are punishable on their own terms).
@export var whiff_recovery: int = 0

@export_group("On hit")
@export var damage: float = 35.0
@export var block_damage: float = 2.0
@export var hitstun: int = 12
@export var blockstun: int = 8
@export var knockback: Vector2 = Vector2(60, 0)
@export var knockdown: bool = false
# PROPOSALS §6: authored blocked pushback in px/s, independent of hit
# knockback. Every strike row carries the parity value 45.0.
@export var block_pushback: float = 45.0

@export_group("Meter")
@export var meter_gain_hit: float = 6.0
@export var meter_gain_block: float = 3.0
@export var meter_gain_whiff: float = 1.5
@export var meter_gain_receive: float = 4.0

@export_group("Hitbox (relative to feet, forward = facing dir)")
@export var hitbox_offset: Vector2 = Vector2(20, -40)
@export var hitbox_size: Vector2 = Vector2(26, 20)

@export_group("Feel")
@export var hitstop: int = 4

@export_group("Landing")
# Extra authored air-move landing lockout after a whiff. Zero preserves the
# legacy 2-frame LAND state. The field is used only for whiffed AIR moves.
@export var landing_recovery: int = 0

@export_group("Invulnerability")
@export var invuln_kind: Invuln = Invuln.NONE
@export var invuln_start: int = 0 # inclusive, frames from move start
@export var invuln_end: int = 0 # exclusive

@export_group("Meter spender (EX)")
# Set on strengthened variants: the move costs this much hype meter and is only
# reachable through the EX input, never through the base special lookup.
@export var meter_cost: float = 0.0
@export var ex: bool = false

@export_group("Cancels")
# Authored hit-confirm cancel routes (PROPOSALS §6); evaluated by FighterBase.
@export var cancels: Array[CancelRule] = []

@export_group("METHtality")
# Marks a finisher row. Finishers are referenced by FighterData.meth_move and
# are never returned by find_move()/find_ex_move().
@export var meth: bool = false

@export_group("Juggle")
# Phase 2 launcher marker: pure data for tooling, the CPU, and the HUD. The
# launch itself is still authored knockback (positive y, knockdown false) —
# this flag changes no behavior on its own.
@export var launcher: bool = false

func total_frames() -> int:
	return startup + active + recovery

func is_active_frame(frame: int) -> bool:
	return frame >= startup and frame < startup + active

func hitbox_rect(fighter_pos: Vector2, facing: int) -> Rect2:
	var center := fighter_pos + Vector2(hitbox_offset.x * facing, hitbox_offset.y)
	return Rect2(center - hitbox_size * 0.5, hitbox_size)
