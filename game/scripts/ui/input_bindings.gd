# Runtime input remapping. The project input map remains the source of shipped
# defaults; this class snapshots those defaults, stores user overrides as plain
# values in user://controls.cfg, then applies them to InputMap at boot.
class_name InputBindings
extends RefCounted

const CONFIG_PATH := "user://controls.cfg"
const CONFIG_VERSION := 1
const AXIS_CAPTURE_DEADZONE := 0.2

# UI actions share their InputMap action names between keyboard and controller.
# The id keeps the two device-specific rows independent in settings storage.
const CONTROL_DEFS := {
	"p1": [
		{"id": "p1_left", "action": "p1_left", "label": "LEFT", "device": "key"},
		{"id": "p1_right", "action": "p1_right", "label": "RIGHT", "device": "key"},
		{"id": "p1_up", "action": "p1_up", "label": "UP / JUMP", "device": "key"},
		{"id": "p1_down", "action": "p1_down", "label": "DOWN / CROUCH", "device": "key"},
		{"id": "p1_light", "action": "p1_light", "label": "LIGHT", "device": "key"},
		{"id": "p1_heavy", "action": "p1_heavy", "label": "HEAVY", "device": "key"},
		{"id": "p1_special", "action": "p1_special", "label": "SPECIAL", "device": "key"},
		{"id": "p1_grab", "action": "p1_grab", "label": "GRAB", "device": "key"},
		{"id": "p1_meth", "action": "p1_meth", "label": "METH", "device": "key"},
		{"id": "p1_pause", "action": "p1_pause", "label": "PAUSE", "device": "key"},
		{"id": "p1_ui_confirm", "action": "ui_confirm", "label": "MENU CONFIRM", "device": "key"},
		{"id": "p1_ui_back", "action": "ui_back", "label": "MENU BACK", "device": "key"},
		{"id": "p1_training_reset", "action": "training_reset", "label": "TRAINING RESET", "device": "key"},
		{"id": "p1_training_record", "action": "training_record", "label": "TRAINING RECORD", "device": "key"},
		{"id": "p1_training_playback", "action": "training_playback", "label": "TRAINING PLAY", "device": "key"},
	],
	"p2": [
		{"id": "p2_left", "action": "p2_left", "label": "LEFT", "device": "pad"},
		{"id": "p2_right", "action": "p2_right", "label": "RIGHT", "device": "pad"},
		{"id": "p2_up", "action": "p2_up", "label": "UP / JUMP", "device": "pad"},
		{"id": "p2_down", "action": "p2_down", "label": "DOWN / CROUCH", "device": "pad"},
		{"id": "p2_light", "action": "p2_light", "label": "LIGHT", "device": "pad"},
		{"id": "p2_heavy", "action": "p2_heavy", "label": "HEAVY", "device": "pad"},
		{"id": "p2_special", "action": "p2_special", "label": "SPECIAL", "device": "pad"},
		{"id": "p2_grab", "action": "p2_grab", "label": "GRAB", "device": "pad"},
		{"id": "p2_meth", "action": "p2_meth", "label": "METH", "device": "pad"},
		{"id": "p2_pause", "action": "p2_pause", "label": "PAUSE", "device": "pad"},
		{"id": "p2_ui_confirm", "action": "ui_confirm", "label": "MENU CONFIRM", "device": "pad"},
		{"id": "p2_ui_back", "action": "ui_back", "label": "MENU BACK", "device": "pad"},
		{"id": "p2_training_reset", "action": "training_reset", "label": "TRAINING RESET", "device": "pad"},
		{"id": "p2_training_record", "action": "training_record", "label": "TRAINING RECORD", "device": "pad"},
		{"id": "p2_training_playback", "action": "training_playback", "label": "TRAINING PLAY", "device": "pad"},
	],
}

var config_path := CONFIG_PATH
var defaults: Dictionary = {}
var bindings: Dictionary = {}
var initialized := false


func initialize() -> void:
	if initialized:
		return
	initialized = true
	defaults = _read_project_defaults()
	bindings = _copy_bindings(defaults)
	load_saved_bindings()


func player_ids() -> Array[String]:
	return ["p1", "p2"]


func control_definitions(player: String) -> Array:
	return CONTROL_DEFS.get(player, []).duplicate(true)


