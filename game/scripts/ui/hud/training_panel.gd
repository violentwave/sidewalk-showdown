# TrainingPanel — the training-mode readout plate (GDD 6.4), street-junk
# style: a dark plate with cream outlined-Marker rows, placed in the free
# band above any jump apex and between the #96 STUNNED labels, so it never
# covers a fighter. Presentation only: it reads the TrainingController's
# captured readouts and the dummy's state each sim tick and writes nothing.
#
# Rows (Sidewalk Marker at native 10, cream on the dark plate):
#   row 1 — last hit: damage and frame advantage of the last connecting move
#   row 2 — that move's startup, the dummy's juggle points, or the active
#           stun window (stun and juggle are mutually exclusive by design)
# plus a right-edge REC/PLAY status while a recording or a playback runs.
class_name TrainingPanel
extends Control

const PLATE_POS := Vector2(84, 31)
const PLATE_SIZE := Vector2(152, 25)
const ROW1_POS := Vector2(86, 32)
const ROW2_POS := Vector2(86, 44)
const ROW_WIDTH := 148.0
const PLATE_COLOR := Color(0.11, 0.086, 0.051, 0.8)  # INK_DARK at 80%

var row1: Label
var row2: Label

var _tc: TrainingController
var _match_root: Node


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var plate := ColorRect.new()
	plate.position = PLATE_POS
	plate.size = PLATE_SIZE
	plate.color = PLATE_COLOR
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(plate)
	row1 = UiText.marker("", ROW1_POS, UiText.CREAM_TEXT, true)
	row1.size = Vector2(ROW_WIDTH, UiText.MARKER_LINE_HEIGHT)
	add_child(row1)
	row2 = UiText.marker("", ROW2_POS, UiText.CREAM_TEXT, true)
	row2.size = Vector2(ROW_WIDTH, UiText.MARKER_LINE_HEIGHT)
	add_child(row2)
func bind(match_root: Node, tc: TrainingController) -> void:
	_match_root = match_root
	_tc = tc


# Called from the HUD's sim tick: frozen by pause and hitstop with it.
func sim_tick() -> void:
	if _tc == null or _match_root == null:
		return
	var mode := " REC" if _tc.record_active else (
		" PLAY" if _tc.playback_active else "")
	if _tc.last_kind.is_empty():
		row1.text = "TRAINING MODE" + mode
	else:
		row1.text = "%s %d  ADV %s%d%s" % [
			_tc.last_kind, int(round(_tc.last_hit_damage)),
			"+" if _tc.last_advantage >= 0 else "-", absi(_tc.last_advantage),
			mode]
	var dummy: FighterBase = _match_root.p2
	var juggle := "START %dF  JUG %d" % [_tc.last_startup,
		dummy.juggle_points]
	if dummy.stun_active() and dummy.stun_frames_remaining > 0:
		juggle = "START %dF  STUN %dF" % [
			_tc.last_startup, dummy.stun_frames_remaining]
	row2.text = juggle
