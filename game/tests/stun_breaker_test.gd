# Stun & breaker suite — Phase 3 (COMBO_SYSTEM_DESIGN §10.5/§11, §15
# decisions #1/#6/#7/#9 + the 2026-11-21 owner calls: Peggy launcher 274,
# Richard Taser Belch 40 + stun, Peggy Peg-Lock 95 + 60f immunity).
#
# Run: godot --headless --path game --script res://tests/stun_breaker_test.gd
#
# Same harness contract as combo_test.gd/combo_fuzz_test.gd (the #76 fix):
# the engine must NEVER tick the match — physics is disabled pre-add,
# post-add, and re-asserted after the ready awaits.
extends SceneTree

const PEGGY := "res://resources/fighters/peg_leg_peggy.tres"
const RICHARD := "res://resources/fighters/whiskey_richard.tres"
const GAS_N_GO := "res://resources/stages/gas_n_go.tres"

var failures := 0
var checks := 0

func _check(label: String, condition: bool, detail: String = "") -> void:
	checks += 1
	if condition:
		print("PASS: ", label)
	else:
		failures += 1
		print("FAIL: ", label, "  ", detail)

func _initialize() -> void:
	await _stun_basics()
	await _stun_fairness_rails()
	await _breaker_basics()
	await _breaker_economy()
	await _breaker_hitstop_buffering()
	await _breaker_juggle_and_corner()
	await _serialization_and_determinism()
	print("stun_breaker: %d checks, %d failure(s)" % [checks, failures])
	quit(1 if failures > 0 else 0)

# ---------------------------------------------------------------------------
# harness (the #76 contract, same as combo_fuzz_test.gd)
# ---------------------------------------------------------------------------

func _build_match() -> Node:
	var mroot: Node = load("res://scenes/match/MatchRoot.tscn").instantiate()
	mroot.selected_p1_data = load(RICHARD)
	mroot.selected_p2_data = load(PEGGY)
	mroot.selected_stage = load(GAS_N_GO)
	mroot.set_physics_process(false)
	root.add_child(mroot)
	mroot.set_physics_process(false)
	await process_frame
	await process_frame
	mroot.set_physics_process(false)
	assert(not mroot.is_physics_processing())
	mroot.p1.set_physics_process(false)
	mroot.p2.set_physics_process(false)
	mroot.p1.reset_state()
	mroot.p2.reset_state()
	return mroot

func _free_match(mroot: Node) -> void:
	mroot.queue_free()
	await process_frame
	await process_frame

func _step(mroot: Node, frames: int = 1, press: String = "") -> void:
	var dt := 1.0 / 60.0
	for _i in frames:
		# Presses inject straight into the owning fighter's buffer (prefix
		# decides the side), exactly like combo_fuzz's _step. Held DIRECTIONS
		# are not buffer actions — tests that need a held direction use
		# Input.action_press/release around these steps.
		for entry in press.split("+"):
			var parts := entry.split("_")
			if parts.size() < 2:
				continue
			var who: FighterBase = mroot.p1 if parts[0] == "p1" else mroot.p2
			var action: String = "_".join(parts.slice(1))
			who.input_buffer[action] = 0
			who._macro_on_press(action)
		Engine.physics_ticks_per_second = 60000
		await physics_frame
		Engine.physics_ticks_per_second = 60
		mroot.p1._physics_process(dt)
		mroot.p2._physics_process(dt)
		mroot._physics_process(dt)

# Drive the match into the FIGHT phase so round state (breaker budget, free
# uses) reflects a real round, not a manual reset.
func _to_fight(mroot: Node) -> void:
	for i in 120:
		await _step(mroot, 1)
		if mroot.phase == 1:
			return

func _reset_pair(mroot: Node, p1_x: float, p2_x: float) -> void:
	var floor_y: float = mroot.stage.floor_y
	mroot.p1.position = Vector2(p1_x, floor_y)
	mroot.p2.position = Vector2(p2_x, floor_y)
	mroot.p1.velocity = Vector2.ZERO
	mroot.p2.velocity = Vector2.ZERO
	mroot.p1.facing = 1
	mroot.p2.facing = -1
	mroot.p1.health = 1000.0
	mroot.p2.health = 1000.0
	mroot.p1.meter = 0.0
	mroot.p2.meter = 0.0
	mroot.p1.input_enabled = true
	mroot.p2.input_enabled = true
	mroot.p1.input_buffer.clear()
	mroot.p2.input_buffer.clear()
	# reset_state re-arms the round-scoped breaker budget; tests that care
	# about a spent budget set it back explicitly.
	mroot.p1.reset_state()
	mroot.p2.reset_state()

# Land `move` from attacker onto defender, on the first active frame,
# through the real resolver.
func _land_hit(mroot: Node, attacker: FighterBase, defender: FighterBase,
		move: MoveData) -> void:
	attacker.input_enabled = true
	defender.input_enabled = true
	attacker._start_move(move)
	attacker.state_frame = move.startup
	mroot._resolve_hits()

# Press the breaker pair once for `who` and step until it resolves (the
# pair rides the hitstop freeze; the break lands the first frame the
# defender's hitstop has served). Returns true when a break happened.
func _break_out(mroot: Node, who: FighterBase, max_frames: int = 20) -> bool:
	var prefix := "p1" if who == mroot.p1 else "p2"
	who.input_buffer["grab"] = 0
	who.input_buffer["special"] = 0
	for i in max_frames:
		await _step(mroot, 1)
		if who.breaker_used_this_combo and who.breaker_invuln_frames > 0:
			return true
	return false

