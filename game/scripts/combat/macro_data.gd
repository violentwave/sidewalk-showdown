# MacroData — one dial-a-combo (COMBO_SYSTEM_DESIGN §9.2).
#
# A macro is a stored dial-ahead: the player presses the steps quickly (each
# within max_gap_frames of the previous) and the tracker replays each press
# into the input buffer exactly when the current move's authored cancel
# window opens after a hit-confirm. Macros continue only while hits connect
# and die on block (decision #3). Steps resolve through ordinary moves and
# ordinary cancel rules — there is no macro-specific move bypass.
class_name MacroData
extends Resource

@export var id: StringName = &"macro"
@export var display_name: String = "Combo"
# Button sequence to dial, in order (action names without the p<index>_ prefix).
@export var steps: Array[StringName] = []
# Frames allowed between dial presses; beyond it the macro dies.
@export var max_gap_frames: int = 18
