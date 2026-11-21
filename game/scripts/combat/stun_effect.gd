# StunEffect — one themed stun authored on a MoveData row
# (COMBO_SYSTEM_DESIGN §9.3 / §10.5, Phase 3). Pure data: the engine never
# hard-codes per-fighter stun values; every number lives here, in the .tres.
#
# Rules the engine enforces around this resource (owner decisions §15 #6/#7):
#   - a stun NEVER lands on an airborne target (launcher_safe ships false at
#     the schema level; no stun-into-juggle loops);
#   - a blocked stun move is just a blocked move — no stun, no meter;
#   - one stun per combo (once_per_combo), tracked off the defender's
#     ComboTracker history so the whole combo governs it;
#   - the stun window rides the existing HITSTUN state: duration_frames are
#     ADDED to the move's authored hitstun, frozen by hitstop like all stun
#     counters, and shake-out shortens it;
#   - when the hit is heavily scaled the window shrinks with the scale, and a
#     window that would fall below minimum_frames does not stun at all;
#   - after the stun ends, immunity_frames protect the defender.
class_name StunEffect
extends Resource

@export var id: StringName = &"stun"
@export var display_name: String = "Stunned"
# Total stun window added on top of the move's authored hitstun.
@export var duration_frames: int = 45
# Mash direction that shortens the window (a buffered action, like jump).
@export var shake_input: StringName = &"up"
@export var shake_frames_per_press: int = 3
# Cannot shake out before this many frames of the window have elapsed.
@export var minimum_frames: int = 20
# Immunity after the stun ends (Peggy 60 by owner decision 2026-11-21,
# Richard 240 per the §10.5 fairness rail; both authored in the .tres).
@export var immunity_frames: int = 240
@export var once_per_combo: bool = true
# Schema-level rail (decision #6): false = cannot stun an airborne target.
@export var launcher_safe: bool = false
# Visual identity only: the silhouette/sprite tint while stunned.
@export var tint: Color = Color(0.6, 0.8, 1.0)
