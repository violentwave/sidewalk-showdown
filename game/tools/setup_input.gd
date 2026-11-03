# Canonical input-map generator. Re-run after changing the controls table:
#   godot --headless --path game --script res://tools/setup_input.gd
# P1 is WASD-only; the arrow keys belong to P2 (plus numpad movement).
extends SceneTree

const P1 := {
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
	for actions: Dictionary in [P1, P2]:
		for action: String in actions:
			var events: Array = []
			for code: int in actions[action]:
				var ev := InputEventKey.new()
				ev.physical_keycode = code
				events.append(ev)
			ProjectSettings.set_setting("input/" + action, {"deadzone": 0.2, "events": events})
	ProjectSettings.save()
	print("P1/P2 input actions written.")
	quit()
