# Canonical input-map generator. Re-run after changing the controls table:
#   godot --headless --path game --script res://tools/setup_input.gd
#
# Device policy (2026-11-16):
#   P1 = keyboard + mouse only. The WASD/right-hand layout follows the common
#   PC fighting-game convention (movement on WASD, attacks on the U-I-O/J-K-L
#   block); mouse buttons are alternate attack inputs.
#   P2 = controller only. Standard fighting-game pad layout: d-pad or left stick
#   to move, face buttons for attacks, right shoulder for the finisher, Start to
#   pause. Joypad events use device -1, so the connected pad drives P2 no matter
#   which USB port it is in.
extends SceneTree

const P1_KEYS := {
	"p1_left": [KEY_A],
	"p1_right": [KEY_D],
	"p1_up": [KEY_W],
	"p1_down": [KEY_S],
	"p1_light": [KEY_J],
	"p1_heavy": [KEY_K],
	"p1_special": [KEY_L],
	"p1_grab": [KEY_U],
	"p1_meth": [KEY_I],
	"p1_pause": [KEY_ESCAPE],
}

# Alternate mouse attack inputs for P1. Left = light, right = heavy, middle =
# special, matching the usual "primary/secondary mouse" convention.
const P1_MOUSE := {
	"p1_light": [MOUSE_BUTTON_LEFT],
	"p1_heavy": [MOUSE_BUTTON_RIGHT],
	"p1_special": [MOUSE_BUTTON_MIDDLE],
}

# Face buttons follow GDD §4.2: west light, north heavy, east special, south
# grab. The right shoulder is the meter finisher.
const P2_PAD_BUTTONS := {
	"p2_light": [JOY_BUTTON_X],
	"p2_heavy": [JOY_BUTTON_Y],
	"p2_special": [JOY_BUTTON_B],
	"p2_grab": [JOY_BUTTON_A],
	"p2_meth": [JOY_BUTTON_RIGHT_SHOULDER],
	"p2_pause": [JOY_BUTTON_START],
	"p2_left": [JOY_BUTTON_DPAD_LEFT],
	"p2_right": [JOY_BUTTON_DPAD_RIGHT],
	"p2_up": [JOY_BUTTON_DPAD_UP],
	"p2_down": [JOY_BUTTON_DPAD_DOWN],
}

# Menu confirm/back on the pad (GDD §4.2: south confirms, east backs out). These
# are appended to the existing keyboard bindings, not rewritten.
const UI_PAD_BUTTONS := {
	"ui_confirm": [JOY_BUTTON_A],
	"ui_back": [JOY_BUTTON_B],
}

# Left stick mirrors the d-pad. One event per direction with the sign the axis
# reports, so Input.get_axis() and digital direction checks both work.
const P2_PAD_AXES := {
	"p2_left": [[JOY_AXIS_LEFT_X, -1.0]],
	"p2_right": [[JOY_AXIS_LEFT_X, 1.0]],
	"p2_up": [[JOY_AXIS_LEFT_Y, -1.0]],
	"p2_down": [[JOY_AXIS_LEFT_Y, 1.0]],
}

func _init() -> void:
	for action: String in P1_KEYS:
		var events: Array = []
		for code: int in P1_KEYS[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = code
			# -1 = accept the event from any input device. Godot's new events
			# default to a concrete device id (16 for the local keyboard) and the
			# serializer writes whatever it is; pinning the wildcard keeps the
			# generated map independent of the machine that ran this tool.
			ev.device = -1
			events.append(ev)
		_write(action, events)

	for action: String in P1_MOUSE:
		var events: Array = []
		for button: int in P1_MOUSE[action]:
			var ev := InputEventMouseButton.new()
			ev.button_index = button
			ev.device = -1
			events.append(ev)
		_append(action, events)

	# P2 is controller-only: every p2_* action is rebuilt from scratch so a
	# leftover keyboard binding cannot keep a second player on the shared board.
	for action: String in P2_PAD_BUTTONS:
		var events: Array = []
		for button: int in P2_PAD_BUTTONS[action]:
			var ev := InputEventJoypadButton.new()
			ev.button_index = button
			ev.device = -1
			events.append(ev)
		for spec: Array in P2_PAD_AXES.get(action, []):
			var motion := InputEventJoypadMotion.new()
			motion.axis = spec[0]
			motion.axis_value = spec[1]
			motion.device = -1
			events.append(motion)
		_write(action, events)

	for action: String in UI_PAD_BUTTONS:
		var events: Array = []
		for button: int in UI_PAD_BUTTONS[action]:
			var ev := InputEventJoypadButton.new()
			ev.button_index = button
			ev.device = -1
			events.append(ev)
		_append(action, events)

	# NOTE: save() rewrites project.godot and drops settings whose value equals the
	# engine default, which includes the explicit [physics] 60 Hz entry. Re-add it
	# by hand after regenerating the map.
	ProjectSettings.save()
	print("P1 keyboard/mouse and P2 controller input actions written.")
	quit()

func _write(action: String, events: Array) -> void:
	ProjectSettings.set_setting("input/" + action, {"deadzone": 0.2, "events": events})

# Appends to an action already written above (P1 mouse alternates, pad UI
# confirm/back). Idempotent: an incoming binding replaces the identical existing
# one instead of stacking duplicates when the generator is re-run.
func _append(action: String, extra: Array) -> void:
	var current: Dictionary = ProjectSettings.get_setting("input/" + action, {})
	var events: Array = current.get("events", []).duplicate()
	for add: InputEvent in extra:
		var kept: Array = []
		for e: InputEvent in events:
			if not _same_binding(e, add):
				kept.append(e)
		kept.append(add)
		events = kept
	ProjectSettings.set_setting("input/" + action, {"deadzone": 0.2, "events": events})

func _same_binding(a: InputEvent, b: InputEvent) -> bool:
	if a.get_class() != b.get_class():
		return false
	if a is InputEventKey and b is InputEventKey:
		return a.physical_keycode == b.physical_keycode and a.keycode == b.keycode
	if a is InputEventMouseButton and b is InputEventMouseButton:
		return a.button_index == b.button_index
	if a is InputEventJoypadButton and b is InputEventJoypadButton:
		return a.button_index == b.button_index
	if a is InputEventJoypadMotion and b is InputEventJoypadMotion:
		return a.axis == b.axis and is_equal_approx(a.axis_value, b.axis_value)
	return false
