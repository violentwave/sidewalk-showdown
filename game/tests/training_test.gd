# training_test.gd — Training mode (GDD 6.4) end to end: the flow from the
# main menu, the training rules (no clock, no KO, refills, meter options),
# every dummy stance and block mode, the CPU dummy, record/playback with
# side-switch mirroring, position resets, the frame-advantage readout, the
# hitbox toggle, and determinism/serialize-restore — on the #76 harness
# (manual physics stepping, test-local seeded state only).
#
# The flow section boots the real Main scene like character_select_test; the
# rules section drives MatchRoot manually like cpu_test, with the training
# controller and the dummy CPU in manual_mode.
extends SceneTree

const MATCH_SCENE := preload("res://scenes/match/MatchRoot.tscn")
const MAIN_SCENE := preload("res://scenes/main/Main.tscn")
const ROSTER := preload("res://resources/match_roster.tres")
const DT := 1.0 / 60.0

var failures := 0
var checks := 0
# Signal flags: lambdas capture locals by value in GDScript, so every
# signal-observing flag lives on the suite itself.
var _results_requested := 0
var _teched := false
var _stun_frames := 0


func _initialize() -> void:
	_run.call_deferred()


func _check(label: String, condition: bool, detail: String = "") -> void:
	checks += 1
	if condition:
		print("PASS: ", label)
	else:
		failures += 1
		print("FAIL: ", label, "  ", detail)


# ---------------- flow harness (engine-driven, like character_select_test) --

func _press(target: Node, action: String) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	target._unhandled_input(event)


func _press_key(target: Node, code: int) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = true
	event.device = -1
	target._unhandled_input(event)


func _step(frames: int) -> void:
	for _frame in frames:
		await physics_frame


func _boot_to_menu() -> Node:
	var instance: Node = MAIN_SCENE.instantiate()
	root.add_child(instance)
	await process_frame
	instance.content_warning._continue()
	await process_frame
	instance.intro.skip_intro()
	await process_frame
	_press(instance.title, "ui_confirm")
	await process_frame
	return instance


# ---------------- manual harness (#76: the engine never ticks the match) ----

func _build_training_match(p1_index: int, p2_index: int, stage_index: int,
		seed := 0) -> Node:
	var mroot: Node = MATCH_SCENE.instantiate()
	mroot.selected_p1_data = ROSTER.fighters[p1_index]
	mroot.selected_p2_data = ROSTER.fighters[p2_index]
	mroot.selected_stage = ROSTER.stages[stage_index]
	mroot.training_mode = true
	mroot.cpu_seed = seed
	mroot.set_physics_process(false)
	root.add_child(mroot)
	mroot.set_physics_process(false)
	# MatchRoot._ready() has constructed the training controller
	# synchronously; disable its engine tick before the first await.
	mroot.training.manual_mode = true
	await process_frame
	await process_frame
	mroot.set_physics_process(false)
	assert(not mroot.is_physics_processing())
	mroot.p1.set_physics_process(false)
	mroot.p2.set_physics_process(false)
	# Erase any engine ticks the fighters may have taken during the awaits.
	mroot.p1.reset_state()
	mroot.p2.reset_state()
	# Harness hygiene: earlier sections may have left synthetic action state
	# on the Input singleton (the game itself never sees such leftovers —
	# a human's buttons release when they release them). Start every build
	# from a clean global input state.
	for action in ["p1_left", "p1_right", "p1_up", "p1_down", "p1_light",
			"p1_heavy", "p1_special", "p1_grab", "p1_meth",
			"p2_left", "p2_right", "p2_up", "p2_down", "p2_light",
			"p2_heavy", "p2_special", "p2_grab", "p2_meth"]:
		Input.action_release(action)
	return mroot


func _free_match(mroot: Node) -> void:
	if mroot.training != null:
		mroot.training._release_all()
	if mroot.cpu_p2 != null:
		mroot.cpu_p2._release_all()
	mroot.free()
	await process_frame
	await process_frame


# One real engine tick advances the physics-frame counter (Input's
# just_pressed latch), then the manual ticks run in the engine's order:
# controllers first, then the fighters, then the match.
func _manual_step(mroot: Node, frames: int) -> void:
	for _i in frames:
		Engine.physics_ticks_per_second = 60000
		await physics_frame
		Engine.physics_ticks_per_second = 60
		if mroot.training != null:
			mroot.training.manual_tick()
		if mroot.cpu_p2 != null:
			mroot.cpu_p2.manual_tick()
		mroot.p1._physics_process(DT)
		mroot.p2._physics_process(DT)
		mroot._physics_process(DT)


func _place_pair(mroot: Node, p1_x := 120.0, p2_x := 146.0) -> void:
	var p1: FighterBase = mroot.p1
	var p2: FighterBase = mroot.p2
	p1.position = Vector2(p1_x, mroot.stage.floor_y)
	p2.position = Vector2(p2_x, mroot.stage.floor_y)
	p1.velocity = Vector2.ZERO
	p2.velocity = Vector2.ZERO
	p1.facing = 1
	p2.facing = -1
	p1.reset_state()
	p2.reset_state()


# Scripted P1 tap. cpu_test's injection point (the #67/#69 latch class): a
# press issued between engine ticks may register one tick early or late, so
# taps land exactly where _poll_input writes them — the input buffer. The
# trainer's dummy and the playback use the real Input path.
func _tap(mroot: Node, action: String) -> void:
	await _manual_step(mroot, 1)
	mroot.p1.input_buffer[action] = 0
	await _manual_step(mroot, 1)


func _attack_light(mroot: Node) -> void:
	await _tap(mroot, "light")


# A state hash for determinism/restore comparisons: fighters, the training
# state, and the phase — never sim_frame (build drift) or presentation.
func _state_hash(mroot: Node) -> Dictionary:
	return {
		"p1": mroot.p1.serialize(),
		"p2": mroot.p2.serialize(),
		"training": mroot.training.serialize(),
		"phase": mroot.phase,
	}


func _run() -> void:
	await process_frame
	await _test_flow()
	await _test_training_rules()
	await _test_dummy_stances()
	await _test_block_modes()
	await _test_tech_and_shakeout()
	await _test_breaker_practice()
	await _test_cpu_dummy()
	await _test_record_playback()
	await _test_position_resets()
	await _test_training_keys()
	await _test_frame_readout()
	await _test_hitbox_toggle_and_pause_tab()
	await _test_input_map()
	await _test_determinism_and_restore()
	print("training_test: %d checks, %d failure(s)" % [checks, failures])
	quit(1 if failures > 0 else 0)


