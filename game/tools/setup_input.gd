# One-shot helper: adds P2 input actions to project.godot with correct serialization.
# Run once: godot --headless --path game --script res://tools/setup_input.gd
extends SceneTree

const P2 := {
	"p2_left": [KEY_LEFT, KEY_KP_4],
	"p2_right": [KEY_RIGHT, KEY_KP_6],
	"p2_up": [KEY_UP, KEY_KP_8],
	"p2_down": [KEY_DOWN, KEY_KP_2],
	"p2_light": [KEY_KP_1, KEY_COMMA],
	"p2_heavy": [KEY_KP_3, KEY_PERIOD],
	"p2_special": [KEY_KP_5, KEY_SLASH],
	"p2_grab": [KEY_KP_7, KEY_SEMICOLON],
	"p2_meth": [KEY_KP_9, KEY_APOSTROPHE],
	"p2_pause": [KEY_KP_0],
}

func _init() -> void:
	for action: String in P2:
		var events: Array = []
		for code: int in P2[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = code
			events.append(ev)
		ProjectSettings.set_setting("input/" + action, {"deadzone": 0.2, "events": events})
	ProjectSettings.save()
	print("P2 input actions written.")
	quit()