# ---------------------------------------------------------------------------
# 1. Stun basics
# ---------------------------------------------------------------------------

func _stun_basics() -> void:
	var mroot: Node = await _build_match()
	await _to_fight(mroot)
	var p1: FighterBase = mroot.p1 # Richard (Taser Belch)
	var p2: FighterBase = mroot.p2 # Peggy (Peg-Lock)
	var taser: MoveData = p1.data.find_move(MoveData.InputType.SPECIAL_NEUTRAL, MoveData.Stance.STAND)

	# 1a. A landed stun move connects with its reduced damage, opens the
	# authored window, and earns the attacker NO meter (§10.5).
	_reset_pair(mroot, 100.0, 140.0)
	_land_hit(mroot, p1, p2, taser)
	_check("taser lands for the reduced 40 damage",
		is_equal_approx(p2.health, 1000.0 - 40.0), "hp=%.1f" % p2.health)
	_check("the stun move earns the attacker no meter",
		p1.meter == 0.0, "meter=%.1f" % p1.meter)
	_check("the stun opens the authored 45-frame window",
		p2.state == FighterBase.State.HITSTUN and p2.stun_id == &"taser_buzz"
			and p2.stun_frames_remaining == 45,
		"state=%d stun=%s frames=%d" % [p2.state, p2.stun_id, p2.stun_frames_remaining])
	_check("the stun window replaces the move's hitstun",
		p2.hitstun_frames == 45, "hitstun=%d" % p2.hitstun_frames)
	_check("the stun follow-up starts at scaling step 3",
		p2.combo_hits == 2, "combo_hits=%d" % p2.combo_hits)

	# 1b. The window times out naturally; immunity is Richard's 240 frames.
	# The stun clock is frozen for the move's authored hitstop, so the loop
	# runs hitstop + window frames.
	var stunned_ticks := 0
	while p2.stun_active():
		await _step(mroot, 1)
		stunned_ticks += 1
	_check("the natural stun window lasts the full 45 frames past hitstop",
		stunned_ticks == 45 + taser.hitstop, "ticks=%d" % stunned_ticks)
	_check("the defender recovers to a neutral state after the stun",
		p2.state in [FighterBase.State.IDLE, FighterBase.State.CROUCH,
			FighterBase.State.WALK_F, FighterBase.State.WALK_B],
		"state=%d" % p2.state)
	_check("post-stun immunity is the authored 240 frames",
		p2.stun_immunity_left() == 240, "immunity=%d" % p2.stun_immunity_left())

	# 1c. Peggy's Peg-Lock: 95 damage kept, 60-frame immunity (owner call).
	var peg_lock: MoveData = p2.data.find_move(MoveData.InputType.SPECIAL_NEUTRAL, MoveData.Stance.STAND)
	_reset_pair(mroot, 140.0, 100.0)
	p2.facing = 1
	p1.facing = -1
	_land_hit(mroot, p2, p1, peg_lock)
	_check("peg-lock keeps the authored 95 damage",
		is_equal_approx(p1.health, 1000.0 - 95.0), "hp=%.1f" % p1.health)
	_check("peg-lock stuns with the authored window",
		p1.stun_id == &"peg_lock" and p1.stun_frames_remaining == 45,
		"stun=%s frames=%d" % [p1.stun_id, p1.stun_frames_remaining])
	while p1.stun_active():
		await _step(mroot, 1)
	_check("peg-lock immunity is the authored 60 frames",
		p1.stun_immunity_left() == 60, "immunity=%d" % p1.stun_immunity_left())

	# 1d. Shake-out: the first 20 frames are unshakeable; afterwards each
	# fresh press of the authored mash direction cuts 3 frames. The stun
	# clock is frozen through the move's hitstop, so 20 elapsed window
	# frames need hitstop + 20 steps.
	_reset_pair(mroot, 100.0, 140.0)
	_land_hit(mroot, p1, p2, taser)
	for i in taser.hitstop + 20:
		await _step(mroot, 1, "p2_up") # mashing from frame one...
	_check("the first 20 window frames ignore mashing (one boundary press lands)",
		p2.stun_frames_remaining == 22 and p2.stun_shake_presses == 1,
		"left=%d presses=%d" % [p2.stun_frames_remaining, p2.stun_shake_presses])
	for i in 4:
		await _step(mroot, 1, "p2_up") # ...then four presses land
	_check("shake-out shortens the window 3f per press",
		p2.stun_frames_remaining == 6 and p2.stun_shake_presses == 5,
		"left=%d presses=%d" % [p2.stun_frames_remaining, p2.stun_shake_presses])
	while p2.stun_active():
		await _step(mroot, 1)
	_check("shake-out ended the stun early and immunity still applies",
		p2.stun_immunity_left() == 240, "immunity=%d" % p2.stun_immunity_left())
	await _free_match(mroot)

# ---------------------------------------------------------------------------
# 2. Stun fairness rails (§10.5 / §15 #6/#7)
# ---------------------------------------------------------------------------