# ---------------- flow ---------------------------------------------------------

func _test_flow() -> void:
	var main: Node = await _boot_to_menu()

	# TRAINING is the second slat, enabled and confirmable.
	_press(main.main_menu, "p1_down")
	_check("the main menu TRAINING slat is enabled and confirmable",
		main.main_menu.index == 1
			and not main.main_menu.ITEMS[1].get("disabled", false),
		"index=%d" % main.main_menu.index)
	_press(main.main_menu, "p1_light")
	await _step(2)
	_check("TRAINING opens a character select where P1 picks both",
		main.character_select != null and main.character_select.training
			and main.character_select.solo,
		"select=%s training=%s solo=%s" % [
			str(main.character_select != null),
			str(main.character_select.training if main.character_select != null else false),
			str(main.character_select.solo if main.character_select != null else false)])

	var select: Node = main.character_select
	_press(select, "p1_light")
	await _step(1)
	_press(select, "p1_light")
	await _step(1)
	_check("training picks hand straight to stage select",
		main.stage_select != null and main.match_root == null,
		"stage=%s match=%s" % [str(main.stage_select != null),
			str(main.match_root != null)])

	_press(main.stage_select, "p1_light")
	await _step(2)
	_check("training stage select starts the match with no VS bumper",
		main.match_root != null and main.vs_screen == null
			and main.match_root.training_mode,
		"match=%s vs=%s training=%s" % [str(main.match_root != null),
			str(main.vs_screen != null),
			str(main.match_root.training_mode if main.match_root != null else false)])
	_check("the training match starts fighting immediately",
		main.match_root.phase == 1 and main.match_root.p1.input_enabled
			and main.match_root.p2.input_enabled,
		"phase=%d" % main.match_root.phase)

	# No Results, ever: a lethal hit floors the dummy and the match idles on.
	_results_requested = 0
	main.match_root.match_results_requested.connect(
		func(): _results_requested += 1)
	main.match_root.p2.health = 1.0
	var light: MoveData = main.match_root.p1.data.find_move(
		MoveData.InputType.LIGHT, MoveData.Stance.STAND)
	main.match_root.p1._start_move(light)
	await _step(60)
	_check("a lethal hit neither KOs nor requests Results",
		_results_requested == 0 and main.match_root.phase == 1
			and main.match_root.p2.health >= 1.0,
		"results=%d phase=%d health=%s" % [_results_requested,
			main.match_root.phase, str(main.match_root.p2.health)])

	# Pause -> MAIN MENU leaves training cleanly. The tab row is focused
	# first; left/right switches to the SYSTEM tab, whose row 4 is MAIN MENU.
	main.match_root._toggle_pause()
	await _step(1)
	main.match_root._unhandled_input(_action_event("p1_left"))
	for _i in 5:
		main.match_root._unhandled_input(_action_event("p1_down"))
	main.match_root._unhandled_input(_action_event("p1_light"))
	await _step(2)
	_check("pause MAIN MENU exits training to the hub",
		main.match_root == null and main.main_menu != null
			and not main.flow.training_mode,
		"match=%s menu=%s training=%s" % [str(main.match_root != null),
			str(main.main_menu != null), str(main.flow.training_mode)])
	main.queue_free()
	await process_frame

	# Back from training character select returns to the main menu.
	main = await _boot_to_menu()
	_press(main.main_menu, "p1_down")
	_press(main.main_menu, "p1_light")
	await _step(2)
	_press_key(main.character_select, KEY_BACKSPACE)
	await _step(1)
	_check("back from training character select returns to the main menu",
		main.main_menu != null and main.mode_select == null
			and not main.flow.training_mode,
		"menu=%s mode=%s" % [str(main.main_menu != null),
			str(main.mode_select != null)])
	main.queue_free()
	await process_frame

	# Versus is untouched: the hub still routes VERSUS through mode select.
	main = await _boot_to_menu()
	_press(main.main_menu, "p1_light")
	await _step(1)
	_check("the VERSUS flow is unchanged (mode select, not training select)",
		main.mode_select != null and main.character_select == null,
		"mode=%s select=%s" % [str(main.mode_select != null),
			str(main.character_select != null)])
	main.queue_free()
	await process_frame


func _action_event(action: String) -> InputEventAction:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	return event


# ---------------- training rules ----------------------------------------------

