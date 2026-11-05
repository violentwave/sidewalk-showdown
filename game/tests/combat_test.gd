# Headless Phase 1 combat test. Run:
#   godot --headless --path game --script res://tests/combat_test.gd
extends SceneTree

var scene: Node2D
var p1: FighterBase
var p2: FighterBase
var failures := 0


func _initialize() -> void:
	scene = load("res://scenes/match/MatchRoot.tscn").instantiate()
	root.add_child(scene)
	_run.call_deferred()


func _step(frames: int = 1) -> void:
	for i in frames:
		await physics_frame


func _check(label: String, condition: bool, detail: String = "") -> void:
	if condition:
		print("PASS: ", label)
	else:
		failures += 1
		print("FAIL: ", label, "  ", detail)


func _press(action: String) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = true
	scene._unhandled_input(ev)


func _reset_fighters(p1_x: float, p2_x: float) -> void:
	p1.position = Vector2(p1_x, 150)
	p2.position = Vector2(p2_x, 150)
	p1.velocity = Vector2.ZERO
	p2.velocity = Vector2.ZERO
	p1.facing = 1
	p2.facing = -1
	p1.health = 1000.0
	p2.health = 1000.0
	p1.combo_hits = 0
	p2.combo_hits = 0
	p1.reset_state()
	p2.reset_state()


# Drop a fighter straight into WAKE_UP. The wake-up length is seeded from data
# the way _knockdown_logic() does it, otherwise the forced state sees
# wakeup_frames == 0 and falls through to IDLE on the next tick.
func _force_wakeup(f: FighterBase) -> void:
	f.wakeup_frames = f.data.wakeup_frames
	f._force_state(FighterBase.State.WAKE_UP)


# Put P1 in an aerial move just above the floor, with the requested move frame
# selected. One physics step then touches down during startup/active/recovery.
func _force_air_landing(move: MoveData, move_frame: int, defender_x := 300.0) -> void:
	scene._begin_round()
	scene._start_fight()
	scene.set("phase", 4)
	_reset_fighters(100.0, defender_x)
	p1.input_enabled = false
	p2.input_enabled = false
	p1.position = Vector2(100.0, scene.stage.floor_y - 1.0)
	p1.velocity = Vector2(0.0, 60.0)
	p1.grounded = false
	p1._start_move(move)
	p1.state_frame = move_frame


