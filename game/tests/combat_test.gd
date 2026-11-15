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


func _check_corner_separation_case(label: String, p1_x: float, p2_x: float,
		pinned_player: int, pinned_x: float, expected_unpinned_shift: float) -> void:
	_reset_fighters(p1_x, p2_x)
	var p1_input_enabled := p1.input_enabled
	var p2_input_enabled := p2.input_enabled
	p1.input_enabled = false
	p2.input_enabled = false
	var pinned: FighterBase = p1 if pinned_player == 1 else p2
	var unpinned: FighterBase = p2 if pinned_player == 1 else p1
	var unpinned_x_before := unpinned.position.x
	scene._separate_pushboxes()
	var r1 := p1.pushbox_rect()
	var r2 := p2.pushbox_rect()
	var overlap := minf(r1.end.x, r2.end.x) - maxf(r1.position.x, r2.position.x)
	var in_bounds: bool = p1.position.x >= scene.stage.left_bound \
		and p1.position.x <= scene.stage.right_bound \
		and p2.position.x >= scene.stage.left_bound \
		and p2.position.x <= scene.stage.right_bound
	_check(label, is_equal_approx(pinned.position.x, pinned_x)
		and is_equal_approx(unpinned.position.x - unpinned_x_before, expected_unpinned_shift)
		and overlap <= 0.001 and in_bounds,
		"p1=%.2f p2=%.2f overlap=%.3f" % [p1.position.x, p2.position.x, overlap])
	p1.input_enabled = p1_input_enabled
	p2.input_enabled = p2_input_enabled


func _run_hitstop_throw_exchange(with_lockout: bool) -> void:
	scene._begin_round()
	scene._start_fight()
	_reset_fighters(100, 120)
	var hitstop_throw: MoveData = p1.data.find_move(
		MoveData.InputType.GRAB, MoveData.Stance.STAND)
	p2.blockstun_frames = 100
	p2._force_state(FighterBase.State.BLOCKSTUN)
	p1._start_move(hitstop_throw)
	p1.state_frame = hitstop_throw.startup - 1
	p1.hitstop_frames = 10
	p2.hitstop_frames = 10
	Input.action_press("p2_grab")
	if with_lockout:
		Input.action_press("p2_light")
	await _step(1)
	Input.action_release("p2_grab")
	if with_lockout:
		Input.action_release("p2_light")
	await _step(9)
	var grab_age_before_resume: int = p2.input_buffer.get("grab", -1)
	var light_age_before_resume: int = p2.input_buffer.get("light", -1)
	_check("hitstop freezes grab and lockout buffers together for the capped window",
		p1.hitstop_frames == 0 and p2.hitstop_frames == 0
			and grab_age_before_resume == FighterBase.BUFFER_NORMAL
			and (light_age_before_resume == FighterBase.BUFFER_NORMAL if with_lockout
				else light_age_before_resume == -1),
		"grab_age=%d light_age=%d lockout=%s" % [grab_age_before_resume,
			light_age_before_resume, str(with_lockout)])
	await _step(1)
	if with_lockout:
		_check("hitstop-frozen light lockout still prevents the throw tech",
			p1.state != FighterBase.State.TECH and p2.state == FighterBase.State.KNOCKDOWN
				and is_equal_approx(p2.health, 1000.0 - hitstop_throw.damage),
			"p1=%d p2=%d hp=%.1f" % [p1.state, p2.state, p2.health])
	else:
		_check("grab pressed during hitstop still techs the incoming throw",
			p1.state == FighterBase.State.TECH and p2.state == FighterBase.State.TECH
				and is_equal_approx(p1.health, 1000.0) and is_equal_approx(p2.health, 1000.0),
			"p1=%d p2=%d hp=%.1f/%.1f" % [p1.state, p2.state, p1.health, p2.health])


