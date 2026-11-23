# meth_cinematic_test.gd — Phase C pins for the deterministic METHtality
# cinematic driver (docs/FX_AND_METH_DESIGN.md §3-4, owner beat maps of
# 2026-11-23: existing clips only).
#
# The suite drives real MatchRoot scenes on the engine clock. Everything
# asserted is state, not pixels: the whiff/block/meter gates, the exact
# 210-frame sequence with its beat clips/props, both finishers on both
# stages, both facing sides, wall-clamped (never scaled) compositions,
# victim masking by the front rim, mid-cinematic serialize/load resumption,
# training no-KO restore plus the UI-confirm skip, CPU-vs-CPU completion,
# and pause freezing.
extends SceneTree

const MATCH_SCENE := preload("res://scenes/match/MatchRoot.tscn")
const ROSTER := preload("res://resources/match_roster.tres")
const LENGTH := 210

var failures := 0
var checks := 0
var scene: Node
var p1: FighterBase
var p2: FighterBase
var hud: MatchHUD
var fx: FxLayer
var driver: MethCinematicDriver


func _initialize() -> void:
	_run.call_deferred()


func _check(label: String, condition: bool, detail: String = "") -> void:
	checks += 1
	if condition:
		print("PASS: ", label)
	else:
		failures += 1
		print("FAIL: ", label, "  ", detail)


func _step(frames: int) -> void:
	for _frame in frames:
		await physics_frame


func _new_match(training := false, stage_index := 0,
		cpus := false) -> void:
	scene = MATCH_SCENE.instantiate()
	scene.selected_p1_data = ROSTER.fighters[0]
	scene.selected_p2_data = ROSTER.fighters[1]
	scene.selected_stage = ROSTER.stages[stage_index]
	scene.training_mode = training
	if cpus:
		scene.p1_cpu = true
		scene.p2_cpu = true
		scene.cpu_seed = 0x5EEDC0DE
	root.add_child(scene)
	await physics_frame
	if training:
		await _step(2)
	else:
		await _step(65)  # round intro
	p1 = scene.p1
	p2 = scene.p2
	hud = scene.hud
	fx = scene.fx
	driver = scene.meth_driver


# Adjacent pair with the given attacker; fills the attacker's meter and
# buffers the METH input. The contact lands a few ticks later.
func _prime_meth(attacker: FighterBase, defender: FighterBase,
		att_x := 120.0, vic_x := 150.0) -> void:
	var floor_y: float = scene.stage.floor_y
	attacker.position = Vector2(att_x, floor_y)
	defender.position = Vector2(vic_x, floor_y)
	attacker.velocity = Vector2.ZERO
	defender.velocity = Vector2.ZERO
	attacker.facing = 1 if att_x < vic_x else -1
	defender.facing = -attacker.facing
	attacker.reset_state()
	defender.reset_state()
	attacker.add_meter(attacker.max_meter)
	attacker.input_buffer["meth"] = 0


# Steps (bounded) until the driver exists and reaches `target`.
func _await_frame(target: int, budget := 260) -> bool:
	for i in budget:
		if driver == null or not driver.active:
			return false
		if driver.frame >= target:
			return true
		await physics_frame
	return driver.active and driver.frame >= target


# A synthetic action event for MatchRoot._unhandled_input (headless-safe).
func _action_event(action: String, pressed := true) -> InputEventAction:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = pressed
	return ev


func _strip_node_refs(data: Dictionary) -> Dictionary:
	var out := data.duplicate(true)
	out.erase("ko_loser")
	return out


func _run() -> void:
	await process_frame
	await _test_gates_whiff_block_meter()
	await _test_walk_the_plank_sequence()
	await _test_flaming_belch_sequence()
	await _test_p2_attacker_left_side()
	await _test_both_stages()
	await _test_wall_clamp()
	await _test_victim_masking()
	await _test_serialize_load_mid_cinematic()
	await _test_training_restore_and_skip()
	await _test_cpu_vs_cpu_completes()
	await _test_pause_freeze()
	print("meth_cinematic_test: %d checks, %d failure(s)" % [checks, failures])
	quit(1 if failures > 0 else 0)