func _run() -> void:
	await _step(65) # let round intro finish
	p1 = scene.p1
	p2 = scene.p2
	_check("fighters spawned", p1 != null and p2 != null)
	_check("match reaches FIGHT phase", scene.phase == 1, "phase=%d" % scene.phase)

	# --- 1. clean hit ---
	_reset_fighters(100, 120)
	await _step(2)
	var light: MoveData = p1.data.find_move(MoveData.InputType.LIGHT, MoveData.Stance.STAND)
	p1._start_move(light)
	await _step(light.total_frames() + 4)
	_check("light hit deals damage", p2.health < 1000.0, "hp=%.1f" % p2.health)
	_check("light damage matches data", is_equal_approx(p2.health, 1000.0 - light.damage), "hp=%.1f" % p2.health)
	_check("attacker gains meter", p1.meter > 0.0, "meter=%.1f" % p1.meter)

	# --- 2. block chip damage ---
	_reset_fighters(100, 120)
	Input.action_press("p2_right") # p2 faces left, right = away
	await _step(3)
	p1._start_move(light)
	await _step(light.total_frames() + 4)
	_check("blocked hit only chips", is_equal_approx(p2.health, 1000.0 - light.block_damage), "hp=%.1f" % p2.health)
	Input.action_release("p2_right")

	# --- 3. low hits standing blocker ---
	_reset_fighters(100, 120)
	Input.action_press("p2_right") # standing block
	await _step(3)
	var low: MoveData = p1.data.find_move(MoveData.InputType.LIGHT, MoveData.Stance.CROUCH)
	p1._start_move(low)
	await _step(low.total_frames() + 4)
	_check("low attack beats stand block", is_equal_approx(p2.health, 1000.0 - low.damage), "hp=%.1f" % p2.health)
	Input.action_release("p2_right")

	# --- 4. throw is unblockable ---
	_reset_fighters(100, 120)
	Input.action_press("p2_right")
	await _step(3)
	var grab: MoveData = p1.data.find_move(MoveData.InputType.GRAB, MoveData.Stance.STAND)
	p1._start_move(grab)
	await _step(grab.total_frames() + 4)
	_check("throw ignores block", is_equal_approx(p2.health, 1000.0 - grab.damage), "hp=%.1f" % p2.health)
	Input.action_release("p2_right")

	# --- 5. jump input works ---
	_reset_fighters(100, 200)
	Input.action_press("p1_up")
	await _step(1)
	Input.action_release("p1_up")
	await _step(6)
	_check("jump leaves the ground", p1.position.y < 150.0, "y=%.1f" % p1.position.y)
	await _step(40)

	# --- 6. P2 input map ---
	_reset_fighters(100, 200)
	Input.action_press("p2_left")
	await _step(6)
	Input.action_release("p2_left")
	_check("P2 moves with own keys", p2.position.x < 200.0, "x=%.1f" % p2.position.x)
	await _step(2)
	Input.action_press("p2_light")
	await _step(2)
	Input.action_release("p2_light")
	_check("P2 attacks with own keys", p2.state == FighterBase.State.ATTACK, "state=%d" % p2.state)
	await _step(30)

	# --- 7. blockstun still blocks ---
	_reset_fighters(100, 120)
	Input.action_press("p2_right") # p2 faces left, right = away
	await _step(3)
	p2.receive_hit(p1, light)
	p2.hitstop_frames = 0
	p2.receive_hit(p1, light)
	_check("blockstun keeps blocking", is_equal_approx(p2.health, 1000.0 - light.block_damage * 2.0),
		"hp=%.1f" % p2.health)
	Input.action_release("p2_right")

	# --- 8. attacker shares hitstop ---
	_reset_fighters(100, 120)
	p1._start_move(light)
	var hit_frames := 0
	while p2.health >= 1000.0 and hit_frames < 30:
		await _step(1)
		hit_frames += 1
	_check("attacker freezes on hit", p1.hitstop_frames > 0 and p2.hitstop_frames > 0,
		"p1=%d p2=%d" % [p1.hitstop_frames, p2.hitstop_frames])
	await _step(20)

	# --- 9. jump arc advances through rise and fall ---
	_reset_fighters(100, 200)
	Input.action_press("p1_up")
	await _step(1)
	Input.action_release("p1_up")
	var saw_rise := false
	var saw_fall := false
	for i in 60:
		await _step(1)
		if p1.state == FighterBase.State.JUMP_RISE:
			saw_rise = true
		if p1.state == FighterBase.State.JUMP_FALL:
			saw_fall = true
			break
	_check("jump transitions rise -> fall", saw_rise and saw_fall,
		"rise=%s fall=%s state=%d" % [saw_rise, saw_fall, p1.state])
	await _step(40)

	# --- 10. KO loser lands and stays KO (last: ends the round) ---
	_reset_fighters(100, 120)
	p2.health = 1.0
	p1._start_move(light)
	await _step(60)
	_check("KO loser lands on stage", is_equal_approx(p2.position.y, 150.0) and p2.grounded,
		"y=%.1f grounded=%s" % [p2.position.y, p2.grounded])
	_check("KO state persists after landing", p2.state == FighterBase.State.KO,
		"state=%d" % p2.state)

	# --- 11. real keyboard events resolve through the input map ---
	# Input.action_press() bypasses the InputMap, so it cannot catch a binding
	# that is stamped with the wrong device id. Replay each mapped key as the
	# device-16 event a physical keyboard actually produces (real events seen via
	# XTest carry device 16; bindings must be device -1 to accept them).
	var unmapped: Array[String] = []
	for action in InputMap.get_actions():
		var an := String(action)
		if not (an.begins_with("p1_") or an.begins_with("p2_")):
			continue
		var mapped := InputMap.action_get_events(action)
		if mapped.is_empty():
			unmapped.append("%s:none" % an)
			continue
		for e: InputEventKey in mapped:
			var probe := InputEventKey.new()
			probe.physical_keycode = e.physical_keycode
			probe.keycode = e.keycode
			probe.device = 16 # what a physical keyboard reports
			if not InputMap.event_is_action(probe, action):
				unmapped.append("%s:%s" % [an, OS.get_keycode_string(e.physical_keycode)])
	_check("keyboard events match input map", unmapped.is_empty(), str(unmapped))

	# --- 12. chip damage cannot KO ---
	# The KO round above ended the match and disabled fighter input; re-enable it
	# so p2 can actually hold back and block these hits.
	_reset_fighters(100, 120)
	p2.input_enabled = true
	p2.health = 1.0
	Input.action_press("p2_right") # p2 faces left, right = away
	await _step(3)
	for i in 5:
		p2.receive_hit(p1, light)
		p2.hitstop_frames = 0
	_check("chip damage cannot KO", p2.state != FighterBase.State.KO and p2.health >= 1.0,
		"hp=%.2f state=%d" % [p2.health, p2.state])
	Input.action_release("p2_right")
	p2.health = 1000.0
	await _step(2)

	# --- 13. pause menu freezes the sim mid-hitstun ---
	_reset_fighters(100, 120)
	p1.health = 1000.0
	p2.health = 1000.0
	p2.receive_hit(p1, light)
	p1.hitstop_frames = 0
	p2.hitstop_frames = 0
	await _step(2)
	_check("p2 is in hitstun", p2.state == FighterBase.State.HITSTUN, "state=%d" % p2.state)
	var hp_before := p2.health
	var p2_frame := p2.state_frame

	_press("p1_pause")
	await _step(4)
	_check("pause freezes fighters", p2.state_frame == p2_frame,
		"frame %d -> %d" % [p2_frame, p2.state_frame])
	_check("pause keeps match controller running", scene.can_process(),
		"can_process=%s" % str(scene.can_process()))
	_check("pause opens the menu", paused and scene.pause_index == 0,
		"paused=%s index=%d" % [str(paused), scene.pause_index])

	# --- 14. both players navigate, selection does not touch the sim ---
	_press("p2_down")
	_check("P2 moves the menu selection", scene.pause_index == 1, "index=%d" % scene.pause_index)
	_press("p1_up")
	_check("P1 moves the menu selection", scene.pause_index == 0, "index=%d" % scene.pause_index)
	_press("p1_up")
	_check("menu wraps to the last option", scene.pause_index == 2, "index=%d" % scene.pause_index)
	_press("p1_down")
	_check("menu wraps to the first option", scene.pause_index == 0, "index=%d" % scene.pause_index)

	await _step(6)
	_check("menu input does not advance sim",
		p2.state_frame == p2_frame and is_equal_approx(p2.health, hp_before),
		"frame %d -> %d hp %.1f" % [p2_frame, p2.state_frame, p2.health])

	_press("p2_light") # RESUME is selected
	await _step(3)
	_check("light attack resumes", not paused, "paused=%s" % str(paused))
	_check("sim resumes mid-hitstun",
		p2.state == FighterBase.State.HITSTUN and p2.state_frame > p2_frame
			and is_equal_approx(p2.health, hp_before),
		"state=%d frame=%d hp=%.1f" % [p2.state, p2.state_frame, p2.health])
	await _step(25)

	# --- 15. restart match from the menu ---
	_press("p2_pause")
	_press("p2_down")
	_check("restart option selected", scene.pause_index == 1, "index=%d" % scene.pause_index)
	_press("ui_confirm")
	await _step(2)
	_check("restart match from the menu",
		not paused and scene.round_number == 1 and scene.wins[0] == 0 and scene.wins[1] == 0,
		"paused=%s round=%d wins=%s" % [str(paused), scene.round_number, str(scene.wins)])

	# --- 16. debug overlay: frame-step and frame advantage ---
	var overlay: DebugOverlay = scene.debug_overlay
	_check("overlay bound to fighters", overlay != null and overlay.p1 == p1 and overlay.p2 == p2,
		"bound=%s" % str(overlay != null))
	overlay.slow_motion = true
	var step_before := p1.state_frame
	overlay.step_frame()
	_check("frame-step advances exactly one frame", p1.state_frame == step_before + 1,
		"state_frame %d -> %d" % [step_before, p1.state_frame])
	var one_step := p1.state_frame
	overlay.step_frame()
	_check("frame-step is one frame per press", p1.state_frame == one_step + 1,
		"state_frame %d -> %d" % [one_step, p1.state_frame])
	_check("frame-step keeps the tree paused", paused, "paused=%s" % str(paused))
	overlay.slow_motion = false
	paused = false
	var idle_frame := p1.state_frame
	overlay.step_frame()
	_check("frame-step is inert without slow-mo", p1.state_frame == idle_frame,
		"state_frame %d -> %d" % [idle_frame, p1.state_frame])

	_reset_fighters(100, 120)
	p2.receive_hit(p1, light)
	p1.hitstop_frames = 0
	p2.hitstop_frames = 0
	await _step(1)
	# p1 is idle, so its remaining recovery is 0 and the advantage equals the
	# defender's remaining hitstun. The old formula (attacker frame minus total
	# hitstun) reported a large negative number here.
	var adv_remaining := maxi(0, p2.hitstun_frames - p2.state_frame)
	var adv_expected := "ADV P1 %+d f0/%dhit" % [adv_remaining, adv_remaining]
	_check("frame advantage reads out during hitstun",
		overlay._advantage_text() == adv_expected,
		"adv='%s' expected='%s'" % [overlay._advantage_text(), adv_expected])

	# --- 17. debug overlay reset ---
	p1.health = 120.0
	p2.health = 60.0
	p1.meter = 5.0
	p1.position = Vector2(160, 120)
	p2.position = Vector2(200, 140)
	p2._force_state(FighterBase.State.HITSTUN)
	var phase_before: int = scene.phase
	overlay.reset_fighters()
	_check("reset restores full health",
		is_equal_approx(p1.health, p1.max_health) and is_equal_approx(p2.health, p2.max_health),
		"p1=%.1f p2=%.1f" % [p1.health, p2.health])
	_check("reset fills meter", is_equal_approx(p1.meter, p1.max_meter), "meter=%.1f" % p1.meter)
	_check("reset restores round positions",
		is_equal_approx(p1.position.x, scene.stage.spawn_p1_x)
			and is_equal_approx(p2.position.x, scene.stage.spawn_p2_x)
			and is_equal_approx(p1.position.y, scene.stage.floor_y),
		"p1=%s p2=%s" % [str(p1.position), str(p2.position)])
	_check("reset returns fighters to idle",
		p1.state == FighterBase.State.IDLE and p2.state == FighterBase.State.IDLE,
		"p1=%d p2=%d" % [p1.state, p2.state])
	_check("reset keeps the match phase", scene.phase == phase_before,
		"phase=%d -> %d" % [phase_before, scene.phase])

	# --- 18. frame-step is gated while the pause menu is open ---
	overlay.slow_motion = true
	overlay.step_frame()
	_check("frame-step leaves tree paused", paused and not scene.pause_menu_open)
	_press("p1_pause")
	_check("pause menu opens while frame-step paused", paused and scene.pause_menu_open,
		"paused=%s menu=%s" % [str(paused), str(scene.pause_menu_open)])
	var gated_frame := p1.state_frame
	overlay.step_frame()
	_check("frame-step is gated while the pause menu is open",
		p1.state_frame == gated_frame, "state_frame %d -> %d" % [gated_frame, p1.state_frame])
	_press("p1_pause")
	overlay.step_frame()
	_check("frame-step works again once the menu closes",
		p1.state_frame == gated_frame + 1, "state_frame %d -> %d" % [gated_frame, p1.state_frame])
	overlay.slow_motion = false
	paused = false

	# --- 19. grounded throw connects, airborne throw whiffs ---
	scene._begin_round()
	scene._start_fight()
	_reset_fighters(100, 120)
	var throw_move: MoveData = p1.data.find_move(MoveData.InputType.GRAB, MoveData.Stance.STAND)
	_check("grab data present", throw_move != null and throw_move.level == MoveData.Level.THROW)
	p1._start_move(throw_move)
	await _step(throw_move.total_frames() + 4)
	_check("grounded throw connects",
		is_equal_approx(p2.health, 1000.0 - throw_move.damage)
			and p2.state == FighterBase.State.KNOCKDOWN,
		"hp=%.1f state=%d" % [p2.health, p2.state])

	# --- 20. airborne defender is not grabbed, and the window survives ---
	scene._begin_round()
	scene._start_fight()
	_reset_fighters(100, 120)
	p1.health = 1000.0
	p2.health = 1000.0
	# 11.25px up with 60px/s down: gravity (900px/s^2 = 15px/s per frame) makes
	# the descent 1.25/1.5/1.75/2.0/2.25 px over five frames, then 2.5 on the
	# sixth, so the throw's first active frame (5) brushes an airborne defender
	# and the second (6) sees them land.
	p2.position = Vector2(120, 150.0 - 11.25)
	p2.velocity = Vector2(0, 60.0)
	p2.grounded = false
	p2._force_state(FighterBase.State.JUMP_FALL)
	p1._start_move(throw_move)
	await _step(5)
	_check("airborne defender is not grabbed",
		not p2.grounded and is_equal_approx(p2.health, 1000.0),
		"grounded=%s hp=%.1f" % [str(p2.grounded), p2.health])
	_check("brushed throw keeps its active window", not p1.move_already_hit,
		"move_already_hit=%s" % str(p1.move_already_hit))
	await _step(3)
	_check("throw lands once the defender is grounded in the window",
		is_equal_approx(p2.health, 1000.0 - throw_move.damage)
			and p2.state == FighterBase.State.KNOCKDOWN,
		"grounded=%s hp=%.1f state=%d" % [str(p2.grounded), p2.health, p2.state])

	# --- 21. wake-up invulnerability: a meaty on wake-up frame 1 whiffs ---
	scene._begin_round()
	scene._start_fight()
	_reset_fighters(100, 120)
	var light_move: MoveData = p1.data.find_move(MoveData.InputType.LIGHT, MoveData.Stance.STAND)
	_force_wakeup(p2)
	p1._start_move(light_move)
	await _step(light_move.total_frames() + 2)
	_check("wake-up invulnerability blocks a frame-1 meaty",
		is_equal_approx(p2.health, 1000.0) and not p1.move_already_hit,
		"hp=%.1f already_hit=%s" % [p2.health, str(p1.move_already_hit)])

	# --- 22. the invuln brush does not consume the active window ---
	scene._begin_round()
	scene._start_fight()
	_reset_fighters(100, 120)
	_force_wakeup(p2)
	await _step(2)
	p1._start_move(light_move)
	await _step(3)
	_check("invulnerable brush is not counted as a hit",
		is_equal_approx(p2.health, 1000.0) and not p1.move_already_hit,
		"frame=%d hp=%.1f" % [p2.state_frame, p2.health])
	await _step(2)
	_check("meaty lands on the first vulnerable frame",
		is_equal_approx(p2.health, 1000.0 - light_move.damage),
		"frame=%d hp=%.1f" % [p2.state_frame, p2.health])

	# --- 23. strike and throw invuln are separate timers ---
	scene._begin_round()
	scene._start_fight()
	_reset_fighters(100, 120)
	_force_wakeup(p2)
	await _step(6)
	var strike_live := not p2.is_invulnerable_to(light_move)
	var throw_shut := p2.is_invulnerable_to(throw_move)
	await _step(2)
	_check("wake-up strike invuln ends before throw invuln",
		p2.state == FighterBase.State.WAKE_UP and strike_live and throw_shut
			and not p2.is_invulnerable_to(throw_move),
		"frame=%d strike_live=%s throw_shut=%s" % [p2.state_frame, str(strike_live), str(throw_shut)])

	# --- 24. a wake-up throw is rejected until its own window ends ---
	scene._begin_round()
	scene._start_fight()
	_reset_fighters(100, 120)
	_force_wakeup(p2)
	await _step(2)
	p1._start_move(throw_move)
	await _step(5)
	_check("wake-up throw is rejected inside the throw-invuln window",
		is_equal_approx(p2.health, 1000.0) and not p1.move_already_hit,
		"frame=%d hp=%.1f" % [p2.state_frame, p2.health])
	await _step(3)
	_check("wake-up throw lands once the throw-invuln window ends",
		is_equal_approx(p2.health, 1000.0 - throw_move.damage)
			and p2.state == FighterBase.State.KNOCKDOWN,
		"frame=%d hp=%.1f state=%d" % [p2.state_frame, p2.health, p2.state])

	# --- 25. wakeup_frames comes from FighterData ---
	scene._begin_round()
	scene._start_fight()
	_reset_fighters(100, 120)
	var authored_wakeup := p2.data.wakeup_frames
	p2.data.wakeup_frames = 20
	p2.knockdown_frames = 2
	p2._force_state(FighterBase.State.KNOCKDOWN)
	await _step(4)
	var override_took := p2.state == FighterBase.State.WAKE_UP and p2.wakeup_frames == 20
	await _step(18)
	_check("wakeup_frames is read from FighterData",
		override_took and p2.state == FighterBase.State.IDLE,
		"wakeup=%d state=%d" % [p2.wakeup_frames, p2.state])
	p2.data.wakeup_frames = authored_wakeup

	# --- 26. the wake-up gate does not shadow the airborne-throw guard ---
	scene._begin_round()
	scene._start_fight()
	_reset_fighters(100, 120)
	# Same descent as test 20: frame 5 brushes an airborne defender, frame 6 lands.
	p2.position = Vector2(120, 150.0 - 11.25)
	p2.velocity = Vector2(0, 60.0)
	p2.grounded = false
	p2._force_state(FighterBase.State.JUMP_FALL)
	var airborne_is_vulnerable := not p2.is_invulnerable_to(throw_move)
	p1._start_move(throw_move)
	await _step(8)
	_check("wake-up invuln does not shadow the airborne throw guard",
		airborne_is_vulnerable and is_equal_approx(p2.health, 1000.0 - throw_move.damage)
			and p2.state == FighterBase.State.KNOCKDOWN,
		"hp=%.1f state=%d" % [p2.health, p2.state])

	# --- 27. F2 readout shows the wake-up invulnerability countdown ---
	scene._begin_round()
	scene._start_fight()
	_reset_fighters(100, 120)
	await _step(1)
	var idle_readout := overlay._invuln_text(p2)
	_force_wakeup(p2)
	await _step(1)
	var strike_readout := overlay._invuln_text(p2)
	await _step(6)
	var throw_readout := overlay._invuln_text(p2)
	var state_readout := overlay._state_text()
	_check("invuln readout is empty while idle", idle_readout == "", "readout='%s'" % idle_readout)
	_check("readout shows the wake-up strike window",
		strike_readout == " INV %df" % (p2.data.wakeup_invuln_frames - 1),
		"readout='%s' frame=%d" % [strike_readout, p2.state_frame])
	_check("readout switches to THROWINV for the throw tail",
		throw_readout == " THROWINV %df" % (p2.data.wakeup_throw_invuln_frames - p2.state_frame),
		"readout='%s' frame=%d" % [throw_readout, p2.state_frame])
	_check("frame-state text carries the countdown",
		state_readout.contains("THROWINV") and state_readout.contains("P2 WAKE_UP"),
		"text='%s'" % state_readout.replace("\n", " | "))

	# --- 28. a reversal's own invuln frames use the same readout slot ---
	scene._begin_round()
	scene._start_fight()
	_reset_fighters(100, 120)
	var reversal: MoveData = p1.data.find_move(MoveData.InputType.HEAVY, MoveData.Stance.STAND)
	var saved_kind := reversal.invuln_kind
	var saved_end := reversal.invuln_end
	reversal.invuln_kind = MoveData.Invuln.FULL
	reversal.invuln_end = 6
	p1._start_move(reversal)
	await _step(1)
	_check("readout shows a reversal's own invuln frames",
		overlay._invuln_text(p1) == " INV %df" % (6 - p1.state_frame),
		"readout='%s' frame=%d" % [overlay._invuln_text(p1), p1.state_frame])
	reversal.invuln_kind = saved_kind
	reversal.invuln_end = saved_end

	# --- 29. hitstop freezes the countdown: the window counts simulation frames ---
	# PROPOSALS §1 assumes exactly this ("an 8-frame invulnerable window can last
	# longer than 8 real frames if a hit lands"). Asserted as documented behaviour,
	# not changed: _physics_process() decrements hitstop and returns before
	# state_frame advances, so the invuln query keeps returning true.
	scene._begin_round()
	scene._start_fight()
	_reset_fighters(100, 120)
	_force_wakeup(p2)
	await _step(2)
	var frozen_frame := p2.state_frame
	p2.hitstop_frames = 3 # what receive_hit() grants on a trade
	await _step(3)
	var frozen_invuln := p2.is_invulnerable_to(light_move)
	_check("hitstop freezes the wake-up invuln countdown",
		p2.state_frame == frozen_frame and frozen_invuln,
		"frame %d -> %d invuln=%s" % [frozen_frame, p2.state_frame, str(frozen_invuln)])
	await _step(4)
	_check("the countdown resumes, and expires, after hitstop",
		p2.state_frame == frozen_frame + 4 and not p2.is_invulnerable_to(light_move),
		"frame=%d invuln=%s" % [p2.state_frame, str(p2.is_invulnerable_to(light_move))])

	# --- 30. authored invuln does not linger after the move ends ---
	# _attack_logic() returns to IDLE without clearing current_move, so the query
	# must also require ATTACK; otherwise the reversal's invuln window is re-read
	# against the fresh IDLE state_frame and the fighter stays intangible.
	scene._begin_round()
	scene._start_fight()
	_reset_fighters(100, 120)
	var saving_input := p1.input_enabled
	p1.input_enabled = false
	var lingering_move: MoveData = p1.data.find_move(MoveData.InputType.HEAVY, MoveData.Stance.STAND)
	var saved_lingering_kind := lingering_move.invuln_kind
	var saved_lingering_start := lingering_move.invuln_start
	var saved_lingering_end := lingering_move.invuln_end
	lingering_move.invuln_kind = MoveData.Invuln.FULL
	lingering_move.invuln_start = 0
	lingering_move.invuln_end = 6
	p1._start_move(lingering_move)
	var step_guard := 0
	while p1.state == FighterBase.State.ATTACK and step_guard < 120:
		await _step(1)
		step_guard += 1
	_check("authored invuln ends with the move",
		p1.state == FighterBase.State.IDLE and not p1.is_invulnerable_to(light_move),
		"state=%d frame=%d invuln=%s" % [p1.state, p1.state_frame,
			str(p1.is_invulnerable_to(light_move))])
	lingering_move.invuln_kind = saved_lingering_kind
	lingering_move.invuln_start = saved_lingering_start
	lingering_move.invuln_end = saved_lingering_end
	p1.input_enabled = saving_input

	# --- 31. throw tech inside the window neutralizes both fighters ---
	# PROPOSALS §2: a grab buffered within throw_tech_window (7f) breaks the
	# throw. Grab is also the throw button, so the defender's own throw attempt
	# is the tech input; the incoming throw breaks it instead of trading.
	scene._begin_round()
	scene._start_fight()
	_reset_fighters(100, 120)
	p1._start_move(throw_move)
	await _step(2)
	Input.action_press("p2_grab")
	await _step(1)
	Input.action_release("p2_grab")
	await _step(3)
	_check("tech neutralizes both fighters with no damage",
		p1.state == FighterBase.State.TECH and p2.state == FighterBase.State.TECH
			and is_equal_approx(p1.health, 1000.0) and is_equal_approx(p2.health, 1000.0),
		"p1=%d p2=%d hp=%.1f/%.1f" % [p1.state, p2.state, p1.health, p2.health])
	_check("tech lasts throw_tech_recovery frames on both",
		p1.tech_frames == p1.data.throw_tech_recovery
			and p2.tech_frames == p2.data.throw_tech_recovery,
		"p1=%d p2=%d" % [p1.tech_frames, p2.tech_frames])
	_check("overlay reports the TECH state",
		overlay._state_text().contains("P1 TECH") and overlay._state_text().contains("P2 TECH"),
		"text='%s'" % overlay._state_text().replace("\n", " | "))
	await _step(12)
	_check("tech pushes both fighters apart", p1.position.x < 100.0 and p2.position.x > 120.0,
		"p1=%.1f p2=%.1f" % [p1.position.x, p2.position.x])
	_check("both fighters leave TECH for neutral",
		p1.state == FighterBase.State.IDLE and p2.state == FighterBase.State.IDLE,
		"p1=%d p2=%d" % [p1.state, p2.state])

	# --- 32. a grab buffer older than the window does not tech ---
	scene._begin_round()
	scene._start_fight()
	_reset_fighters(100, 120)
	p2.input_enabled = false
	p2.input_buffer["grab"] = p2.data.throw_tech_window + 2
	p1._start_move(throw_move)
	await _step(10)
	_check("tech after the window is a normal throw",
		p2.state == FighterBase.State.KNOCKDOWN
			and is_equal_approx(p2.health, 1000.0 - throw_move.damage),
		"state=%d hp=%.1f" % [p2.state, p2.health])
	p2.input_enabled = true

	# --- 33. SF6-style lockout: mashing another button kills the tech ---
	scene._begin_round()
	scene._start_fight()
	_reset_fighters(100, 120)
	p1._start_move(throw_move)
	await _step(2)
	Input.action_press("p2_grab")
	await _step(1)
	Input.action_release("p2_grab")
	Input.action_press("p2_light")
	await _step(1)
	Input.action_release("p2_light")
	await _step(3)
	_check("lockout prevents option-select mashing",
		p2.state != FighterBase.State.TECH and p2.state == FighterBase.State.KNOCKDOWN
			and is_equal_approx(p2.health, 1000.0 - throw_move.damage),
		"state=%d hp=%.1f" % [p2.state, p2.health])

	# --- 34. a whiffed throw recovers in throw_whiff_recovery frames ---
	scene._begin_round()
	scene._start_fight()
	_reset_fighters(100, 260)
	p1.input_enabled = false
	p2.input_enabled = false
	p1._start_move(throw_move)
	var whiff_frames := 0
	while p1.state == FighterBase.State.ATTACK and whiff_frames < 120:
		await _step(1)
		whiff_frames += 1
	var expected_whiff := throw_move.startup + throw_move.active + p1.data.throw_whiff_recovery
	_check("throw whiff recovery is authored at 22 frames",
		p1.data.throw_whiff_recovery == 22 and throw_move.recovery == 16,
		"field=%d authored=%d" % [p1.data.throw_whiff_recovery, throw_move.recovery])
	_check("whiffed throw measures the extended recovery",
		whiff_frames == expected_whiff and p2.health >= 1000.0,
		"frames=%d expected=%d hp=%.1f" % [whiff_frames, expected_whiff, p2.health])
	p1.input_enabled = true
	p2.input_enabled = true

	# --- 35. the airborne-throw guard composes with tech ---
	# Same descent as test 20: frame 5 brushes an airborne defender, frame 6 lands.
	scene._begin_round()
	scene._start_fight()
	_reset_fighters(100, 120)
	p2.input_enabled = false
	p2.input_buffer["grab"] = 1
	p2.position = Vector2(120, 150.0 - 11.25)
	p2.velocity = Vector2(0, 60.0)
	p2.grounded = false
	p2._force_state(FighterBase.State.JUMP_FALL)
	p1._start_move(throw_move)
	await _step(5)
	_check("no tech while the defender is airborne",
		p2.state != FighterBase.State.TECH and is_equal_approx(p2.health, 1000.0),
		"state=%d hp=%.1f" % [p2.state, p2.health])
	await _step(2)
	_check("the live tech buffer breaks the throw on landing",
		p2.state == FighterBase.State.TECH and p1.state == FighterBase.State.TECH
			and is_equal_approx(p2.health, 1000.0),
		"p1=%d p2=%d hp=%.1f" % [p1.state, p2.state, p2.health])
	p2.input_enabled = true

	# --- 36. wake-up throw invuln composes with tech ---
	# The throw's whole active window sits inside the 8f throw-invuln tail, so
	# it is rejected outright; once the tail ends a fresh tech buffer works.
	scene._begin_round()
	scene._start_fight()
	_reset_fighters(100, 120)
	_force_wakeup(p2)
	p1._start_move(throw_move)
	Input.action_press("p2_grab")
	await _step(1)
	Input.action_release("p2_grab")
	await _step(6)
	_check("wake-up throw invuln rejects a teched throw",
		p2.state != FighterBase.State.TECH and is_equal_approx(p2.health, 1000.0)
			and not p1.move_already_hit,
		"state=%d hp=%.1f already_hit=%s" % [p2.state, p2.health, str(p1.move_already_hit)])

	scene._begin_round()
	scene._start_fight()
	_reset_fighters(100, 120)
	_force_wakeup(p2)
	await _step(4)
	Input.action_press("p2_grab")
	await _step(1)
	Input.action_release("p2_grab")
	p1._start_move(throw_move)
	await _step(5)
	_check("tech works once the throw-invuln tail ends",
		p1.state == FighterBase.State.TECH and p2.state == FighterBase.State.TECH
			and is_equal_approx(p2.health, 1000.0),
		"p1=%d p2=%d hp=%.1f" % [p1.state, p2.state, p2.health])

	# --- 37. EX specials: meter spend, fallback, data, floor ---
	scene._begin_round()
	scene._start_fight()
	_reset_fighters(100, 200)
	p1.meter = 100.0
	Input.action_press("p1_heavy")
	Input.action_press("p1_special")
	await _step(2)
	Input.action_release("p1_heavy")
	Input.action_release("p1_special")
	_check("EX special starts from special+heavy",
		p1.state == FighterBase.State.ATTACK and p1.current_move != null
			and p1.current_move.ex,
		"state=%d move=%s" % [p1.state,
			p1.current_move.id if p1.current_move else "null"])
	_check("EX spends its meter cost", is_equal_approx(p1.meter, 50.0),
		"meter=%.1f" % p1.meter)

	scene._begin_round()
	scene._start_fight()
	_reset_fighters(100, 200)
	p1.meter = 20.0
	Input.action_press("p1_heavy")
	Input.action_press("p1_special")
	await _step(2)
	Input.action_release("p1_heavy")
	Input.action_release("p1_special")
	_check("insufficient meter falls back to the base special",
		p1.state == FighterBase.State.ATTACK and p1.current_move != null
			and not p1.current_move.ex and p1.current_move.id == "peggy_neutral"
			and is_equal_approx(p1.meter, 20.0),
		"move=%s meter=%.1f" % [p1.current_move.id if p1.current_move else "null", p1.meter])

	var base_neutral := p1.data.find_move(MoveData.InputType.SPECIAL_NEUTRAL, MoveData.Stance.STAND)
	var ex_neutral := p1.data.find_ex_move(MoveData.InputType.SPECIAL_NEUTRAL, MoveData.Stance.STAND)
	var ex_forward := p1.data.find_ex_move(MoveData.InputType.SPECIAL_FWD, MoveData.Stance.STAND)
	_check("EX variants differ from base in damage and startup",
		ex_neutral.damage > base_neutral.damage
			and ex_neutral.startup < base_neutral.startup
			and ex_forward != null and ex_forward.meter_cost == 50.0,
		"base=%.0f/%d ex=%.0f/%d" % [base_neutral.damage, base_neutral.startup,
			ex_neutral.damage, ex_neutral.startup])
	_check("find_move never returns an EX row",
		not base_neutral.ex and ex_neutral.ex)
	_check("both fighters have neutral and forward EX rows",
		p2.data.find_ex_move(MoveData.InputType.SPECIAL_NEUTRAL, MoveData.Stance.STAND) != null
			and p2.data.find_ex_move(MoveData.InputType.SPECIAL_FWD, MoveData.Stance.STAND) != null)

	p1.meter = 50.0
	var paid := p1.spend_meter(50.0)
	_check("meter floors at 0 when the exact cost is paid", paid and p1.meter == 0.0,
		"meter=%.1f" % p1.meter)
	_check("an empty bar rejects spending", not p1.spend_meter(1.0) and p1.meter == 0.0,
		"meter=%.1f" % p1.meter)

	# --- 38. METHtality: gate, spend, banner, KO win ---
	scene._begin_round()
	scene._start_fight()
	_reset_fighters(100, 130)
	p1.meter = 100.0
	p2.health = 800.0
	p2.hitstun_frames = 60
	p2._force_state(FighterBase.State.HITSTUN)
	Input.action_press("p1_meth")
	await _step(2)
	Input.action_release("p1_meth")
	_check("METHtality is blocked above the health threshold",
		not (p1.current_move != null and p1.current_move.meth)
			and is_equal_approx(p1.meter, 100.0),
		"move=%s meter=%.1f" % [p1.current_move.id if p1.current_move else "null", p1.meter])

	scene._begin_round()
	scene._start_fight()
	_reset_fighters(100, 130)
	p1.meter = 100.0
	p2.health = 100.0
	p2.reset_state()
	Input.action_press("p1_meth")
	await _step(2)
	Input.action_release("p1_meth")
	_check("METHtality needs a stunned or knocked-down opponent",
		not (p1.current_move != null and p1.current_move.meth)
			and is_equal_approx(p1.meter, 100.0),
		"state=%d meter=%.1f" % [p2.state, p1.meter])

	scene._begin_round()
	scene._start_fight()
	_reset_fighters(100, 130)
	p1.meter = 90.0
	p2.health = 100.0
	p2.hitstun_frames = 60
	p2._force_state(FighterBase.State.HITSTUN)
	Input.action_press("p1_meth")
	await _step(2)
	Input.action_release("p1_meth")
	_check("METHtality needs a full hype bar",
		not (p1.current_move != null and p1.current_move.meth)
			and is_equal_approx(p1.meter, 90.0),
		"meter=%.1f" % p1.meter)

	scene._begin_round()
	scene._start_fight()
	_reset_fighters(100, 130)
	p1.meter = 100.0
	p2.health = 200.0
	p2.hitstun_frames = 60
	p2._force_state(FighterBase.State.HITSTUN)
	var wins_before_meth: int = scene.wins[0]
	Input.action_press("p1_meth")
	await _step(2)
	Input.action_release("p1_meth")
	_check("METHtality triggers in a kill-confirm window",
		p1.state == FighterBase.State.ATTACK and p1.current_move != null
			and p1.current_move.meth,
		"state=%d move=%s" % [p1.state, p1.current_move.id if p1.current_move else "null"])
	_check("METHtality drains the meter fully", is_equal_approx(p1.meter, 0.0),
		"meter=%.1f" % p1.meter)
	_check("HUD announces the METHtality",
		scene.hud.meth_banner.visible and scene.hud.meth_banner.text.contains("WALK THE PLANK"),
		"banner='%s'" % scene.hud.meth_banner.text)
	await _step(10)
	_check("METHtality ends the opponent",
		p2.health <= 0.0 and p2.state == FighterBase.State.KO,
		"hp=%.1f state=%d" % [p2.health, p2.state])
	await _step(110)
	_check("METHtality round ends as a KO win",
		scene.wins[0] == wins_before_meth + 1,
		"wins=%s before=%d" % [str(scene.wins), wins_before_meth])

	scene._begin_round()
	scene._start_fight()
	_reset_fighters(100, 130)
	p1.meter = 100.0
	p2.health = 200.0
	_force_wakeup(p2)
	Input.action_press("p1_meth")
	await _step(2)
	Input.action_release("p1_meth")
	_check("wake-up invulnerability blocks the finisher",
		not (p1.current_move != null and p1.current_move.meth)
			and is_equal_approx(p1.meter, 100.0),
		"state=%d meter=%.1f" % [p2.state, p1.meter])

	_check("vertical-slice fighters have distinct METHtalities",
		p1.data.meth_move != null and p2.data.meth_move != null
			and p1.data.meth_move.id != p2.data.meth_move.id
			and p1.data.meth_name != p2.data.meth_name
			and p1.data.meth_move.meth and p2.data.meth_move.meth)

	# --- 39. whiffed air moves use authored landing recovery ---
	var air_light: MoveData = p1.data.find_move(MoveData.InputType.LIGHT, MoveData.Stance.AIR)
	var air_heavy: MoveData = p1.data.find_move(MoveData.InputType.HEAVY, MoveData.Stance.AIR)
	var air_special: MoveData = p1.data.find_move(MoveData.InputType.SPECIAL_AIR, MoveData.Stance.AIR)
	var ground_light: MoveData = p1.data.find_move(MoveData.InputType.LIGHT, MoveData.Stance.STAND)
	var peggy_throw: MoveData = p1.data.find_move(MoveData.InputType.GRAB, MoveData.Stance.STAND)
	var richard_throw: MoveData = p2.data.find_move(MoveData.InputType.GRAB, MoveData.Stance.STAND)
	_check("air-balance data regeneration preserves throw damage",
		peggy_throw.damage == 95.0 and richard_throw.damage == 105.0,
		"throw damage=%.1f/%.1f" % [peggy_throw.damage, richard_throw.damage])
	_check("landing recovery is authored on aerial rows, not grounded attacks",
		air_light.landing_recovery > 0 and air_heavy.landing_recovery > 0
			and air_special.landing_recovery >= air_heavy.landing_recovery
			and ground_light.landing_recovery == 0,
		"jump=%d/%d air-special=%d ground=%d" % [air_light.landing_recovery,
			air_heavy.landing_recovery, air_special.landing_recovery, ground_light.landing_recovery])

	# Startup touchdown cancels the move before its first active frame.
	_force_air_landing(air_special, maxi(1, air_special.startup / 2))
	_check("startup landing begins before any active hitbox",
		p1.get_hitbox_rect().size == Vector2.ZERO)
	await _step(1)
	_check("startup whiff lands into authored recovery with no stale move/hitbox",
		p1.state == FighterBase.State.LAND
			and p1.landing_recovery_frames == air_special.landing_recovery
			and p1.current_move == null and p1.get_hitbox_rect().size == Vector2.ZERO,
		"state=%d recovery=%d move=%s" % [p1.state, p1.landing_recovery_frames,
			str(p1.current_move)])

	# Active-frame touchdown removes the active hitbox immediately. LAND consumes
	# exactly the authored simulation frames, excluding shared hitstop.
	_force_air_landing(air_special, air_special.startup)
	_check("active-frame landing fixture starts with a live hitbox",
		p1.get_hitbox_rect().size != Vector2.ZERO)
	await _step(1)
	_check("active landing clears hitbox and move without replaying startup",
		p1.state == FighterBase.State.LAND and p1.current_move == null
			and p1.get_hitbox_rect().size == Vector2.ZERO and p1.state_frame == 0,
		"state=%d frame=%d move=%s" % [p1.state, p1.state_frame, str(p1.current_move)])
	var landing_frame_before_stop: int = p1.state_frame
	paused = true
	await _step(2)
	paused = false
	_check("pause freezes landing recovery", p1.state == FighterBase.State.LAND
		and p1.state_frame == landing_frame_before_stop,
		"state=%d frame=%d" % [p1.state, p1.state_frame])
	p1.hitstop_frames = 2
	await _step(2)
	_check("hitstop freezes the landing-recovery countdown",
		p1.state == FighterBase.State.LAND and p1.state_frame == landing_frame_before_stop,
		"state=%d frame=%d" % [p1.state, p1.state_frame])
	await _step(air_special.landing_recovery - 1)
	_check("landing remains locked for all but its final authored frame",
		p1.state == FighterBase.State.LAND,
		"state=%d frame=%d recovery=%d" % [p1.state, p1.state_frame, air_special.landing_recovery])
	await _step(1)
	_check("fighter becomes actionable on the authored landing-recovery frame",
		p1.state == FighterBase.State.IDLE,
		"state=%d frame=%d" % [p1.state, p1.state_frame])

	# Touchdown during authored aerial recovery has the same whiff penalty.
	_force_air_landing(air_special, air_special.startup + air_special.active + 1)
	_check("recovery-phase landing fixture has no live hitbox", p1.get_hitbox_rect().size == Vector2.ZERO)
	await _step(1)
	_check("recovery-phase whiff receives authored landing lockout",
		p1.state == FighterBase.State.LAND
			and p1.landing_recovery_frames == air_special.landing_recovery
			and p1.current_move == null,
		"state=%d recovery=%d" % [p1.state, p1.landing_recovery_frames])

	_force_air_landing(air_special, air_special.total_frames() - 1)
	p1.position.y = scene.stage.floor_y - 20.0
	p1.velocity.y = 60.0
	await _step(1)
	_check("a whiff that finishes in the air falls with its move data intact",
		p1.state == FighterBase.State.JUMP_FALL and p1.current_move == air_special
			and not p1.grounded and p1.get_hitbox_rect().size == Vector2.ZERO,
		"state=%d move=%s grounded=%s" % [p1.state, str(p1.current_move), str(p1.grounded)])
	p1.position.y = scene.stage.floor_y - 1.0
	p1.velocity.y = 60.0
	await _step(1)
	_check("falling touchdown applies the finished aerial move's recovery",
		p1.state == FighterBase.State.LAND
			and p1.landing_recovery_frames == air_special.landing_recovery
			and p1.current_move == null,
		"state=%d recovery=%d" % [p1.state, p1.landing_recovery_frames])

	# A clean hit and a block both count as contact; neither gets the whiff penalty.
	_force_air_landing(air_special, air_special.startup, 120.0)
	var hit_hp_before: float = p2.health
	scene._resolve_hits()
	var hit_stop: int = p1.hitstop_frames
	var hit_frame_before_stop: int = p1.state_frame
	_check("airborne special connects through the real resolver before landing",
		p1.move_already_hit and p2.health < hit_hp_before and hit_stop > 0,
		"connected=%s hp=%.1f stop=%d" % [str(p1.move_already_hit), p2.health, hit_stop])
	await _step(hit_stop)
	_check("hitstop holds the airborne attacker above the landing transition",
		p1.state == FighterBase.State.ATTACK and not p1.grounded
			and p1.state_frame == hit_frame_before_stop,
		"state=%d grounded=%s frame=%d" % [p1.state, str(p1.grounded), p1.state_frame])
	await _step(1)
	_check("a resolved hit lands with legacy recovery, not whiff recovery",
		p1.state == FighterBase.State.LAND and p1.landing_recovery_frames == 2
			and p1.current_move == null and p1.get_hitbox_rect().size == Vector2.ZERO,
		"state=%d recovery=%d" % [p1.state, p1.landing_recovery_frames])

	_force_air_landing(air_special, air_special.startup, 120.0)
	p2.input_enabled = true
	Input.action_press("p2_right") # facing left: hold away to block
	scene._resolve_hits()
	_check("air-special block resolves and counts as contact",
		p1.move_already_hit and p2.state == FighterBase.State.BLOCKSTUN,
		"connected=%s defender=%d" % [str(p1.move_already_hit), p2.state])
	var block_stop: int = p1.hitstop_frames
	await _step(block_stop + 1)
	Input.action_release("p2_right")
	_check("a blocked aerial move also uses legacy 2-frame landing recovery",
		p1.state == FighterBase.State.LAND and p1.landing_recovery_frames == 2
			and p1.current_move == null and p1.get_hitbox_rect().size == Vector2.ZERO,
		"state=%d recovery=%d" % [p1.state, p1.landing_recovery_frames])
	p1.input_enabled = true
	Input.action_press("p1_left") # P1 faces right; left is away
	_check("legacy 2-frame LAND keeps its existing block behavior", p1.is_blocking())
	Input.action_release("p1_left")
	p1.input_enabled = false

	# An opponent hit interrupts an aerial move and its landing preserves the
	# existing knockdown state instead of layering landing recovery over it.
	_force_air_landing(air_special, 2, 120.0)
	var anti_air: MoveData = p2.data.find_move(MoveData.InputType.HEAVY, MoveData.Stance.CROUCH)
	p2._start_move(anti_air)
	p2.state_frame = anti_air.startup
	scene._resolve_hits()
	p1.velocity.y = 60.0 # keep the interrupted fighter descending into the floor
	var interrupt_stop: int = p1.hitstop_frames
	_check("an anti-air hit interrupts aerial startup", p1.state == FighterBase.State.KNOCKDOWN,
		"state=%d stop=%d" % [p1.state, interrupt_stop])
	await _step(interrupt_stop + 1)
	_check("landing during knockdown does not add aerial recovery",
		p1.grounded and p1.state == FighterBase.State.KNOCKDOWN
			and p1.landing_recovery_frames == 2 and p1.current_move == null,
		"grounded=%s state=%d recovery=%d" % [str(p1.grounded), p1.state, p1.landing_recovery_frames])

	# A hit during LAND recovery replaces the landing state with ordinary hitstun.
	_force_air_landing(air_special, air_special.startup + air_special.active + 1, 120.0)
	await _step(1)
	var ground_poke: MoveData = p2.data.find_move(MoveData.InputType.LIGHT, MoveData.Stance.STAND)
	p2._start_move(ground_poke)
	p2.state_frame = ground_poke.startup
	p1.input_enabled = true
	Input.action_press("p1_left") # holding back cannot block extended whiff recovery
	var land_hp_before_punish: float = p1.health
	scene._resolve_hits()
	Input.action_release("p1_left")
	_check("whiff landing recovery cannot block and is interrupted by a hit",
		p1.state == FighterBase.State.HITSTUN and p1.health < land_hp_before_punish,
		"state=%d hp=%.1f/%.1f" % [p1.state, p1.health, land_hp_before_punish])
	p1.input_enabled = false

	# Match restart clears any landing-recovery data and returns both fighters to
	# the normal intro state; grounded attacks still use their ordinary frames.
	p1.move_hit_confirmed = true
	p1.move_already_hit = true
	scene._reset_match()
	_check("restart clears landing recovery and the aerial move",
		scene.phase == 0 and p1.state == FighterBase.State.IDLE
			and p1.current_move == null and p1.landing_recovery_frames == 2
			and not p1.move_hit_confirmed and not p1.move_already_hit,
		"phase=%d state=%d recovery=%d" % [scene.phase, p1.state, p1.landing_recovery_frames])
	await _step(65)
	scene.set("phase", 4)
	_reset_fighters(100.0, 200.0)
	p1.input_enabled = false
	var grounded_total := ground_light.total_frames()
	p1._start_move(ground_light)
	await _step(2)
	_check("grounded attacks remain in their authored attack state and total",
		p1.state == FighterBase.State.ATTACK and p1.current_move == ground_light
			and ground_light.total_frames() == grounded_total
			and ground_light.landing_recovery == 0,
		"state=%d total=%d authored=%d" % [p1.state, ground_light.total_frames(), grounded_total])

	var richard_air_special: MoveData = p2.data.find_move(MoveData.InputType.SPECIAL_AIR, MoveData.Stance.AIR)
	scene._begin_round()
	scene._start_fight()
	scene.set("phase", 4)
	_reset_fighters(100.0, 200.0)
	p1.input_enabled = false
	p2.input_enabled = false
	p2.position = Vector2(200.0, scene.stage.floor_y - 1.0)
	p2.velocity = Vector2(0.0, 60.0)
	p2.grounded = false
	p2._start_move(richard_air_special)
	p2.state_frame = richard_air_special.startup
	await _step(1)
	_check("Whiskey Richard uses his authored aerial landing recovery",
		p2.state == FighterBase.State.LAND
			and p2.landing_recovery_frames == richard_air_special.landing_recovery
			and p2.current_move == null and p2.get_hitbox_rect().size == Vector2.ZERO,
		"state=%d recovery=%d data=%d" % [p2.state, p2.landing_recovery_frames,
			richard_air_special.landing_recovery])

	print("\n%d failure(s)" % failures)
	quit(1 if failures > 0 else 0)