func _test_training_rules() -> void:
	var mroot: Node = await _build_training_match(0, 1, 0)
	_check("training starts in FIGHT with the infinity clock",
		mroot.phase == 1 and mroot.timer_frames == 0
			and mroot.hud.timer_digits[0].texture.region.position.x == 80.0
			and mroot.hud.timer_digits[1].texture.region.position.x == 80.0,
		"phase=%d timer=%d digits=%s" % [mroot.phase, mroot.timer_frames,
			str(mroot.hud.timer_digits[0].texture.region.position.x)])
	var p1_apex: float = mroot.stage.floor_y - FighterBase.SILHOUETTE_HEIGHT \
		- pow(mroot.p1.jump_speed, 2.0) / (2.0 * mroot.p1.gravity)
	var p2_apex: float = mroot.stage.floor_y - FighterBase.SILHOUETTE_HEIGHT \
		- pow(mroot.p2.jump_speed, 2.0) / (2.0 * mroot.p2.gravity)
	var panel_bottom := TrainingPanel.PLATE_POS.y + TrainingPanel.PLATE_SIZE.y
	_check("the training readout panel clears both maximum jump silhouettes",
		panel_bottom < p1_apex and panel_bottom < p2_apex,
		"panel_bottom=%s p1_apex=%s p2_apex=%s" % [
			str(panel_bottom), str(p1_apex), str(p2_apex)])
	await _manual_step(mroot, 120)
	_check("the clock never counts down in training",
		mroot.timer_frames == 0 and mroot.phase == 1,
		"timer=%d" % mroot.timer_frames)

	# The health floor: a lethal hit leaves the dummy at 1 HP, never a KO.
	_place_pair(mroot)
	mroot.p2.health = 5.0
	await _attack_light(mroot)
	await _manual_step(mroot, 12)
	_check("damage floors at 1 HP instead of a KO",
		mroot.p2.health == 1.0 and mroot.phase == 1
			and mroot.p2.state != FighterBase.State.KO,
		"health=%s phase=%d state=%d" % [str(mroot.p2.health), mroot.phase,
			mroot.p2.state])

	# Refill after the combo ends (default REFILL mode).
	await _manual_step(mroot, 90)
	_check("health refills after the combo ends",
		mroot.p2.health == mroot.p2.max_health,
		"health=%s" % str(mroot.p2.health))

	# HOLD mode keeps damage until a reset.
	mroot.training.health_mode = mroot.training.HealthMode.HOLD
	_place_pair(mroot)
	await _attack_light(mroot)
	await _manual_step(mroot, 90)
	_check("HEALTH HOLD keeps the damage until a reset",
		mroot.p2.health < mroot.p2.max_health,
		"health=%s" % str(mroot.p2.health))
	mroot.training.reset_positions()
	_check("a position reset restores full health and clears stun state",
		mroot.p2.health == mroot.p2.max_health
			and mroot.p1.health == mroot.p1.max_health,
		"p1=%s p2=%s" % [str(mroot.p1.health), str(mroot.p2.health)])
	mroot.training.health_mode = mroot.training.HealthMode.REFILL

	# Meter NORMAL: nothing awarded but landed hits (the standing economy).
	mroot.p1.meter = 0.0
	mroot.p1.meter_changed.emit(mroot.p1.meter, mroot.p1.max_meter)
	_place_pair(mroot)
	var meter_before: float = mroot.p1.meter
	await _attack_light(mroot)
	await _manual_step(mroot, 20)
	_check("meter NORMAL keeps the landed-hits economy",
		mroot.p1.meter > meter_before,
		"meter %s -> %s" % [str(meter_before), str(mroot.p1.meter)])

	# Meter FULL: a landed METHtality spends and instantly refills, and it
	# neither KOs the dummy nor ends the training match.
	mroot.training.meter_mode = mroot.training.MeterMode.FULL
	await _manual_step(mroot, 2)
	_check("meter FULL tops both bars up",
		mroot.p1.meter == mroot.p1.max_meter and mroot.p2.meter == mroot.p2.max_meter,
		"p1=%s p2=%s" % [str(mroot.p1.meter), str(mroot.p2.meter)])
	_place_pair(mroot)
	await _manual_step(mroot, 1)
	await _tap(mroot, "meth")
	await _manual_step(mroot, 40)
	_check("a landed METHtality neither KOs nor ends the training match",
		mroot.phase == 1 and mroot.p2.health >= 1.0,
		"phase=%d health=%s" % [mroot.phase, str(mroot.p2.health)])
	_check("meter FULL refills through the METH spend",
		mroot.p1.meter == mroot.p1.max_meter,
		"meter=%s" % str(mroot.p1.meter))
	mroot.training.meter_mode = mroot.training.MeterMode.NORMAL
	await _free_match(mroot)

	# Non-training matches keep the vanilla floor: versus/solo untouched.
	var vanilla: Node = MATCH_SCENE.instantiate()
	vanilla.selected_p1_data = ROSTER.fighters[0]
	vanilla.selected_p2_data = ROSTER.fighters[1]
	vanilla.selected_stage = ROSTER.stages[0]
	vanilla.set_physics_process(false)
	root.add_child(vanilla)
	vanilla.set_physics_process(false)
	await process_frame
	await process_frame
	_check("a non-training match keeps the vanilla health floor",
		vanilla.p1.training_min_health == 0.0
			and vanilla.p2.training_min_health == 0.0,
		"floor=%s" % str(vanilla.p1.training_min_health))
	await _free_match(vanilla)


# ---------------- dummy stances -----------------------------------------------

func _test_dummy_stances() -> void:
	var mroot: Node = await _build_training_match(0, 1, 0)
	await _manual_step(mroot, 10)
	_check("the STAND dummy stands neutral",
		mroot.p2.state == FighterBase.State.IDLE,
		"state=%d" % mroot.p2.state)

	mroot.training.set_option_value(0, 1)  # CROUCH
	await _manual_step(mroot, 10)
	_check("the CROUCH dummy holds crouch",
		mroot.p2.state == FighterBase.State.CROUCH,
		"state=%d" % mroot.p2.state)

	mroot.training.set_option_value(0, 2)  # JUMP
	await _manual_step(mroot, 30)
	var airborne: bool = mroot.p2.state in [FighterBase.State.JUMP_START,
		FighterBase.State.JUMP_RISE, FighterBase.State.JUMP_FALL]
	await _manual_step(mroot, 60)
	var jumps_twice: bool = mroot.p2.state in [FighterBase.State.JUMP_START,
		FighterBase.State.JUMP_RISE, FighterBase.State.JUMP_FALL] \
		or not mroot.p2.grounded
	_check("the JUMP dummy keeps jumping",
		airborne and jumps_twice,
		"airborne=%s second=%s" % [str(airborne), str(jumps_twice)])
	mroot.training.set_option_value(0, 0)
	await _free_match(mroot)


# ---------------- block modes --------------------------------------------------