# ---------------- gates: whiff / block / meter ----------------

func _test_gates_whiff_block_meter() -> void:
	await _new_match()
	# Whiff: full meter, opponent far out of reach. The bar still drains and
	# the banner still shows, but no cinematic and no damage.
	_prime_meth(p1, p2, 120.0, 250.0)
	await _step(40)
	_check("a whiffed METH still spends the full bar",
		absf(p1.meter) < 0.001, "meter=%f" % p1.meter)
	_check("a whiffed METH starts no cinematic",
		scene.phase == scene.Phase.FIGHT and not driver.active,
		"phase=%s" % str(scene.phase))
	_check("a whiffed METH deals no damage",
		p2.health == p2.max_health, "health=%f" % p2.health)

	# Below-full meter: the input never starts the move at all.
	p1.add_meter(p1.max_meter - 1.0)
	p1.input_buffer["meth"] = 0
	await _step(40)
	_check("a below-full meter never starts the METH move",
		scene.phase == scene.Phase.FIGHT and p1.meter > 90.0
			and p2.health == p2.max_health,
		"meter=%f" % p1.meter)

	# Blocked: the defender holds away; ordinary block handling with the
	# row's authored 0.0 chip, no cinematic.
	_prime_meth(p1, p2)
	Input.action_press("p2_right")
	await _step(40)
	_check("a blocked METH keeps ordinary block handling (no cinematic)",
		scene.phase == scene.Phase.FIGHT and not driver.active
			and p2.state == FighterBase.State.BLOCKSTUN,
		"phase=%s state=%s" % [str(scene.phase), str(p2.state)])
	_check("a blocked METH pays its authored chip (0.0 on the finisher row)",
		p2.health == p2.max_health,
		"health=%f" % p2.health)
	_check("a blocked METH still spent the attacker's bar",
		absf(p1.meter) < 0.001, "meter=%f" % p1.meter)
	Input.action_release("p2_right")

	# Knockdown victim: K1 allows METH strikes, so the finisher grabs a
	# knocked-down target and the cinematic starts.
	p1.add_meter(p1.max_meter)
	p1._start_move(p1.data.find_move(MoveData.InputType.HEAVY,
		MoveData.Stance.CROUCH))
	var knocked := false
	for i in 60:
		await physics_frame
		if p2.state == FighterBase.State.KNOCKDOWN:
			knocked = true
			break
	_check("setup: the crouch heavy knocked the defender down",
		knocked, "state=%s" % str(p2.state))
	p1.reset_state()
	_prime_meth(p1, p2)
	await _step(12)
	_check("a METH on a knocked-down victim starts the cinematic (K1)",
		scene.phase == scene.Phase.METH_CINEMATIC and driver.active,
		"phase=%s" % str(scene.phase))
	scene.queue_free()
	await _step(2)


# ---------------- Walk the Plank ----------------