func _stun_fairness_rails() -> void:
	var mroot: Node = await _build_match()
	await _to_fight(mroot)
	var p1: FighterBase = mroot.p1
	var p2: FighterBase = mroot.p2
	var taser: MoveData = p1.data.find_move(MoveData.InputType.SPECIAL_NEUTRAL, MoveData.Stance.STAND)
	var light: MoveData = p1.data.find_move(MoveData.InputType.LIGHT, MoveData.Stance.STAND)

	# 2a. Immunity: a second stun attempt inside the window does not stun.
	_reset_pair(mroot, 100.0, 140.0)
	_land_hit(mroot, p1, p2, taser)
	while p2.stun_active():
		await _step(mroot, 1)
	var immunity_at_hit: int = p2.stun_immunity_left()
	var hp_before: float = p2.health
	_land_hit(mroot, p1, p2, taser)
	_check("immunity blocks a re-stun inside the window",
		p2.stun_id == &"" and p2.stun_frames_remaining == 0
			and p2.stun_immunity_left() == immunity_at_hit,
		"stun=%s immunity=%d/%d" % [p2.stun_id, p2.stun_immunity_left(), immunity_at_hit])
	_check("an immune hit still deals its damage normally",
		p2.health < hp_before, "hp=%.1f" % p2.health)
	await _free_match(mroot)

	# 2b. Once per combo: within one combo the stun cannot land twice, even
	# with immunity artificially cleared (the string consumed the window).
	var mroot2: Node = await _build_match()
	await _to_fight(mroot2)
	p1 = mroot2.p1
	p2 = mroot2.p2
	_reset_pair(mroot2, 100.0, 140.0)
	_land_hit(mroot2, p1, p2, taser)
	var first_stunned: bool = p2.stun_active()
	_land_hit(mroot2, p1, p2, light) # the string hit consumes the window
	p2.stun_immunity_frames = 0 # isolate the once-per-combo tag alone
	_land_hit(mroot2, p1, p2, taser)
	_check("one stun per combo: a second stun move in the same combo is plain damage",
		first_stunned and p2.stun_id == &"" and p2.stun_frames_remaining == 0,
		"first=%s second_stun=%s" % [first_stunned, p2.stun_id])
	await _free_match(mroot2)

	# 2c. Strings during the stun pay the scaling ladder: the stun advanced
	# the combo to step 3, so the next hit pays 0.85.
	var mroot3: Node = await _build_match()
	await _to_fight(mroot3)
	p1 = mroot3.p1
	p2 = mroot3.p2
	_reset_pair(mroot3, 100.0, 140.0)
	_land_hit(mroot3, p1, p2, taser)
	var hp_after_stun: float = p2.health
	_land_hit(mroot3, p1, p2, light)
	_check("a string hit during the stun pays the step-3 ladder (0.85)",
		is_equal_approx(p2.health, hp_after_stun - light.damage * 0.85),
		"hp=%.1f expected=%.1f" % [p2.health, hp_after_stun - light.damage * 0.85])
	await _free_match(mroot3)

	# 2d. A blocked stun move is just a blocked move: no stun, no meter.
	var mroot4: Node = await _build_match()
	await _to_fight(mroot4)
	p1 = mroot4.p1
	p2 = mroot4.p2
	_reset_pair(mroot4, 100.0, 140.0)
	p2.input_enabled = true
	Input.action_press("p2_right") # away from the attacker: block hold
	await _step(mroot4, 3)
	var blocked_hp: float = p2.health
	p1._start_move(taser)
	p1.state_frame = taser.startup
	mroot4._resolve_hits()
	_check("a blocked stun move stuns nothing",
		p2.state == FighterBase.State.BLOCKSTUN and p2.stun_id == &"",
		"state=%d stun=%s" % [p2.state, p2.stun_id])
	_check("a blocked stun move pays the attacker nothing",
		p1.meter == 0.0 and p2.health == maxf(1.0, blocked_hp - taser.block_damage),
		"meter=%.1f hp=%.1f" % [p1.meter, p2.health])
	Input.action_release("p2_right")
	await _step(mroot4, 20)
	await _free_match(mroot4)

	# 2e. Stun never lands on an airborne target (decision #6).
	var mroot5: Node = await _build_match()
	await _to_fight(mroot5)
	p1 = mroot5.p1
	p2 = mroot5.p2
	_reset_pair(mroot5, 100.0, 140.0)
	p2.grounded = false
	p2.velocity = Vector2.ZERO
	p2.position.y = mroot5.stage.floor_y - 40.0
	p2._force_state(FighterBase.State.JUMP_RISE)
	_land_hit(mroot5, p1, p2, taser)
	_check("an airborne target takes the damage but no stun",
		p2.stun_id == &"" and p2.health < 1000.0,
		"stun=%s hp=%.1f" % [p2.stun_id, p2.health])
	await _free_match(mroot5)

	# 2f. Buffered inputs never outlive a stun freeze: a shake press
	# buffered on the stun frame cannot act (the minimum gate), and ages out
	# under the normal buffer rules — the hitstop freeze cap (5) bounds how
	# long ANY buffered press survives a freeze.
	var mroot6: Node = await _build_match()
	await _to_fight(mroot6)
	p1 = mroot6.p1
	p2 = mroot6.p2
	_reset_pair(mroot6, 100.0, 140.0)
	p2.input_buffer["up"] = 0 # buffered on the very frame of the hit
	_land_hit(mroot6, p1, p2, taser)
	for i in taser.hitstop + 12:
		await _step(mroot6, 1)
	_check("a press frozen in the stun's hitstop never shakes before the minimum",
		p2.stun_frames_remaining == 33 and p2.stun_shake_presses == 0,
		"left=%d presses=%d" % [p2.stun_frames_remaining, p2.stun_shake_presses])
	for i in 15:
		await _step(mroot6, 1)
	_check("the buffered press aged out under the normal buffer rules",
		not p2.input_buffer.has("up") and p2.stun_shake_presses == 0,
		"up=%s presses=%d" % [str(p2.input_buffer.get("up", -1)), p2.stun_shake_presses])
	await _free_match(mroot6)

