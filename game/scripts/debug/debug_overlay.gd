# DebugOverlay — F1 boxes, F2 frame state + frame advantage, F3 input history,
# F4 slow motion, F5 frame-step (while slow-mo is on), F6 refill/reset.
class_name DebugOverlay
extends Node2D

var p1: FighterBase
var p2: FighterBase

var show_boxes := true
var show_state := false
var show_input := false
var slow_motion := false
var frame_step := false

var _layer: CanvasLayer
var _text: Label
var _inputs: Label
var _headless := false

func _ready() -> void:
	_headless = DisplayServer.get_name() == "headless"
	z_index = 100
	_layer = CanvasLayer.new()
	_layer.layer = 20
	add_child(_layer)

	_text = _make_label(Vector2(4, 40), Vector2(240, 66))
	_inputs = _make_label(Vector2(4, 156), Vector2(312, 22))
	_text.visible = false
	_inputs.visible = false
	if _headless:
		# Headless runs (test suites) have no window and no input, so the
		# overlay stays inert instead of drawing or polling anything.
		set_process(false)

func bind(a: FighterBase, b: FighterBase) -> void:
	p1 = a
	p2 = b

func _make_label(pos: Vector2, size: Vector2) -> Label:
	var l := Label.new()
	l.position = pos
	l.size = size
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var settings := LabelSettings.new()
	settings.font_size = 8
	settings.font_color = Color(1, 1, 1, 0.9)
	settings.outline_size = 2
	settings.outline_color = Color(0, 0, 0, 1)
	l.label_settings = settings
	_layer.add_child(l)
	return l

func _process(_delta: float) -> void:
	queue_redraw()
	if frame_step and not get_tree().paused:
		frame_step = false # the match was unpaused elsewhere (pause menu)
	if _text.visible:
		_text.text = _state_text()
	if _inputs.visible and p1 != null and p2 != null:
		_inputs.text = "P1: %s\nP2: %s" % [
			" ".join(p1.input_history.slice(-8)),
			" ".join(p2.input_history.slice(-8)),
		]

func _draw() -> void:
	if _headless or not show_boxes or p1 == null:
		return
	for f: FighterBase in [p1, p2]:
		draw_rect(f.pushbox_rect(), Color(0.25, 0.55, 1.0, 0.9), false, 1.0)
		draw_rect(f.hurtbox_rect(), Color(0.2, 1.0, 0.35, 0.9), false, 1.0)
		if f.state == FighterBase.State.ATTACK:
			var hb := f.get_hitbox_rect()
			if hb.size != Vector2.ZERO:
				draw_rect(hb, Color(1.0, 0.2, 0.2, 1.0), false, 1.0)

func _state_text() -> String:
	if p1 == null or p2 == null:
		return ""
	var text := "P1 %s f%d\nP2 %s f%d\nFPS %d" % [
		_state_name(p1), p1.state_frame,
		_state_name(p2), p2.state_frame,
		Engine.get_frames_per_second(),
	]
	var adv := _advantage_text()
	if adv != "":
		text += "\n" + adv
	if frame_step:
		text += "\nFRAME STEP"
	if slow_motion:
		text += "  SLOW-MO"
	return text

# Frame advantage: the attacker's current frame minus the defender's remaining
# stun frames, for whichever fighter is currently stunned. A negative number
# means the attacker recovers while the defender is still stunned (attacker plus).
func _advantage_text() -> String:
	if p1 == null or p2 == null:
		return ""
	for pair in [[p1, p2, "P1"], [p2, p1, "P2"]]:
		var attacker: FighterBase = pair[0]
		var defender: FighterBase = pair[1]
		if defender.state == FighterBase.State.HITSTUN:
			return "ADV %s %+d f%d/%dhit" % [
				pair[2], attacker.state_frame - defender.hitstun_frames,
				attacker.state_frame, defender.hitstun_frames]
		if defender.state == FighterBase.State.BLOCKSTUN:
			return "ADV %s %+d f%d/%dblk" % [
				pair[2], attacker.state_frame - defender.blockstun_frames,
				attacker.state_frame, defender.blockstun_frames]
	return ""

func _state_name(f: FighterBase) -> String:
	return FighterBase.State.keys()[f.state]

# F5: hold the tree paused and advance exactly one simulation frame.
func step_frame() -> void:
	if not slow_motion or p1 == null or p2 == null:
		return
	frame_step = true
	get_tree().paused = true
	var root := get_parent()
	if root != null and root.has_method("step_simulation_frame"):
		root.step_simulation_frame()

# F6: refill both fighters at their round positions without touching the match
# phase, round number, wins, or timer.
func reset_fighters() -> void:
	if p1 == null or p2 == null:
		return
	var st := p1.stage if p1.stage != null else p2.stage
	var floor_y := 150.0
	var p1_x := 110.0
	var p2_x := 210.0
	if st != null:
		floor_y = st.floor_y
		p1_x = st.spawn_p1_x
		p2_x = st.spawn_p2_x
	p1.begin_round(Vector2(p1_x, floor_y), p2_x)
	p2.begin_round(Vector2(p2_x, floor_y), p1_x)
	for f: FighterBase in [p1, p2]:
		f.add_meter(f.max_meter)
		f.input_enabled = true

func _unhandled_input(event: InputEvent) -> void:
	if _headless:
		return
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_F1:
			show_boxes = not show_boxes
		KEY_F2:
			show_state = not show_state
			_text.visible = show_state
		KEY_F3:
			show_input = not show_input
			_inputs.visible = show_input
		KEY_F4:
			slow_motion = not slow_motion
			Engine.time_scale = 0.25 if slow_motion else 1.0
			if not slow_motion:
				frame_step = false
		KEY_F5:
			step_frame()
		KEY_F6:
			reset_fighters()