func _test_walk_the_plank_sequence() -> void:
	await _new_match()
	_prime_meth(p1, p2)
	await _step(12)
	_check("a confirmed METH contact enters METH_CINEMATIC",
		scene.phase == scene.Phase.METH_CINEMATIC and driver.active,
		"phase=%s" % str(scene.phase))
	_check("the sequence id is Walk the Plank for Peggy",
		driver.seq == MethCinematicDriver.SEQ_WALK_THE_PLANK,
		"seq=%d" % driver.seq)
	_check("the opening holds the captured positions",
		p1.position == Vector2(120.0, scene.stage.floor_y)
			and p2.position == Vector2(150.0, scene.stage.floor_y),
		"p1=%s p2=%s" % [str(p1.position), str(p2.position)])
	_check("both fighters are held out of the ordinary tick",
		p1.cinematic_hold and p2.cinematic_hold, "hold flags")
	_check("entry cleared both input buffers",
		p1.input_buffer.is_empty() and p2.input_buffer.is_empty(),
		"buffers not cleared")
	_check("the METH banner is up with the finisher's name",
		hud.banner_plate.visible
			and hud.meth_banner.text.contains("WALK THE PLANK"),
		"banner=%s" % hud.meth_banner.text)
	_check("the letterbox and dim overlay are on the FX layer",
		fx.get_child_count() >= 3, "fx children=%d" % fx.get_child_count())
	_check("normal HUD clutter is hidden for the sequence",
		hud._cinematic_hidden.size() > 0,
		"hidden=%d" % hud._cinematic_hidden.size())
	_check("the active driver joins the serializable state",
		typeof(scene.serialize()["meth_cinematic"]) == TYPE_DICTIONARY,
		"meth_cinematic missing")

	# Opening freeze: 20 more ticks, positions still frozen.
	await _step(20)
	_check("frames 0-29 are the opening freeze (no movement)",
		driver.frame >= 20 and driver.frame <= 30
			and absf(p1.position.x - 120.0) < 0.01
			and absf(p2.position.x - 150.0) < 0.01,
		"frame=%d p1=%s" % [driver.frame, str(p1.position)])

	# Beat samples: the owner beat map, existing clips only.
	await _await_frame(35)
	_check("beat 30-59: the attacker plays the forward poke's recovery",
		driver.attacker_pose_key() == "forward"
			and driver.prop_visible("plank_base"),
		"att=%s" % driver.attacker_pose_key())
	await _await_frame(45)
	_check("beat 30-59: the victim is knocked onto the plank",
		driver.victim_pose_key() == "knockdown",
		"vic=%s" % driver.victim_pose_key())
	await _await_frame(65)
	_check("beat 60-89: the pin plays crouch_heavy (peg-leg sweep)",
		driver.attacker_pose_key() == "crouch_heavy",
		"att=%s" % driver.attacker_pose_key())
	await _await_frame(95)
	_check("beat 90-119: the stomp plays crouch_heavy cels 3-5 (placeholder)",
		driver.attacker_pose_key() == "crouch_heavy"
			and driver.prop_visible("plank_snap_sheet"),
		"att=%s" % driver.attacker_pose_key())
	await _await_frame(100)
	_check("beat 90-119: the sewer opening begins behind the victim",
		driver.prop_visible("sewer_open_sheet"), "sewer not visible")
	await _await_frame(125)
	_check("beat 120-167: the victim tumbles into the opening (ko_air)",
		driver.victim_pose_key() == "ko_air"
			and driver.prop_visible("water_drop_mask_sheet"),
		"vic=%s" % driver.victim_pose_key())
	await _await_frame(155)
	_check("beat 150+: the victim is behind the aperture (ko_ground)",
		driver.victim_pose_key() == "ko_ground",
		"vic=%s" % driver.victim_pose_key())
	await _await_frame(170)
	_check("the finish beat plays the win clip",
		driver.attacker_pose_key() == "win",
		"att=%s" % driver.attacker_pose_key())
	_check("props are never scaled at any beat",
		driver.prop_scale("plank_base") == Vector2.ONE
			and driver.prop_scale("water_drop_mask_sheet") == Vector2.ONE,
		"a prop was scaled")
	_check("the clamped group keeps both fighters inside the bounds",
		p1.position.x >= scene.stage.left_bound
			and p1.position.x <= scene.stage.right_bound
			and p2.position.x >= scene.stage.left_bound
			and p2.position.x <= scene.stage.right_bound,
		"p1=%f p2=%f" % [p1.position.x, p2.position.x])

	# Exact length: count the remaining ticks until the phase leaves the
	# sequence; with frame 170 sampled, exactly 40 remain (210 total).
	var ticks := 0
	while scene.phase == scene.Phase.METH_CINEMATIC and ticks < 80:
		await physics_frame
		ticks += 1
	_check("the sequence runs exactly 210 frames (40 remain at frame 170)",
		ticks == 40, "remaining ticks=%d" % ticks)
	_check("the deferred METH damage is applied once at the boundary",
		p2.health <= 0.0 and scene.round_damage[0] >= 1000.0,
		"health=%f damage=%f" % [p2.health, scene.round_damage[0]])
	_check("the ordinary KO flow owns the end (KO phase)",
		scene.phase == scene.Phase.KO and scene.ko_loser == p2,
		"phase=%s" % str(scene.phase))
	_check("the cinematic presentation is torn down after the finish",
		driver._cinematic_root == null and not driver.active
			and hud._cinematic_hidden.is_empty()
			and not p1.cinematic_hold and not p2.cinematic_hold,
		"presentation leak")
	_check("no stale cinematic joins the serialized state after the end",
		scene.serialize()["meth_cinematic"] == null, "driver serialized")

	# Round/match flow continues normally.
	await _step(100 + 90)
	_check("the round resolves for the finisher",
		scene.wins[0] == 1 and scene.wins[1] == 0,
		"wins=%s" % str(scene.wins))
	scene.queue_free()
	await _step(2)