func _test_block_modes() -> void:
	var mroot: Node = await _build_training_match(0, 1, 0)

	# NONE: the first clean hit lands.
	_place_pair(mroot)
	await _attack_light(mroot)
	await _manual_step(mroot, 12)
	_check("block NONE eats the clean hit",
		mroot.p2.state == FighterBase.State.HITSTUN
			and mroot.p2.health < mroot.p2.max_health,
		"state=%d health=%s" % [mroot.p2.state, str(mroot.p2.health)])
	await _manual_step(mroot, 90)

	# ALL: everything is blocked, chip only, defender combo never opens.
	# The dummy is placed at the wall so holding away cannot walk it out of
	# the trainer's reach.
	mroot.training.set_option_value(1, 1)  # ALL
	_place_pair(mroot, 66, 40)
	var health_before: float = mroot.p2.health
	await _attack_light(mroot)
	await _manual_step(mroot, 12)
	var light: MoveData = mroot.p1.data.find_move(
		MoveData.InputType.LIGHT, MoveData.Stance.STAND)
	_check("block ALL blocks the attack (chip only, no combo)",
		mroot.p2.state == FighterBase.State.BLOCKSTUN
			and health_before - mroot.p2.health <= light.block_damage
			and mroot.p2.combo_tracker.hits == 0,
		"state=%d drop=%s hits=%d" % [mroot.p2.state,
			str(health_before - mroot.p2.health),
			mroot.p2.combo_tracker.hits])

	# ALL blocks the cross-up: a CROUCH dummy cannot walk away, so the
	# trainer jumps clean over it and hits from behind — the positional
	# hold-away flips with the crossover and the crouch block still holds.
	mroot.training.set_option_value(0, 1)  # CROUCH dummy
	_place_pair(mroot, 114, 140)
	health_before = mroot.p2.health
	Input.action_press("p1_up")
	Input.action_press("p1_right")
	await _manual_step(mroot, 34)
	Input.action_release("p1_up")
	Input.action_release("p1_right")
	await _manual_step(mroot, 10)
	var crossed_over: bool = mroot.p1.position.x > mroot.p2.position.x
	await _attack_light(mroot)
	await _manual_step(mroot, 12)
	_check("block ALL keeps blocking through a cross-up",
		crossed_over
			and health_before - mroot.p2.health <= light.block_damage
			and mroot.p2.combo_tracker.hits == 0,
		"crossed=%s drop=%s" % [str(crossed_over),
			str(health_before - mroot.p2.health)])
	await _manual_step(mroot, 40)

	# AFTER HIT: the first hit lands, the follow-up is blocked.
	mroot.training.set_option_value(0, 0)  # back to STAND
	mroot.training.set_option_value(1, 2)  # AFTER HIT
	_place_pair(mroot, 66, 40)
	await _attack_light(mroot)
	await _manual_step(mroot, 12)
	var first_landed: bool = mroot.p2.state == FighterBase.State.HITSTUN
	await _manual_step(mroot, 40)
	health_before = mroot.p2.health
	await _attack_light(mroot)
	await _manual_step(mroot, 12)
	_check("AFTER HIT eats the first hit and blocks the follow-up",
		first_landed and mroot.p2.state == FighterBase.State.BLOCKSTUN
			and health_before - mroot.p2.health <= light.block_damage,
		"first=%s second_state=%d drop=%s" % [str(first_landed),
			mroot.p2.state, str(health_before - mroot.p2.health)])
	mroot.training.set_option_value(1, 0)
	await _free_match(mroot)

	# RANDOM: same seed -> same block pattern; the pattern actually varies.
	var pattern_a: Array = await _random_block_pattern(1234)
	var pattern_b: Array = await _random_block_pattern(1234)
	var pattern_c: Array = await _random_block_pattern(4321)
	_check("block RANDOM replays identically from the recorded seed",
		pattern_a == pattern_b,
		"a=%s b=%s" % [str(pattern_a), str(pattern_b)])
	var all_same: bool = true
	for i in pattern_a.size():
		if pattern_a[i] != pattern_a[0]:
			all_same = false
	_check("block RANDOM varies across attacks (it is a real roll)",
		not all_same and pattern_a != pattern_c,
		"pattern=%s" % str(pattern_a))


# Attacks every 30 frames and records which ones were blocked, for the RANDOM
# determinism pin.
func _random_block_pattern(seed: int) -> Array:
	var mroot: Node = await _build_training_match(0, 1, 0, seed)
	mroot.training.set_option_value(1, 3)  # RANDOM
	var pattern: Array = []
	for _attack in 6:
		_place_pair(mroot)
		await _attack_light(mroot)
		await _manual_step(mroot, 12)
		pattern.append(mroot.p2.state == FighterBase.State.BLOCKSTUN)
		await _manual_step(mroot, 30)
	await _free_match(mroot)
	return pattern


# ---------------- tech / shake-out ---------------------------------------------

func _test_tech_and_shakeout() -> void:
	var mroot: Node = await _build_training_match(0, 1, 0)

	# TECH ON: the incoming throw is teched.
	_place_pair(mroot)
	_teched = false
	mroot.p2.teched.connect(func(): _teched = true)
	await _tap(mroot, "grab")
	await _manual_step(mroot, 30)
	_check("TECH ON makes the dummy tech the incoming throw",
		_teched and mroot.p2.health == mroot.p2.max_health,
		"teched=%s state=%d health=%s" % [str(_teched), mroot.p2.state,
			str(mroot.p2.health)])
	await _manual_step(mroot, 30)

	# TECH OFF: the throw connects.
	mroot.training.set_option_value(2, 0)  # TECH OFF
	_place_pair(mroot)
	await _tap(mroot, "grab")
	await _manual_step(mroot, 40)
	_check("TECH OFF lets the throw land",
		mroot.p2.health < mroot.p2.max_health,
		"health=%s" % str(mroot.p2.health))
	mroot.training.set_option_value(2, 1)
	await _manual_step(mroot, 60)

	# Stun shake-out, measured as the tick the stun ends: the ON dummy mashes
	# up past the authored minimum and cuts the window short; the OFF dummy
	# serves the whole authored window. (The shake counter itself is
	# transient — it resets when the stun ends — so the end tick is the
	# observable.)
	var on_end: int = await _stun_end_tick(true)
	var off_end: int = await _stun_end_tick(false)
	_check("SHAKE-OUT ON shakes the dummy out of the stun early",
		on_end > 0 and off_end > on_end,
		"on_end=%d off_end=%d" % [on_end, off_end])
	_check("SHAKE-OUT OFF holds the full stun window",
		off_end > 34 and off_end > on_end,
		"on_end=%d off_end=%d" % [on_end, off_end])
	await _manual_step(mroot, 40)
	mroot.training.set_option_value(4, 1)
	await _free_match(mroot)


# Lands Peggy's stun special on a fresh dummy and returns the tick the stun
# window ended (0 if the stun never landed, -1 if it outlasted the cap).
func _stun_end_tick(shake_on: bool) -> int:
	var mroot: Node = await _build_training_match(0, 1, 0)
	mroot.training.set_option_value(4,
		mroot.training.Toggle.ON if shake_on else mroot.training.Toggle.OFF)
	_place_pair(mroot)
	_stun_frames = 0
	mroot.p2.stun_started.connect(
		func(_id: StringName, frames: int): _stun_frames = frames)
	await _tap(mroot, "special")
	var end := -1
	for i in 90:
		await _manual_step(mroot, 1)
		if _stun_frames > 0 and end < 0 and not mroot.p2.stun_active():
			end = i + 1
			break
	var window: int = _stun_frames
	await _free_match(mroot)
	if window <= 0:
		return 0
	return end


