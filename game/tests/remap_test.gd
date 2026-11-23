# remap_test.gd — runtime InputMap overrides, persistence, UI capture and
# action-name consumers on the #76 manual-step harness. No physical controller
# is required: pad buttons and axes are injected as InputEvent instances.
extends SceneTree

const MATCH_SCENE := preload("res://scenes/match/MatchRoot.tscn")
const SETTINGS_SCENE := preload("res://scenes/menus/settings_overlay.tscn")
const WARNING_SCENE := preload("res://scenes/menus/content_warning.tscn")
const TITLE_SCENE := preload("res://scenes/menus/title.tscn")
const CLIP_SCRIPT := preload("res://scripts/ui/the_clip_comic.gd")
const ROSTER := preload("res://resources/match_roster.tres")
const TEST_PATH := "user://remap_test_bindings.cfg"

var checks := 0
var failures := 0
var settings: Node
var bindings: InputBindings


func _initialize() -> void:
	_run.call_deferred()


func _check(label: String, condition: bool, detail: String = "") -> void:
	checks += 1
	if condition:
		print("PASS: ", label)
	else:
		failures += 1
		print("FAIL: ", label, "  ", detail)


func _run() -> void:
	await process_frame
	settings = root.get_node_or_null("Settings")
	if settings == null or settings.controls == null:
		_check("Settings owns the runtime input remapper", false, "missing autoload service")
		_finish()
		return
	bindings = settings.controls
	bindings.config_path = TEST_PATH
	_delete_scratch()
	bindings.load_saved_bindings()
	_release_all_inputs()

	var project_text := FileAccess.get_file_as_string("res://project.godot")
	var project_hash := project_text.hash()
	_check("a missing controls config uses defaults without creating a file",
		not FileAccess.file_exists(_scratch_path())
			and bindings.binding_label("p1", "p1_left") == "A"
			and bindings.binding_label("p2", "p2_light") == "X")
	_check("the fixed 60 Hz physics setting remains in project.godot",
		"common/physics_ticks_per_second=60" in project_text)

	# Shipped defaults come from the live project map and remain untouched
	# unless a user rebinds them.
	_check("P1 defaults are captured from the generated keyboard map",
		bindings.binding_label("p1", "p1_left") == "A"
			and bindings.binding_label("p1", "p1_light") == "J")
	_check("P2 keeps both d-pad and stick defaults",
		bindings.binding_label("p2", "p2_left") == "D-PAD LEFT / LS LEFT")

	# Real InputEventKey injection proves the new key resolves to the action
	# through InputMap and the former key no longer resolves to it.
	var result := bindings.rebind_control("p1", "p1_light", _key_event(KEY_Q))
	_check("a keyboard action can be rebound at runtime", bool(result["ok"]),
		str(result["message"]))
	_check("P1 mouse alternates survive keyboard remapping",
		_has_mouse_button("p1_light", MOUSE_BUTTON_LEFT))
	_press_key(KEY_Q)
	_check("the new key drives the rebound action",
		Input.is_action_pressed("p1_light"))
	_release_key(KEY_Q)
	_press_key(KEY_J)
	_check("the former key no longer drives that action",
		not Input.is_action_pressed("p1_light"))
	_release_key(KEY_J)

	# A same-player collision exchanges the two key assignments.
	result = bindings.rebind_control("p1", "p1_heavy", _key_event(KEY_Q))
	_check("a same-player conflict reports a swap",
		bool(result["ok"]) and str(result["swapped_with"]) == "p1_light",
		str(result))
	_check("the conflicting controls exchange their keys",
		bindings.binding_label("p1", "p1_heavy") == "Q"
			and bindings.binding_label("p1", "p1_light") == "K")
	_press_key(KEY_Q)
	_check("the swapped key now drives Heavy", Input.is_action_pressed("p1_heavy"))
	_release_key(KEY_Q)
	_press_key(KEY_K)
	_check("the old Light key now drives Light", Input.is_action_pressed("p1_light"))
	_release_key(KEY_K)

	# No clear operation may remove the last menu route.
	result = bindings.rebind_control("p1", "p1_ui_confirm", null)
	_check("a menu-breaking unbind is refused",
		not bool(result["ok"])
			and bindings.binding_label("p1", "p1_ui_confirm").begins_with("ENTER"),
		str(result))

	# Immediate save and a fresh read from the scratch config.
	result = bindings.rebind_control("p1", "p1_special", _key_event(KEY_Z))
	_check("a rebind saves immediately", bool(result["ok"]) \
		and FileAccess.file_exists(_scratch_path()), str(result))
	bindings.load_saved_bindings()
	_check("control bindings survive a save/load round trip",
		bindings.binding_label("p1", "p1_special") == "Z"
			and bindings.binding_label("p1", "p1_heavy") == "Q")

	# Invalid ConfigFile input is ignored as a whole; shipped defaults apply.
	_write_scratch("""
[meta]
version=1

[p1]
p1_left=123
""")
	bindings.load_saved_bindings()
	_check("a corrupt controls config falls back to shipped defaults",
		bindings.binding_label("p1", "p1_left") == "A"
			and bindings.binding_label("p1", "p1_light") == "J"
			and bindings.binding_label("p2", "p2_light") == "X")

	# P1 reset is scoped to P1; the P2 controller row stays customized.
	bindings.rebind_control("p1", "p1_light", _key_event(KEY_Q))
	result = bindings.rebind_control("p2", "p2_light", _pad_button(JOY_BUTTON_BACK))
	_check("P2 accepts a controller-button binding", bool(result["ok"]),
		str(result))
	bindings.reset_player("p1")
	_check("reset-to-defaults restores only the selected player",
		bindings.binding_label("p1", "p1_light") == "J"
			and bindings.binding_label("p2", "p2_light") == "BACK")

	# Drive the actual Settings capture path. Small analog rest noise must not
	# end the listening state or alter the current binding.
	var overlay: Control = SETTINGS_SCENE.instantiate()
	root.add_child(overlay)
	await process_frame
	overlay.control_player = "p2"
	overlay.pending_control_id = "p2_light"
	var noise := InputEventJoypadMotion.new()
	noise.axis = JOY_AXIS_LEFT_X
	noise.axis_value = 0.012
	noise.device = 0
	overlay._unhandled_input(noise)
	_check("DualSense rest noise is ignored below the capture deadzone",
		overlay.pending_control_id == "p2_light"
			and bindings.binding_label("p2", "p2_light") == "BACK")
	overlay._unhandled_input(_key_event(KEY_ESCAPE))
	_check("Esc cancels an active rebind without changing the binding",
		overlay.pending_control_id.is_empty()
			and bindings.binding_label("p2", "p2_light") == "BACK")
	overlay.pending_control_id = "p2_light"
	var injected_pad := _pad_button(JOY_BUTTON_MISC1)
	overlay._unhandled_input(injected_pad)
	_check("an injected pad button completes controller rebinding",
		overlay.pending_control_id.is_empty()
			and bindings.binding_label("p2", "p2_light") == "BUTTON 15")
	overlay.control_player = "p2"
	overlay.pending_control_id = "p2_left"
	var injected_axis := InputEventJoypadMotion.new()
	injected_axis.axis = JOY_AXIS_LEFT_Y
	injected_axis.axis_value = -0.9
	injected_axis.device = 0
	overlay._unhandled_input(injected_axis)
	_check("an injected stick axis can bind a controller action",
		overlay.pending_control_id.is_empty()
			and bindings.binding_label("p2", "p2_left") == "LS UP")
	overlay.queue_free()
	await process_frame

	_press_pad(JOY_BUTTON_MISC1)
	_check("the injected new pad button drives P2 Light",
		Input.is_action_pressed("p2_light"))
	_release_pad(JOY_BUTTON_MISC1)
	_press_pad(JOY_BUTTON_BACK)
	_check("the former P2 Light button no longer drives Light",
		not Input.is_action_pressed("p2_light"))
	_release_pad(JOY_BUTTON_A)

	# After the P2 remap, the actual CPU command helper still writes to the
	# same named action, independent of physical button assignments.
	var cpu_match: Node = await _build_match(false, true)
	if cpu_match.cpu_p2 != null:
		cpu_match.cpu_p2._press(CpuController.A_LIGHT, true)
	_check("CPU action injection still drives P2 Light after rebinding",
		Input.is_action_pressed("p2_light"))
	if cpu_match.cpu_p2 != null:
		cpu_match.cpu_p2._press(CpuController.A_LIGHT, false)
	await _free_match(cpu_match)

	# Training playback likewise issues named P2 actions rather than keycodes.
	var training_match: Node = await _build_match(true, false)
	training_match.training.recording.clear()
	training_match.training.recording.append(1 << training_match.training.A_LIGHT)
	training_match.training.playback_active = true
	training_match.training.play_index = 0
	training_match.training._apply_playback_frame()
	_check("training playback still drives P2 Light after rebinding",
		Input.is_action_pressed("p2_light"))
	training_match.training._release_all()

	# The #76 harness feeds the semantic action names directly, matching the
	# same named actions emitted by the remapped keys without wall-clock input
	# latch flakiness.
	bindings.rebind_control("p1", "p1_light", _key_event(KEY_Q))
	_release_all_inputs()
	await physics_frame
	training_match.p1.reset_state()
	training_match.p1.input_enabled = true
	training_match.p1._macro_on_press("light")
	_check("a remapped Light press still enters the macro action path",
		training_match.p1.macro_active != &""
			and training_match.p1.macro_next_press == 1)

	bindings.rebind_control("p1", "p1_grab", _key_event(KEY_Z))
	bindings.rebind_control("p1", "p1_special", _key_event(KEY_X))
	training_match.p1.reset_state()
	training_match.p1.input_enabled = true
	training_match.p1.grounded = true
	_release_all_inputs()
	await physics_frame
	training_match.p1.input_buffer["grab"] = 0
	training_match.p1.input_buffer["special"] = 0
	training_match.p1._poll_input()
	_check("remapped Grab + Special still arms the breaker pair",
		training_match.p1.input_buffer.has("grab")
			and training_match.p1.input_buffer.has("special")
			and training_match.p1.breaker_pair_frames > 0)
	training_match.p1._force_state(FighterBase.State.HITSTUN)
	training_match.p1.breaker_free_uses_left = 1
	training_match.p1.breaker_used_this_combo = false
	training_match.p1.breaker_cooldown_frames = 0
	_check("the breaker resolves from remapped action names",
		training_match.p1._try_breaker())
	_release_key(KEY_Z)
	_release_key(KEY_X)

	training_match.p1.reset_state()
	training_match.p1.input_enabled = true
	training_match.p1.grounded = true
	var heavy: MoveData = training_match.p1.data.find_move(
		MoveData.InputType.HEAVY, MoveData.Stance.STAND)
	training_match.p1.current_move = heavy
	training_match.p1._force_state(FighterBase.State.ATTACK)
	training_match.p1.state_frame = heavy.startup + heavy.active
	training_match.p1.meter = 100.0
	training_match.p1.clip_cancel_used = false
	_release_all_inputs()
	await physics_frame
	training_match.p1.input_buffer["grab"] = 0
	training_match.p1.input_buffer["special"] = 0
	_check("the Clip Cancel consumes the remapped Grab + Special pair",
		training_match.p1._try_clip_cancel()
			and training_match.p1.clip_cancel_used)
	_release_key(KEY_Z)
	_release_key(KEY_X)
	training_match.training._release_all()
	bindings.reset_player("p2")
	_check("P2 reset restores its shipped pad and stick defaults",
		bindings.binding_label("p2", "p2_light") == "X"
			and bindings.binding_label("p2", "p2_left") == "D-PAD LEFT / LS LEFT")
	await _free_match(training_match)

	# Prompts resolve their text/glyph from the current UI bindings.
	bindings.rebind_control("p1", "p1_ui_confirm", _key_event(KEY_F))
	bindings.rebind_control("p1", "p1_ui_back", _key_event(KEY_G))
	ScreenRouter.note_input_device(_key_event(KEY_A))
	var prompt := UiPromptLine.new("SELECT", "BACK")
	root.add_child(prompt)
	await process_frame
	prompt._refresh_device()
	_check("shared menu prompts show the current key bindings",
		prompt._confirm_key.text == "[F]" and prompt._back_key.text == "[G]",
		"%s / %s" % [prompt._confirm_key.text, prompt._back_key.text])
	var warning: Control = WARNING_SCENE.instantiate()
	root.add_child(warning)
	await process_frame
	warning._process(0.0)
	_check("the Content Warning prompt shows the current confirm key",
		warning._key_label.text == "[F]", warning._key_label.text)
	var title: Node = TITLE_SCENE.instantiate()
	root.add_child(title)
	await process_frame
	title._refresh_confirm_prompt()
	_check("the Title prompt shows the current confirm key",
		title._press_start.text == "PRESS [F]", title._press_start.text)
	var clip: Node = CLIP_SCRIPT.new()
	root.add_child(clip)
	await process_frame
	clip._process(0.0)
	_check("The Clip hint shows the current confirm/back keys",
		"[F] NEXT" in clip._advance_hint.text and "[G/ESC] SKIP" in clip._advance_hint.text,
		clip._advance_hint.text)
	clip.queue_free()
	title.queue_free()
	warning.queue_free()
	prompt.queue_free()
	await process_frame

	var project_after := FileAccess.get_file_as_string("res://project.godot")
	_check("runtime rebinding never writes the project input map",
		project_after.hash() == project_hash
			and "common/physics_ticks_per_second=60" in project_after)

	bindings.reset_all()
	bindings.config_path = InputBindings.CONFIG_PATH
	bindings.load_saved_bindings()
	_delete_scratch()
	_release_all_inputs()
	print("remap_test: %d checks, %d failure(s)" % [checks, failures])
	_finish()