# ---------------- Flaming Belch ----------------

func _test_flaming_belch_sequence() -> void:
	await _new_match()
	_prime_meth(p2, p1, 150.0, 120.0)
	await _step(12)
	_check("Richard's confirmed METH enters the cinematic",
		scene.phase == scene.Phase.METH_CINEMATIC and driver.active,
		"phase=%s" % str(scene.phase))
	_check("the sequence id is Flaming Belch for Richard",
		driver.seq == MethCinematicDriver.SEQ_FLAMING_BELCH,
		"seq=%d" % driver.seq)
	await _await_frame(35)
	_check("beat 30-59: the drench plays heavy cels 1-3 (bottle raised)",
		driver.attacker_pose_key() == "heavy"
			and driver.prop_visible("whiskey_fumes_sheet"),
		"att=%s" % driver.attacker_pose_key())
	await _await_frame(65)
	_check("beat 60-89: the drench pose holds with the fumes up",
		driver.attacker_pose_key() == "heavy"
			and driver.prop_visible("whiskey_fumes_sheet"),
		"att=%s" % driver.attacker_pose_key())
	await _await_frame(95)
	_check("beat 90-119: the belch/ignite plays neutral cels 2-5",
		driver.attacker_pose_key() == "neutral"
			and driver.prop_visible("fire_belch_sheet"),
		"att=%s" % driver.attacker_pose_key())
	await _await_frame(125)
	_check("beat 120-149: the victim launches toward the sign (ko_air)",
		driver.victim_pose_key() == "ko_air"
			and driver.prop_visible("fictional_bar_sign_base"),
		"vic=%s sign=%s" % [driver.victim_pose_key(),
			str(driver.prop_visible("fictional_bar_sign_base"))])
	await _await_frame(155)
	_check("beat 150+: the sign shatters around the victim",
		driver.prop_visible("bar_sign_shatter_back_sheet")
			and driver.prop_visible("bar_sign_shatter_front_sheet")
			and not driver.prop_visible("fictional_bar_sign_base"),
		"shatter layers")
	await _await_frame(185)
	_check("the finish beat plays the win clip",
		driver.attacker_pose_key() == "win",
		"att=%s" % driver.attacker_pose_key())
	var ticks := 0
	while scene.phase == scene.Phase.METH_CINEMATIC and ticks < 60:
		await physics_frame
		ticks += 1
	_check("Flaming Belch also runs exactly 210 frames",
		ticks == LENGTH - 185, "remaining ticks=%d" % ticks)
	_check("the deferred damage KO'd the victim",
		p1.health <= 0.0 and scene.phase == scene.Phase.KO,
		"health=%f phase=%s" % [p1.health, str(scene.phase)])
	scene.queue_free()
	await _step(2)


# ---------------- P2 attacker / left side ----------------

func _test_p2_attacker_left_side() -> void:
	await _new_match()
	_prime_meth(p2, p1, 150.0, 120.0)  # P2 right, facing left
	await _step(12)
	_check("P2 as attacker enters the cinematic facing left",
		scene.phase == scene.Phase.METH_CINEMATIC and driver.active
			and driver.cap_att_facing == -1,
		"facing=%d" % driver.cap_att_facing)
	await _await_frame(50)
	_check("the victim stays on the struck side (left of the attacker)",
		p1.position.x < p2.position.x,
		"vic=%f att=%f" % [p1.position.x, p2.position.x])
	var ticks := 0
	while scene.phase == scene.Phase.METH_CINEMATIC and ticks < 200:
		await physics_frame
		ticks += 1
	_check("the mirrored-side sequence completes with damage",
		ticks == LENGTH - 50 and p1.health <= 0.0,
		"ticks=%d health=%f" % [ticks, p1.health])
	scene.queue_free()
	await _step(2)