# Put a fighter mid-move with the cancel question posed directly: the move, the
# frame, and whether the strike hit (and whether it was a counter hit).
func _prime_cancel(f: FighterBase, move: MoveData, frame: int, hit: bool, counter := false) -> void:
	f.input_enabled = false
	f.reset_state()
	f._start_move(move)
	f.state_frame = frame
	f.move_hit_confirmed = hit
	f.move_counter_hit = counter


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
	_reset_fighters(100, 200)
	p1.input_enabled = false
	p2.input_enabled = false
	p1._force_state(FighterBase.State.WALK_F)
	p2._force_state(FighterBase.State.WALK_F)
	p1.state_frame = 4
	p2.state_frame = 4
	var p1_box_before := p1.pushbox_rect()
	var p2_box_before := p2.pushbox_rect()
	p1._sync_visuals()
	p2._sync_visuals()
	var richard_walk_tex := p2._clip_texture(RichardClipLibrary.state_clip("walk_f"))
	_check("Richard's authored walk plays while Peggy's gated walk keeps the idle fallback",
		p1.idle_sprite.visible and p2.idle_sprite.visible
			and not p1.character_sprite.visible and not p2.character_sprite.visible
			and p1.idle_sprite.texture == p1._idle_sheet_tex and p1.idle_sprite.frame == 0
			and p2.idle_sprite.texture == richard_walk_tex and p2.idle_sprite.frame == 0
			and p1.visual_root.position != Vector2.ZERO
			and p2.visual_root.position == Vector2.ZERO
			and p1.position == Vector2(100, 150) and p2.position == Vector2(200, 150)
			and p1.pushbox_rect().position == p1_box_before.position
			and p1.pushbox_rect().size == p1_box_before.size
			and p2.pushbox_rect().position == p2_box_before.position
			and p2.pushbox_rect().size == p2_box_before.size,
		"animation profiles overlap or changed fighter collision positions")
	p1._force_state(FighterBase.State.IDLE)
	p1.state_frame = 1
	p1._sync_visuals()
	var peggy_idle_pose := p1.visual_root.position
	p1.state_frame = 8
	p1._sync_visuals()
	_check("authored idle replaces the idle breathing bob",
		p1.idle_sprite.texture != null and p1.idle_sprite.hframes == 4
			and p1._idle_art_valid and p1._idle_ticks_per_cel == 9
			and p1.visual_root.position == Vector2.ZERO
			and p1.visual_root.scale == Vector2.ONE
			and p1.visual_root.position.distance_to(peggy_idle_pose) == 0.0,
		"idle sheet missing or visual_root still animating")
	p1.input_enabled = true
	p2.input_enabled = true

	# --- 1b. authored idle loop behavior (IDLE only, sim-timed) ---
	_reset_fighters(100, 200)
	p1.input_enabled = false
	p2.input_enabled = false
	p1._force_state(FighterBase.State.IDLE)
	p1.state_frame = 0
	p1._sync_visuals()
	_check("idle shows the sheet and hides the cutout",
		p1.idle_sprite.visible and not p1.character_sprite.visible
			and p1.character_sprite.texture != null,
		"idle=%s cutout=%s" % [str(p1.idle_sprite.visible), str(p1.character_sprite.visible)])
	var idle_box := p1.pushbox_rect()
	_check("idle does not move combat boxes",
		idle_box.position == Vector2(100 - p1.body_width * 0.5, 150 - p1.body_height)
			and idle_box.size == Vector2(p1.body_width, p1.body_height),
		str(idle_box))
	var sync_frame := p1.idle_sprite.frame
	for i in 5:
		p1._sync_visuals()
	_check("repeated visual syncs do not restart the idle", p1.idle_sprite.frame == sync_frame,
		"frame %d -> %d" % [sync_frame, p1.idle_sprite.frame])
	var cel_samples := {0: 0, 8: 0, 9: 1, 17: 1, 18: 2, 35: 3, 36: 0}
	var cel_ok := true
	for tick: int in cel_samples:
		p1.state_frame = tick
		p1._sync_visuals()
		if p1.idle_sprite.frame != cel_samples[tick]:
			cel_ok = false
	_check("idle cels advance every 9 simulation ticks and wrap",
		cel_ok and p1._idle_ticks_per_cel == 9,
		"ticks_per_cel=%d" % p1._idle_ticks_per_cel)
	p1.state_frame = 4
	p1.facing = -1
	p1._sync_visuals()
	_check("facing flip pivots the idle around the feet anchor",
		p1.idle_sprite.flip_h and p1.idle_sprite.position == Vector2.ZERO
			and p1.idle_sprite.offset == Vector2(-48, -78),
		"flip=%s pos=%s" % [str(p1.idle_sprite.flip_h), str(p1.idle_sprite.position)])
	p1.facing = 1
	p1._force_state(FighterBase.State.WALK_F)
	p1.state_frame = 30
	p1._sync_visuals()
	var walk_scale := p1.idle_sprite.scale
	var walk_pos := p1.idle_sprite.position
	_check("non-idle states keep the same sheet artwork, scale, and anchor",
		p1.idle_sprite.visible and not p1.character_sprite.visible
			and p1.idle_sprite.frame == 0 and walk_pos == Vector2.ZERO
			and is_equal_approx(walk_scale.x, p1._idle_art_scale),
		"frame=%d pos=%s scale=%s" % [p1.idle_sprite.frame, str(walk_pos), str(walk_scale)])
	p1._force_state(FighterBase.State.CROUCH)
	p1._sync_visuals()
	var crouch_clip: Dictionary = p1._active_clip
	_check("crouch shows the authored crouch_hold clip at the shared height",
		not crouch_clip.is_empty() and p1.idle_sprite.texture != null
			and p1.idle_sprite.texture != p1._idle_sheet_tex
			and is_equal_approx(p1.idle_sprite.scale.x,
				p1._idle_art_scale * PeggyClipLibrary.STANDING_REFERENCE_H_REF
					/ float(crouch_clip.h_ref))
			and p1.idle_sprite.frame == 0,
		"scale=%.3f frame=%d" % [p1.idle_sprite.scale.x, p1.idle_sprite.frame])
	# The hurtbox squash is gameplay and stays procedural: the pushbox still
	# collapses to 0.65 height while the authored art carries the crouch pose.
	_check("crouch keeps the authored pushbox squash",
		is_equal_approx(p1._pushbox_height(), p1.body_height * 0.65),
		"pushbox_h=%.1f" % p1._pushbox_height())
	# Crouch sets crouching=true via state change; clear it through IDLE.
	p1._force_state(FighterBase.State.IDLE)
	p1.crouching = false
	p1._sync_visuals()
	_check("idle re-entry restarts deterministically at cel zero",
		p1.state_frame == 0 and p1.idle_sprite.frame == 0,
		"state_frame=%d cel=%d" % [p1.state_frame, p1.idle_sprite.frame])
	_check("idle loop resumes with the shared artwork and no size jump",
		p1.idle_sprite.visible and not p1.character_sprite.visible
			and is_equal_approx(p1.idle_sprite.scale.x, walk_scale.x),
		"scale %.3f vs %.3f state=%s transient=%s active=%s tex=%s" % [p1.idle_sprite.scale.x, walk_scale.x, str(p1.state), p1._transient_clip_key, str(p1._active_clip), str(p1.idle_sprite.texture.resource_path if p1.idle_sprite.texture else "")])
	# Hitstop/pause freeze: the frame index derives from state_frame, which the
	# hitstop early-return never advances and a paused tree never ticks.
	var frozen_cel := p1.idle_sprite.frame
	p1.hitstop_frames = 5
	await _step(3)
	_check("hitstop freezes idle cels",
		p1.hitstop_frames == 2 and p1.state_frame == 0 and p1.idle_sprite.frame == frozen_cel,
		"hitstop=%d state_frame=%d cel=%d" % [p1.hitstop_frames, p1.state_frame, p1.idle_sprite.frame])
	await _step(5)
	p1._idle_art_valid = false
	p1._sync_visuals()
	_check("invalid idle art falls back to the cutout",
		not p1.idle_sprite.visible and p1.character_sprite.visible,
		"idle=%s cutout=%s" % [str(p1.idle_sprite.visible), str(p1.character_sprite.visible)])
	p1._configure_idle_sprite()
	p2._force_state(FighterBase.State.IDLE)
	p2.state_frame = 0
	p2._sync_visuals()
	_check("Richard's idle sheet loads with his own silhouette",
		p2.idle_sprite.texture != null and p2.idle_sprite.hframes == 4
			and p2.idle_sprite.visible and not p2.character_sprite.visible
			and p2.idle_sprite.texture != p1.idle_sprite.texture,
		"richard idle=%s" % str(p2.idle_sprite.texture != null))
	p1.input_enabled = true
	p2.input_enabled = true

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
	p1._sync_visuals()
	_check("pause freezes idle cels",
		p1.state == FighterBase.State.IDLE and p1.idle_sprite.frame == 0
			and p1.idle_sprite.visible,
		"state=%d cel=%d visible=%s" % [p1.state, p1.idle_sprite.frame,
			str(p1.idle_sprite.visible)])
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

	# --- K1. knockdown rejects strikes, while the existing METH gate remains open ---
	scene._begin_round()
	scene._start_fight()
	_reset_fighters(100, 120)
	p2.knockdown_frames = 300
	p2._force_state(FighterBase.State.KNOCKDOWN)
	p1.input_enabled = false
	var knockdown_crouch_heavy: MoveData = p1.data.find_move(
		MoveData.InputType.HEAVY, MoveData.Stance.CROUCH)
	for attempt in range(3):
		p1._start_move(knockdown_crouch_heavy)
		await _step(knockdown_crouch_heavy.startup + 1)
		_check("K1 crouch-heavy does not connect during knockdown (attempt %d)" % (attempt + 1),
			p2.state == FighterBase.State.KNOCKDOWN and p2.health == 1000.0
				and not p1.move_already_hit,
			"state=%d hp=%.1f consumed=%s" % [p2.state, p2.health, str(p1.move_already_hit)])
		await _step(knockdown_crouch_heavy.active + knockdown_crouch_heavy.recovery + 1)
	_check("repeated crouch-heavy cannot loop on a knocked-down defender",
		p2.state == FighterBase.State.KNOCKDOWN and p2.health == 1000.0,
		"state=%d hp=%.1f" % [p2.state, p2.health])
	_check("K1 also rejects direct non-METH strike resolution",
		not p2.receive_hit(p1, knockdown_crouch_heavy) and p2.health == 1000.0,
		"hp=%.1f" % p2.health)
	p1.input_enabled = true

	scene._begin_round()
	scene._start_fight()
	_reset_fighters(100, 130)
	p1.meter = 100.0
	p2.health = 200.0
	p2.knockdown_frames = 300
	p2._force_state(FighterBase.State.KNOCKDOWN)
	var meth_on_knockdown: MoveData = p1.data.meth_move
	p1.input_buffer["meth"] = 0
	var meth_gate_accepts_knockdown := p1.can_meth()
	var meth_started_on_knockdown := p1._try_start_meth()
	_check("K1 preserves can_meth knockdown eligibility and activation",
		meth_gate_accepts_knockdown and meth_started_on_knockdown
			and p1.current_move == meth_on_knockdown,
		"can_meth=%s started=%s move=%s" % [str(meth_gate_accepts_knockdown),
			str(meth_started_on_knockdown), p1.current_move.id if p1.current_move else "null"])
	_check("METH activation on knockdown spends the full meter bar",
		is_equal_approx(p1.meter, 0.0), "meter=%.1f" % p1.meter)
	await _step(meth_on_knockdown.startup + 1)
	_check("K1 permits the METH row to hit a knocked-down target",
		p2.health <= 0.0 and p2.state == FighterBase.State.KO,
		"hp=%.1f state=%d" % [p2.health, p2.state])

	# --- R1. no throw connects during knockdown ---
	scene._begin_round()
	scene._start_fight()
	_reset_fighters(100, 120)
	var richard_knockdown_throw: MoveData = p2.data.find_move(
		MoveData.InputType.GRAB, MoveData.Stance.STAND)
	p2.knockdown_frames = 300
	p2._force_state(FighterBase.State.KNOCKDOWN)
	p1._start_move(throw_move)
	await _step(throw_move.startup + 1)
	_check("R1 rejects Peggy's throw on a knocked-down Richard without consuming its active window",
		p2.state == FighterBase.State.KNOCKDOWN and p2.health == 1000.0
			and not p1.move_already_hit and p2.is_invulnerable_to(throw_move),
		"state=%d hp=%.1f consumed=%s" % [p2.state, p2.health, str(p1.move_already_hit)])
	_check("R1 is enforced for direct throw resolution too",
		not p2.receive_hit(p1, throw_move) and p2.health == 1000.0,
		"hp=%.1f" % p2.health)

	scene._begin_round()
	scene._start_fight()
	_reset_fighters(100, 120)
	p1.knockdown_frames = 300
	p1._force_state(FighterBase.State.KNOCKDOWN)
	p2._start_move(richard_knockdown_throw)
	await _step(richard_knockdown_throw.startup + 1)
	_check("R1 rejects Richard's throw on a knocked-down Peggy",
		p1.state == FighterBase.State.KNOCKDOWN and p1.health == 1000.0
			and not p2.move_already_hit,
		"state=%d hp=%.1f consumed=%s" % [p1.state, p1.health, str(p2.move_already_hit)])
	_check("R1 does not change normal throw damage",
		throw_move.damage == 95.0 and richard_knockdown_throw.damage == 105.0,
		"damage=%.1f/%.1f" % [throw_move.damage, richard_knockdown_throw.damage])

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

	# --- D3/PR 4a. bounded hitstop-only input-buffer age freeze ---
	scene._begin_round()
	scene._start_fight()
	_reset_fighters(100, 120)
	p2.input_buffer["light"] = 0
	p2.input_buffer["grab"] = 0
	p2.input_buffer["meth"] = 0
	p2.hitstop_frames = 3
	await _step(3)
	_check("all buffered actions stay the same age during short hitstop",
		p2.input_buffer["light"] == 0 and p2.input_buffer["grab"] == 0
			and p2.input_buffer["meth"] == 0,
		"buffer=%s" % str(p2.input_buffer))

	scene._begin_round()
	scene._start_fight()
	_reset_fighters(100, 120)
	p2.input_buffer["light"] = 0
	p2.input_buffer["grab"] = 0
	p2.hitstop_frames = 6
	await _step(6)
	_check("hitstop buffer freeze is capped after one normal buffer window",
		p2.hitstop_buffer_freeze_frames == FighterBase.BUFFER_NORMAL
			and p2.input_buffer["light"] == 1 and p2.input_buffer["grab"] == 1,
		"freeze=%d buffers=%s" % [p2.hitstop_buffer_freeze_frames, str(p2.input_buffer)])

	scene._begin_round()
	scene._start_fight()
	_reset_fighters(100, 120)
	p2.input_buffer["heavy"] = 0
	p2.hitstop_frames = 8
	await _step(8)
	_check("longer hitstop ages inputs after the five-frame freeze cap",
		p2.hitstop_buffer_freeze_frames == FighterBase.BUFFER_NORMAL
			and p2.input_buffer["heavy"] == 3,
		"freeze=%d heavy_age=%d" % [p2.hitstop_buffer_freeze_frames,
			p2.input_buffer.get("heavy", -1)])

	scene._begin_round()
	scene._start_fight()
	_reset_fighters(100, 120)
	p2.input_buffer["meth"] = 0
	p2.hitstop_frames = 30
	await _step(30)
	_check("one capped extension does not preserve inputs through a long METH freeze",
		p2.hitstop_buffer_freeze_frames == FighterBase.BUFFER_NORMAL
			and not p2.input_buffer.has("meth"),
		"freeze=%d buffer=%s" % [p2.hitstop_buffer_freeze_frames, str(p2.input_buffer)])

	await _run_hitstop_throw_exchange(false)
	await _run_hitstop_throw_exchange(true)

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

	# --- 38. METHtality: full-meter input, spend, banner, KO win ---
	scene._begin_round()
	scene._start_fight()
	_reset_fighters(100, 130)
	p1.meter = 100.0
	p2.health = p2.max_health
	p2.reset_state()
	var wins_before_meth: int = scene.wins[0]
	Input.action_press("p1_meth")
	await _step(2)
	Input.action_release("p1_meth")
	_check("full meter plus METH input triggers against a healthy neutral opponent",
		p1.state == FighterBase.State.ATTACK and p1.current_move != null
			and p1.current_move.meth,
		"state=%d move=%s" % [p1.state, p1.current_move.id if p1.current_move else "null"])
	_check("METHtality drains the meter fully", is_equal_approx(p1.meter, 0.0),
		"meter=%.1f" % p1.meter)
	_check("HUD announces the METHtality",
		scene.hud.meth_banner.visible and scene.hud.meth_banner.text.contains("WALK THE PLANK"),
		"banner='%s'" % scene.hud.meth_banner.text)
	await _step(10)
	_check("METHtality ends the healthy opponent",
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
	p2.health = p2.max_health
	_force_wakeup(p2)
	Input.action_press("p1_meth")
	await _step(2)
	Input.action_release("p1_meth")
	_check("full meter triggers even against wake-up invulnerability",
		p1.current_move != null and p1.current_move.meth
			and is_equal_approx(p1.meter, 0.0),
		"state=%d meter=%.1f" % [p2.state, p1.meter])

	scene._begin_round()
	scene._start_fight()
	_reset_fighters(100, 130)
	p1.meter = 90.0
	p2.health = p2.max_health
	p2.reset_state()
	Input.action_press("p1_meth")
	await _step(2)
	Input.action_release("p1_meth")
	_check("METHtality still requires a full hype bar",
		not (p1.current_move != null and p1.current_move.meth)
			and is_equal_approx(p1.meter, 90.0),
		"meter=%.1f" % p1.meter)

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

	# --- B4. clamp a pinned fighter and transfer all remaining separation ---
	var left_wall: float = scene.stage.left_bound
	var right_wall: float = scene.stage.right_bound
	_check_corner_separation_case("corner separation: P1 pinned at left wall",
		left_wall, left_wall + 19.0, 1, left_wall, 10.0)
	_check_corner_separation_case("corner separation: P2 pinned at left wall",
		left_wall + 19.0, left_wall, 2, left_wall, 10.0)
	_check_corner_separation_case("corner separation: P1 pinned at right wall",
		right_wall, right_wall - 19.0, 1, right_wall, -10.0)
	_check_corner_separation_case("corner separation: P2 pinned at right wall",
		right_wall - 19.0, right_wall, 2, right_wall, -10.0)

	# --- 40. counter hit (GDD 5.6): startup interruption, +2 shared hitstop ---
	# Driven through the real resolver with explicit frames, so tick order cannot
	# blur the startup / active / recovery distinction under test.
	var counter_strike: MoveData = p1.data.find_move(MoveData.InputType.LIGHT, MoveData.Stance.STAND)
	var counter_reply: MoveData = p2.data.find_move(MoveData.InputType.LIGHT, MoveData.Stance.STAND)
	scene._begin_round()
	scene._start_fight()
	_reset_fighters(100, 120)
	p1.input_enabled = false
	p2.input_enabled = false
	p1._start_move(counter_strike)
	p1.state_frame = counter_strike.startup
	p2._start_move(counter_reply)
	p2.state_frame = 0
	scene._resolve_hits()
	_check("counter hit: a strike into the defender's startup lands",
		is_equal_approx(p2.health, 1000.0 - counter_strike.damage),
		"hp=%.1f" % p2.health)
	_check("counter hit adds +2 hitstop shared by both fighters",
		p1.hitstop_frames == counter_strike.hitstop + FighterBase.COUNTER_HIT_HITSTOP
			and p2.hitstop_frames == counter_strike.hitstop + FighterBase.COUNTER_HIT_HITSTOP,
		"p1=%d p2=%d base=%d" % [p1.hitstop_frames, p2.hitstop_frames, counter_strike.hitstop])
	_check("counter hit is recorded on the attacker and interrupts the defender",
		p1.move_counter_hit and p2.state == FighterBase.State.HITSTUN,
		"counter=%s state=%d" % [str(p1.move_counter_hit), p2.state])
	_check("counter hit shows the HUD text indicator",
		scene.hud.counter_flash.visible and scene.hud.counter_flash.text == "COUNTER HIT",
		"visible=%s" % str(scene.hud.counter_flash.visible))

	scene._begin_round()
	scene._start_fight()
	_reset_fighters(100, 120)
	p1._start_move(counter_strike)
	p1.state_frame = counter_strike.startup
	p2._start_move(counter_reply)
	p2.state_frame = counter_reply.startup + counter_reply.active
	scene._resolve_hits()
	_check("a hit during the defender's recovery is an ordinary hit",
		not p1.move_counter_hit and p2.hitstop_frames == counter_strike.hitstop,
		"counter=%s hitstop=%d" % [str(p1.move_counter_hit), p2.hitstop_frames])

	scene._begin_round()
	scene._start_fight()
	_reset_fighters(100, 120)
	p1._start_move(counter_strike)
	p1.state_frame = counter_strike.startup
	p2._start_move(counter_reply)
	p2.state_frame = counter_reply.startup
	scene._resolve_hits()
	_check("a same-frame trade is not a counter hit",
		not p1.move_counter_hit and not p2.move_counter_hit
			and p1.hitstop_frames == counter_strike.hitstop
			and p2.hitstop_frames == counter_reply.hitstop,
		"p1=%d p2=%d" % [p1.hitstop_frames, p2.hitstop_frames])
	p1.input_enabled = true
	p2.input_enabled = true

	# --- 41. authored cancel rules (PROPOSALS 6): data matrix and legacy parity ---
	var matrix_ok := true
	var matrix_detail := ""
	var rule_rows := 0
	for fighter_data in [p1.data, p2.data]:
		for m in fighter_data.moves:
			var expected: Array = []
			if m.input == MoveData.InputType.HEAVY and m.id == "jump_heavy":
				expected = [
					[CancelRule.Target.EX, CancelRule.Kind.CANCEL],
					[CancelRule.Target.SPECIAL, CancelRule.Kind.CANCEL],
					[CancelRule.Target.LIGHT, CancelRule.Kind.CHAIN]]
			elif m.input == MoveData.InputType.HEAVY:
				expected = [
					[CancelRule.Target.EX, CancelRule.Kind.CANCEL],
					[CancelRule.Target.SPECIAL, CancelRule.Kind.CANCEL]]
			elif m.input == MoveData.InputType.LIGHT:
				expected = [
					[CancelRule.Target.SPECIAL, CancelRule.Kind.CANCEL],
					[CancelRule.Target.LIGHT, CancelRule.Kind.CHAIN],
					[CancelRule.Target.HEAVY, CancelRule.Kind.CHAIN]]
			var actual: Array = []
			for r in m.cancels:
				actual.append([r.target, r.kind])
				rule_rows += 1
				if r.condition != CancelRule.Condition.HIT or r.from_frame != m.startup + 1 \
						or r.to_frame != m.total_frames() or r.validate() != "":
					matrix_ok = false
					matrix_detail = "%s rule %s" % [m.id, r.validate()]
			if str(actual) != str(expected):
				matrix_ok = false
				matrix_detail = "%s actual=%s expected=%s" % [m.id, str(actual), str(expected)]
	_check("every light/heavy row carries its legacy cancel routes, valid and hit-only",
		matrix_ok and rule_rows == 32, "rules=%d %s" % [rule_rows, matrix_detail])
	_check("specials and grabs author no cancel routes",
		p1.data.find_move(MoveData.InputType.SPECIAL_NEUTRAL, MoveData.Stance.STAND).cancels.is_empty()
			and p1.data.find_move(MoveData.InputType.GRAB, MoveData.Stance.STAND).cancels.is_empty(),
		"")

	var legacy_light: MoveData = p1.data.find_move(MoveData.InputType.LIGHT, MoveData.Stance.STAND)
	var legacy_heavy: MoveData = p1.data.find_move(MoveData.InputType.HEAVY, MoveData.Stance.STAND)
	var legacy_special: MoveData = p1.data.find_move(MoveData.InputType.SPECIAL_NEUTRAL, MoveData.Stance.STAND)
	var cancel_window := legacy_light.startup + 1
	var heavy_window := legacy_heavy.startup + 1

	_prime_cancel(p1, legacy_light, cancel_window, true)
	p1.input_buffer["heavy"] = 0
	_check("legal chain: light hit confirms into heavy",
		p1._try_cancel() and p1.current_move == legacy_heavy,
		"move=%s" % (p1.current_move.id if p1.current_move else "null"))

	_prime_cancel(p1, legacy_light, cancel_window, true)
	p1.input_buffer["special"] = 0
	_check("legal cancel: light hit confirms into special",
		p1._try_cancel() and p1.current_move == legacy_special,
		"move=%s" % (p1.current_move.id if p1.current_move else "null"))

	_prime_cancel(p1, legacy_heavy, heavy_window, true)
	p1.input_buffer["light"] = 0
	_check("illegal chain: heavy hit cannot chain into a normal, buffer kept",
		not p1._try_cancel() and p1.current_move == legacy_heavy and p1.input_buffer.has("light"),
		"move=%s buffer=%s" % [p1.current_move.id if p1.current_move else "null", str(p1.input_buffer)])

	_prime_cancel(p1, legacy_heavy, heavy_window, true)
	p1.input_buffer["special"] = 0
	_check("legal cancel: heavy hit confirms into special",
		p1._try_cancel() and p1.current_move == legacy_special,
		"move=%s" % (p1.current_move.id if p1.current_move else "null"))

	_prime_cancel(p1, legacy_light, legacy_light.startup, true)
	p1.input_buffer["heavy"] = 0
	_check("cancel window does not open on the last startup frame",
		not p1._try_cancel() and p1.input_buffer.has("heavy"),
		"frame=%d" % p1.state_frame)

	_prime_cancel(p1, legacy_light, legacy_light.total_frames(), true)
	p1.input_buffer["heavy"] = 0
	_check("cancel window stays open through the move's final frame",
		p1._try_cancel() and p1.current_move == legacy_heavy,
		"frame=%d" % p1.state_frame)

	_prime_cancel(p1, legacy_light, cancel_window, false)
	p1.input_buffer["heavy"] = 0
	_check("no hit-confirm means no cancel",
		not p1._try_cancel() and p1.input_buffer.has("heavy"), "")

	# Counter-specific rules outrank ordinary HIT rules: inject one on a copy of
	# the row and restore the authored data afterwards (assign(), because an
	# untyped Array cannot replace the typed cancels property).
	var saved_cancels: Array[CancelRule] = legacy_light.cancels.duplicate()
	var counter_rule := CancelRule.new()
	counter_rule.target = CancelRule.Target.HEAVY
	counter_rule.kind = CancelRule.Kind.CHAIN
	counter_rule.condition = CancelRule.Condition.COUNTER_HIT
	counter_rule.from_frame = cancel_window
	counter_rule.to_frame = legacy_light.total_frames()
	var injected: Array[CancelRule] = [counter_rule]
	injected.append_array(saved_cancels)
	legacy_light.cancels = injected
	_prime_cancel(p1, legacy_light, cancel_window, true, true)
	p1.input_buffer["light"] = 0
	p1.input_buffer["heavy"] = 0
	var counter_first := p1._try_cancel() and p1.current_move == legacy_heavy \
		and p1.input_buffer.has("light")
	_prime_cancel(p1, legacy_light, cancel_window, true, false)
	p1.input_buffer["light"] = 0
	p1.input_buffer["heavy"] = 0
	var ordinary_first := p1._try_cancel() and p1.current_move == legacy_light
	legacy_light.cancels.assign(saved_cancels)
	_check("counter-specific cancel precedes the ordinary HIT chain",
		counter_first and ordinary_first,
		"counter=%s ordinary=%s" % [str(counter_first), str(ordinary_first)])

	var reserved := CancelRule.new()
	reserved.condition = CancelRule.Condition.BLOCK
	reserved.from_frame = 1
	reserved.to_frame = 2
	var backwards := CancelRule.new()
	backwards.from_frame = 5
	backwards.to_frame = 2
	var wrong_target := CancelRule.new()
	wrong_target.kind = CancelRule.Kind.CHAIN
	wrong_target.target = CancelRule.Target.SPECIAL
	wrong_target.from_frame = 1
	wrong_target.to_frame = 2
	_check("cancel validation rejects reserved conditions, empty windows, and kind/target mismatch",
		reserved.validate() != "" and backwards.validate() != ""
			and wrong_target.validate() != "" and counter_rule.validate() == "",
		"%s | %s | %s" % [reserved.validate(), backwards.validate(), wrong_target.validate()])

	# --- 42. juggle/OTG rules (PROPOSALS 6): cap, reset, repeat-hit scaling ---
	# Airborne juggle sequence driven through the real receive_hit path: three
	# allowed airborne hits, the fourth rejected. Between hits the attacker
	# starts fresh moves, so the counter is demonstrably not reset by a move
	# change, only by combo end.
	var jg_strike: MoveData = p1.data.find_move(MoveData.InputType.LIGHT, MoveData.Stance.STAND)
	scene._begin_round()
	scene._start_fight()
	_reset_fighters(100, 120)
	p1.input_enabled = false
	p2.input_enabled = false
	# Launch the defender: all four attempts target an airborne fighter.
	p2.grounded = false
	p2._force_state(FighterBase.State.JUMP_FALL)
	var jg_velocities: Array[float] = []
	var jg_expectations: Array[float] = []
	var jg_health: Array[float] = []
	for i in range(4):
		var jg_move: MoveData = jg_strike if i != 2 \
			else p1.data.find_move(MoveData.InputType.HEAVY, MoveData.Stance.STAND)
		p1._start_move(jg_move)
		jg_health.append(p2.health)
		# Expected pushback: authored knockback, scaled down per prior airborne
		# hit in the combo (first airborne hit unscaled).
		var jg_prior := p2.juggle_hits
		jg_expectations.append(float(jg_move.knockback.x) *
			pow(FighterBase.JUGGLE_KNOCKBACK_SCALE, float(jg_prior)))
		if p2.receive_hit(p1, p1.current_move):
			jg_velocities.append(absf(p2.velocity.x))
	var cap := FighterBase.JUGGLE_HIT_CAP
	_check("juggle: the first three airborne hits connect, none after the cap",
		jg_velocities.size() == cap and p2.health == jg_health[cap],
		"hits=%d hp_after=%s" % [jg_velocities.size(), str(p2.health)])
	_check("juggle: the first airborne hit keeps the authored pushback exactly",
		jg_velocities[0] == jg_expectations[0], "v=%.3f" % jg_velocities[0])
	_check("juggle: each repeat airborne hit scales horizontal pushback down",
		is_equal_approx(jg_velocities[1], jg_expectations[1])
			and is_equal_approx(jg_velocities[2], jg_expectations[2]),		"v=%s" % str(jg_velocities))
	_check("juggle: the counter survives an attacker move change inside the combo",
		p2.juggle_hits == cap, "juggle=%d" % p2.juggle_hits)
	var jg_gravity_ok := false
	var vy_before := p2.velocity.y
	p2._apply_gravity(1.0 / 60.0)
	jg_gravity_ok = is_equal_approx(vy_before + p2.gravity * FighterBase.JUGGLE_GRAVITY_MULT / 60.0,
		p2.velocity.y)
	_check("juggle: gravity multiplies once a repeat hit carries the arc",
		jg_gravity_ok, "vy=%.3f" % p2.velocity.y)

	# Combo end resets both counters; mid-juggle stun ticks do not.
	p1._start_move(jg_strike)
	p2._force_state(FighterBase.State.KNOCKDOWN)
	p2.frames_since_hit = 41
	p2._tick_combo()
	var early := p2.juggle_hits
	p2._force_state(FighterBase.State.IDLE)
	p2.grounded = true
	p2._tick_combo()
	_check("juggle: the counter survives non-ending airborne stun ticks",
		early == cap, "juggle=%d" % early)
	_check("juggle: combo end resets the airborne-hit counter together with combo",
		p2.juggle_hits == 0 and p2.combo_hits == 0
			and p2.receive_hit(p1, p1.current_move),
		"juggle=%d" % p2.juggle_hits)
	# After the reset a fresh airborne attempt re-enters the count from 1.
	p2.grounded = false
	p2._force_state(FighterBase.State.JUMP_FALL)
	var re_entered := p2.receive_hit(p1, p1.current_move)
	_check("juggle: after reset a fresh airborne hit re-enters the count",
		re_entered and p2.juggle_hits == 1, "juggle=%d" % p2.juggle_hits)

	# Grounded knockdown protection stays K1/R1 and keeps the attacker's window
	# live: MatchRoot._poll_hit returns null and the move is not spent.
	scene._begin_round()
	scene._start_fight()
	_reset_fighters(100, 120)
	p1._start_move(jg_strike)
	p1.state_frame = jg_strike.startup
	p2._force_state(FighterBase.State.KNOCKDOWN)
	p2.knockdown_frames = 30
	_check("OTG: a strike against grounded knockdown is skipped by _poll_hit",
		scene._poll_hit(p1, p2) == null and not p1.move_already_hit,
		"polled=%s spent=%s" % ["hit" if scene._poll_hit(p1, p2) != null else "null",
			str(p1.move_already_hit)])

	p1.input_enabled = true
	p2.input_enabled = true

	# --- 43. authored combo routes (PROPOSALS 6): jump-in, grounded chain,
	# punish EX command (special+heavy buffers), and the blocked endpoints,
	# measured through the real resolver for both fighters.
	for route_pair in [[p1, p2], [p2, p1]]:
		var atk: FighterBase = route_pair[0]
		var dfd: FighterBase = route_pair[1]
		var tag: String = "route " + atk.data.id
		var j_heavy: MoveData = atk.data.find_move(MoveData.InputType.HEAVY, MoveData.Stance.AIR)
		var _gr_light: MoveData = atk.data.find_move(MoveData.InputType.LIGHT, MoveData.Stance.STAND)
		var _gr_heavy: MoveData = atk.data.find_move(MoveData.InputType.HEAVY, MoveData.Stance.STAND)
		var _ex_fwd: MoveData = atk.data.find_ex_move(MoveData.InputType.SPECIAL_FWD, MoveData.Stance.STAND)
		var _base_fwd: MoveData = atk.data.find_move(MoveData.InputType.SPECIAL_FWD, MoveData.Stance.STAND)
		# dfd blocks by holding away from atk: P1 faces right, P2 faces left.
		var blk: String = "p%d_left" % dfd.player_index if dfd == p1 			else "p%d_right" % dfd.player_index

		# Jump-in starter + light follow-up: the follow-up must CONNECT, not
		# merely start. Measured connect window (spacing sweep, PR B): launch
		# height 10-30 px, horizontal gap 20-44 px. Test at 20 px / 28 px for
		# both starters (jump_heavy and jump_light).
		for jump_starter in [j_heavy, atk.data.find_move(MoveData.InputType.LIGHT, MoveData.Stance.AIR)]:
			scene._begin_round()
			scene._start_fight()
			scene.set("phase", 4)
			_reset_fighters(100.0, 128.0)
			atk.input_enabled = false
			dfd.input_enabled = false
			atk.position.y = scene.stage.floor_y - 1.0 - 20.0
			atk.velocity = Vector2(0.0, 60.0)
			atk.grounded = false
			atk._start_move(jump_starter)
			atk.state_frame = jump_starter.startup
			scene._resolve_hits()
			var j_starter_hit: bool = dfd.combo_hits == 1
			var j_follow_hit := false
			var j_follow_id := ""
			var j_follow_grounded := false
			for j_f in 60:
				if atk.move_hit_confirmed and atk.current_move \
						and atk.state_frame > atk.current_move.startup:
					atk.input_enabled = true
					atk.input_buffer["light"] = 0
					if not atk._try_cancel():
						atk.input_buffer.clear()
					atk.input_enabled = false
				var j_before: float = dfd.health
				await _step()
				scene._resolve_hits()
				if j_starter_hit and dfd.health < j_before:
					j_follow_hit = true
					j_follow_id = atk.current_move.id if atk.current_move else "?"
					j_follow_grounded = atk.grounded
					break
			_check(tag + ": " + jump_starter.id + " jump-in follow-up CONNECTS at the verified spacing",
				j_starter_hit and j_follow_hit and j_follow_id == "jump_light",
				"starter=%s follow=%s move=%s grounded=%s" % [str(j_starter_hit), str(j_follow_hit),
					j_follow_id, str(j_follow_grounded)])

		# Blocked variant: no continuation in the parity state. Endpoints
		# measured, not assumed: remaining blockstun and the surviving buffer.
		scene._begin_round()
		scene._start_fight()
		_reset_fighters(100.0, 128.0)
		Input.action_press(blk)
		atk.position.y = scene.stage.floor_y - 1.0
		atk.velocity = Vector2(0.0, 60.0)
		atk.grounded = false
		atk._start_move(j_heavy)
		atk.state_frame = j_heavy.startup
		atk.input_buffer["light"] = 0
		scene._resolve_hits()
		var b_blocked: bool = dfd.state == FighterBase.State.BLOCKSTUN and dfd.combo_hits == 0
		var b_no_chain: bool = not atk._try_cancel() and atk.input_buffer.has("light")
		_check(tag + ": blocked jump-in keeps parity (no chain, buffer held)",
			b_blocked and b_no_chain,
			"blocked=%s chain=%s" % [str(b_blocked), str(b_no_chain)])
		_check(tag + ": blocked jump-in endpoint measured (defending blockstun)",
			dfd.blockstun_frames == j_heavy.blockstun,
			"measured blockstun_remaining=%d authored=%d" % [dfd.blockstun_frames, j_heavy.blockstun])
		Input.action_release(blk)

		# Grounded chain: light confirms, buffered heavy chains via the light
		# rule, as an end-to-end route through the resolver.
		scene._begin_round()
		scene._start_fight()
		_reset_fighters(100.0, 128.0)
		atk._start_move(_gr_light)
		atk.state_frame = _gr_light.startup
		scene._resolve_hits()
		atk.state_frame += 1
		var g_connected: bool = dfd.combo_hits == 1
		atk.input_buffer["heavy"] = 0
		var g_chain: bool = atk._try_cancel() and atk.current_move == _gr_heavy
		_check(tag + ": grounded light chain connects into heavy",
			g_connected and g_chain and dfd.combo_hits == 1,
			"hit=%s chain=%s" % [str(g_connected), str(g_chain)])

		# Punish route: the EX command (special buffer + heavy buffer) confirms
		# into the forward EX special, paying its meter cost. Blocked heavy
		# follows up with nothing (parity).
		scene._begin_round()
		scene._start_fight()
		_reset_fighters(100.0, 132.0)
		atk._start_move(_gr_heavy)
		atk.state_frame = _gr_heavy.startup
		scene._resolve_hits()
		atk.state_frame += 1
		var pp_connected: bool = dfd.combo_hits == 1
		atk.meter = atk.max_meter
		var prev_meter: float = atk.meter
		atk.input_buffer["special"] = 0
		atk.input_buffer["heavy"] = 0
		var fwd_key: String = "p%d_%s" % [atk.player_index, "right" if atk.facing == 1 else "left"]
		atk.input_enabled = true
		Input.action_press(fwd_key)
		var pp_chain: bool = atk._try_cancel() and atk.current_move == _ex_fwd
		Input.action_release(fwd_key)
		atk.input_enabled = false
		_check(tag + ": punish heavy confirms into forward EX special (special+heavy buffers)",
			pp_connected and pp_chain and atk.meter == prev_meter - _ex_fwd.meter_cost,
			"hit=%s chain=%s meter=%.1f" % [str(pp_connected), str(pp_chain), atk.meter])
		_check(tag + ": EX punish pays the authored 50 meter cost",
			_ex_fwd.meter_cost == 50.0 and pp_chain,
			"cost=%.1f" % _ex_fwd.meter_cost)

		# Fallback: EX command present but meter cannot pay transforms into the
		# base forward special, unchanged meter.
		scene._begin_round()
		scene._start_fight()
		_reset_fighters(100.0, 132.0)
		atk._start_move(_gr_heavy)
		atk.state_frame = _gr_heavy.startup
		scene._resolve_hits()
		atk.state_frame += 1
		atk.meter = 0.0
		atk.input_buffer["special"] = 0
		atk.input_buffer["heavy"] = 0
		atk.input_enabled = true
		Input.action_press(fwd_key)
		var fb_chain: bool = atk._try_cancel() and atk.current_move == _base_fwd
		Input.action_release(fwd_key)
		atk.input_enabled = false
		_check(tag + ": punish route falls back to the base forward special at zero meter",
			fb_chain and atk.meter == 0.0,
			"chain=%s meter=%.1f" % [str(fb_chain), atk.meter])

		# Direction gate: with NO forward held, the same buffered special+heavy
		# does not start the forward EX, and does not fall back to the forward
		# special either. The legacy SPECIAL route resolves it by direction (neutral).
		scene._begin_round()
		scene._start_fight()
		_reset_fighters(100.0, 132.0)
		atk._start_move(_gr_heavy)
		atk.state_frame = _gr_heavy.startup
		scene._resolve_hits()
		atk.state_frame += 1
		atk.meter = atk.max_meter
		atk.input_buffer["special"] = 0
		atk.input_buffer["heavy"] = 0
		atk.input_enabled = true
		var neutral_chain: bool = atk._try_cancel()
		atk.input_enabled = false
		_check(tag + ": neutral special+heavy never starts the forward EX or forward fallback",
			neutral_chain and atk.current_move != _ex_fwd and atk.current_move != _base_fwd
				and atk.current_move == atk.data.find_move(MoveData.InputType.SPECIAL_NEUTRAL, MoveData.Stance.STAND)
				and atk.meter == atk.max_meter,
			"move=%s meter=%.1f" % [atk.current_move.id if atk.current_move else "null", atk.meter])

		# Blocked punish: no continuation; partially-buffered EX inputs are
		# measured surviving the block.
		scene._begin_round()
		scene._start_fight()
		_reset_fighters(100.0, 132.0)
		Input.action_press(blk)
		atk._start_move(_gr_heavy)
		atk.state_frame = _gr_heavy.startup
		scene._resolve_hits()
		var pp_blocked: bool = dfd.state == FighterBase.State.BLOCKSTUN and dfd.combo_hits == 0
		atk.input_buffer["special"] = 0
		atk.input_buffer["heavy"] = 0
		var pp_no_chain: bool = not atk._try_cancel() and atk.input_buffer.has("special") \
			and atk.input_buffer.has("heavy")
		_check(tag + ": blocked punish keeps parity (no follow-up, buffers held)",
			pp_blocked and pp_no_chain,
			"blocked=%s chain=%s" % [str(pp_blocked), str(pp_no_chain)])
		_check(tag + ": blocked punish endpoint measured (defending blockstun)",
			dfd.blockstun_frames == _gr_heavy.blockstun,
			"measured blockstun_remaining=%d authored=%d" % [dfd.blockstun_frames, _gr_heavy.blockstun])
		Input.action_release(blk)
		atk.input_enabled = true
		dfd.input_enabled = true

	# --- 44. block-pushback data (PROPOSALS 6): authored 45 px/s parity, data
	# driven displacement, and corner transfer ----
	var push_matrix_ok := true
	var push_detail := "ok"
	for fighter_data in [p1.data, p2.data]:
		for m in fighter_data.moves:
			var expect_push := 0.0 if m.level == MoveData.Level.THROW else 45.0
			if not is_equal_approx(m.block_pushback, expect_push):
				push_matrix_ok = false
				push_detail = "%s authored %.1f expected %.1f" % [m.id, m.block_pushback, expect_push]
	_check("every strike row authors the 45 px/s block-pushback parity value, throws author 0",
		push_matrix_ok, push_detail)

	scene._begin_round()
	scene._start_fight()
	_reset_fighters(100, 128)
	Input.action_press("p2_right") # p2 faces left; right = away = block
	var block_light: MoveData = p1.data.find_move(MoveData.InputType.LIGHT, MoveData.Stance.STAND)
	p1._start_move(block_light)
	p1.state_frame = block_light.startup
	scene._resolve_hits()
	_check("blocked light resolves as blockstun",
		p2.state == FighterBase.State.BLOCKSTUN and p2.combo_hits == 0, "")
	_check("blocked pushback now comes from authored data (45 px/s), not the constant",
		is_equal_approx(p2.velocity.x, 45.0) and p1.velocity.x == 0.0,
		"p2_vx=%.1f p1_vx=%.1f" % [p2.velocity.x, p1.velocity.x])
	Input.action_release("p2_right")

	# Data-driven proof: an off-parity authored value wins over the old constant.
	var push_move: MoveData = p1.data.find_move(MoveData.InputType.LIGHT, MoveData.Stance.STAND).duplicate()
	push_move.block_pushback = 60.0
	_reset_fighters(100, 128)
	Input.action_press("p2_right")
	p1._start_move(push_move)
	p1.state_frame = push_move.startup
	scene._resolve_hits()
	_check("blocked displacement matches data rather than the hard-coded constant",
		is_equal_approx(p2.velocity.x, 60.0), "p2_vx=%.1f" % p2.velocity.x)
	Input.action_release("p2_right")

	# Corner transfer (§6): a pinned defender keeps 0 pushback; the attacker is
	# displaced away from the defender by the same magnitude. Tested at both
	# walls, with the attacker positioned so the blocked strike drives the
	# defender into the wall.
	for corner in [["left", 1, -1], ["right", -1, 1]]:
		var wall_name: String = corner[0]
		var dfd_facing: int = corner[1]
		var atk_facing: int = corner[2]
		scene._begin_round()
		scene._start_fight()
		_reset_fighters(64.0, 128.0)
		var wall_x: float = p1.stage.left_bound if wall_name == "left" else p1.stage.right_bound
		p2.position.x = wall_x
		p1.position.x = wall_x - atk_facing * 30.0
		p2.facing = dfd_facing
		p1.facing = atk_facing
		# Defender holds away from its facing, blocking the strike.
		Input.action_press("p2_left" if dfd_facing == 1 else "p2_right")
		var corner_heavy: MoveData = p1.data.find_move(MoveData.InputType.HEAVY, MoveData.Stance.STAND)
		p1._start_move(corner_heavy)
		p1.state_frame = corner_heavy.startup
		scene._resolve_hits()
		_check("corner block (" + wall_name + " wall): defender pinned, attacker displaced away",
			p2.state == FighterBase.State.BLOCKSTUN
				and is_equal_approx(p2.velocity.x, 0.0)
				and is_equal_approx(p1.velocity.x, float(atk_facing) * -45.0),
			"p2_vx=%.1f p1_vx=%.1f" % [p2.velocity.x, p1.velocity.x])
		_check("corner block (" + wall_name + " wall): no wall crossing and no residual overlap",
			p2.position.x == clampf(p2.position.x, p1.stage.left_bound, p1.stage.right_bound),
			"p2_x=%.1f" % p2.position.x)
		var p1r := p1.pushbox_rect()
		var p2r := p2.pushbox_rect()
		var penetration: float = minf(p1r.end.x, p2r.end.x) - maxf(p1r.position.x, p2r.position.x)
		_check("corner block (" + wall_name + " wall): no residual pushbox penetration",
			penetration <= 0.0,
			"measured penetration=%.1f" % penetration)
		Input.action_release("p2_left" if dfd_facing == 1 else "p2_right")

	# --- 45. command grabs (PROPOSALS 7): resolution, untechable, guards ---
	# Data matrix: exactly one COMMAND_GRAB row per fighter with owner values.
	var cg_ok := true
	var cg_detail := ""
	for fighter_data in [p1.data, p2.data]:
		var cg: MoveData = null
		for m in fighter_data.moves:
			if m.input == MoveData.InputType.COMMAND_GRAB:
				if cg != null:
					cg_ok = false
					cg_detail = "duplicate command grab row in " + fighter_data.id
				cg = m
		if cg == null:
			cg_ok = false
			cg_detail = "no command grab row in " + fighter_data.id
			continue
		var want_damage := 120.0 if fighter_data.id == "peg_leg_peggy" else 140.0
		var want_startup := 14 if fighter_data.id == "peg_leg_peggy" else 16
		var want_whiff := 24 if fighter_data.id == "peg_leg_peggy" else 26
		var want_meter := 6.0 if fighter_data.id == "peg_leg_peggy" else 8.0
		var ok := cg.level == MoveData.Level.THROW \
			and is_equal_approx(cg.damage, want_damage) \
			and cg.startup == want_startup and cg.active == 3 \
			and cg.whiff_recovery == want_whiff and cg.meth == false \
			and is_equal_approx(cg.meter_gain_hit, want_meter) \
			and is_equal_approx(cg.meter_gain_whiff, 1.5) \
			and is_equal_approx(cg.meter_gain_receive, 4.0) \
			and cg.knockdown and is_equal_approx(cg.block_pushback, 0.0) \
			and cg.ex == false and cg.block_damage == 0.0
		if not ok:
			cg_ok = false
			cg_detail = "%s values off" % cg.id
	_check("each fighter authors exactly one THROW-level command grab with owner values",
		cg_ok, cg_detail)
	_check("normal find_move lookup never collides with the command grab row",
		p1.data.find_move(MoveData.InputType.GRAB, MoveData.Stance.STAND).input
			== MoveData.InputType.GRAB
			and p2.data.find_command_grab().input == MoveData.InputType.COMMAND_GRAB,
		"")

	# Resolution: forward+grab starts the command grab; neutral or back-held
	# grab starts the techable normal throw. Direction is read live, so hold
	# the axis with Input while buffering the grab press.
	scene._begin_round()
	scene._start_fight()
	_reset_fighters(100, 120)
	Input.action_press("p1_right") # p1 faces right: forward held
	p1.input_buffer["grab"] = 0
	p1._try_start_attack()
	_check("forward+grab resolves to the command grab row",
		p1.current_move != null and p1.current_move.input == MoveData.InputType.COMMAND_GRAB,
		"move=%s" % (p1.current_move.id if p1.current_move else "null"))
	p1.reset_state()
	Input.action_release("p1_right")
	p1.input_buffer["grab"] = 0
	p1._try_start_attack()
	_check("neutral grab resolves to the techable normal throw",
		p1.current_move != null and p1.current_move.input == MoveData.InputType.GRAB,
		"move=%s" % (p1.current_move.id if p1.current_move else "null"))
	p1.reset_state()
	Input.action_press("p1_left") # p1 faces right: back-held
	p1.input_buffer["grab"] = 0
	p1._try_start_attack()
	_check("back-held grab resolves to the normal throw, not the command grab",
		p1.current_move != null and p1.current_move.input == MoveData.InputType.GRAB,
		"move=%s" % (p1.current_move.id if p1.current_move else "null"))
	Input.action_release("p1_left")

	# p2 direction selection, same rule (both fighters; p2 faces left).
	scene._begin_round()
	scene._start_fight()
	_reset_fighters(100, 120)
	Input.action_press("p2_left") # p2 faces left: forward held
	p2.input_buffer["grab"] = 0
	p2._try_start_attack()
	_check("richard forward+grab fires his command grab",
		p2.current_move != null and p2.current_move.id == "richard_command_grab",
		"move=%s" % (p2.current_move.id if p2.current_move else "null"))
	p2.reset_state()
	Input.action_release("p2_left")
	p2.input_buffer["grab"] = 0
	p2._try_start_attack()
	_check("richard neutral grab fires the normal throw",
		p2.current_move != null and p2.current_move.input == MoveData.InputType.GRAB,
		"move=%s" % (p2.current_move.id if p2.current_move else "null"))

	# Connects as a THROW against an idle grounded defender, earns its damage
	# and knockdown; stands and crouches cannot block it.
	for cmd_pair in [p1, p2]:
		var atk: FighterBase = cmd_pair
		var dfd: FighterBase = p2 if atk == p1 else p1
		var tagc: String = "cmdgrab " + atk.data.id
		var cmd: MoveData = atk.data.find_command_grab()
		scene._begin_round()
		scene._start_fight()
		_reset_fighters(100.0, 128.0)
		var hp_cg: float = dfd.health
		atk._start_move(cmd)
		atk.state_frame = cmd.startup
		Input.action_press("p2_right" if dfd == p2 else "p1_left") # held block attempt
		scene._resolve_hits()
		_check(tagc + ": connects as damage even when the defender holds block",
			is_equal_approx(hp_cg - dfd.health, cmd.damage)
			and dfd.state == FighterBase.State.KNOCKDOWN
			and dfd.combo_hits == 1,
			"hp_loss=%.1f state=%d" % [hp_cg - dfd.health, dfd.state])
		_check(tagc + ": defender wakes with the authored 30-frame knockdown",
			dfd.knockdown_frames == 30,
			"frames=%d" % dfd.knockdown_frames)

		# UNTECHABLE: a grab buffered inside throw_tech_window does NOT break
		# the command grab, no TECH state, damage lands.
		Input.action_release("p2_right" if dfd == p2 else "p1_left")
		scene._begin_round()
		scene._start_fight()
		_reset_fighters(100.0, 128.0)
		var hp_teched: float = dfd.health
		atk._start_move(cmd)
		atk.state_frame = cmd.startup
		dfd.input_buffer["grab"] = 0
		scene._resolve_hits()
		_check(tagc + ": buffered grab does not tech the command grab",
			dfd.state != FighterBase.State.TECH
				and is_equal_approx(hp_teched - dfd.health, cmd.damage),
			"state=%d hp_loss=%.1f" % [dfd.state, hp_teched - dfd.health])

		# R1: rejected against a knocked-down defender, no opt-out.
		scene._begin_round()
		scene._start_fight()
		_reset_fighters(100.0, 128.0)
		dfd._force_state(FighterBase.State.KNOCKDOWN)
		dfd.knockdown_frames = 30
		atk._start_move(cmd)
		atk.state_frame = cmd.startup
		var r1_health: float = dfd.health
		scene._resolve_hits()
		_check(tagc + ": rejected against knockdown (R1)",
			is_equal_approx(dfd.health, r1_health)
				and dfd.state == FighterBase.State.KNOCKDOWN,
			"health=%.1f" % dfd.health)

		# Wake-up throw invulnerability still rejects it.
		scene._begin_round()
		scene._start_fight()
		_reset_fighters(100.0, 128.0)
		dfd._force_state(FighterBase.State.WAKE_UP)
		dfd.state_frame = 0
		r1_health = dfd.health
		atk._start_move(cmd)
		atk.state_frame = cmd.startup
		scene._resolve_hits()
		_check(tagc + ": wake-up throw-invulnerable defender rejects the command grab",
			is_equal_approx(dfd.health, r1_health),
			"health=%.1f" % dfd.health)

		# Airborne rejection: _poll_hit returns null without spending the
		# attacker's active window (shared resolver rule).
		scene._begin_round()
		scene._start_fight()
		_reset_fighters(100.0, 128.0)
		dfd.grounded = false
		dfd._force_state(FighterBase.State.JUMP_FALL)
		atk._start_move(cmd)
		atk.state_frame = cmd.startup
		_check(tagc + ": airborne defender rejects the grab without spending the window",
			scene._poll_hit(atk, dfd) == null and not atk.move_already_hit,
			"polled=null expected")

		# Whiff recovery is row-authored and punishable in kind: the move
		# total reads the overridden whiff value, not data.throw_whiff_recovery.
		scene._begin_round()
		scene._start_fight()
		_reset_fighters(400.0, 128.0) # out of range on purpose
		atk._start_move(cmd)
		var whiff_total: int = atk._move_total(cmd)
		_check(tagc + ": whiff recovery uses the row override",
			whiff_total == cmd.startup + cmd.active + cmd.whiff_recovery,
			"total=%d authored=%d+%d+%d" % [whiff_total, cmd.startup, cmd.active,
				cmd.whiff_recovery])
		# Informational metric (no assertion): reward vs the defender's best
		# single-hit punish during the whiff window.
		var punish: float = 0.0
		for m_probe in dfd.data.moves:
			if m_probe.level != MoveData.Level.THROW and m_probe.damage > punish:
				punish = m_probe.damage
		print("metric: %s reward/whiff-punish = %.2f (%.0f / %.0f best hit)"
			% [atk.data.id, cmd.damage / punish, cmd.damage, punish])
		atk.reset_state()

	# Normal throw still techs exactly as before (regression of the recorded
	# owner decision boundary).
	scene._begin_round()
	scene._start_fight()
	_reset_fighters(100.0, 128.0)
	var normal_throw: MoveData = p1.data.find_move(MoveData.InputType.GRAB, MoveData.Stance.STAND)
	p1._start_move(normal_throw)
	p1.state_frame = normal_throw.startup
	p2.input_buffer["grab"] = 0
	var hp_tech: float = p2.health
	scene._resolve_hits()
	_check("normal throw still techs: grab buffered in the window breaks it",
		p1.state == FighterBase.State.TECH and p2.health == hp_tech,
		"state=%d hp=%.1f" % [p1.state, p2.health])

	# Owner rule (PROPOSALS §7): tech accepts ANY grab press, direction-blind.
	# The defender holds forward (toward the thrower's side) and presses grab
	# inside the window; the incoming normal throw must still be teched.
	scene._begin_round()
	scene._start_fight()
	_reset_fighters(100.0, 128.0)
	Input.action_press("p2_left") # p2 faces left: forward held
	p1._start_move(normal_throw)
	p1.state_frame = normal_throw.startup
	p2.input_buffer["grab"] = 0
	var hp_fwd: float = p2.health
	scene._resolve_hits()
	_check("forward-held grab press still techs an incoming normal throw",
		p1.state == FighterBase.State.TECH and p2.health == hp_fwd,
		"state=%d hp=%.1f" % [p1.state, p2.health])
	Input.action_release("p2_left")

	# --- 46. launchers (PROPOSALS 6, owner decisions 2026-11-07): authored
	# vertical knockback on the forward specials + EX, launch state, juggle
	# scaling/cap on the real hit path, and block punishability.
	# Owner values: Peggy base 228 (80% of jump), Richard base 260 (intentional
	# asymmetry: one follow-up); EX higher for both.
	var launch_matrix_ok := true
	var launch_detail := "ok"
	for fighter_data in [p1.data, p2.data]:
		var base_fwd: MoveData = fighter_data.find_move(MoveData.InputType.SPECIAL_FWD, MoveData.Stance.STAND)
		var ex_fwd: MoveData = fighter_data.find_ex_move(MoveData.InputType.SPECIAL_FWD, MoveData.Stance.STAND)
		var want_base := 228.0 if fighter_data.id == "peg_leg_peggy" else 260.0
		var want_ex := 360.0 if fighter_data.id == "peg_leg_peggy" else 340.0
		if not is_equal_approx(base_fwd.knockback.y, want_base):
			launch_matrix_ok = false
			launch_detail = "%s base y=%.1f expected %.1f" % [fighter_data.id, base_fwd.knockback.y, want_base]
		if not is_equal_approx(ex_fwd.knockback.y, want_ex):
			launch_matrix_ok = false
			launch_detail = "%s EX y=%.1f expected %.1f" % [fighter_data.id, ex_fwd.knockback.y, want_ex]
		if ex_fwd.knockback.y <= base_fwd.knockback.y or ex_fwd.knockback.y <= 0.0:
			launch_matrix_ok = false
			launch_detail = "%s EX y=%.1f not above base %.1f" % [fighter_data.id, ex_fwd.knockback.y, base_fwd.knockback.y]
		if base_fwd.knockdown or ex_fwd.knockdown:
			launch_matrix_ok = false
			launch_detail = "%s launcher rows must not be hard knockdowns" % fighter_data.id
		var crouch_heavy: MoveData = fighter_data.find_move(MoveData.InputType.HEAVY, MoveData.Stance.CROUCH)
		if crouch_heavy.knockback.y != 0.0 or not crouch_heavy.knockdown:
			launch_matrix_ok = false
			launch_detail = "%s crouch heavy changed" % fighter_data.id
	_check("launchers are authored data with the owner values (Peggy 228/360, Richard 260/340)",
		launch_matrix_ok, launch_detail)
	_check("crouch heavies remain hard knockdowns with no vertical knockback",
		p1.data.find_move(MoveData.InputType.HEAVY, MoveData.Stance.CROUCH).knockdown
			and p1.data.find_move(MoveData.InputType.HEAVY, MoveData.Stance.CROUCH).knockback.y == 0.0
			and p2.data.find_move(MoveData.InputType.HEAVY, MoveData.Stance.CROUCH).knockdown,
		"")

	# The launch happens through the real resolver and the defender is airborne.
	for launch_pair in [[p1, p2], [p2, p1]]:
		var latk: FighterBase = launch_pair[0]
		var ldfd: FighterBase = launch_pair[1]
		var tagl: String = "launcher " + latk.data.id
		var lmove: MoveData = latk.data.find_move(MoveData.InputType.SPECIAL_FWD, MoveData.Stance.STAND)
		scene._begin_round()
		scene._start_fight()
		_reset_fighters(100, 128)
		latk.input_enabled = false
		ldfd.input_enabled = false
		latk._start_move(lmove)
		latk.state_frame = lmove.startup
		scene._resolve_hits()
		var airborne := not ldfd.grounded and ldfd.velocity.y < 0.0
		latk._start_move(lmove)
		latk.state_frame = 0
		_check(tagl + ": the authored forward special launches the defender",
			airborne and ldfd.state == FighterBase.State.HITSTUN,
			"grounded=%s vy=%.1f state=%d" % [str(ldfd.grounded), ldfd.velocity.y, ldfd.state])

		# A juggle hit connects on the airborne defender (real hit path).
		var juggle_move: MoveData = latk.data.find_move(MoveData.InputType.HEAVY, MoveData.Stance.AIR)
		var hp_before_launch: float = ldfd.health
		ldfd.receive_hit(latk, juggle_move)
		_check(tagl + ": at least one airborne juggle hit connects before landing",
			ldfd.juggle_hits == 1 and ldfd.health < hp_before_launch,
			"juggle=%d hp=%.1f" % [ldfd.juggle_hits, ldfd.health])

	# Owner asymmetry (2026-11-07): Richard's base launcher is 260 and a walk-in
	# light follow-up connects once on the real route (Peggy keeps the full
	# 3-hit EX route; Richard's EX unlocks depth).
	scene._begin_round()
	scene._start_fight()
	_reset_fighters(100, 128)
	var rich_atk: FighterBase = p2
	var rich_dfd: FighterBase = p1
	rich_atk.input_enabled = false
	rich_dfd.input_enabled = false
	rich_atk.position = Vector2(100.0, 150.0)
	rich_dfd.position = Vector2(128.0, 150.0)
	rich_atk.facing = 1
	rich_dfd.facing = -1
	var rich_base: MoveData = rich_atk.data.find_move(MoveData.InputType.SPECIAL_FWD, MoveData.Stance.STAND)
	rich_atk._start_move(rich_base)
	rich_atk.state_frame = rich_base.startup
	scene._resolve_hits()
	var rich_started := false
	var rich_follow_hit := false
	var rich_forward := "p%d_right" % rich_atk.player_index
	var rich_light: MoveData = rich_atk.data.find_move(MoveData.InputType.LIGHT, MoveData.Stance.STAND)
	for r_f in 120:
		if not rich_started and rich_atk.state in [FighterBase.State.IDLE, FighterBase.State.WALK_F,
				FighterBase.State.WALK_B]:
			rich_atk.input_enabled = true
			if rich_light.hitbox_rect(rich_atk.position, rich_atk.facing).intersects(
					rich_dfd.hurtbox_rect()):
				rich_atk._start_move(rich_light)
				rich_started = true
			else:
				Input.action_press(rich_forward)
		var r_before: float = rich_dfd.health
		await _step()
		scene._resolve_hits()
		if rich_started and rich_dfd.health < r_before and not rich_dfd.grounded:
			rich_follow_hit = true
			break
		if rich_dfd.grounded and r_f > 5:
			break
	Input.action_release(rich_forward)
	rich_atk.input_enabled = false
	_check("Richard's 260 base launcher connects one juggle follow-up on the real route",
		rich_base.knockback.y == 260.0 and rich_follow_hit and rich_dfd.juggle_hits >= 1,
		"kb_y=%.1f follow=%s juggle=%d" % [rich_base.knockback.y, str(rich_follow_hit),
			rich_dfd.juggle_hits])

	# Cap + 85% step through the real receive path on one airborne defender.
	var cap_atk: FighterBase = p1
	var cap_dfd: FighterBase = p2
	scene._begin_round()
	scene._start_fight()
	_reset_fighters(100, 128)
	cap_atk.input_enabled = false
	cap_dfd.input_enabled = false
	var cap_launch: MoveData = cap_atk.data.find_move(MoveData.InputType.SPECIAL_FWD, MoveData.Stance.STAND)
	cap_atk._start_move(cap_launch)
	cap_atk.state_frame = cap_launch.startup
	scene._resolve_hits()
	var cap_dmg: Array[float] = []
	for i in range(FighterBase.JUGGLE_HIT_CAP):
		var before_hp: float = cap_dfd.health
		cap_atk._start_move(cap_atk.data.find_move(MoveData.InputType.HEAVY, MoveData.Stance.AIR))
		var connected: bool = cap_dfd.receive_hit(cap_atk, cap_atk.current_move)
		cap_dmg.append(before_hp - cap_dfd.health if connected else 0.0)
	var fourth_hp: float = cap_dfd.health
	cap_atk._start_move(cap_atk.data.find_move(MoveData.InputType.LIGHT, MoveData.Stance.AIR))
	var fourth := cap_dfd.receive_hit(cap_atk, cap_atk.current_move)
	_check("the airborne-hit cap is reachable (3 hits counted on one defender)",
		cap_dfd.juggle_hits == FighterBase.JUGGLE_HIT_CAP
			and not is_zero_approx(cap_dmg[0]) and not is_zero_approx(cap_dmg[1])
			and not is_zero_approx(cap_dmg[2]),
		"juggle=%d dmg=%s" % [cap_dfd.juggle_hits, str(cap_dmg)])
	var juggle_heavy: MoveData = cap_atk.data.find_move(MoveData.InputType.HEAVY, MoveData.Stance.AIR)
	_check("the 85% third-hit damage step fires in the airborne chain",
		is_equal_approx(cap_dmg[0], juggle_heavy.damage)
			and is_equal_approx(cap_dmg[1], juggle_heavy.damage * 0.85)
			and is_equal_approx(cap_dmg[2], juggle_heavy.damage * 0.70),
		"dmg=%s authored=%.1f" % [str(cap_dmg), juggle_heavy.damage])
	_check("the cap rejects the next airborne hit and keeps the window live",
		not fourth and cap_dfd.health == fourth_hp
			and cap_dfd.is_invulnerable_to(cap_atk.data.find_move(MoveData.InputType.LIGHT,
				MoveData.Stance.AIR)),
		"connected=%s hp=%.1f" % [str(fourth), cap_dfd.health])

	# Block: the launcher's recovery leaves it punishable (defender actionable first).
	scene._begin_round()
	scene._start_fight()
	_reset_fighters(100, 128)
	var blk_atk: FighterBase = p1
	var blk_dfd: FighterBase = p2
	Input.action_press("p2_right")
	blk_atk._start_move(blk_atk.data.find_move(MoveData.InputType.SPECIAL_FWD, MoveData.Stance.STAND))
	blk_atk.state_frame = blk_atk.current_move.startup
	scene._resolve_hits()
	var blocked_launcher: bool = blk_dfd.state == FighterBase.State.BLOCKSTUN
	var dfd_act := -1
	var atk_act := -1
	for i in 90:
		await _step()
		if dfd_act < 0 and blk_dfd.state not in [FighterBase.State.BLOCKSTUN]:
			dfd_act = i
		if atk_act < 0 and blk_atk.state not in [FighterBase.State.ATTACK]:
			atk_act = i
		if dfd_act >= 0 and atk_act >= 0:
			break
	Input.action_release("p2_right")
	_check("a blocked launcher is punishable (defender acts before the attacker recovers)",
		blocked_launcher and dfd_act >= 0 and (atk_act < 0 or dfd_act < atk_act),
		"blocked=%s dfd_act=%d atk_act=%d" % [str(blocked_launcher), dfd_act, atk_act])

	# R1/K1/METH are unchanged; their dedicated regressions above cover them.
	p2._force_state(FighterBase.State.KNOCKDOWN)
	p2.knockdown_frames = 30
	var r1_throw: MoveData = p1.data.find_move(MoveData.InputType.GRAB, MoveData.Stance.STAND)
	_check("R1 still rejects a throw against a knocked-down defender",
		p2.is_invulnerable_to(r1_throw))
	p2.reset_state()

	# --- 47. combo readability flashes (GDD 10.3): silhouette-only, frozen
	# during hitstop, restored afterwards. Headless-safe (modulate fields only).
	var flash_light: MoveData = p1.data.find_move(MoveData.InputType.LIGHT, MoveData.Stance.STAND)
	# Hit flash: strong, 3 frames, frozen by hitstop.
	scene._begin_round(); scene._start_fight(); _reset_fighters(100, 128)
	p1.input_enabled = false; p2.input_enabled = false
	p1._start_move(flash_light); p1.state_frame = flash_light.startup
	scene._resolve_hits()
	var flash_body: Color = p2.body_color
	_check("a hit starts the strong silhouette flash",
		p2.hit_flash_frames == FighterBase.HIT_FLASH_FRAMES,
		"frames=%d state=%d" % [p2.hit_flash_frames, p2.state])
	var frozen_stop: float = p2.hitstop_frames
	await _step() # one tick inside hitstop
	_check("the flash survives hitstop frames without counting down",
		p2.hit_flash_frames == FighterBase.HIT_FLASH_FRAMES and p2.hitstop_frames < frozen_stop,
		"stop=%s->%s frames=%d" % [str(frozen_stop), str(p2.hitstop_frames), p2.hit_flash_frames])
	p2.hitstop_frames = 0
	for ff in FighterBase.HIT_FLASH_FRAMES + 1:
		await _step()
	_check("the flash clears and the silhouette restores its body color",
		p2.hit_flash_frames == 0 and p2.block_flash_frames == 0
			and p2.get_node("VisualRoot/Silhouette").modulate == flash_body,
		"hit=%d block=%d modulate=%s body=%s" % [p2.hit_flash_frames, p2.block_flash_frames,
			str(p2.get_node("VisualRoot/Silhouette").modulate), str(flash_body)])
	# Block flash: subtle, 2 frames.
	scene._begin_round(); scene._start_fight(); _reset_fighters(100, 128)
	p1.input_enabled = false
	Input.action_press("p2_right") # p2 faces left; right = away = standing block
	p1._start_move(flash_light); p1.state_frame = flash_light.startup
	scene._resolve_hits()
	var block_body: Color = p2.body_color
	var block_lightened: Color = block_body.lightened(0.35)
	_check("a block starts the subtler silhouette flash",
		p2.block_flash_frames == FighterBase.BLOCK_FLASH_FRAMES and p2.hit_flash_frames == 0
			and p2.state == FighterBase.State.BLOCKSTUN,
		"block=%d hit=%d state=%d" % [p2.block_flash_frames, p2.hit_flash_frames, p2.state])
	_check("the block flash modulates with the lightened body color",
		p2.get_node("VisualRoot/Silhouette").modulate == block_lightened,
		"modulate=%s expected=%s" % [str(p2.get_node("VisualRoot/Silhouette").modulate), str(block_lightened)])
	Input.action_release("p2_right")
	p2.hitstop_frames = 0
	for ff in FighterBase.BLOCK_FLASH_FRAMES + 1:
		await _step()
	_check("the block flash clears and restores the body color",
		p2.block_flash_frames == 0 and p2.get_node("VisualRoot/Silhouette").modulate == block_body,
		"")

	# ---------------- Authored presentation clips (Peggy) ----------------
	_reset_fighters(100.0, 400.0)
	_check("clip test context: p1 is Peggy with a clip library",
		p1.data.id == "peg_leg_peggy" and p1._clip_library_valid
			and PeggyClipLibrary.has_clips("peg_leg_peggy")
			and not PeggyClipLibrary.has_clips("whiskey_richard"),
		"p1=%s valid=%s" % [p1.data.id, str(p1._clip_library_valid)])

	# Library integrity: every enabled clip texture loads with a valid single
	# row of integer cels and a sane anchor/scale reference.
	var clip_defects := 0
	for key in PeggyClipLibrary.CLIPS:
		var c: Dictionary = PeggyClipLibrary.CLIPS[key]
		if not c.enabled:
			continue
		var tex := p1._clip_texture(c)
		var cel_w := tex.get_width() / int(c.frames) if tex != null else 0
		if tex == null or int(c.anchor.y) > tex.get_height() \
				or int(c.anchor.x) <= 0 or int(c.anchor.x) >= cel_w \
				or float(c.h_ref) <= 0.0:
			clip_defects += 1
	_check("every enabled Peggy clip loads with valid cel geometry", clip_defects == 0,
		"defects=%d" % clip_defects)

	# Scale consistency: every enabled clip must render at the idle art scale
	# (runtime scale = idle_art_scale * 74 / h_ref). Sheets drawn at a different
	# art scale carry their own h_ref, so only the known odd-scale sources are
	# exempt: the two guard sheets are drawn ~1.5x larger, and the JPEG-derived
	# crouch_hold is masked from an opaque photo whose scale is estimated.
	var scale_off := []
	for key in PeggyClipLibrary.CLIPS:
		var c: Dictionary = PeggyClipLibrary.CLIPS[key]
		if not c.enabled:
			continue
		if key in ["block_stand", "blockstun_stand", "crouch_hold"]:
			continue
		if absf(float(c.h_ref) - 74.0) > 5.0:
			scale_off.append("%s=%.1f" % [key, float(c.h_ref)])
	_check("enabled clips share the idle art scale (no size popping)", scale_off.is_empty(),
		", ".join(scale_off))

	# Draft-strip playback order: the airborne sheet's last cel is a touchdown
	# crouch and the land sheet starts upright, so the renderer holds the
	# airborne cel and re-orders the landing to absorb-then-recover.
	var p_fall: Dictionary = PeggyClipLibrary.state_clip("jump_fall")
	p1._force_state(FighterBase.State.JUMP_FALL)
	var p_fall_frames := []
	for sf in [0, 4, 12, 40]:
		p1.state_frame = sf
		p_fall_frames.append(p1._clip_frame(p_fall))
	var p_land: Dictionary = PeggyClipLibrary.state_clip("land")
	p1._force_state(FighterBase.State.LAND)
	p1.landing_recovery_frames = 2
	p1.state_frame = 0
	var p_land_first := p1._clip_frame(p_land)
	p1.state_frame = 1
	var p_land_second := p1._clip_frame(p_land)
	_check("Peggy's jump-fall holds the airborne cel for the whole descent",
		p_fall_frames == [0, 0, 0, 0], str(p_fall_frames))
	_check("Peggy's landing absorbs first and recovers on the next frame",
		p_land_first == 1 and p_land_second == 2,
		"first=%d second=%d" % [p_land_first, p_land_second])
	p1._force_state(FighterBase.State.IDLE)

	# Move mapping: every Peggy move ID resolves its intended clip.
	var unmapped_moves := 0
	for move: MoveData in p1.data.moves:
		if PeggyClipLibrary.move_clip(move.id).is_empty():
			unmapped_moves += 1
	var meth_clip := PeggyClipLibrary.move_clip("peggy_meth")
	_check("all 16 authored Peggy move rows resolve a clip", unmapped_moves == 0,
		"unmapped=%d" % unmapped_moves)
	_check("gated and optional clips stay unavailable to the runtime",
		PeggyClipLibrary.move_clip("peggy_meth").is_empty() == false
			and PeggyClipLibrary.state_clip("walk_f").is_empty()
			and PeggyClipLibrary.state_clip("walk_b").is_empty()
			and PeggyClipLibrary.CLIPS["crouch_down"].enabled == false
			and PeggyClipLibrary.CLIPS["stage_intro"].enabled == false
			and PeggyClipLibrary.CLIPS["throw_target"].enabled == false,
		"")

	# Attack phase boundaries: cels map onto authored startup/active/recovery.
	var clip_light: MoveData = p1.data.find_move(MoveData.InputType.LIGHT, MoveData.Stance.STAND)
	var clip_heavy: MoveData = p1.data.find_move(MoveData.InputType.HEAVY, MoveData.Stance.STAND)
	var clip_meth: MoveData = p1.data.meth_move
	p1._force_state(FighterBase.State.ATTACK)
	p1.current_move = clip_light
	p1.state_frame = 0
	_check("light startup starts on cel 0",
		p1._attack_clip_frame(clip_light, 6) == 0, "")
	p1.state_frame = 2
	_check("light keeps its second startup cel through the last startup frame",
		p1._attack_clip_frame(clip_light, 6) == 1, "")
	p1.state_frame = 3
	_check("light switches to the active group exactly at the active frame",
		clip_light.is_active_frame(3) and p1._attack_clip_frame(clip_light, 6) == 2, "")
	p1.state_frame = 4
	_check("light holds the active cel through the last active frame",
		clip_light.is_active_frame(4) and p1._attack_clip_frame(clip_light, 6) == 2, "")
	p1.state_frame = 5
	_check("light enters recovery cels on the first recovery frame",
		not clip_light.is_active_frame(5) and p1._attack_clip_frame(clip_light, 6) == 3, "")
	p1.state_frame = 11
	_check("light clamps to its final recovery cel",
		p1._attack_clip_frame(clip_light, 6) == 5, "")
	p1.current_move = clip_heavy
	p1.state_frame = 6
	_check("heavy maps its longer startup across two cels",
		p1._attack_clip_frame(clip_heavy, 6) == 1, "")
	p1.state_frame = 7
	_check("heavy reaches the active group at frame 7",
		clip_heavy.is_active_frame(7) and p1._attack_clip_frame(clip_heavy, 6) == 2, "")
	p1.state_frame = 9
	_check("heavy holds the active cel through the last active frame",
		clip_heavy.is_active_frame(9) and p1._attack_clip_frame(clip_heavy, 6) == 2, "")
	p1.state_frame = 10
	_check("heavy enters recovery after the active window",
		p1._attack_clip_frame(clip_heavy, 6) == 3, "")
	p1.current_move = clip_meth
	p1.state_frame = 2
	_check("meth spends no cel on its zero-length active phase",
		p1._attack_clip_frame(clip_meth, 6) == 0, "")
	p1.state_frame = 3
	_check("meth starts recovery cels immediately after startup",
		p1._attack_clip_frame(clip_meth, 6) == 1, "")
	p1.state_frame = 26
	_check("meth finishes on its final recovery cel",
		p1._attack_clip_frame(clip_meth, 6) == 5, "")

	# End-to-end attack display: texture, cel count, and no procedural pose
	# transforms stacking on top of the authored animation.
	p1.current_move = clip_light
	p1.state_frame = 3
	p1._sync_visuals()
	var light_tex: Texture2D = p1._clip_texture(PeggyClipLibrary.move_clip("light"))
	_check("light attack displays its authored clip on the art sprite",
		p1.idle_sprite.visible and not p1.character_sprite.visible
			and p1.idle_sprite.texture == light_tex
			and p1.idle_sprite.hframes == 6
			and p1.idle_sprite.frame == 2,
		"frame=%d hframes=%d" % [p1.idle_sprite.frame, p1.idle_sprite.hframes])
	_check("authored attacks disable the procedural pose transforms",
		p1.visual_root.scale == Vector2.ONE and p1.visual_root.rotation == 0.0
			and p1.visual_root.position == Vector2.ZERO,
		"scale=%s rot=%.3f" % [str(p1.visual_root.scale), p1.visual_root.rotation])
	_check("attack clip scale keeps the established body height",
		is_equal_approx(p1.idle_sprite.scale.x,
			p1._idle_art_scale * PeggyClipLibrary.STANDING_REFERENCE_H_REF
				/ float(PeggyClipLibrary.move_clip("light").h_ref)),
		"scale=%.3f" % p1.idle_sprite.scale.x)

	# Repeat attacks reset deterministically; hitstop freezes playback.
	p1.hitstop_frames = 4
	await _step(2)
	var frozen_attack_cel := p1.idle_sprite.frame
	_check("hitstop freezes authored attack playback",
		p1.hitstop_frames == 2 and p1.state_frame == 3
			and p1.idle_sprite.frame == frozen_attack_cel,
		"frame=%d frozen=%d" % [p1.idle_sprite.frame, frozen_attack_cel])
	await _step(2)
	await _step(10)
	p1._start_move(clip_light)
	p1._sync_visuals()
	_check("repeating the same attack restarts the clip at cel 0",
		p1.state_frame == 0 and p1.idle_sprite.frame == 0
			and p1.idle_sprite.texture == light_tex,
		"frame=%d" % p1.idle_sprite.frame)

	# Interruption: a hit during the move swaps to the authored reaction clip.
	p1.hitstun_frames = 12
	p1._force_state(FighterBase.State.HITSTUN)
	p1.state_frame = 3
	p1._sync_visuals()
	var hitstun_tex: Texture2D = p1._clip_texture(PeggyClipLibrary.state_clip("hitstun_stand"))
	_check("hit reactions swap to the authored hitstun clip immediately",
		p1._active_clip.is_empty() == false
			and p1.idle_sprite.texture == hitstun_tex and p1.idle_sprite.hframes == 3,
		"texture_swapped=%s" % str(p1.idle_sprite.texture == hitstun_tex))
	p1.state_frame = 11
	p1._sync_visuals()
	_check("hitstun one-shot clamps to its final cel without looping",
		p1.idle_sprite.frame == 2, "frame=%d" % p1.idle_sprite.frame)

	# Reactions resolve by combat context, including crouching and airborne.
	p1.crouching = true
	p1._sync_visuals()
	var hitstun_crouch_tex: Texture2D = p1._clip_texture(PeggyClipLibrary.state_clip("hitstun_crouch"))
	_check("crouching defenders show the crouched hitstun clip",
		p1.idle_sprite.texture == hitstun_crouch_tex, "")
	p1.crouching = false
	p1.grounded = false
	p1._sync_visuals()
	var hitstun_air_tex: Texture2D = p1._clip_texture(PeggyClipLibrary.state_clip("hitstun_air"))
	_check("airborne defenders show the air hitstun clip",
		p1.idle_sprite.texture == hitstun_air_tex, "")
	p1.grounded = true

	# Holds and one-shots: crouch loops, knockdown fits its authored duration.
	p1._force_state(FighterBase.State.CROUCH)
	p1.state_frame = 0
	p1._sync_visuals()
	var crouch_tex: Texture2D = p1._clip_texture(PeggyClipLibrary.state_clip("crouch"))
	_check("crouch hold loops its authored two cels",
		p1.idle_sprite.texture == crouch_tex and p1.idle_sprite.frame == 0, "")
	p1.state_frame = 12
	p1._sync_visuals()
	_check("crouch hold cadence advances to the second cel",
		p1.idle_sprite.frame == 1, "frame=%d" % p1.idle_sprite.frame)
	p1.state_frame = 24
	p1._sync_visuals()
	_check("crouch hold wraps without leaving the clip",
		p1.idle_sprite.frame == 0 and p1.idle_sprite.texture == crouch_tex,
		"frame=%d" % p1.idle_sprite.frame)

	p1.knockdown_frames = 30
	p1._force_state(FighterBase.State.KNOCKDOWN)
	p1.state_frame = 0
	p1._sync_visuals()
	var knockdown_tex: Texture2D = p1._clip_texture(PeggyClipLibrary.state_clip("knockdown"))
	_check("knockdown plays its authored fall-and-drop clip",
		p1.idle_sprite.texture == knockdown_tex and p1.idle_sprite.frame == 0, "")
	p1.state_frame = 29
	p1._sync_visuals()
	_check("knockdown holds its final downed cel across the authored duration",
		p1.idle_sprite.frame == 3, "frame=%d" % p1.idle_sprite.frame)

	# KO: air cels while airborne, grounded cels after landing, final pose held.
	p1._force_state(FighterBase.State.KO)
	p1.grounded = false
	p1.state_frame = 0
	p1._ko_grounded_frame = 0
	p1._sync_visuals()
	var ko_air_tex: Texture2D = p1._clip_texture(PeggyClipLibrary.state_clip("ko_air"))
	var ko_ground_tex: Texture2D = p1._clip_texture(PeggyClipLibrary.state_clip("ko_ground"))
	_check("KO shows the air clip while airborne",
		p1.idle_sprite.texture == ko_air_tex, "")
	p1.grounded = true
	p1._ko_grounded_frame = 20
	p1._sync_visuals()
	_check("KO switches to the grounded clip on landing",
		p1.idle_sprite.texture == ko_ground_tex, "")
	p1._ko_grounded_frame = 400
	p1._sync_visuals()
	_check("grounded KO holds its final pose forever",
		p1.idle_sprite.frame == 2, "frame=%d" % p1.idle_sprite.frame)

	# Gated walk clips keep the approved static-artwork fallback in place.
	p1._force_state(FighterBase.State.WALK_F)
	p1.state_frame = 10
	p1._sync_visuals()
	_check("gated walk clips leave the approved idle-artwork fallback",
		p1._resolve_visual_clip().is_empty() and p1.idle_sprite.texture == p1._idle_sheet_tex
			and p1.idle_sprite.frame == 0 and p1.idle_sprite.hframes == 4,
		"hframes=%d" % p1.idle_sprite.hframes)

	# ---------------- Authored presentation clips (Richard) ----------------
	_reset_fighters(100.0, 400.0)
	p2._configure_idle_sprite()
	_check("clip test context: p2 is Richard with his own clip library",
		p2.data.id == "whiskey_richard" and p2._clip_library_valid
			and RichardClipLibrary.has_clips("whiskey_richard")
			and not RichardClipLibrary.has_clips("peg_leg_peggy"),
		"p2=%s valid=%s" % [p2.data.id, str(p2._clip_library_valid)])

	# Library integrity: every enabled clip texture loads with a valid single
	# row of integer cels and a sane anchor/scale reference.
	var r_clip_defects := 0
	var r_clip_paths := {}
	for key in RichardClipLibrary.CLIPS:
		var c: Dictionary = RichardClipLibrary.CLIPS[key]
		if not c.enabled:
			continue
		var tex := p2._clip_texture(c)
		var cel_w := tex.get_width() / int(c.frames) if tex != null else 0
		if tex == null or int(c.anchor.y) > tex.get_height() \
				or int(c.anchor.x) <= 0 or int(c.anchor.x) >= cel_w \
				or float(c.h_ref) <= 0.0:
			r_clip_defects += 1
		r_clip_paths[str(c.path)] = true
	_check("every enabled Richard clip loads with valid cel geometry", r_clip_defects == 0,
		"defects=%d" % r_clip_defects)
	_check("all 38 enabled Richard clips point at distinct runtime textures",
		r_clip_paths.size() == 38, "paths=%d" % r_clip_paths.size())

	var r_unmapped := 0
	for move: MoveData in p2.data.moves:
		if RichardClipLibrary.move_clip(move.id).is_empty():
			r_unmapped += 1
	_check("all 16 authored Richard move rows resolve a clip", r_unmapped == 0,
		"unmapped=%d" % r_unmapped)
	_check("Richard's custom move rows map to their intended clips",
		RichardClipLibrary.move_clip("richard_meth").get("path", "").ends_with("/meth.png")
			and RichardClipLibrary.move_clip("richard_command_grab").get("path", "").ends_with("/command_grab.png")
			and RichardClipLibrary.move_clip("richard_neutral").get("path", "").ends_with("/neutral.png")
			and RichardClipLibrary.move_clip("richard_forward_ex").get("path", "").ends_with("/forward_ex.png"),
		"")
	_check("Richard's optional clips stay unavailable to the runtime",
		RichardClipLibrary.CLIPS["stage_intro"].enabled == false
			and RichardClipLibrary.CLIPS["throw_target"].enabled == false,
		"")
	_check("Richard's walk and crouch-hold clips are live (unlike Peggy's gated JPEGs)",
		RichardClipLibrary.state_clip("walk_f").get("path", "").ends_with("/walk_forward.png")
			and RichardClipLibrary.state_clip("walk_b").get("path", "").ends_with("/walk_backward.png")
			and RichardClipLibrary.state_clip("crouch").get("path", "").ends_with("/crouch_hold.png")
			and RichardClipLibrary.CLIPS["crouch_down"].enabled,
		"")

	# --- Jump / landing / walk presentation regressions (2026-11-15) ---
	# Walk cycles wrap instead of clamping on their final cel (the old path froze
	# the last cel and read as a sliding statue while a direction was held).
	var r_walk_b: Dictionary = RichardClipLibrary.state_clip("walk_b")
	p2._force_state(FighterBase.State.WALK_B)
	var walk_frames := []
	for sf in [0, 6, 12, 24, 30, 36, 42]:
		p2.state_frame = sf
		walk_frames.append(p2._clip_frame(r_walk_b))
	_check("Richard's walk cycle wraps instead of freezing on its last cel",
		walk_frames == [0, 1, 2, 4, 5, 0, 1], str(walk_frames))

	# jump_fall holds the airborne cel: the touchdown crouch no longer plays in
	# mid-air, which used to read as standing on invisible ground before landing.
	var r_fall: Dictionary = RichardClipLibrary.state_clip("jump_fall")
	p2._force_state(FighterBase.State.JUMP_FALL)
	var fall_frames := []
	for sf in [0, 3, 6, 20, 60]:
		p2.state_frame = sf
		fall_frames.append(p2._clip_frame(r_fall))
	_check("Richard's jump-fall never plays the touchdown pose mid-air",
		fall_frames == [0, 0, 0, 0, 0], str(fall_frames))

	# Landing plays absorb -> recover. The draft strip starts upright, so the
	# default order popped back to standing before the crouch absorb.
	var r_land: Dictionary = RichardClipLibrary.state_clip("land")
	p2._force_state(FighterBase.State.LAND)
	p2.landing_recovery_frames = 2
	p2.state_frame = 0
	var land_first := p2._clip_frame(r_land)
	p2.state_frame = 1
	var land_second := p2._clip_frame(r_land)
	_check("Richard's landing absorbs first and recovers on the next frame",
		land_first == 1 and land_second == 2,
		"first=%d second=%d" % [land_first, land_second])

	# Guard presentation while holding back: pinned at a wall shows the authored
	# stand guard, crouch-blocking shows the crouch guard, and a mid-screen
	# retreat still plays the walk cycle.
	var r_guard_stand := p2._clip_texture(RichardClipLibrary.state_clip("block_stand"))
	var r_guard_crouch := p2._clip_texture(RichardClipLibrary.state_clip("block_crouch"))
	p2.input_enabled = true
	Input.action_press("p2_right") # p2 faces left, so right is back
	p2._force_state(FighterBase.State.WALK_B)
	p2.position.x = (p2.stage.left_bound + p2.stage.right_bound) * 0.5
	p2.velocity.x = p2.walk_speed_back
	p2._sync_visuals()
	var retreat_tex := p2.idle_sprite.texture
	p2.position.x = p2.stage.right_bound
	p2.velocity.x = p2.walk_speed_back
	p2._sync_visuals()
	var wall_guard := p2.idle_sprite.texture == r_guard_stand
	p2._force_state(FighterBase.State.CROUCH)
	p2._sync_visuals()
	var crouch_guard := p2.idle_sprite.texture == r_guard_crouch
	Input.action_release("p2_right")
	p2.input_enabled = false
	_check("Richard shows the authored stand guard when pinned at the wall",
		wall_guard and retreat_tex != r_guard_stand,
		"wall_guard=%s retreat_guard=%s" % [str(wall_guard), str(retreat_tex == r_guard_stand)])
	_check("Richard shows the authored crouch guard while holding down-back",
		crouch_guard, "")
	p2._force_state(FighterBase.State.IDLE)
	p2.position.x = 400.0
	p2.velocity.x = 0.0

	# Attack phase boundaries: cels map onto authored startup/active/recovery.
	var r_light: MoveData = p2.data.find_move(MoveData.InputType.LIGHT, MoveData.Stance.STAND)
	var r_heavy: MoveData = p2.data.find_move(MoveData.InputType.HEAVY, MoveData.Stance.STAND)
	var r_meth: MoveData = p2.data.meth_move
	p2._force_state(FighterBase.State.ATTACK)
	p2.current_move = r_light
	p2.state_frame = 0
	_check("Richard's light starts on cel 0",
		p2._attack_clip_frame(r_light, 5) == 0, "")
	p2.state_frame = 3
	_check("Richard's light keeps startup cels through the last startup frame",
		p2._attack_clip_frame(r_light, 5) == 0, "")
	p2.state_frame = 4
	_check("Richard's light switches to its active cel exactly at the active frame",
		r_light.is_active_frame(4) and p2._attack_clip_frame(r_light, 5) == 1, "")
	p2.state_frame = 5
	_check("Richard's light holds the active cel through the last active frame",
		r_light.is_active_frame(5) and p2._attack_clip_frame(r_light, 5) == 1, "")
	p2.state_frame = 6
	_check("Richard's light enters recovery cels on the first recovery frame",
		not r_light.is_active_frame(6) and p2._attack_clip_frame(r_light, 5) == 2, "")
	p2.state_frame = 14
	_check("Richard's light clamps to its final recovery cel",
		p2._attack_clip_frame(r_light, 5) == 4, "")
	p2.current_move = r_heavy
	p2.state_frame = 8
	_check("Richard's heavy maps its longer startup across two cels",
		p2._attack_clip_frame(r_heavy, 5) == 1, "")
	p2.state_frame = 9
	_check("Richard's heavy reaches the active group at its active frame",
		r_heavy.is_active_frame(9) and p2._attack_clip_frame(r_heavy, 5) == 2, "")
	p2.state_frame = 11
	_check("Richard's heavy holds the active cel through the last active frame",
		r_heavy.is_active_frame(11) and p2._attack_clip_frame(r_heavy, 5) == 2, "")
	p2.state_frame = 12
	_check("Richard's heavy enters recovery after the active window",
		p2._attack_clip_frame(r_heavy, 5) == 3, "")
	p2.current_move = r_meth
	p2.state_frame = 2
	_check("Richard's meth spends no cel on its zero-length active phase",
		p2._attack_clip_frame(r_meth, 6) == 0, "")
	p2.state_frame = 3
	_check("Richard's meth starts recovery cels immediately after startup",
		p2._attack_clip_frame(r_meth, 6) == 1, "")
	p2.state_frame = 26
	_check("Richard's meth finishes on its final recovery cel",
		p2._attack_clip_frame(r_meth, 6) == 5, "")

	# End-to-end display: texture, cel count, no procedural transform stacking,
	# and the runtime scale the manifest's h_ref implies.
	p2.current_move = r_light
	p2.state_frame = 4
	p2._sync_visuals()
	var r_light_tex: Texture2D = p2._clip_texture(RichardClipLibrary.move_clip("light"))
	_check("Richard's attack displays his authored clip on the art sprite",
		p2.idle_sprite.visible and not p2.character_sprite.visible
			and p2.idle_sprite.texture == r_light_tex
			and p2.idle_sprite.hframes == 5
			and p2.idle_sprite.frame == 1,
		"frame=%d hframes=%d" % [p2.idle_sprite.frame, p2.idle_sprite.hframes])
	_check("Richard's authored attacks disable the procedural pose transforms",
		p2.visual_root.scale == Vector2.ONE and p2.visual_root.rotation == 0.0
			and p2.visual_root.position == Vector2.ZERO,
		"scale=%s rot=%.3f" % [str(p2.visual_root.scale), p2.visual_root.rotation])
	_check("Richard's attack clip scale follows his measured h_ref",
		is_equal_approx(p2.idle_sprite.scale.x,
			p2._idle_art_scale * RichardClipLibrary.STANDING_REFERENCE_H_REF
				/ float(RichardClipLibrary.move_clip("light").h_ref)),
		"scale=%.3f" % p2.idle_sprite.scale.x)

	# Repeat attacks reset deterministically; hitstop freezes playback.
	p2.state_frame = 3
	p2.hitstop_frames = 4
	await _step(2)
	var r_frozen_cel := p2.idle_sprite.frame
	_check("hitstop freezes Richard's authored attack playback",
		p2.hitstop_frames == 2 and p2.state_frame == 3
			and p2.idle_sprite.frame == r_frozen_cel,
		"frame=%d frozen=%d" % [p2.idle_sprite.frame, r_frozen_cel])
	await _step(2)
	await _step(10)
	p2._start_move(r_light)
	p2._sync_visuals()
	_check("repeating Richard's same attack restarts the clip at cel 0",
		p2.state_frame == 0 and p2.idle_sprite.frame == 0
			and p2.idle_sprite.texture == r_light_tex,
		"frame=%d" % p2.idle_sprite.frame)

	# Interruption: a hit during the move swaps to the authored reaction clip.
	p2.hitstun_frames = 12
	p2._force_state(FighterBase.State.HITSTUN)
	p2.state_frame = 3
	p2._sync_visuals()
	var r_hitstun_tex: Texture2D = p2._clip_texture(RichardClipLibrary.state_clip("hitstun_stand"))
	_check("Richard's hit reaction swaps to his authored hitstun clip",
		p2._active_clip.is_empty() == false
			and p2.idle_sprite.texture == r_hitstun_tex and p2.idle_sprite.hframes == 3,
		"texture_swapped=%s" % str(p2.idle_sprite.texture == r_hitstun_tex))
	p2.state_frame = 11
	p2._sync_visuals()
	_check("Richard's hitstun one-shot clamps to its final cel without looping",
		p2.idle_sprite.frame == 2, "frame=%d" % p2.idle_sprite.frame)

	# Both fighters now carry authored sets: representative states and every
	# move row resolve for each, with no cross-contamination of their tables.
	var coverage_gaps := []
	var states_checked := 0
	for fighter in [p1, p2]:
		for state_key in ["walk_f", "walk_b", "crouch", "jump_start", "jump_rise",
				"jump_fall", "land", "block_stand", "block_crouch", "hitstun_stand",
				"hitstun_crouch", "hitstun_air", "blockstun_stand", "blockstun_crouch",
				"knockdown", "wake_up", "tech", "ko_air", "ko_ground", "win",
				"crouch_up_transient"]:
			var enabled_candidate := false
			for cand in fighter._clip_lib.STATE_CLIPS.get(state_key, []):
				var cdef: Dictionary = fighter._clip_lib.CLIPS.get(str(cand), {})
				if cdef.get("enabled", false):
					enabled_candidate = true
			if not enabled_candidate:
				continue  # intentionally gated (e.g. Peggy's JPEG walk)
			states_checked += 1
			if fighter._clip_lib.state_clip(state_key).is_empty():
				coverage_gaps.append("%s:%s" % [fighter.data.id, state_key])
		for move: MoveData in fighter.data.moves:
			if fighter._clip_lib.move_clip(move.id).is_empty():
				coverage_gaps.append("%s:move:%s" % [fighter.data.id, move.id])
	_check("both fighters resolve every enabled authored state and move clip",
		coverage_gaps.is_empty() and states_checked >= 36,
		"states=%d %s" % [states_checked, ", ".join(coverage_gaps)])

	# Round reset clears all presentation-clip playback state.
	p1._transient_clip_key = "crouch_up"
	p1._transient_clip_tick = 3
	p1._ko_grounded_frame = 9
	p1.begin_round(Vector2(100, 150), 200.0)
	_check("round reset clears presentation-clip playback state",
		p1._transient_clip_key == "" and p1._transient_clip_tick == 0
			and p1._ko_grounded_frame == 0 and p1._active_clip.is_empty(),
		"")

	print("\n%d failure(s)" % failures)
	quit(1 if failures > 0 else 0)
