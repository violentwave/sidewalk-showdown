# ComboTuning — the data-driven combo economics for one fighter
# (COMBO_SYSTEM_DESIGN §9.3). Owned by FighterData.combo_tuning; a shared
# default .tres keeps both fighters in sync. Nothing here is hardcoded in
# the engine: every number lives in a resource.
#
# The approved ladder (decision #4) is exactly the legacy _damage_scale():
# 1.0 / 1.0 / 0.85 / 0.70 / 0.55 for the 1st..Nth hit of a combo, so
# replacing the hardcoded function with this resource is a no-op for
# balance until the owner edits the .tres.
class_name ComboTuning
extends Resource

# Damage scale by 1-indexed hit position; the last entry is the floor for
# every later hit.
@export var scaling_curve: Array[float] = [1.0, 1.0, 0.85, 0.70, 0.55]

# Repeat-move penalty (decision: variety-based scaling). A move id used
# more than `repeat_freebies` times in one combo pays this per extra use.
@export var repeat_penalty: float = 0.9
@export var repeat_freebies: int = 1

# Variety bonus: this move plus the previous two all distinct -> +5%,
# never above 1.0 total.
@export var variety_bonus: float = 0.05

# Hard per-combo caps (decision: infinite prevention).
@export var combo_hit_cap: int = 12
@export var combo_damage_cap: float = 550.0

# Air hitstun decay: each air hit multiplies the authored hitstun, floored.
@export var air_hitstun_decay: float = 0.9
@export var air_hitstun_floor: int = 8

# Juggle point economics (Phase 2, decision #5): a launch grants the
# defender a point budget; each air hit spends from it by move type. When
# the budget cannot pay, the next air hit is REJECTED and stays live
# (meaty-safe, like the old flat cap). Air normals cost 2, air specials 3,
# so a normals-only juggle gets two hits, an air-special route gets one
# plus one normal, and no regen mid-combo.
@export var juggle_points_start: int = 5
@export var juggle_cost_normal: int = 2
@export var juggle_cost_air_special: int = 3

# Meter inside an active combo (decision #2): x0.5 from the second hit on,
# the multiplier itself never below the floor.
@export var meter_gain_in_combo: float = 0.5
@export var meter_gain_floor: float = 0.25

func ladder_for(hit_index: int) -> float:
	var idx: int = clampi(hit_index - 1, 0, scaling_curve.size() - 1)
	return scaling_curve[idx]