# ---------------- breaker practice ----------------------------------------------

func _test_breaker_practice() -> void:
	var mroot: Node = await _build_training_match(0, 1, 0)
	mroot.training.set_option_value(3, 1)  # BREAKER ALWAYS

	_place_pair(mroot)
	await _attack_light(mroot)
	await _manual_step(mroot, 30)
	var broke: bool = mroot.p2.breaker_used_this_combo
	var free_after: int = mroot.p2.breaker_free_uses_left
	_check("BREAKER ALWAYS makes the dummy break the first hitstun",
		broke,
		"used_this_combo=%s" % str(broke))
	_check("breaker free uses never run out",
		broke and free_after == mroot.p2.data.breaker_free_per_round,
		"free=%d" % free_after)

	# The cooldown is a combat rule and stays — but a position reset clears
	# it, so the very next practice string breaks again.
	mroot.training.reset_positions()
	_place_pair(mroot)
	await _attack_light(mroot)
	await _manual_step(mroot, 30)
	_check("a position reset re-arms the dummy's next break",
		mroot.p2.breaker_used_this_combo
			and mroot.p2.state != FighterBase.State.HITSTUN,
		"used=%s state=%d" % [str(mroot.p2.breaker_used_this_combo),
			mroot.p2.state])
	mroot.training.set_option_value(3, 0)
	await _free_match(mroot)


# ---------------- CPU dummy ------------------------------------------------------

func _test_cpu_dummy() -> void:
	var mroot: Node = await _build_training_match(0, 1, 0)
	mroot.training.set_option_value(0, 4)  # CPU NORMAL
	if mroot.cpu_p2 != null:
		mroot.cpu_p2.manual_mode = true
	_check("the CPU dummy spawns at the chosen difficulty",
		mroot.cpu_p2 != null,
		"cpu=%s" % str(mroot.cpu_p2 != null))
	var start_x: float = mroot.p2.position.x
	await _manual_step(mroot, 90)
	_check("the CPU dummy acts (it approaches the trainer)",
		absf(mroot.p2.position.x - start_x) > 4.0,
		"dx=%s" % str(mroot.p2.position.x - start_x))
	mroot.training.set_option_value(0, 0)
	_check("leaving the CPU stance frees the dummy CPU",
		mroot.cpu_p2 == null,
		"cpu=%s" % str(mroot.cpu_p2 != null))
	await _free_match(mroot)


# ---------------- record / playback ----------------------------------------------

func _test_record_playback() -> void:
	var mroot: Node = await _build_training_match(0, 1, 0)

	# Record: the trainer drives the dummy through the p2 actions while the
	# controller only captures.
	mroot.training.toggle_recording()
	_check("recording starts with an empty slot",
		mroot.training.record_active and mroot.training.recording.is_empty(),
		"active=%s frames=%d" % [str(mroot.training.record_active),
			mroot.training.recording.size()])
	var frozen_tick: int = mroot.training._tick
	var frozen_size: int = mroot.training.recording.size()
	mroot.p1.hitstop_frames = 2
	await _manual_step(mroot, 2)
	_check("recording and training RNG age freeze during hitstop",
		mroot.training._tick == frozen_tick
			and mroot.training.recording.size() == frozen_size,
		"tick %d -> %d frames %d -> %d" % [frozen_tick,
			mroot.training._tick, frozen_size, mroot.training.recording.size()])
	var recorded_path: Array = []
	Input.action_press("p2_right")
	for _i in 12:
		await _manual_step(mroot, 1)
		recorded_path.append(mroot.p2.position.x)
	Input.action_release("p2_right")
	await _manual_step(mroot, 4)
	Input.action_press("p2_light")
	await _manual_step(mroot, 2)
	Input.action_release("p2_light")
	await _manual_step(mroot, 4)
	mroot.training.toggle_recording()
	_check("recording stops and keeps the captured frames",
		not mroot.training.record_active
			and mroot.training.recording.size() == 22,
		"frames=%d path=%d" % [mroot.training.recording.size(),
			recorded_path.size()])

	# Playback loops the exact path; after the first pass the loop boundary
	# state (the dummy just attacked) repeats, so consecutive full loops are
	# frame-identical.
	mroot.training.reset_positions()
	mroot.training.toggle_playback()
	var played_path: Array = []
	for _i in recorded_path.size():
		await _manual_step(mroot, 1)
		played_path.append(mroot.p2.position.x)
	_check("playback replays the recorded dummy exactly",
		played_path == recorded_path,
		"recorded=%s played=%s" % [str(recorded_path), str(played_path)])
	for _i in 22 - recorded_path.size():
		await _manual_step(mroot, 1)
	var loop_b: Array = []
	var loop_c: Array = []
	for pass_index in 2:
		var path: Array = []
		for _i in 22:
			await _manual_step(mroot, 1)
			path.append(mroot.p2.position.x)
		if pass_index == 0:
			loop_b = path
		else:
			loop_c = path
	# Looping replays the INPUT sequence; the loop boundary lands in the
	# recorded attack's recovery, so the dummy creeps a fixed step each
	# loop while the per-frame movement pattern repeats exactly.
	_check("playback loops seamlessly (consecutive loops move identically)",
		_deltas(loop_b) == _deltas(loop_c),
		"b=%s c=%s" % [str(_deltas(loop_b)), str(_deltas(loop_c))])
	mroot.training.toggle_playback()

	# Mirroring: a recording made facing left applies left/right swapped
	# when the dummy faces right (side switches do not reverse the input).
	var word: int = 1 << mroot.training.A_RIGHT
	var crafted: Array[int] = [word]
	mroot.training.recording = crafted
	# Put the P2 dummy on P1's left after crossing; its grounded neutral
	# facing derives right from the new positional side.
	mroot.p1.position.x = 170.0
	mroot.p2.position.x = 120.0
	mroot.p2.reset_state()
	mroot.p2.grounded = true
	mroot.p2.facing = -1
	mroot.p2._update_facing()
	mroot.training.playback_active = true
	mroot.training.play_index = 0
	mroot.training.manual_tick()
	_check("playback mirrors left/right after a side switch",
		Input.is_action_pressed("p2_left")
			and not Input.is_action_pressed("p2_right"),
		"left=%s right=%s" % [str(Input.is_action_pressed("p2_left")),
			str(Input.is_action_pressed("p2_right"))])
	var crafted_flip: Array[int] = [word | (1 << mroot.training.FACING_BIT)]
	mroot.training.recording = crafted_flip
	mroot.training.play_index = 0
	mroot.training.manual_tick()
	_check("playback keeps directions when the facing matches",
		Input.is_action_pressed("p2_right")
			and not Input.is_action_pressed("p2_left"),
		"left=%s right=%s" % [str(Input.is_action_pressed("p2_left")),
			str(Input.is_action_pressed("p2_right"))])
	mroot.training.playback_active = false
	mroot.training.manual_tick()
	Input.action_release("p2_left")
	Input.action_release("p2_right")

	# The 10 s cap auto-stops the recording.
	mroot.training.recording.clear()
	for _i in mroot.training.RECORD_MAX_FRAMES - 1:
		mroot.training.recording.append(0)
	mroot.training.record_active = true
	await _manual_step(mroot, 1)
	_check("recording auto-stops at the 10 second cap",
		mroot.training.recording.size() == mroot.training.RECORD_MAX_FRAMES
			and not mroot.training.record_active,
		"frames=%d active=%s" % [mroot.training.recording.size(),
			str(mroot.training.record_active)])
	await _free_match(mroot)