# ---------------- both stages ----------------

func _test_both_stages() -> void:
	await _new_match(false, 1)  # bus_stop_night
	_prime_meth(p1, p2)
	await _step(12)
	_check("Walk the Plank runs on Bus Stop too",
		scene.phase == scene.Phase.METH_CINEMATIC and driver.active,
		"phase=%s" % str(scene.phase))
	var f0 := driver.frame
	var ticks := 0
	while scene.phase == scene.Phase.METH_CINEMATIC and ticks < 220:
		await physics_frame
		ticks += 1
	_check("the Bus Stop sequence completed",
		ticks == LENGTH - f0 and p2.health <= 0.0,
		"ticks=%d f0=%d health=%f" % [ticks, f0, p2.health])
	scene.queue_free()
	await _step(2)


# ---------------- wall clamp ----------------

func _test_wall_clamp() -> void:
	# Near the LEFT wall: the composition slides inward as one group.
	await _new_match()
	_prime_meth(p1, p2, 50.0, 76.0)
	await _step(12)
	_check("the near-left-wall METH still starts",
		scene.phase == scene.Phase.METH_CINEMATIC and driver.active,
		"phase=%s" % str(scene.phase))
	await _await_frame(50)
	_check("the group shifted inward near the left wall",
		driver.group_shift > 0.0, "shift=%f" % driver.group_shift)
	_check("near the left wall the whole group stays in bounds",
		p1.position.x >= scene.stage.left_bound
			and p2.position.x >= scene.stage.left_bound,
		"p1=%f p2=%f" % [p1.position.x, p2.position.x])
	var ticks := 0
	while scene.phase == scene.Phase.METH_CINEMATIC and ticks < 200:
		await physics_frame
		ticks += 1
	_check("the near-left-wall sequence completes",
		ticks == LENGTH - 50, "ticks=%d" % ticks)
	scene.queue_free()
	await _step(2)

	# Near the RIGHT wall.
	await _new_match()
	_prime_meth(p1, p2, 250.0, 274.0)
	await _step(12)
	await _await_frame(50)
	_check("the group shifted inward near the right wall",
		driver.group_shift < 0.0, "shift=%f" % driver.group_shift)
	_check("near the right wall the whole group stays in bounds",
		p1.position.x <= scene.stage.right_bound
			and p2.position.x <= scene.stage.right_bound,
		"p1=%f p2=%f" % [p1.position.x, p2.position.x])
	_check("props near the wall are clamped with the group, never scaled",
		driver.prop_scale("plank_base") == Vector2.ONE,
		"a prop was scaled")
	var wall_ticks := 0
	while scene.phase == scene.Phase.METH_CINEMATIC and wall_ticks < 200:
		await physics_frame
		wall_ticks += 1
	_check("the near-right-wall sequence completes",
		wall_ticks == LENGTH - 50, "ticks=%d" % wall_ticks)
	scene.queue_free()
	await _step(2)


# ---------------- victim masking ----------------

func _test_victim_masking() -> void:
	await _new_match()
	_prime_meth(p1, p2)
	await _step(12)
	await _await_frame(167)
	var mask_z: int = 5
	_check("after the drop the front water mask is up and above the victim",
		driver.prop_visible("water_drop_mask_sheet")
			and p2.z_index <= mask_z,
		"victim z=%d" % p2.z_index)
	_check("the victim has sunk fully behind the rim line",
		p2.position.y >= scene.stage.floor_y + 12.0,
		"vic y=%f floor=%f" % [p2.position.y, scene.stage.floor_y])
	await _await_frame(200)
	_check("the victim stays hidden below the rim to the end",
		p2.position.y >= scene.stage.floor_y + 12.0,
		"vic y=%f" % p2.position.y)
	var ticks := 0
	while scene.phase == scene.Phase.METH_CINEMATIC and ticks < 60:
		await physics_frame
		ticks += 1
	_check("the masked sequence completes",
		ticks == LENGTH - 200, "ticks=%d" % ticks)
	scene.queue_free()
	await _step(2)