# ---------------------------------------------------------------------------
# 3. Breaker basics (decision #1/#9)
# ---------------------------------------------------------------------------

func _breaker_basics() -> void:
	var mroot: Node = await _build_match()
	await _to_fight(mroot)
	var p1: FighterBase = mroot.p1
	var p2: FighterBase = mroot.p2
	var heavy: MoveData = p1.data.find_move(MoveData.InputType.HEAVY, MoveData.Stance.STAND)

	# 3a. The free break: a defender in hitstun with both breaker actions
	# buffered breaks out — combo dies, pushback separates, invuln covers.
	# A defender with ZERO meter still gets it.
	_reset_pair(mroot, 100.0, 140.0)
	_land_hit(mroot, p1, p2, heavy)
	_check("the defender is in hitstun before the break",
		p2.state == FighterBase.State.HITSTUN, "state=%d" % p2.state)
	var combo_before: int = p2.combo_tracker.hits
	var x_before: float = p2.position.x
	var broke: bool = await _break_out(mroot, p2)
	await _step(mroot, 8) # the separating push runs 6 frames after the break
	_check("a meter-less defender still gets the free break",
		broke and p2.meter == 0.0, "broke=%s meter=%.1f" % [broke, p2.meter])
	_check("the break frees the defender from hitstun",
		p2.state == FighterBase.State.IDLE, "state=%d" % p2.state)
	_check("the free break spends the round's free use",
		p2.breaker_free_remaining() == 0, "free=%d" % p2.breaker_free_remaining())
	_check("the attacker's combo dies with the break",
		p2.combo_tracker.hits == 0 and combo_before > 0,
		"hits=%d before=%d" % [p2.combo_tracker.hits, combo_before])
	_check("the break separates the defender away from the attacker",
		p2.position.x - x_before >= 25.0, "dx=%.1f" % (p2.position.x - x_before))
	_check("the break grants the 20-frame invulnerability window",
		p2.breaker_invuln_frames > 0 and p2.is_invulnerable_to(heavy),
		"invuln=%d" % p2.breaker_invuln_frames)
	_check("the break arms the 5-second cooldown",
		p2.breaker_cooldown_left() > 0
			and p2.breaker_cooldown_left() <= p1.data.breaker_cooldown_frames,
		"cooldown=%d" % p2.breaker_cooldown_left())

	# 3b. Not in blockstun: a blocking defender eats the blockstun and the
	# buffered pair does nothing there (blocking is the defense).
	_reset_pair(mroot, 100.0, 140.0)
	p2.input_enabled = true
	Input.action_press("p2_right")
	await _step(mroot, 3)
	p2.input_buffer["grab"] = 0
	p2.input_buffer["special"] = 0
	p1._start_move(heavy)
	p1.state_frame = heavy.startup
	mroot._resolve_hits()
	_check("the defender blocked into blockstun",
		p2.state == FighterBase.State.BLOCKSTUN, "state=%d" % p2.state)
	await _step(mroot, 10)
	_check("the breaker never fires during blockstun",
		p2.breaker_free_remaining() == 1 and p2.breaker_cooldown_left() == 0
			and p2.breaker_invuln_frames == 0,
		"free=%d cooldown=%d invuln=%d" % [p2.breaker_free_remaining(),
			p2.breaker_cooldown_left(), p2.breaker_invuln_frames])
	await _step(mroot, 30) # let blockstun expire
	Input.action_release("p2_right")

	# 3c. Not in neutral: the buffered pair in neutral is just inputs (the
	# grab resolves through the normal throw path, not a break).
	_reset_pair(mroot, 100.0, 200.0)
	await _step(mroot, 1, "p2_grab+p2_special")
	await _step(mroot, 20)
	_check("the buffered pair in neutral never breaks",
		p2.breaker_free_remaining() == 1 and p2.breaker_cooldown_left() == 0
			and p2.breaker_invuln_frames == 0,
		"free=%d cooldown=%d invuln=%d" % [p2.breaker_free_remaining(),
			p2.breaker_cooldown_left(), p2.breaker_invuln_frames])
	await _free_match(mroot)

# ---------------------------------------------------------------------------
# 4. Breaker economy (costs, cooldown, once per combo)
# ---------------------------------------------------------------------------