# ---------------- position resets --------------------------------------------------

func _test_position_resets() -> void:
	var mroot: Node = await _build_training_match(0, 1, 0)
	var st: Node2D = mroot.stage

	# Damage/stun the pair first so the restore is observable.
	_place_pair(mroot, st.left_bound + 60.0, st.left_bound + 16.0)
	mroot.p2.health = 300.0
	mroot.p2.breaker_cooldown_frames = 123

	mroot.training.reset_positions()
	_check("MIDSCREEN reset places the pair at the spawns",
		mroot.p1.position.x == st.spawn_p1_x
			and mroot.p2.position.x == st.spawn_p2_x,
		"p1=%s p2=%s" % [str(mroot.p1.position.x), str(mroot.p2.position.x)])
	_check("the reset restores health, meter and breaker rails",
		mroot.p2.health == mroot.p2.max_health
			and mroot.p2.meter == mroot.p2.max_meter
			and mroot.p2.breaker_cooldown_frames == 0,
		"health=%s meter=%s cooldown=%d" % [str(mroot.p2.health),
			str(mroot.p2.meter), mroot.p2.breaker_cooldown_frames])

	mroot.training.set_option_value(7, 1)  # LEFT CORNER
	mroot.training.reset_positions()
	_check("LEFT CORNER reset puts the dummy in the corner",
		absf(mroot.p2.position.x - (st.left_bound + 16.0)) < 0.01
			and absf(mroot.p1.position.x - (st.left_bound + 60.0)) < 0.01,
		"dummy=%s trainer=%s" % [str(mroot.p2.position.x),
			str(mroot.p1.position.x)])

	mroot.training.set_option_value(7, 2)  # RIGHT CORNER
	mroot.training.reset_positions()
	_check("RIGHT CORNER reset mirrors to the far wall",
		absf(mroot.p2.position.x - (st.right_bound - 16.0)) < 0.01
			and absf(mroot.p1.position.x - (st.right_bound - 60.0)) < 0.01,
		"dummy=%s trainer=%s" % [str(mroot.p2.position.x),
			str(mroot.p1.position.x)])
	await _free_match(mroot)


# ---------------- training keys ------------------------------------------------------

func _test_training_keys() -> void:
	var mroot: Node = await _build_training_match(0, 1, 0)
	mroot.p1.position = Vector2(60, mroot.stage.floor_y)
	mroot.p2.position = Vector2(90, mroot.stage.floor_y)

	mroot._unhandled_input(_action_event("training_reset"))
	_check("the reset key restores the pair to the option's position",
		mroot.p1.position.x == mroot.stage.spawn_p1_x
			and mroot.p2.position.x == mroot.stage.spawn_p2_x,
		"p1=%s p2=%s" % [str(mroot.p1.position.x), str(mroot.p2.position.x)])

	mroot._unhandled_input(_action_event("training_record"))
	var recording: bool = mroot.training.record_active
	mroot._unhandled_input(_action_event("training_record"))
	_check("the record key toggles dummy recording",
		recording and not mroot.training.record_active,
		"first=%s after=%s" % [str(recording),
			str(mroot.training.record_active)])

	mroot._unhandled_input(_action_event("training_playback"))
	var playing: bool = mroot.training.playback_active
	mroot._unhandled_input(_action_event("training_playback"))
	_check("the playback key toggles dummy playback (empty slot refuses)",
		not playing and not mroot.training.playback_active,
		"started=%s after=%s" % [str(playing),
			str(mroot.training.playback_active)])
	await _free_match(mroot)


# ---------------- frame readout ------------------------------------------------------