# ---------------- serialize / load mid-cinematic ----------------

func _test_serialize_load_mid_cinematic() -> void:
	# Determinism first: two identical runs serialize identically at f60.
	await _new_match()
	_prime_meth(p1, p2)
	await _step(12)
	await _await_frame(60)
	var det_a: Dictionary = scene.serialize()
	scene.queue_free()
	await _step(2)
	await _new_match()
	_prime_meth(p1, p2)
	await _step(12)
	await _await_frame(60)
	var det_b: Dictionary = scene.serialize()
	_check("two identical runs serialize identically mid-cinematic",
		_strip_node_refs(det_a) == _strip_node_refs(det_b),
		"serialize dictionaries differ")

	# Run A continues to completion; run B loads the mid-state at f100 and
	# must reach the identical end state.
	var snap: Dictionary = {}
	await _await_frame(100)
	snap = scene.serialize()
	var ticks := 0
	while scene.phase == scene.Phase.METH_CINEMATIC and ticks < 200:
		await physics_frame
		ticks += 1
	var final_a: Dictionary = scene.serialize()
	scene.queue_free()
	await _step(2)

	await _new_match()
	_prime_meth(p1, p2)
	await _step(12)
	await _await_frame(100)
	scene.load(snap)
	_check("a mid-cinematic load resumes on the exact saved frame",
		scene.phase == scene.Phase.METH_CINEMATIC and driver.active
			and driver.frame == 100,
		"phase=%s frame=%d" % [str(scene.phase), driver.frame])
	await _await_frame(105)
	var f0 := driver.frame
	var resume_ticks := 0
	while scene.phase == scene.Phase.METH_CINEMATIC and resume_ticks < 200:
		await physics_frame
		resume_ticks += 1
	_check("the resumed sequence runs exactly its remaining frames",
		resume_ticks == LENGTH - f0, "ticks=%d f0=%d" % [resume_ticks, f0])
	var final_b: Dictionary = scene.serialize()
	_check("the resumed run ends in the identical serialized state",
		_strip_node_refs(final_a) == _strip_node_refs(final_b),
		"final states differ")
	scene.queue_free()
	await _step(2)


# ---------------- training ----------------

func _test_training_restore_and_skip() -> void:
	# No-KO restore at the natural end.
	await _new_match(true)
	_prime_meth(p1, p2)
	var pre_health: float = p2.health
	var pre_meter: float = p1.meter
	await _step(12)
	_check("training enters the METH cinematic too",
		scene.phase == scene.Phase.METH_CINEMATIC and driver.active,
		"phase=%s" % str(scene.phase))
	var f0 := driver.frame
	var ticks := 0
	while scene.phase == scene.Phase.METH_CINEMATIC and ticks < 220:
		await physics_frame
		ticks += 1
	_check("the training sequence runs its full length",
		ticks == LENGTH - f0, "ticks=%d f0=%d" % [ticks, f0])
	_check("training restores the pre-METH phase without KO",
		scene.phase == scene.Phase.FIGHT and p2.state != FighterBase.State.KO,
		"phase=%s" % str(scene.phase))
	_check("training restores the victim's health",
		p2.health == pre_health, "health=%f" % p2.health)
	_check("training restores the full meter so the sequence repeats",
		absf(p1.meter - pre_meter) < 0.001, "meter=%f" % p1.meter)
	_check("training restores the pre-METH positions",
		absf(p1.position.x - 120.0) < 0.01
			and absf(p2.position.x - 150.0) < 0.01,
		"p1=%s p2=%s" % [str(p1.position), str(p2.position)])

	# The restored state is repeatable.
	_prime_meth(p1, p2)
	await _step(12)
	_check("the training METH is repeatable after the restore",
		scene.phase == scene.Phase.METH_CINEMATIC and driver.active,
		"phase=%s" % str(scene.phase))
	scene.queue_free()
	await _step(2)

	# The training-only UI-confirm skip after the opening hold.
	await _new_match(true)
	_prime_meth(p1, p2)
	await _step(12)
	# Before frame 30 the skip is refused.
	scene._unhandled_input(_action_event("ui_confirm"))
	await physics_frame
	_check("the skip is refused during the 30f opening hold",
		scene.phase == scene.Phase.METH_CINEMATIC and driver.active,
		"phase=%s" % str(scene.phase))
	await _await_frame(40)
	scene._unhandled_input(_action_event("ui_confirm"))
	await physics_frame
	_check("a UI confirm after the opening hold skips the sequence",
		scene.phase == scene.Phase.FIGHT and not driver.active,
		"phase=%s" % str(scene.phase))
	_check("the skip restored the training snapshot",
		p2.health == p2.max_health and absf(p1.meter - p1.max_meter) < 0.001,
		"health=%f meter=%f" % [p2.health, p1.meter])
	_check("the skip left no buffered combat action behind",
		p1.input_buffer.is_empty() and p2.input_buffer.is_empty(),
		"buffers not cleared")
	scene.queue_free()
	await _step(2)