func binding_label(player: String, control_id: String) -> String:
	var encoded: Array = bindings.get(player, {}).get(control_id, [])
	if encoded.is_empty():
		return "UNBOUND"
	var labels: Array[String] = []
	for item in encoded:
		var event := _deserialize_event(item)
		if event != null:
			labels.append(_event_label(event))
	return " / ".join(labels) if not labels.is_empty() else "UNBOUND"


func binding_label_for_device(player: String, control_id: String) -> String:
	return binding_label(player, control_id)


func rebind_control(player: String, control_id: String,
		source_event: InputEvent = null) -> Dictionary:
	if not initialized:
		initialize()
	if not _has_control(player, control_id):
		return _result(false, "UNKNOWN CONTROL")
	if source_event == null:
		# The UI has no unbind operation. This guard also protects the menu's
		# confirm/back routes if a future caller attempts to clear a row.
		return _result(false, "KEEP AT LEAST ONE BINDING")

	var definition := _definition(player, control_id)
	var candidate := _normalize_event(source_event, str(definition["device"]))
	if candidate == null:
		return _result(false, "USE A KEY" if definition["device"] == "key"
			else "USE A PAD BUTTON OR AXIS")
	if candidate is InputEventKey and _key_code(candidate) == KEY_ESCAPE:
		return _result(false, "ESC CANCELS REBINDING")

	var current: Array = bindings[player][control_id]
	for item in current:
		var bound := _deserialize_event(item)
		if bound != null and _same_binding(bound, candidate):
			return _result(true, "ALREADY BOUND")
	if current.is_empty():
		return _result(false, "KEEP AT LEAST ONE BINDING")

	var next := _copy_bindings(bindings)
	var previous := _deserialize_event(current[0])
	if previous == null:
		return _result(false, "CURRENT BINDING IS INVALID")

	var conflict_id := ""
	for other: Dictionary in CONTROL_DEFS[player]:
		var other_id := str(other["id"])
		if other_id == control_id:
			continue
		for item in next[player][other_id]:
			var existing := _deserialize_event(item)
			if existing != null and _same_binding(existing, candidate):
				conflict_id = other_id
				break
		if not conflict_id.is_empty():
			break

	next[player][control_id] = [_serialize_event(candidate)]
	if not conflict_id.is_empty():
		next[player][conflict_id] = [_serialize_event(previous)]
	if not _menu_routes_valid(next):
		return _result(false, "KEEP MENU CONFIRM AND BACK BOUND")

	bindings = next
	_apply_bindings()
	save()
	var message := "BOUND"
	if not conflict_id.is_empty():
		message = "SWAPPED WITH %s" % str(_definition(player, conflict_id)["label"])
	return _result(true, message, conflict_id)


func reset_player(player: String) -> bool:
	if not initialized:
		initialize()
	if not defaults.has(player):
		return false
	bindings[player] = defaults[player].duplicate(true)
	_apply_bindings()
	save()
	return true


func reset_all() -> void:
	if not initialized:
		initialize()
	bindings = _copy_bindings(defaults)
	_apply_bindings()
	save()


func load_saved_bindings() -> void:
	if defaults.is_empty():
		return
	bindings = _copy_bindings(defaults)
	var file := ConfigFile.new()
	if file.load(config_path) != OK:
		_apply_bindings()
		return
	if int(file.get_value("meta", "version", CONFIG_VERSION)) != CONFIG_VERSION:
		_apply_bindings()
		return

	var loaded := _copy_bindings(defaults)
	var corrupt := false
	for player: String in CONTROL_DEFS:
		for definition: Dictionary in CONTROL_DEFS[player]:
			var control_id := str(definition["id"])
			if not file.has_section_key(player, control_id):
				continue
			var raw: Variant = file.get_value(player, control_id)
			if not (raw is Array) or raw.is_empty():
				corrupt = true
				break
			var decoded: Array[Dictionary] = []
			for item in raw:
				var event := _deserialize_event(item)
				if event == null or _event_device(event) != str(definition["device"]):
					corrupt = true
					break
				if event is InputEventJoypadMotion \
						and absf(event.axis_value) < AXIS_CAPTURE_DEADZONE:
					corrupt = true
					break
				decoded.append(_serialize_event(event))
			if corrupt:
				break
			loaded[player][control_id] = decoded
		if corrupt:
			break

	if corrupt or not _menu_routes_valid(loaded):
		bindings = _copy_bindings(defaults)
	else:
		bindings = loaded
	_apply_bindings()