func _breaker_economy() -> void:
	var mroot: Node = await _build_match()
	await _to_fight(mroot)
	var p1: FighterBase = mroot.p1
	var p2: FighterBase = mroot.p2
	var heavy: MoveData = p1.data.find_move(MoveData.InputType.HEAVY, MoveData.Stance.STAND)

	# 4a. Extra breaks cost the authored meter: 40.
	_reset_pair(mroot, 100.0, 140.0)
	p2.breaker_free_uses_left = 0
	p2.meter = 60.0
	_land_hit(mroot, p1, p2, heavy)
	var broke: bool = await _break_out(mroot, p2)
	_check("an extra break costs the authored 40 meter",
		broke and is_equal_approx(p2.meter, 20.0), "broke=%s meter=%.1f" % [broke, p2.meter])
	await _step(mroot, 30)

	# 4b. Once per combo even with meter: after this combo's first (paid)
	# break, a second hitstun in the SAME combo cannot break again — the
	# rail is combo-scoped, so the meter is never touched.
	_reset_pair(mroot, 100.0, 140.0)
	p2.breaker_free_uses_left = 0
	p2.breaker_used_this_combo = false
	p2.breaker_cooldown_frames = 0
	p2.meter = 100.0
	_land_hit(mroot, p1, p2, heavy)
	var first: bool = await _break_out(mroot, p2)
	_check("the combo's first (paid) break resolves",
		first and is_equal_approx(p2.meter, 60.0), "first=%s meter=%.1f" % [first, p2.meter])
	await _step(mroot, 30) # let recovery settle; used_this_combo stays true
	_land_hit(mroot, p1, p2, heavy)
	p2.input_buffer["grab"] = 0
	p2.input_buffer["special"] = 0
	await _step(mroot, 2)
	_check("a second break in the same combo is rejected without spending",
		p2.breaker_invuln_frames == 0 and is_equal_approx(p2.meter, 60.0),
		"invuln=%d meter=%.1f" % [p2.breaker_invuln_frames, p2.meter])
	await _step(mroot, 40)

	# 4c. The cooldown gates a NEW combo's break; a 0-meter, 0-free defender
	# with the cooldown running cannot break at all.
	_reset_pair(mroot, 100.0, 140.0)
	p2.breaker_free_uses_left = 0
	p2.breaker_used_this_combo = false
	p2.breaker_cooldown_frames = 60 # mid-cooldown
	p2.meter = 0.0
	_land_hit(mroot, p1, p2, heavy)
	await _break_out(mroot, p2)
	_check("a mid-cooldown defender cannot break",
		p2.state == FighterBase.State.HITSTUN and p2.breaker_cooldown_left() > 0
			and p2.breaker_invuln_frames == 0,
		"state=%d cooldown=%d" % [p2.state, p2.breaker_cooldown_left()])
	await _step(mroot, 40)

	# 4d. After the cooldown expires, a new combo CAN pay the meter break.
	_reset_pair(mroot, 100.0, 140.0)
	p2.breaker_free_uses_left = 0
	p2.breaker_used_this_combo = false
	p2.breaker_cooldown_frames = 0
	p2.meter = 45.0
	_land_hit(mroot, p1, p2, heavy)
	var post_cd: bool = await _break_out(mroot, p2)
	_check("a post-cooldown meter break resolves",
		post_cd and is_equal_approx(p2.meter, 5.0),
		"broke=%s meter=%.1f" % [post_cd, p2.meter])

	# 4e. breaker_ready() readouts for the later HUD.
	_check("breaker_ready is false while the combo's break is spent",
		not p2.breaker_ready(), "ready=%s used=%s" % [p2.breaker_ready(), p2.breaker_used_this_combo])
	p2.breaker_used_this_combo = false
	p2.breaker_cooldown_frames = 0
	p2.meter = 0.0
	p2.breaker_free_uses_left = 1
	_check("breaker_ready is true with the free use armed",
		p2.breaker_ready(), "ready=%s" % p2.breaker_ready())
	await _free_match(mroot)

# ---------------------------------------------------------------------------
# 4f. Breaker chord buffered through hitstop (A2 owner decision)
# ---------------------------------------------------------------------------

func _prepare_breaker_hit(mroot: Node, attacker: FighterBase,
		defender: FighterBase, move: MoveData) -> void:
	_reset_pair(mroot, 100.0, 140.0)
	if attacker == mroot.p2:
		attacker.position = Vector2(100.0, mroot.stage.floor_y)
		defender.position = Vector2(140.0, mroot.stage.floor_y)
		attacker.facing = 1
		defender.facing = -1
	_land_hit(mroot, attacker, defender, move)


func _step_until_break(mroot: Node, who: FighterBase, max_frames: int = 24) -> bool:
	for _frame in max_frames:
		await _step(mroot, 1)
		if who.breaker_invuln_frames > 0:
			return true
	return false


