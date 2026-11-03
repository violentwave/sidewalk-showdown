# MoveData — one attack's frame data. All timings are simulation frames (60Hz).
class_name MoveData
extends Resource

enum InputType { LIGHT, HEAVY, SPECIAL_NEUTRAL, SPECIAL_FWD, SPECIAL_DOWN, SPECIAL_BACK, SPECIAL_AIR, GRAB }
enum Stance { STAND, CROUCH, AIR }
enum Level { MID, LOW, OVERHEAD, THROW }

@export var id: String = "move"
@export var input: InputType = InputType.LIGHT
@export var stance: Stance = Stance.STAND
@export var level: Level = Level.MID

@export_group("Timing")
@export var startup: int = 4
@export var active: int = 2
@export var recovery: int = 8

@export_group("On hit")
@export var damage: float = 35.0
@export var block_damage: float = 2.0
@export var hitstun: int = 12
@export var blockstun: int = 8
@export var knockback: Vector2 = Vector2(60, 0)
@export var knockdown: bool = false

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

func total_frames() -> int:
	return startup + active + recovery

func is_active_frame(frame: int) -> bool:
	return frame >= startup and frame < startup + active

func hitbox_rect(fighter_pos: Vector2, facing: int) -> Rect2:
	var center := fighter_pos + Vector2(hitbox_offset.x * facing, hitbox_offset.y)
	return Rect2(center - hitbox_size * 0.5, hitbox_size)