func save() -> void:
	if not initialized:
		return
	var file := ConfigFile.new()
	file.set_value("meta", "version", CONFIG_VERSION)
	for player: String in CONTROL_DEFS:
		for definition: Dictionary in CONTROL_DEFS[player]:
			var control_id := str(definition["id"])
			file.set_value(player, control_id, bindings[player][control_id])
	var error := file.save(config_path)
	if error != OK:
		push_error("InputBindings: cannot save %s (error %d)" % [config_path, error])


func _read_project_defaults() -> Dictionary:
	var result: Dictionary = {}
	for player: String in CONTROL_DEFS:
		result[player] = {}
		for definition: Dictionary in CONTROL_DEFS[player]:
			var control_id := str(definition["id"])
			var action := str(definition["action"])
			var device := str(definition["device"])
			var events: Array[Dictionary] = []
			if InputMap.has_action(action):
				for event: InputEvent in InputMap.action_get_events(action):
					if _event_device(event) == device:
						events.append(_serialize_event(event))
			result[player][control_id] = events
	return result


func _apply_bindings() -> void:
	var action_events: Dictionary = {}
	for player: String in CONTROL_DEFS:
		for definition: Dictionary in CONTROL_DEFS[player]:
			var action := str(definition["action"])
			if not action_events.has(action):
				action_events[action] = InputMap.action_get_events(action).duplicate()
			var device := str(definition["device"])
			var kept: Array[InputEvent] = []
			for event: InputEvent in action_events[action]:
				if _event_device(event) != device:
					kept.append(event)
			for item in bindings.get(player, {}).get(str(definition["id"]), []):
				var event := _deserialize_event(item)
				if event != null:
					kept.append(event)
			action_events[action] = kept

	for action: String in action_events:
		InputMap.action_erase_events(action)
		for event: InputEvent in action_events[action]:
			InputMap.action_add_event(action, event)


func _normalize_event(source: InputEvent, device: String) -> InputEvent:
	if device == "key" and source is InputEventKey:
		var key := source.duplicate() as InputEventKey
		if _key_code(key) == KEY_UNKNOWN:
			return null
		key.device = -1
		key.pressed = false
		key.echo = false
		return key
	if device == "pad" and source is InputEventJoypadButton:
		if not source.pressed:
			return null
		var button := source.duplicate() as InputEventJoypadButton
		button.device = -1
		button.pressed = false
		return button
	if device == "pad" and source is InputEventJoypadMotion:
		if absf(source.axis_value) < AXIS_CAPTURE_DEADZONE:
			return null
		var motion := source.duplicate() as InputEventJoypadMotion
		motion.device = -1
		motion.axis_value = signf(source.axis_value)
		return motion
	return null


func _serialize_event(event: InputEvent) -> Dictionary:
	if event is InputEventKey:
		return {
			"type": "key",
			"keycode": event.keycode,
			"physical_keycode": event.physical_keycode,
			"shift": event.shift_pressed,
			"alt": event.alt_pressed,
			"ctrl": event.ctrl_pressed,
			"meta": event.meta_pressed,
		}
	if event is InputEventJoypadButton:
		return {"type": "button", "button_index": event.button_index}
	if event is InputEventJoypadMotion:
		return {
			"type": "axis",
			"axis": event.axis,
			"axis_value": signf(event.axis_value),
		}
	return {}


func _deserialize_event(value: Variant) -> InputEvent:
	if not (value is Dictionary):
		return null
	match str(value.get("type", "")):
		"key":
			var key := InputEventKey.new()
			key.keycode = int(value.get("keycode", KEY_UNKNOWN))
			key.physical_keycode = int(value.get("physical_keycode", KEY_UNKNOWN))
			key.shift_pressed = bool(value.get("shift", false))
			key.alt_pressed = bool(value.get("alt", false))
			key.ctrl_pressed = bool(value.get("ctrl", false))
			key.meta_pressed = bool(value.get("meta", false))
			key.device = -1
			return key
		"button":
			var button := InputEventJoypadButton.new()
			button.button_index = int(value.get("button_index", -1))
			button.device = -1
			return button
		"axis":
			var motion := InputEventJoypadMotion.new()
			motion.axis = int(value.get("axis", -1))
			motion.axis_value = signf(float(value.get("axis_value", 0.0)))
			motion.device = -1
			return motion
	return null