func _build_match(training_mode: bool, p2_cpu: bool) -> Node:
	var match_root: Node = MATCH_SCENE.instantiate()
	match_root.selected_p1_data = ROSTER.fighters[0]
	match_root.selected_p2_data = ROSTER.fighters[1]
	match_root.selected_stage = ROSTER.stages[0]
	match_root.training_mode = training_mode
	match_root.p2_cpu = p2_cpu
	match_root.cpu_level = 1
	match_root.cpu_seed = 32021
	match_root.set_physics_process(false)
	root.add_child(match_root)
	match_root.set_physics_process(false)
	if match_root.training != null:
		match_root.training.manual_mode = true
	if match_root.cpu_p2 != null:
		match_root.cpu_p2.manual_mode = true
	await process_frame
	await process_frame
	match_root.set_physics_process(false)
	assert(not match_root.is_physics_processing())
	match_root.p1.set_physics_process(false)
	match_root.p2.set_physics_process(false)
	match_root.p1.reset_state()
	match_root.p2.reset_state()
	match_root.p1.input_enabled = true
	match_root.p2.input_enabled = true
	_release_all_inputs()
	return match_root


func _free_match(match_root: Node) -> void:
	if match_root.training != null:
		match_root.training._release_all()
	if match_root.cpu_p2 != null:
		match_root.cpu_p2._release_all()
	match_root.queue_free()
	await process_frame
	await process_frame


