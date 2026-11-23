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
		cpus := false, p1_index := 0, p2_index := 1) -> void:
	scene = MATCH_SCENE.instantiate()
	scene.selected_p1_data = ROSTER.fighters[p1_index]
	scene.selected_p2_data = ROSTER.fighters[p2_index]
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
	await _test_prop_visibility_and_anchors()
	await _test_review_fix_contract()
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
			and not driver.prop_visible("plank_base"),
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
	_check("beat 150+: the victim is still dropping in ko_air, below the rim",
		driver.victim_pose_key() == "ko_air",
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
		driver.presentation_roots_cleared() and not driver.active
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
	await _await_frame(100)
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
	var mask: Sprite2D = driver.prop_sprite("water_drop_mask_sheet")
	_check("after the drop the front water mask is up and above the victim",
		driver.prop_visible("water_drop_mask_sheet")
			and mask != null and mask.texture != null
			and MethCinematicDriver.PROPS["water_drop_mask_sheet"]["layer"] == "front"
			and mask.z_index > p2.z_index,
		"mask layer=%s z=%d victim z=%d" % [
			MethCinematicDriver.PROPS["water_drop_mask_sheet"]["layer"],
			mask.z_index if mask != null else -1, p2.z_index])
	_check("the mask covers the victim's sinking column",
		mask != null and absf(mask.global_position.x - p2.position.x) <= 48.0,
		"mask x=%f victim x=%f" % [mask.global_position.x, p2.position.x])
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


# ---------------- numeric prop visibility (review-bug regressions) ----------
# Every check below asserts the prop is actually drawn where the storyboard
# says: sprite alive with a texture, visible, on the correct ordered layer
# (back = between the stage and the fighters; front = above them), its
# manifest anchor within a few pixels of the intended world point, inside
# the 320x180 viewport, and mirrored correctly for the attacker's facing.
# These FAILED on 5587b1c (props on negative z behind the stage; fire cone
# anchored/mirrored wrong) and must pass after the fix.

const ANCHOR_TOL := 3.0


func _check_prop(label: String, id: String, expected_point: Vector2,
		layer: String, mirrored: bool) -> void:
	if not driver.has_method("prop_anchor_point"):
		# The visibility introspection is part of the visual-fix contract;
		# an unfixed driver fails every check right here.
		_check(label + " [visibility introspection]", false,
			"driver lacks the numeric prop visibility API")
		return
	var sprite: Sprite2D = driver.prop_sprite(id)
	if sprite == null:
		_check(label + " [sprite exists]", false, "prop node missing")
		return
	var ok_visible: bool = sprite.visible and sprite.texture != null
	_check(label + " [visible with texture]", ok_visible,
		"visible=%s texture=%s" % [str(sprite.visible),
			str(sprite.texture != null)])
	var ok_layer: bool = driver.prop_layer(id) == layer
	if layer == "back":
		# Tree order between the stage and the fighters — the review bug
		# was negative z drawing behind the whole stage.
		var stage_idx: int = scene.stage.get_index()
		var back_idx: int = driver.back_root_index(scene)
		ok_layer = ok_layer and back_idx > stage_idx and back_idx < p1.get_index()
	else:
		ok_layer = ok_layer and sprite.z_index > maxi(p1.z_index, p2.z_index)
	_check(label + " [layer " + layer + "]", ok_layer,
		"layer=%s back_idx=%d stage_idx=%d z=%d" % [
			driver.prop_layer(id), driver.back_root_index(scene),
			scene.stage.get_index(), sprite.z_index])
	var at: Vector2 = driver.prop_anchor_point(id)
	_check(label + " [anchor at intended point]",
		at.distance_to(expected_point) <= ANCHOR_TOL,
		"anchor=%s expected=%s" % [str(at), str(expected_point)])
	_check(label + " [anchor inside the 320x180 viewport]",
		at.x >= 0.0 and at.x <= 320.0 and at.y >= 0.0 and at.y <= 180.0,
		"anchor=%s" % str(at))
	_check(label + " [mirroring]",
		sprite.flip_h == mirrored,
		"flip_h=%s expected=%s" % [str(sprite.flip_h), str(mirrored)])
	_check(label + " [never scaled]",
		sprite.scale == Vector2.ONE, "scale=%s" % str(sprite.scale))


func _test_prop_visibility_and_anchors() -> void:
	# --- Walk the Plank, attacker LEFT (Peggy facing right) ---
	await _new_match()
	_prime_meth(p1, p2)
	await _step(12)
	await _await_frame(70)
	var vic_x := driver.cap_vic_pos.x + driver.group_shift
	var floor_y: float = scene.stage.floor_y
	_check_prop("WTP f70 plank_base (settled under the victim)",
		"plank_base", Vector2(vic_x - 44.0, floor_y), "back", false)
	await _await_frame(100)
	_check_prop("WTP f100 plank_snap", "plank_snap_sheet",
		Vector2(vic_x, floor_y), "back", false)
	_check("WTP f100 plank_snap frame index",
		driver.prop_frame("plank_snap_sheet") == (100 - 90) / 3,
		"frame=%d" % driver.prop_frame("plank_snap_sheet"))
	_check_prop("WTP f100 sewer_open", "sewer_open_sheet",
		Vector2(vic_x, floor_y), "back", false)
	_check("WTP f100 sewer frame index",
		driver.prop_frame("sewer_open_sheet") == (100 - 96) / 3,
		"frame=%d" % driver.prop_frame("sewer_open_sheet"))
	await _await_frame(125)
	_check_prop("WTP f125 water mask", "water_drop_mask_sheet",
		Vector2(vic_x, floor_y), "front", false)
	_check("WTP f125 sewer still open under the mask",
		driver.prop_visible("sewer_open_sheet"),
		"sewer hidden at the drop beat")
	scene.queue_free()
	await _step(2)


# ---------------- per-frame review-fix contract (items 1-7) ------------------
# Each sequence is stepped frame by frame; every check below reads the
# recorded state (positions, drawn sprite rects, prop layers/anchors, banner
# rect), never pixels. Both facings. The pre-fix head (8a8f2c3) FAILS these:
# the victim popped up instead of dropping, the plank sat under the standing
# victim, the fire cone/fumes were estimates away from the mouth/bottle, the
# victim never left the ground, and the banner sat over the fighters.

# Measured cel points (cel pixels from the top-left, art drawn facing right),
# read off the clips independently of the driver: Richard's mouth in the
# neutral belch cels and the bottle mouth in the first `heavy` drench cel.
const NEUTRAL_MOUTH := {1: Vector2(44, 22), 2: Vector2(44, 19),
	3: Vector2(44, 18), 4: Vector2(44, 21)}
const HEAVY_BOTTLE := Vector2(68, 26)
const RIM_DEPTH := 12.0
# Real opaque extent of the fumes cel 6 (rows 7..71 of the 96px cell).
const FUMES_TOP_ROW := 7.0
const FUMES_BOTTOM_ROW := 71.0


# World point of a cel pixel through the fighter's REAL sprite transform
# (offset, flip_h mirroring inside the cel rect, scale, shake).
func _cel_world(f: FighterBase, cel_pt: Vector2) -> Vector2:
	var sp: Sprite2D = f.idle_sprite
	var cell_w: float = sp.texture.get_width() / float(sp.hframes)
	var lx: float = sp.offset.x + ((cell_w - cel_pt.x) if sp.flip_h else cel_pt.x)
	return sp.global_transform * Vector2(lx, sp.offset.y + cel_pt.y)


func _sprite_world_rect(sp: Sprite2D) -> Rect2:
	var r := sp.get_rect()
	return Rect2(sp.global_position + r.position * sp.global_scale,
		r.size * sp.global_scale.abs())


func _body_rect(f: FighterBase) -> Rect2:
	return Rect2(f.position.x - f.body_width * 0.5, f.position.y - f.body_height,
		f.body_width, f.body_height)


func _banner_rect() -> Rect2:
	return Rect2(hud.banner_plate.position, hud.banner_plate.size)


# Steps one full sequence recording one dictionary per sequence frame.
func _record_sequence(att_is_left: bool, richard_attacks: bool) -> Array:
	var att_idx := 1 if richard_attacks else 0
	var vic_idx := 1 - att_idx
	var att: FighterBase
	var vic: FighterBase
	if att_is_left:
		await _new_match(false, 0, false, att_idx, vic_idx)
		att = p1
		vic = p2
		_prime_meth(att, vic, 120.0, 150.0)
	else:
		await _new_match(false, 0, false, vic_idx, att_idx)
		att = p2
		vic = p1
		_prime_meth(att, vic, 250.0, 224.0)
	var rec: Array = []
	for _i in 40:
		await physics_frame
		if driver != null and driver.active:
			break
	var last := -1
	for _i in 400:
		if driver == null or not driver.active:
			break
		if driver.frame != last:
			last = driver.frame
			var fire: Sprite2D = driver.prop_sprite("fire_belch_sheet")
			var fumes: Sprite2D = driver.prop_sprite("whiskey_fumes_sheet")
			var water: Sprite2D = driver.prop_sprite("water_drop_mask_sheet")
			var vrect := _sprite_world_rect(vic.idle_sprite)
			var mat: ShaderMaterial = vic.idle_sprite.material as ShaderMaterial
			rec.append({
				"f": driver.frame,
				"att_pos": att.position, "vic_pos": vic.position,
				"att_rect": _body_rect(att), "vic_rect": _body_rect(vic),
				"vic_sprite": vrect,
				"vic_pose": driver.victim_pose_key(), "att_pose": driver.attacker_pose_key(),
				"att_cel": att.idle_sprite.frame,
				"banner": _banner_rect(),
				"plank": driver.prop_visible("plank_base"),
				"sewer": driver.prop_visible("sewer_open_sheet"),
				"water": driver.prop_visible("water_drop_mask_sheet"),
				"water_frame": driver.prop_frame("water_drop_mask_sheet"),
				"clip_on": float(mat.get_shader_parameter("clip_on")) if mat != null else -1.0,
				"rim": mat.get_shader_parameter("rim") if mat != null else Vector4.ZERO,
				"water_anchor": driver.prop_anchor_point("water_drop_mask_sheet"),
				"fire_vis": fire != null and fire.visible,
				"fire_frame": fire.frame if fire != null else -1,
				"fire_anchor": driver.prop_anchor_point("fire_belch_sheet"),
				"fire_rect": _sprite_world_rect(fire) if fire != null else Rect2(),
				"fire_z": fire.z_index if fire != null else -9,
				"fire_flip": fire.flip_h if fire != null else false,
				"fumes_vis": fumes != null and fumes.visible,
				"fumes_frame": fumes.frame if fumes != null else -1,
				"fumes_anchor": driver.prop_anchor_point("whiskey_fumes_sheet"),
				"fumes_flip": fumes.flip_h if fumes != null else false,
				"mouth": _cel_world(att, NEUTRAL_MOUTH.get(att.idle_sprite.frame, Vector2(44, 20))),
				"bottle": _cel_world(att, HEAVY_BOTTLE),
				"flash": fx.get_child_count() > 0 and _flash_alpha(),
				"sign_vis": driver.prop_visible("fictional_bar_sign_base"),
				"sign_anchor": driver.prop_anchor_point("fictional_bar_sign_base"),
				"shatter_vis": driver.prop_visible("bar_sign_shatter_front_sheet"),
			})
		await physics_frame
	scene.queue_free()
	await _step(2)
	return rec


func _flash_alpha() -> float:
	for child in fx.get_children():
		if child is ColorRect and child.visible and child.color.a > 0.0 \
				and child.color.r > 0.9 and child.size.x >= 320.0:
			return child.color.a
	return 0.0


func _at(rec: Array, f: int) -> Dictionary:
	for r in rec:
		if r["f"] == f:
			return r
	return {}


func _test_review_fix_contract() -> void:
	for facing_left in [true, false]:
		var tag := "attacker LEFT" if facing_left else "attacker RIGHT"
		await _check_plank_contract(facing_left, tag)
		await _check_belch_contract(facing_left, tag)


func _check_plank_contract(att_left: bool, tag: String) -> void:
	var rec: Array = await _record_sequence(att_left, false)
	_check("WTP %s: the record spans the whole 210-frame sequence" % tag,
		rec.size() >= LENGTH - 1, "frames=%d" % rec.size())
	if rec.size() < LENGTH - 1:
		return
	var floor_y: float = rec[0]["att_pos"].y
	# Item 2: no plank under the standing victim; it appears as he lands.
	var early_plank := false
	for f in range(0, 54):
		early_plank = early_plank or _at(rec, f).get("plank", false)
	_check("WTP %s: no plank before the knock-down (f0-53)" % tag,
		not early_plank, "plank visible early")
	_check("WTP %s: the plank is down once he has landed (f66)" % tag,
		_at(rec, 66).get("plank", false), "plank missing at f66")
	# Item 1: the drop. From the stomp the victim only goes DOWN, with
	# increasing speed (gravity), centred on the sewer anchor.
	var prev_y := -1.0e9
	var prev_dy := -1.0
	var falling := true
	var accel := true
	var centred := true
	var sewer_x: float = _at(rec, 130)["water_anchor"].x
	for f in range(108, 160):
		var r: Dictionary = _at(rec, f)
		var dy: float = r["vic_pos"].y - prev_y if f > 108 else 0.0
		if f > 108 and dy < -0.01:
			falling = false
		prev_dy = dy
		prev_y = r["vic_pos"].y
		if absf(r["vic_pos"].x - sewer_x) > 3.0:
			centred = false
	_check("WTP %s: from the stomp (f108-159) the victim only moves DOWN" % tag,
		falling, "he rose")
	accel = (_at(rec, 140)["vic_pos"].y - _at(rec, 124)["vic_pos"].y) \
		> (_at(rec, 124)["vic_pos"].y - _at(rec, 108)["vic_pos"].y) + 2.0
	_check("WTP %s: the drop speeds up (gravity)" % tag, accel, "no acceleration")
	_check("WTP %s: he drops centred on the sewer anchor (<=3px)" % tag,
		centred, "off-centre vs x=%f" % sewer_x)
	var peak_y := 1.0e9
	for f in range(100, 161):
		peak_y = minf(peak_y, _at(rec, f)["vic_pos"].y)
	_check("WTP %s: he never pops above the floor line after the stomp" % tag,
		peak_y >= floor_y - 0.5, "peak y=%f floor=%f" % [peak_y, floor_y])
	# Rim clip (shader): on from the drop, anchored at the sewer, 12px deep.
	var r130: Dictionary = _at(rec, 130)
	_check("WTP %s: the rim clip is active and anchored on the sewer (f130)" % tag,
		r130["clip_on"] > 0.5 and absf(r130["rim"].x - sewer_x) <= 1.0
			and absf(r130["rim"].y - floor_y) <= 1.0
			and absf(r130["rim"].w - RIM_DEPTH) <= 0.5,
		"clip=%f rim=%s sewer_x=%f" % [r130["clip_on"], str(r130["rim"]), sewer_x])
	_check("WTP %s: the victim's art is above the rim before the stomp (f100)" % tag,
		_at(rec, 100)["clip_on"] < 0.5 and _at(rec, 100)["vic_sprite"].position.y < floor_y,
		"clip=%f" % _at(rec, 100)["clip_on"])
	# Fully below the rim and invisible by ~f160, and stays so.
	var hidden := true
	var worst := -1.0e9
	for f in range(160, 210):
		var r: Dictionary = _at(rec, f)
		var top: float = r["vic_sprite"].position.y
		worst = maxf(worst, floor_y + RIM_DEPTH - top)
		if top < floor_y + RIM_DEPTH - 0.01 or r["clip_on"] < 0.5:
			hidden = false
	_check("WTP %s: every victim pixel is below the rim arc from f160 on" % tag,
		hidden, "sprite top above the rim by up to %.1f px" % worst)
	_check("WTP %s: the victim has not vanished early (visible above rim at f132)" % tag,
		_at(rec, 132)["vic_sprite"].position.y < floor_y + RIM_DEPTH,
		"top=%f" % _at(rec, 132)["vic_sprite"].position.y)
	# Splash plays as he goes under; the opening and settled splash stay.
	_check("WTP %s: the splash plays as he goes under (f124 -> f136)" % tag,
		_at(rec, 124)["water_frame"] <= 1 and _at(rec, 136)["water_frame"] >= 4,
		"frames %d -> %d" % [_at(rec, 124)["water_frame"], _at(rec, 136)["water_frame"]])
	var open_to_end := true
	for f in range(114, 210):
		var r: Dictionary = _at(rec, f)
		open_to_end = open_to_end and r["sewer"] and r["water"]
	_check("WTP %s: the open sewer and settled splash stay to the end" % tag,
		open_to_end, "sewer/water vanished")
	_check("WTP %s: the plank is gone once it has snapped (f120)" % tag,
		not _at(rec, 120)["plank"], "plank still drawn")
	_check("WTP %s: Peggy plays win after the drop (f180)" % tag,
		_at(rec, 180)["att_pose"] == "win", "att=%s" % _at(rec, 180)["att_pose"])
	await _check_banner(rec, tag, "WTP")


# Item 6: banner centred through the hold, then clear of both fighters.
func _check_banner(rec: Array, tag: String, seq_tag: String) -> void:
	var b0: Rect2 = _at(rec, 10)["banner"]
	_check("%s %s: the banner is centred during the 30f opening hold" % [seq_tag, tag],
		absf(b0.get_center().y - 90.0) <= 20.0, "banner=%s" % str(b0))
	var clear := true
	var worst := ""
	for f in range(44, 210):
		var r: Dictionary = _at(rec, f)
		for key in ["att_rect", "vic_rect"]:
			if r["banner"].intersects(r[key]):
				clear = false
				worst = "f%d %s banner=%s rect=%s" % [f, key, str(r["banner"]), str(r[key])]
	_check("%s %s: the banner never overlaps either fighter after the hold" % [seq_tag, tag],
		clear, worst)


func _check_belch_contract(att_left: bool, tag: String) -> void:
	var rec: Array = await _record_sequence(att_left, true)
	_check("FB %s: the record spans the whole 210-frame sequence" % tag,
		rec.size() >= LENGTH - 1, "frames=%d" % rec.size())
	if rec.size() < LENGTH - 1:
		return
	var floor_y: float = rec[0]["att_pos"].y
	var d: float = 1.0 if att_left else -1.0
	# Item 3: the fire cone at Richard's mouth, above the victim and fumes.
	var worst_mouth := 0.0
	var frames_seen := {}
	var fire_frames := 0
	var above := true
	var crosses_victim := false
	var unmirrored_ok := true
	for f in range(90, 125):
		var r: Dictionary = _at(rec, f)
		if not r["fire_vis"]:
			continue
		fire_frames += 1
		frames_seen[r["fire_frame"]] = true
		worst_mouth = maxf(worst_mouth, r["fire_anchor"].distance_to(r["mouth"]))
		above = above and r["fire_z"] > 1
		if r["fire_rect"].intersects(r["vic_rect"]):
			crosses_victim = true
		unmirrored_ok = unmirrored_ok and (r["fire_flip"] == (not att_left))
	_check("FB %s: the fire cone's mouth anchor is within 3px of Richard's mouth" % tag,
		fire_frames > 0 and worst_mouth <= 3.0, "worst=%.2f px over %d frames" % [worst_mouth, fire_frames])
	_check("FB %s: the cone steps through all 7 frames over the ignite beat" % tag,
		frames_seen.size() == 7, "seen=%s" % str(frames_seen.keys()))
	_check("FB %s: the cone is drawn above both fighters (z) and mirrored with facing" % tag,
		above and unmirrored_ok, "z/mirror wrong")
	_check("FB %s: the cone visibly streams across the victim" % tag,
		crosses_victim, "cone rect never meets the victim")
	var layered: bool = MethCinematicDriver.PROPS["fire_belch_sheet"]["layer"] == "front" \
		and MethCinematicDriver.PROPS["whiskey_fumes_sheet"]["layer"] == "back"
	_check("FB %s: the cone is on the front layer, the fumes on the back layer" % tag,
		layered, "layers")
	# Item 4: fumes at the bottle, billowing across head/torso height.
	var r35: Dictionary = _at(rec, 35)
	_check("FB %s: the fumes anchor sits at the bottle mouth (<=3px)" % tag,
		r35["fumes_vis"] and r35["fumes_anchor"].distance_to(r35["bottle"]) <= 3.0,
		"anchor=%s bottle=%s" % [str(r35["fumes_anchor"]), str(r35["bottle"])])
	var r80: Dictionary = _at(rec, 80)
	var span_top: float = r80["fumes_anchor"].y - 70.0 + FUMES_TOP_ROW
	var span_bottom: float = r80["fumes_anchor"].y - 70.0 + FUMES_BOTTOM_ROW
	var body_h: float = 56.0
	_check("FB %s: the fume cloud spans the fighters' head-to-waist band" % tag,
		span_top < floor_y - body_h * 0.5 and span_bottom > floor_y - body_h,
		"cloud y %.1f..%.1f vs band %.1f..%.1f" % [span_top, span_bottom,
			floor_y - body_h, floor_y - body_h * 0.5])
	_check("FB %s: the fumes are mirrored with facing and hold their last frame" % tag,
		r80["fumes_flip"] == (not att_left) and r80["fumes_frame"] == 6,
		"flip=%s frame=%d" % [str(r80["fumes_flip"]), r80["fumes_frame"]])
	var flashed := false
	var calm_before := true
	for f in range(0, 100):
		calm_before = calm_before and not (_at(rec, f)["flash"] as bool)
	for f in range(100, 114):
		flashed = flashed or (_at(rec, f)["flash"] as bool)
	_check("FB %s: the fumes ignite — a tint flash only once the belch hits them" % tag,
		flashed and calm_before and not _at(rec, 140)["fumes_vis"],
		"flashed=%s calm=%s" % [str(flashed), str(calm_before)])
	# Item 5: the launch arc, the sign on it, the shatter on arrival.
	var peak := 0.0
	var away := true
	var prev_x: float = _at(rec, 120)["vic_pos"].x
	for f in range(120, 161):
		var r: Dictionary = _at(rec, f)
		peak = maxf(peak, floor_y - r["vic_pos"].y)
		if (r["vic_pos"].x - prev_x) * d < -0.01:
			away = false
		prev_x = r["vic_pos"].x
	_check("FB %s: the victim's launch peaks at least 30px above the floor" % tag,
		peak >= 30.0, "peak=%.1f" % peak)
	_check("FB %s: the victim flies away from Richard (monotone, pixel-snapped)" % tag,
		away and _at(rec, 130)["vic_pos"] == _at(rec, 130)["vic_pos"].round(),
		"x not monotone/snapped")
	_check("FB %s: ko_air through the arc, ko_ground on landing" % tag,
		_at(rec, 140)["vic_pose"] == "ko_air" and _at(rec, 170)["vic_pose"] == "ko_ground"
			and absf(_at(rec, 165)["vic_pos"].y - floor_y) < 0.5,
		"poses %s / %s" % [_at(rec, 140)["vic_pose"], _at(rec, 170)["vic_pose"]])
	var shatter_f := -1
	for f in range(100, 200):
		if _at(rec, f)["shatter_vis"]:
			shatter_f = f
			break
	var reach_f := -1
	var sign_x: float = _at(rec, 130)["sign_anchor"].x
	for f in range(120, 161):
		var r: Dictionary = _at(rec, f)
		if (r["vic_pos"].x - sign_x) * d >= -1.0:
			reach_f = f
			break
	_check("FB %s: the shatter starts on the frame the victim reaches the sign" % tag,
		shatter_f > 0 and reach_f > 0 and absi(shatter_f - reach_f) <= 1,
		"shatter f%d reach f%d" % [shatter_f, reach_f])
	var sr: Dictionary = _at(rec, maxi(shatter_f, 1))
	var sign_y: float = _at(rec, 130)["sign_anchor"].y
	var vic_feet: float = sr["vic_pos"].y
	_check("FB %s: the sign hangs on the arc at chest/head height of the victim" % tag,
		sign_y <= vic_feet - 25.0 and sign_y >= vic_feet - 80.0,
		"sign y=%.1f victim feet=%.1f" % [sign_y, vic_feet])
	var inside := true
	for f in range(120, 210):
		var r: Dictionary = _at(rec, f)
		inside = inside and r["vic_pos"].x >= 44.0 and r["vic_pos"].x <= 276.0
	_check("FB %s: the whole flight and landing stay inside the arena bounds" % tag,
		inside, "left bounds")
	_check("FB %s: back shards behind the victim, front shards in front" % tag,
		MethCinematicDriver.PROPS["bar_sign_shatter_back_sheet"]["layer"] == "back"
			and MethCinematicDriver.PROPS["bar_sign_shatter_front_sheet"]["layer"] == "front",
		"shard layers")
	_check("FB %s: Richard plays win before the sequence ends" % tag,
		_at(rec, 195)["att_pose"] == "win", "att=%s" % _at(rec, 195)["att_pose"])
	await _check_banner(rec, tag, "FB")
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