func _event_device(event: InputEvent) -> String:
	if event is InputEventKey:
		return "key"
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		return "pad"
	return ""


func _same_binding(a: InputEvent, b: InputEvent) -> bool:
	if a is InputEventKey and b is InputEventKey:
		return _key_code(a) == _key_code(b) \
			and a.shift_pressed == b.shift_pressed \
			and a.alt_pressed == b.alt_pressed \
			and a.ctrl_pressed == b.ctrl_pressed \
			and a.meta_pressed == b.meta_pressed
	if a is InputEventJoypadButton and b is InputEventJoypadButton:
		return a.button_index == b.button_index
	if a is InputEventJoypadMotion and b is InputEventJoypadMotion:
		return a.axis == b.axis and signf(a.axis_value) == signf(b.axis_value)
	return false


func _event_label(event: InputEvent) -> String:
	if event is InputEventKey:
		var code := _key_code(event)
		if code == KEY_ENTER or code == KEY_KP_ENTER:
			return "ENTER"
		if code == KEY_BACKSPACE:
			return "BKSP"
		if code == KEY_ESCAPE:
			return "ESC"
		if code == KEY_SPACE:
			return "SPACE"
		var label := OS.get_keycode_string(code).to_upper()
		if event.ctrl_pressed:
			label = "CTRL+" + label
		if event.alt_pressed:
			label = "ALT+" + label
		if event.shift_pressed:
			label = "SHIFT+" + label
		if event.meta_pressed:
			label = "META+" + label
		return label
	if event is InputEventJoypadButton:
		return _button_label(event.button_index)
	if event is InputEventJoypadMotion:
		var direction := "POS" if event.axis_value > 0.0 else "NEG"
		match event.axis:
			JOY_AXIS_LEFT_X:
				direction = "RIGHT" if event.axis_value > 0.0 else "LEFT"
				return "LS " + direction
			JOY_AXIS_LEFT_Y:
				direction = "DOWN" if event.axis_value > 0.0 else "UP"
				return "LS " + direction
			_:
				return "AXIS %d %s" % [event.axis, direction]
	return "UNBOUND"


func _button_label(button: int) -> String:
	match button:
		JOY_BUTTON_A: return "A"
		JOY_BUTTON_B: return "B"
		JOY_BUTTON_X: return "X"
		JOY_BUTTON_Y: return "Y"
		JOY_BUTTON_BACK: return "BACK"
		JOY_BUTTON_START: return "START"
		JOY_BUTTON_LEFT_STICK: return "L3"
		JOY_BUTTON_RIGHT_STICK: return "R3"
		JOY_BUTTON_LEFT_SHOULDER: return "LB"
		JOY_BUTTON_RIGHT_SHOULDER: return "RB"
		JOY_BUTTON_DPAD_UP: return "D-PAD UP"
		JOY_BUTTON_DPAD_DOWN: return "D-PAD DOWN"
		JOY_BUTTON_DPAD_LEFT: return "D-PAD LEFT"
		JOY_BUTTON_DPAD_RIGHT: return "D-PAD RIGHT"
		_: return "BUTTON %d" % button


func _key_code(event: InputEventKey) -> int:
	return event.physical_keycode if event.physical_keycode != KEY_UNKNOWN \
		else event.keycode


func _definition(player: String, control_id: String) -> Dictionary:
	for definition: Dictionary in CONTROL_DEFS.get(player, []):
		if str(definition["id"]) == control_id:
			return definition
	return {}


func _has_control(player: String, control_id: String) -> bool:
	return not _definition(player, control_id).is_empty()


func _menu_routes_valid(candidate: Dictionary) -> bool:
	for control_id in ["p1_ui_confirm", "p1_ui_back",
			"p2_ui_confirm", "p2_ui_back"]:
		var player := "p1" if control_id.begins_with("p1_") else "p2"
		if candidate.get(player, {}).get(control_id, []).is_empty():
			return false
	return true


func _copy_bindings(source: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for player in source:
		result[player] = {}
		for control_id in source[player]:
			result[player][control_id] = source[player][control_id].duplicate(true)
	return result


func _result(ok: bool, message: String, swapped_with: String = "") -> Dictionary:
	return {"ok": ok, "message": message, "swapped_with": swapped_with}