func _breaker_hitstop_buffering() -> void:
	var mroot: Node = await _build_match()
	await _to_fight(mroot)
	var heavy_p1: FighterBase = mroot.p1 # Richard
	var heavy_p2: FighterBase = mroot.p2 # Peggy
	var heavy_6f: MoveData = heavy_p1.data.find_move(
		MoveData.InputType.HEAVY, MoveData.Stance.STAND)
	var heavy_6f_p2: MoveData = heavy_p2.data.find_move(
		MoveData.InputType.HEAVY, MoveData.Stance.STAND)
	var ex_10f_p1: MoveData = heavy_p1.data.find_ex_move(
		MoveData.InputType.SPECIAL_FWD, MoveData.Stance.STAND)
	var ex_10f_p2: MoveData = heavy_p2.data.find_ex_move(
		MoveData.InputType.SPECIAL_FWD, MoveData.Stance.STAND)
	_check("the focused hitstop cases are the authored 6f heavy and 10f EX",
		heavy_6f.hitstop == 6 and ex_10f_p1.hitstop == 10
			and ex_10f_p2.hitstop == 10,
		"heavy=%d EX=%d/%d" % [heavy_6f.hitstop, ex_10f_p1.hitstop,
			ex_10f_p2.hitstop])

	# Single pair press at 6f and 10f impacts, with each fighter as the
	# defender. The A2 adversarial check covers one 10f direction unchanged;
	# these focused checks pin both hitstop lengths and P1/P2 symmetry.
	var cases: Array = [
		[mroot.p1, mroot.p2, heavy_6f, "P2 defender, 6f heavy"],
		[mroot.p1, mroot.p2, ex_10f_p1, "P2 defender, 10f EX"],
		[mroot.p2, mroot.p1, heavy_6f_p2, "P1 defender, 6f heavy"],
		[mroot.p2, mroot.p1, ex_10f_p2, "P1 defender, 10f EX"],
	]
	for entry in cases:
		var attacker: FighterBase = entry[0]
		var defender: FighterBase = entry[1]
		var move: MoveData = entry[2]
		var label: String = entry[3]
		_prepare_breaker_hit(mroot, attacker, defender, move)
		var expected_hitstop: int = move.hitstop
		var free_before: int = defender.breaker_free_uses_left
		var meter_before: float = defender.meter
		var broke: bool = await _break_out(mroot, defender, 24)
		_check("one impact-frame breaker chord works — " + label,
			broke and defender.breaker_invuln_frames > 0
				and defender.breaker_free_uses_left == free_before - 1
				and is_equal_approx(defender.meter, meter_before),
			"hitstop=%d broke=%s free=%d->%d meter=%.1f->%.1f" % [
				expected_hitstop, str(broke), free_before,
				defender.breaker_free_uses_left, meter_before, defender.meter])

	# A chord one sim frame BEFORE impact is not eligible for the pending
	# mask. The fighter poll runs before MatchRoot's resolver, so after the
	# press frame and the next (impact) frame the buffer age is 2; the
	# hitstop poll must not turn it into a current-combo break.
	_reset_pair(mroot, 100.0, 140.0)
	mroot.p2.input_buffer["grab"] = 0
	mroot.p2.input_buffer["special"] = 0
	await _step(mroot, 2) # press frame, then the immediately-following frame
	_land_hit(mroot, mroot.p1, mroot.p2, ex_10f_p1)
	var prehit_broke: bool = await _step_until_break(mroot, mroot.p2, 20)
	_check("a breaker chord pressed one frame before the hit does not break",
		not prehit_broke and mroot.p2.breaker_invuln_frames == 0
			and mroot.p2.breaker_free_uses_left == 1
			and is_equal_approx(mroot.p2.meter, 0.0),
		"broke=%s free=%d meter=%.1f" % [str(prehit_broke),
			mroot.p2.breaker_free_uses_left, mroot.p2.meter])

	# The pending chord does not bypass the combo-used or cooldown rails and
	# does not consume either the free use or meter when the guard refuses.
	_reset_pair(mroot, 100.0, 140.0)
	mroot.p2.breaker_free_uses_left = 0
	mroot.p2.meter = 100.0
	mroot.p2.breaker_cooldown_frames = 60
	_land_hit(mroot, mroot.p1, mroot.p2, ex_10f_p1)
	mroot.p2.input_buffer["grab"] = 0
	mroot.p2.input_buffer["special"] = 0
	var cooldown_broke: bool = await _step_until_break(mroot, mroot.p2, 20)
	_check("an impact-frame pending chord cannot break through cooldown",
		not cooldown_broke and mroot.p2.breaker_free_uses_left == 0
			and is_equal_approx(mroot.p2.meter, 100.0)
			and mroot.p2.breaker_cooldown_frames > 0,
		"broke=%s meter=%.1f cooldown=%d" % [str(cooldown_broke),
			mroot.p2.meter, mroot.p2.breaker_cooldown_frames])

	_reset_pair(mroot, 100.0, 140.0)
	mroot.p2.breaker_free_uses_left = 1
	mroot.p2.meter = 40.0
	_land_hit(mroot, mroot.p1, mroot.p2, ex_10f_p1)
	# A fresh-combo hit clears the prior combo's once-per-combo rail (A1);
	# simulate a break already used in THIS new combo after impact.
	mroot.p2.breaker_used_this_combo = true
	mroot.p2.input_buffer["grab"] = 0
	mroot.p2.input_buffer["special"] = 0
	var used_broke: bool = await _step_until_break(mroot, mroot.p2, 20)
	_check("an impact-frame pending chord cannot break twice in one combo",
		not used_broke and mroot.p2.breaker_free_uses_left == 1
			and is_equal_approx(mroot.p2.meter, 40.0)
			and mroot.p2.breaker_invuln_frames == 0,
		"broke=%s free=%d meter=%.1f" % [str(used_broke),
			mroot.p2.breaker_free_uses_left, mroot.p2.meter])

	# Mashing keeps working but resolves exactly once (no repeat spending or
	# re-trigger after the break moves the defender to neutral).
	_reset_pair(mroot, 100.0, 140.0)
	_land_hit(mroot, mroot.p1, mroot.p2, ex_10f_p1)
	var break_signals := [0]
	mroot.p2.breaker_used.connect(func(_free: bool): break_signals[0] += 1)
	for _frame in 24:
		await _step(mroot, 1, "p2_grab+p2_special")
	_check("mashing the pair still breaks exactly once",
		break_signals[0] == 1 and mroot.p2.breaker_used_this_combo
			and mroot.p2.breaker_free_uses_left == 0,
		"signals=%d free=%d used=%s" % [break_signals[0],
			mroot.p2.breaker_free_uses_left, str(mroot.p2.breaker_used_this_combo)])

	# Save/restore DURING hitstop after the chord is pending. An uninterrupted
	# run and the restored run must break on the same frame with identical
	# fighter state (the pending mask is part of serialize()/load()).
	var uninterrupted: Node = await _build_match()
	await _to_fight(uninterrupted)
	_prepare_breaker_hit(uninterrupted, uninterrupted.p1, uninterrupted.p2,
		uninterrupted.p1.data.find_ex_move(
			MoveData.InputType.SPECIAL_FWD, MoveData.Stance.STAND))
	uninterrupted.p2.input_buffer["grab"] = 0
	uninterrupted.p2.input_buffer["special"] = 0
	await _step(uninterrupted, 1)
	var pending_snapshot: Dictionary = uninterrupted.serialize()
	_check("the impact-frame chord is serialized as pending during hitstop",
		pending_snapshot["p2"]["breaker_pending_hitstop_mask"] == 3
			and pending_snapshot["p2"]["hitstop_frames"] > 0,
		"pending=%d hitstop=%d" % [
			pending_snapshot["p2"]["breaker_pending_hitstop_mask"],
			pending_snapshot["p2"]["hitstop_frames"]])
	var uninterrupted_broke: bool = await _step_until_break(
		uninterrupted, uninterrupted.p2, 20)
	var uninterrupted_state: Dictionary = uninterrupted.p2.serialize()

	var restored: Node = await _build_match()
	await _to_fight(restored)
	restored.load(pending_snapshot)
	var restored_broke: bool = await _step_until_break(restored, restored.p2, 20)
	_check("a pending hitstop chord survives serialize/load with identical outcome",
		restored_broke == uninterrupted_broke and restored_broke
			and restored.p2.serialize() == uninterrupted_state,
		"uninterrupted=%s restored=%s pending=%d" % [
			str(uninterrupted_broke), str(restored_broke),
			restored.p2.breaker_pending_hitstop_mask])
	await _free_match(uninterrupted)
	await _free_match(restored)
	await _free_match(mroot)