func _test_frame_readout() -> void:
	var mroot: Node = await _build_training_match(0, 1, 0)

	# Peggy's standing light on hit: hitstun 13 minus the 9 recovery frames
	# left after a first-active-frame contact = +4.
	_place_pair(mroot)
	await _attack_light(mroot)
	await _manual_step(mroot, 12)
	var light: MoveData = mroot.p1.data.find_move(
		MoveData.InputType.LIGHT, MoveData.Stance.STAND)
	var expected_hit: int = light.hitstun - (
		light.total_frames() - light.startup)
	_check("the readout reports the light's hit advantage (+4)",
		mroot.training.last_kind == "DMG"
			and mroot.training.last_advantage == 4
			and mroot.training.last_advantage == expected_hit
			and mroot.training.last_hit_damage == light.damage
			and mroot.training.last_startup == light.startup,
		"kind=%s adv=%d expected=%d dmg=%s start=%d" % [
			mroot.training.last_kind, mroot.training.last_advantage,
			expected_hit, str(mroot.training.last_hit_damage),
			mroot.training.last_startup])
	await _manual_step(mroot, 60)

	# Blocked: blockstun 8 minus the same 9 recovery = -1.
	mroot.training.set_option_value(1, 1)  # block ALL
	_place_pair(mroot)
	await _attack_light(mroot)
	await _manual_step(mroot, 12)
	var expected_block: int = light.blockstun - (
		light.total_frames() - light.startup)
	_check("the readout reports the light's block advantage (-1)",
		mroot.training.last_kind == "BLK"
			and mroot.training.last_advantage == -1
			and mroot.training.last_advantage == expected_block,
		"kind=%s adv=%d expected=%d" % [mroot.training.last_kind,
			mroot.training.last_advantage, expected_block])
	mroot.training.set_option_value(1, 0)
	await _free_match(mroot)

	# Richard's standing heavy on hit: 18 stun minus 20 recovery = -2.
	var richard: Node = await _build_training_match(1, 0, 1)
	_place_pair(richard)
	await _tap(richard, "heavy")
	await _manual_step(richard, 16)
	var heavy: MoveData = richard.p1.data.find_move(
		MoveData.InputType.HEAVY, MoveData.Stance.STAND)
	var expected_heavy: int = heavy.hitstun - (
		heavy.total_frames() - heavy.startup)
	_check("the readout reports Richard's heavy hit advantage (-2)",
		richard.training.last_kind == "DMG"
			and richard.training.last_advantage == -2
			and richard.training.last_advantage == expected_heavy,
		"kind=%s adv=%d expected=%d" % [richard.training.last_kind,
			richard.training.last_advantage, expected_heavy])
	await _free_match(richard)

	# Cross-check a second move in each roster row, both HIT and BLOCK
	# arithmetic against the move's authored stun and total frame data.
	var peg_heavy_hit: Dictionary = await _readout_probe(0, 1,
		MoveData.InputType.HEAVY, false)
	var peg_heavy: MoveData = ROSTER.fighters[0].find_move(
		MoveData.InputType.HEAVY, MoveData.Stance.STAND)
	var peg_heavy_hit_expected := peg_heavy.hitstun \
		- (peg_heavy.total_frames() - peg_heavy.startup)
	_check("the readout matches Peggy heavy hit advantage (0)",
		peg_heavy_hit["kind"] == "DMG"
			and peg_heavy_hit["adv"] == 0
			and peg_heavy_hit["adv"] == peg_heavy_hit_expected,
		str(peg_heavy_hit))
	var peg_heavy_block: Dictionary = await _readout_probe(0, 1,
		MoveData.InputType.HEAVY, true)
	var peg_heavy_block_expected := peg_heavy.blockstun \
		- (peg_heavy.total_frames() - peg_heavy.startup)
	_check("the readout matches Peggy heavy block advantage (-6)",
		peg_heavy_block["kind"] == "BLK"
			and peg_heavy_block["adv"] == -6
			and peg_heavy_block["adv"] == peg_heavy_block_expected,
		str(peg_heavy_block))

	var richard_light_hit: Dictionary = await _readout_probe(1, 0,
		MoveData.InputType.LIGHT, false)
	var richard_light: MoveData = ROSTER.fighters[1].find_move(
		MoveData.InputType.LIGHT, MoveData.Stance.STAND)
	var richard_light_hit_expected := richard_light.hitstun \
		- (richard_light.total_frames() - richard_light.startup)
	_check("the readout matches Richard light hit advantage (+2)",
		richard_light_hit["kind"] == "DMG"
			and richard_light_hit["adv"] == 2
			and richard_light_hit["adv"] == richard_light_hit_expected,
		str(richard_light_hit))
	var richard_light_block: Dictionary = await _readout_probe(1, 0,
		MoveData.InputType.LIGHT, true)
	var richard_light_block_expected := richard_light.blockstun \
		- (richard_light.total_frames() - richard_light.startup)
	_check("the readout matches Richard light block advantage (-3)",
		richard_light_block["kind"] == "BLK"
			and richard_light_block["adv"] == -3
			and richard_light_block["adv"] == richard_light_block_expected,
		str(richard_light_block))
	var richard_heavy_block: Dictionary = await _readout_probe(1, 0,
		MoveData.InputType.HEAVY, true)
	var richard_heavy: MoveData = ROSTER.fighters[1].find_move(
		MoveData.InputType.HEAVY, MoveData.Stance.STAND)
	var richard_heavy_block_expected := richard_heavy.blockstun \
		- (richard_heavy.total_frames() - richard_heavy.startup)
	_check("the readout matches Richard heavy block advantage (-8)",
		richard_heavy_block["kind"] == "BLK"
			and richard_heavy_block["adv"] == -8
			and richard_heavy_block["adv"] == richard_heavy_block_expected,
		str(richard_heavy_block))


func _readout_probe(p1_index: int, p2_index: int,
		input_type: MoveData.InputType, blocked: bool) -> Dictionary:
	var mroot: Node = await _build_training_match(p1_index, p2_index, 0, 812)
	if blocked:
		mroot.training.block = mroot.training.Block.ALL
	_place_pair(mroot)
	var move: MoveData = mroot.p1.data.find_move(input_type,
		MoveData.Stance.STAND)
	mroot.p1._start_move(move)
	for _frame in 60:
		await _manual_step(mroot, 1)
		if mroot.training.last_move_id == move.id:
			break
	var result := {
		"kind": mroot.training.last_kind,
		"adv": mroot.training.last_advantage,
		"startup": mroot.training.last_startup,
	}
	await _free_match(mroot)
	return result


# ---------------- hitbox toggle and pause tab ----------------------------------------