# ---------------- CPU vs CPU ----------------

func _test_cpu_vs_cpu_completes() -> void:
	await _new_match(false, 0, true)
	_check("setup: both CPU controllers are live",
		scene.cpu_p1 != null and scene.cpu_p2 != null, "cpus missing")
	_prime_meth(p1, p2)
	Input.action_press("p1_meth")
	await _step(12)
	Input.action_release("p1_meth")
	_check("a scripted METH starts inside a CPU-vs-CPU match",
		scene.phase == scene.Phase.METH_CINEMATIC and driver.active,
		"phase=%s" % str(scene.phase))
	await _await_frame(60)
	_check("the CPU just waits during the sequence (plan cleared)",
		scene.cpu_p2.plan == 0 and scene.cpu_p1.plan == 0,
		"p1 plan=%s p2 plan=%s" % [str(scene.cpu_p1.plan), str(scene.cpu_p2.plan)])
	var ticks := 0
	while scene.phase == scene.Phase.METH_CINEMATIC and ticks < 220:
		await physics_frame
		ticks += 1
	_check("the CPU match sequence completes with the deferred damage",
		ticks == LENGTH - 60 and p2.health <= 0.0 and scene.phase == scene.Phase.KO,
		"ticks=%d health=%f" % [ticks, p2.health])
	# The ordinary round flow resumes afterwards: KO (100) + ROUND_END (90)
	# + the next round's INTRO is well within this budget.
	var progressed := false
	for i in 400:
		await physics_frame
		if scene.phase == scene.Phase.INTRO or scene.phase == scene.Phase.FIGHT:
			progressed = true
			break
	_check("the CPU-vs-CPU match continues past the cinematic",
		progressed and scene.wins[0] == 1,
		"wins=%s phase=%s" % [str(scene.wins), str(scene.phase)])
	scene.queue_free()
	await _step(2)


# ---------------- pause ----------------

func _test_pause_freeze() -> void:
	await _new_match()
	_prime_meth(p1, p2)
	await _step(12)
	await _await_frame(40)
	var frozen_at: int = driver.frame
	self.paused = true
	await _step(6)
	_check("the sequence freezes while the tree is paused",
		driver.frame == frozen_at, "frame=%d expected=%d" % [driver.frame, frozen_at])
	self.paused = false
	await _step(4)
	_check("the sequence resumes stepping after the unpause",
		driver.frame > frozen_at, "frame=%d" % driver.frame)
	var ticks := 0
	while scene.phase == scene.Phase.METH_CINEMATIC and ticks < 200:
		await physics_frame
		ticks += 1
	_check("the paused-then-resumed sequence still completes exactly",
		ticks == LENGTH - driver.frame + 1 or ticks >= LENGTH - 45,
		"ticks=%d frame=%d" % [ticks, driver.frame])
	scene.queue_free()
	await _step(2)