# ---------------------------------------------------------------------------
# 5. Breaker in juggles and the corner escape
# ---------------------------------------------------------------------------

func _breaker_juggle_and_corner() -> void:
	var mroot: Node = await _build_match()
	await _to_fight(mroot)
	var p1: FighterBase = mroot.p1
	var p2: FighterBase = mroot.p2
	var launcher: MoveData = p1.data.find_move(MoveData.InputType.SPECIAL_FWD, MoveData.Stance.STAND)
	var air_heavy: MoveData = p1.data.find_move(MoveData.InputType.HEAVY, MoveData.Stance.AIR)

	# 5a. A juggled defender can break between air hits (decision #9).
	_reset_pair(mroot, 100.0, 140.0)
	_land_hit(mroot, p1, p2, launcher)
	_check("the launch put the defender in an airborne juggle",
		not p2.grounded and p2.state == FighterBase.State.HITSTUN
			and p2.juggle_points >= 0,
		"grounded=%s points=%d" % [p2.grounded, p2.juggle_points])
	_land_hit(mroot, p1, p2, air_heavy) # first juggle hit lands
	var broke: bool = await _break_out(mroot, p2)
	_check("a juggled defender breaks out of the juggle",
		broke and p2.state == FighterBase.State.JUMP_FALL and p2.breaker_invuln_frames > 0,
		"broke=%s state=%d invuln=%d" % [broke, p2.state, p2.breaker_invuln_frames])
	_check("the break kills the juggle budget",
		p2.juggle_points == -1 and p2.juggle_hits == 0,
		"points=%d hits=%d" % [p2.juggle_points, p2.juggle_hits])
	# The invuln window holds until touchdown; the fall cannot be re-hit.
	var protected_frames := 0
	while not p2.grounded and protected_frames < 60:
		await _step(mroot, 1)
		protected_frames += 1
	_check("the post-break invuln covers the rest of the juggle fall",
		p2.grounded and protected_frames <= FighterBase.BREAKER_INVULN_FRAMES + 40,
		"frames=%d" % protected_frames)

	# 5b. The corner-escape fix: a defender pinned at the wall breaks, the
	# pushback transfers to the attacker, and the defender walks out. The
	# attacker stands close enough that the launcher actually reaches.
	_reset_pair(mroot, 250.0, 296.0)
	var right_bound: float = mroot.stage.right_bound
	p2.position.x = right_bound # pinned at the stage wall
	p2.breaker_used_this_combo = false
	p2.breaker_cooldown_frames = 0
	p2.breaker_free_uses_left = 1
	_land_hit(mroot, p1, p2, launcher)
	_check("the cornered defender is in hitstun",
		p2.state == FighterBase.State.HITSTUN, "state=%d" % p2.state)
	var attacker_x: float = p1.position.x
	var corner_broke: bool = await _break_out(mroot, p2)
	await _step(mroot, 8) # the transferred push runs on the attacker
	_check("the cornered defender breaks",
		corner_broke and p2.breaker_invuln_frames > 0, "broke=%s invuln=%d"
		% [corner_broke, p2.breaker_invuln_frames])
	_check("a wall-pinned defender's pushback transfers to the attacker",
		p1.position.x < attacker_x - 25.0,
		"dx=%.1f" % (p1.position.x - attacker_x))
	_check("the cornered defender is freed from the corner pressure",
		p2.state in [FighterBase.State.IDLE, FighterBase.State.JUMP_FALL],
		"state=%d" % p2.state)
	# Walk out of the corner during the invuln window.
	Input.action_press("p2_left")
	await _step(mroot, 24)
	Input.action_release("p2_left")
	_check("the cornered defender escapes the corner after the break",
		p2.position.x < right_bound - 30.0, "x=%.1f bound=%.1f" % [p2.position.x, right_bound])
	await _free_match(mroot)