func _test_hitbox_toggle_and_pause_tab() -> void:
	var mroot: Node = await _build_training_match(0, 1, 0)

	# The menu row drives the F1 debug drawing.
	mroot.training.set_option_value(8, 1)
	_check("the HITBOXES row toggles the F1 box drawing",
		mroot.debug_overlay.show_boxes,
		"show_boxes=%s" % str(mroot.debug_overlay.show_boxes))
	mroot.training.set_option_value(8, 0)
	_check("the HITBOXES row toggles the boxes back off",
		not mroot.debug_overlay.show_boxes,
		"show_boxes=%s" % str(mroot.debug_overlay.show_boxes))

	# The pause menu: tabs, in-place value adjustment, apply rows.
	mroot._toggle_pause()
	_check("the training pause opens on the TRAINING tab row",
		mroot.pause_menu_open and mroot.pause_tab == 1
			and mroot.pause_index == -1,
		"tab=%d index=%d" % [mroot.pause_tab, mroot.pause_index])
	mroot._unhandled_input(_action_event("p1_down"))
	mroot._unhandled_input(_action_event("p1_right"))
	_check("left/right adjusts the focused training row in place",
		mroot.training.dummy == mroot.training.Dummy.CROUCH,
		"dummy=%d" % mroot.training.dummy)
	mroot._unhandled_input(_action_event("p1_left"))
	mroot._unhandled_input(_action_event("p1_down"))
	mroot._unhandled_input(_action_event("p1_right"))
	_check("the BLOCK row cycles its values",
		mroot.training.block == mroot.training.Block.ALL,
		"block=%d" % mroot.training.block)

	# Confirm on the POSITION row applies a reset; row 7 from row 1 is six
	# downs away. Then HITBOXES toggles through the row too.
	for _i in 6:
		mroot._unhandled_input(_action_event("p1_down"))
	mroot._unhandled_input(_action_event("p1_right"))
	mroot.p1.position.x = 55.0
	mroot._unhandled_input(_action_event("p1_light"))
	_check("confirm on the POSITION row applies it as a reset",
		mroot.training.reset_pos == mroot.training.ResetPos.LEFT_CORNER
			and mroot.p1.position.x != 55.0,
		"pos=%d p1x=%s" % [mroot.training.reset_pos,
			str(mroot.p1.position.x)])
	mroot._unhandled_input(_action_event("p1_down"))
	mroot._unhandled_input(_action_event("p1_right"))
	_check("the HITBOXES row applies through the menu",
		mroot.training.hitboxes == mroot.training.Toggle.ON
			and mroot.debug_overlay.show_boxes,
		"hitboxes=%d boxes=%s" % [mroot.training.hitboxes,
			str(mroot.debug_overlay.show_boxes)])

	# The SYSTEM tab keeps the six original options and RESUME unpauses.
	for _i in 9:
		mroot._unhandled_input(_action_event("p1_up"))
	mroot._unhandled_input(_action_event("p1_right"))
	_check("the tab row switches to the SYSTEM options",
		mroot.pause_tab == 0 and mroot.pause_index == -1,
		"tab=%d index=%d" % [mroot.pause_tab, mroot.pause_index])
	mroot._unhandled_input(_action_event("p1_down"))
	mroot._unhandled_input(_action_event("p1_light"))
	_check("RESUME on the system tab unpauses the training match",
		not mroot.pause_menu_open and not paused,
		"open=%s paused=%s" % [str(mroot.pause_menu_open), str(paused)])
	await _free_match(mroot)


# ---------------- input map ----------------------------------------------------------

func _test_input_map() -> void:
	_check("the three training actions exist with keyboard and pad bindings",
		InputMap.has_action("training_reset")
			and InputMap.has_action("training_record")
			and InputMap.has_action("training_playback"),
		"actions missing")
	var expected_keys := {
		"training_reset": KEY_R,
		"training_record": KEY_T,
		"training_playback": KEY_P,
	}
	var collisions: Array[String] = []
	for action in InputMap.get_actions():
		var name := String(action)
		if not (name.begins_with("p1_") or name.begins_with("p2_")):
			continue
		for event in InputMap.action_get_events(action):
			if event is InputEventKey \
					and expected_keys.values().has(event.physical_keycode):
				collisions.append(name)
			if event is InputEventJoypadButton \
					and event.button_index in [JOY_BUTTON_LEFT_SHOULDER,
						JOY_BUTTON_RIGHT_STICK, JOY_BUTTON_LEFT_STICK]:
				collisions.append(name)
	_check("training keys and pads collide with no player binding",
		collisions.is_empty(), str(collisions))
	var has_all_bindings := true
	for action in expected_keys.keys():
		var saw_key := false
		var saw_pad := false
		for event in InputMap.action_get_events(action):
			if event is InputEventKey \
					and event.physical_keycode == expected_keys[action]:
				saw_key = true
			if event is InputEventJoypadButton:
				saw_pad = true
		if not (saw_key and saw_pad):
			has_all_bindings = false
	_check("each training action carries its R/T/P key and pad button",
		has_all_bindings, "missing key or pad events")


# ---------------- determinism / serialize-restore -------------------------------------

func _run_scripted_frames(mroot: Node, frames: int) -> Array:
	var hashes: Array = []
	for i in frames:
		if i % 30 == 0:
			# Buffer injection (the #67/#69 latch class): taps must land on
			# the exact frame the manual tick reads them.
			mroot.p1.input_buffer["light"] = 0
		await _manual_step(mroot, 1)
		hashes.append(_state_hash(mroot))
	return hashes


func _test_determinism_and_restore() -> void:
	var a: Node = await _build_training_match(0, 1, 0, 777)
	a.training.set_option_value(1, 3)  # RANDOM block
	_place_pair(a)
	var run_a: Array = await _run_scripted_frames(a, 240)
	var b: Node = await _build_training_match(0, 1, 0, 777)
	b.training.set_option_value(1, 3)
	_place_pair(b)
	var run_b: Array = await _run_scripted_frames(b, 240)
	_check("training is deterministic: same seed replays identically",
		run_a == run_b,
		"first diff=%d" % _first_diff(run_a, run_b))

	# Serialize mid-training (mid-string, mid-random) and restore into a
	# fresh match: the state round-trips, and the continuations match.
	var snapshot: Dictionary = a.serialize()
	var c: Node = await _build_training_match(0, 1, 0, 777)
	c.load(snapshot)
	_check("training save pins the no-KO floor on both fighters",
		snapshot["p1"].get("training_min_health", 0.0) == 1.0
			and snapshot["p2"].get("training_min_health", 0.0) == 1.0
			and c.p1.training_min_health == 1.0
			and c.p2.training_min_health == 1.0,
		"saved p1=%s p2=%s" % [
			str(snapshot["p1"].get("training_min_health")),
			str(snapshot["p2"].get("training_min_health"))])
	var roundtrip: Dictionary = c.serialize()
	_check("training state round-trips through serialize/load",
		roundtrip.get("training") == snapshot.get("training"),
		"training dict diverged")
	var cont_a: Array = await _run_scripted_frames(a, 120)
	var cont_c: Array = await _run_scripted_frames(c, 120)
	_check("a mid-training serialize/restore resumes identically",
		cont_a == cont_c,
		"first diff=%d" % _first_diff(cont_a, cont_c))
	await _free_match(a)
	await _free_match(b)
	await _free_match(c)


func _first_diff(a: Array, b: Array) -> int:
	for i in mini(a.size(), b.size()):
		if a[i] != b[i]:
			return i
	return -1


func _deltas(path: Array) -> Array:
	var out: Array = []
	for i in path.size():
		out.append(0.0 if i == 0 else path[i] - path[i - 1])
	return out