func _key_event(code: int, pressed := true) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	event.device = 16
	return event


func _pad_button(button: int) -> InputEventJoypadButton:
	var event := InputEventJoypadButton.new()
	event.button_index = button
	event.pressed = true
	event.device = 0
	return event


func _press_key(code: int) -> void:
	Input.parse_input_event(_key_event(code, true))
	Input.flush_buffered_events()


func _release_key(code: int) -> void:
	Input.parse_input_event(_key_event(code, false))
	Input.flush_buffered_events()


func _press_pad(button: int) -> void:
	Input.parse_input_event(_pad_button(button))
	Input.flush_buffered_events()


func _release_pad(button: int) -> void:
	var event := _pad_button(button)
	event.pressed = false
	Input.parse_input_event(event)
	Input.flush_buffered_events()


func _release_all_inputs() -> void:
	for action in [
			"p1_left", "p1_right", "p1_up", "p1_down", "p1_light",
			"p1_heavy", "p1_special", "p1_grab", "p1_meth", "p1_pause",
			"p2_left", "p2_right", "p2_up", "p2_down", "p2_light",
			"p2_heavy", "p2_special", "p2_grab", "p2_meth", "p2_pause",
			"ui_confirm", "ui_back"]:
		Input.action_release(action)


func _has_mouse_button(action: String, button: int) -> bool:
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventMouseButton and event.button_index == button:
			return true
	return false


func _scratch_path() -> String:
	return ProjectSettings.globalize_path(TEST_PATH)


func _delete_scratch() -> void:
	if FileAccess.file_exists(_scratch_path()):
		DirAccess.remove_absolute(_scratch_path())


func _write_scratch(text: String) -> void:
	var file := FileAccess.open(_scratch_path(), FileAccess.WRITE)
	file.store_string(text)
	file.close()


func _finish() -> void:
	quit(1 if failures > 0 else 0)