# ---------------------------------------------------------------------------
# 6. Serialization and determinism
# ---------------------------------------------------------------------------

func _serialization_and_determinism() -> void:
	# 6a. Mid-stun snapshot: serialize the defender mid-window, restore, and
	# continue — the window, shake presses, and immunity all survive.
	var mroot: Node = await _build_match()
	await _to_fight(mroot)
	var p1: FighterBase = mroot.p1
	var p2: FighterBase = mroot.p2
	var taser: MoveData = p1.data.find_move(MoveData.InputType.SPECIAL_NEUTRAL, MoveData.Stance.STAND)
	_reset_pair(mroot, 100.0, 140.0)
	_land_hit(mroot, p1, p2, taser)
	for i in 12:
		await _step(mroot, 1)
	for i in 2:
		await _step(mroot, 1, "p2_up")
	var snap: Dictionary = p2.serialize()
	_check("the stun window serializes mid-stun",
		snap["stun_id"] == "taser_buzz" and snap["stun_frames_remaining"] > 0
			and snap["stun_grant_immunity"] == 240,
		"id=%s frames=%d" % [snap["stun_id"], snap["stun_frames_remaining"]])
	var remaining_at_snap: int = p2.stun_frames_remaining
	var presses_at_snap: int = p2.stun_shake_presses
	p2.reset_state()
	p2.load(snap)
	_check("a mid-stun restore resumes the exact window and shake count",
		p2.stun_id == &"taser_buzz" and p2.stun_frames_remaining == remaining_at_snap
			and p2.stun_shake_presses == presses_at_snap,
		"frames=%d/%d presses=%d/%d" % [p2.stun_frames_remaining, remaining_at_snap,
			p2.stun_shake_presses, presses_at_snap])

	# 6b. Mid-break snapshot: the spent free use, the cooldown, and the
	# invuln window all round-trip.
	var heavy: MoveData = p1.data.find_move(MoveData.InputType.HEAVY, MoveData.Stance.STAND)
	_reset_pair(mroot, 100.0, 140.0)
	_land_hit(mroot, p1, p2, heavy)
	var broke: bool = await _break_out(mroot, p2)
	var snap2: Dictionary = p2.serialize()
	_check("the breaker state serializes mid-break",
		broke and snap2["breaker_free_uses_left"] == 0 and snap2["breaker_invuln_frames"] > 0
			and snap2["breaker_cooldown_frames"] > 0,
		"free=%d invuln=%d cd=%d" % [snap2["breaker_free_uses_left"],
			snap2["breaker_invuln_frames"], snap2["breaker_cooldown_frames"]])
	p2.reset_state()
	p2.load(snap2)
	_check("a mid-break restore resumes cooldown and invuln exactly",
		p2.breaker_free_remaining() == 0 and p2.breaker_invuln_frames > 0
			and p2.breaker_cooldown_left() == snap2["breaker_cooldown_frames"],
		"free=%d invuln=%d cd=%d" % [p2.breaker_free_remaining(),
			p2.breaker_invuln_frames, p2.breaker_cooldown_left()])
	await _free_match(mroot)

	# 6c. Determinism: two identical scripted stun-then-string sequences end
	# in identical state (no RNG, no delta, no node order).
	var states: Array[Dictionary] = []
	for run in 2:
		var m: Node = await _build_match()
		await _to_fight(m)
		var a: FighterBase = m.p1
		var d: FighterBase = m.p2
		var tas: MoveData = a.data.find_move(MoveData.InputType.SPECIAL_NEUTRAL, MoveData.Stance.STAND)
		var lit: MoveData = a.data.find_move(MoveData.InputType.LIGHT, MoveData.Stance.STAND)
		_reset_pair(m, 100.0, 140.0)
		_land_hit(m, a, d, tas)
		for i in 22:
			await _step(m, 1)
			if i % 3 == 0:
				await _step(m, 0, "p2_up")
		_land_hit(m, a, d, lit)
		await _step(m, 20)
		states.append(d.serialize())
		await _free_match(m)
	var left: Dictionary = states[0]
	var right: Dictionary = states[1]
	var same := true
	for key in ["health", "state", "state_frame", "stun_frames_remaining",
			"stun_immunity_frames", "breaker_free_uses_left", "combo_hits",
			"stun_shake_presses"]:
		if str(left[key]) != str(right[key]):
			same = false
			_check("determinism key mismatch: " + key, false,
				"%s vs %s" % [str(left[key]), str(right[key])])
	_check("two identical stun+string runs end in identical state", same, "")
