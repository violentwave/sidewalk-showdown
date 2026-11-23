# Combo adversarial suite — an INDEPENDENT check of the Phase 1-3 combo layer
# (cancel graph, Clip Cancel, juggle budget, stuns, breaker), written by an
# agent that did not build those features. Every check states the INTENDED
# behavior; a FAIL here is a finding logged in docs/COMBO_FINDINGS.md
# ("Adversarial pass 2"), not something this suite papers over.
#
# Attack list (see the findings doc): breaker abuse (re-hit, cooldown-edge,
# 0-meter, stun, juggle, budget-rejection frame, KO frame, blockstun,
# hitstop, round transition, new-combo meter break), the shared
# grab+special pair (Clip Cancel vs breaker option-select, trades), stun
# edge cases (launcher chains, heavy scaling, immunity boundary,
# counter-hit, shake-out, wake-up), combined stun/launcher/juggle/clip/break
# loops, every-frame serialize/restore determinism, P1/P2 swap symmetry, and
# meter accounting.
#
# Run: godot --headless --path game --script res://tests/combo_adversarial_test.gd
#
# Same harness contract as stun_breaker_test.gd (the #76 fix): the engine must
# NEVER tick the match — physics disabled pre-add, post-add, and re-asserted
# after the ready awaits. All randomness is a test-local seeded LCG; the
# gameplay CPU RNG is never touched.
extends SceneTree

const PEGGY := "res://resources/fighters/peg_leg_peggy.tres"
const RICHARD := "res://resources/fighters/whiskey_richard.tres"
const GAS_N_GO := "res://resources/stages/gas_n_go.tres"
const BUS_STOP := "res://resources/stages/bus_stop_night.tres"

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
	await _breaker_abuse()
	await _clip_cancel_vs_breaker()
	await _ruling_matrix()
	await _stun_edge_cases()
	await _combined_loops_fuzz()
	await _every_frame_restore()
	await _p1_p2_symmetry()
	await _meter_checks()
	await _earlier_findings_recheck()
	print("combo_adversarial: %d checks, %d failure(s)" % [checks, failures])
	quit(1 if failures > 0 else 0)

# ---------------------------------------------------------------------------
# harness (the #76 contract, copied from stun_breaker_test.gd)
# ---------------------------------------------------------------------------

func _build_match(p1_path: String, p2_path: String, stage_path: String) -> Node:
	var mroot: Node = load("res://scenes/match/MatchRoot.tscn").instantiate()
	mroot.selected_p1_data = load(p1_path)
	mroot.selected_p2_data = load(p2_path)
	mroot.selected_stage = load(stage_path)
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
		# decides the side), exactly like stun_breaker's _step.
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
	# reset_state re-arms the round-scoped breaker budget (see the Phase 3
	# note in reset_state); tests that need a spent budget set it back after.
	mroot.p1.reset_state()
	mroot.p2.reset_state()

# Land `move` from attacker onto defender, on the first active frame, through
# the real resolver (positions must already be in range).
func _land_hit(mroot: Node, attacker: FighterBase, move: MoveData) -> void:
	attacker._start_move(move)
	attacker.state_frame = move.startup
	mroot._resolve_hits()

# Inject the breaker pair (grab+special) into `who`'s buffer once.
func _press_pair(who: FighterBase) -> void:
	who.input_buffer["grab"] = 0
	who.input_buffer["special"] = 0

# Breaker pair pressed once; step until it resolves or `max_frames` pass.
func _try_break(mroot: Node, who: FighterBase, max_frames: int = 20) -> bool:
	_press_pair(who)
	for i in max_frames:
		await _step(mroot, 1)
		if who.breaker_invuln_frames > 0:
			return true
	return false

# Test-local deterministic LCG (same constants as the other suites; the
# gameplay CPU RNG is never touched).
func _lcg(state: int) -> int:
	return (state * 1664525 + 1013904223) & 0xFFFFFFFF

func _actionable(f: FighterBase) -> bool:
	return f.grounded and f.state in [FighterBase.State.IDLE,
		FighterBase.State.WALK_F, FighterBase.State.WALK_B,
		FighterBase.State.CROUCH]

# Whole-match fingerprint: integer fields only, covers every Phase 3 counter.
func _match_hash(mroot: Node) -> int:
	var p1: FighterBase = mroot.p1
	var p2: FighterBase = mroot.p2
	return hash([
		int(round(p1.position.x)), int(round(p1.position.y)),
		int(p1.state), int(p1.state_frame),
		int(round(p1.health * 100.0)), int(round(p1.meter * 100.0)),
		int(round(p2.position.x)), int(round(p2.position.y)),
		int(p2.state), int(p2.state_frame),
		int(round(p2.health * 100.0)), int(round(p2.meter * 100.0)),
		p2.combo_hits, p2.juggle_hits, p2.juggle_points,
		int(round(p2.combo_tracker.total_damage * 100.0)),
		String(p2.stun_id), p2.stun_frames_remaining, p2.stun_immunity_frames,
		p1.breaker_free_uses_left, p2.breaker_free_uses_left,
		int(p2.breaker_cooldown_frames), int(p2.breaker_invuln_frames),
		int(mroot.timer_frames), int(mroot.sim_frame),
	])

# ---------------------------------------------------------------------------
# 1. Breaker abuse
# ---------------------------------------------------------------------------

func _breaker_abuse() -> void:
	# Both matchups: each character takes a turn as the DEFENDER (the breaker
	# role is defender-side, so both fighter datasets get exercised).
	for matchup in [[PEGGY, RICHARD], [RICHARD, PEGGY]]:
		var p1_path: String = matchup[0]
		var p2_path: String = matchup[1]
		var dfd_name: String = "Richard" if p1_path == PEGGY else "Peggy"
		var mroot: Node = await _build_match(p1_path, p2_path, GAS_N_GO)
		await _to_fight(mroot)
		var p1: FighterBase = mroot.p1
		var p2: FighterBase = mroot.p2
		var heavy: MoveData = p1.data.find_move(MoveData.InputType.HEAVY, MoveData.Stance.STAND)
		var tag := "breaker abuse (defender " + dfd_name + "): "

		# 1a. Break, then immediately get re-hit: the 20f invuln window blocks
		# the re-hit (a query, meaty-safe), then a fresh hit connects.
		_reset_pair(mroot, 100.0, 140.0)
		_land_hit(mroot, p1, heavy)
		var broke: bool = await _try_break(mroot, p2)
		var invuln_live: bool = p2.breaker_invuln_frames > 0 \
			and p2.is_invulnerable_to(heavy)
		await _step(mroot, 25) # invuln (20) fully served
		_reset_pair(mroot, 100.0, 140.0)
		var hp_fresh: float = p2.health
		_land_hit(mroot, p1, heavy)
		_check(tag + "the 20f post-break invuln blocks the immediate re-hit, then a fresh hit lands",
			broke and invuln_live and p2.health < hp_fresh,
			"broke=%s invuln_live=%s hp=%.2f" % [str(broke), str(invuln_live),
				p2.health])

		# 1b. Break on the EXACT frame the cooldown ends: the cooldown counts
		# down before the check, so the break must fire that very tick.
		_reset_pair(mroot, 100.0, 140.0)
		p2.breaker_free_uses_left = 0
		p2.breaker_used_this_combo = false
		p2.breaker_cooldown_frames = 1
		p2.meter = 100.0
		_land_hit(mroot, p1, heavy)
		var cd_broke: bool = await _try_break(mroot, p2, 12)
		_check(tag + "a break fires on the exact frame the cooldown ends",
			cd_broke and is_equal_approx(p2.meter, 60.0),
			"broke=%s meter=%.1f cooldown=%d" % [str(cd_broke), p2.meter,
				p2.breaker_cooldown_frames])

		# 1c. Break at 0 meter after the free one is used: refused, nothing
		# spent, no invuln, hitstun runs its natural course.
		_reset_pair(mroot, 100.0, 140.0)
		p2.breaker_free_uses_left = 0
		p2.breaker_used_this_combo = false
		p2.breaker_cooldown_frames = 0
		p2.meter = 0.0
		_land_hit(mroot, p1, heavy)
		var zero_broke: bool = await _try_break(mroot, p2, 16)
		_check(tag + "a 0-meter, 0-free defender cannot break and spends nothing",
			not zero_broke and is_equal_approx(p2.meter, 0.0)
				and p2.breaker_invuln_frames == 0,
			"broke=%s meter=%.1f invuln=%d" % [str(zero_broke), p2.meter,
				p2.breaker_invuln_frames])

		# 1d. Break during a stun window: stun rides HITSTUN, so the break is
		# legal and must END the stun, granting the authored immunity.
		_reset_pair(mroot, 100.0, 140.0)
		var stun_move: MoveData = p1.data.find_move(
			MoveData.InputType.SPECIAL_NEUTRAL, MoveData.Stance.STAND)
		_land_hit(mroot, p1, stun_move)
		var in_stun: bool = p2.stun_id != &""
		var stun_broke: bool = await _try_break(mroot, p2)
		_check(tag + "a break during a stun ends the window and grants immunity",
			in_stun and stun_broke and p2.stun_id == &""
				and p2.stun_immunity_frames > 0,
			"stunned=%s broke=%s stun=%s immunity=%d" % [str(in_stun),
				str(stun_broke), String(p2.stun_id), p2.stun_immunity_frames])

		# 1e. Break during a juggle: the launched defender breaks mid-air, the
		# juggle record dies, the invuln blocks the next air hit, and the
		# defender lands and can act.
		_reset_pair(mroot, 100.0, 140.0)
		var launcher: MoveData = p1.data.find_move(
			MoveData.InputType.SPECIAL_FWD, MoveData.Stance.STAND)
		_land_hit(mroot, p1, launcher)
		var airborne: bool = not p2.grounded and p2.juggle_points == 5
		var juggle_broke: bool = await _try_break(mroot, p2)
		var record_dead: bool = p2.combo_hits == 0 and p2.juggle_points == -1
		var air_l: MoveData = p1.data.find_move(MoveData.InputType.LIGHT, MoveData.Stance.AIR)
		var invuln_blocks: bool = p2.is_invulnerable_to(air_l)
		var landed := false
		for i in 150:
			await _step(mroot, 1)
			if _actionable(p2):
				landed = true
				break
		_check(tag + "a mid-juggle break kills the record and the defender lands",
			airborne and juggle_broke and record_dead and invuln_blocks and landed,
			"air=%s broke=%s dead=%s invuln_blocks=%s landed=%s"
				% [str(airborne), str(juggle_broke), str(record_dead),
					str(invuln_blocks), str(landed)])

		# 1f. Break at the budget-rejection frame: budget spent to 1 point,
		# the next air hit would reject — the break must still fire.
		_reset_pair(mroot, 100.0, 140.0)
		_land_hit(mroot, p1, launcher)
		p2.receive_hit(p1, air_l) # 5 -> 3
		p2.receive_hit(p1, p1.data.find_move(MoveData.InputType.HEAVY,
			MoveData.Stance.AIR)) # 3 -> 1
		var at_rejection: bool = p2.juggle_points == 1 \
			and p2.receive_hit(p1, air_l) == false
		var rej_broke: bool = await _try_break(mroot, p2)
		_check(tag + "the break fires at the budget-rejection frame",
			at_rejection and rej_broke,
			"at_reject=%s broke=%s points=%d" % [str(at_rejection),
				str(rej_broke), p2.juggle_points])

		# 1g. Break on the frame of a KO: the killing blow resolves first,
		# the defender is in KO — no break, no meter spent.
		_reset_pair(mroot, 100.0, 140.0)
		p2.health = 10.0
		p2.meter = 100.0
		_land_hit(mroot, p1, heavy)
		var ko_now: bool = p2.state == FighterBase.State.KO
		var ko_broke: bool = await _try_break(mroot, p2, 8)
		_check(tag + "a KO'd defender cannot break",
			ko_now and not ko_broke and is_equal_approx(p2.meter, 100.0)
				and p2.breaker_invuln_frames == 0,
			"ko=%s broke=%s meter=%.1f" % [str(ko_now), str(ko_broke), p2.meter])

		# 1h. Break in blockstun must fail (blocking is already the defense).
		_reset_pair(mroot, 100.0, 140.0)
		Input.action_press("p2_right") # p2 faces left: hold away to block
		_land_hit(mroot, p1, heavy)
		var blocked: bool = p2.state == FighterBase.State.BLOCKSTUN
		var block_broke: bool = await _try_break(mroot, p2, 16)
		Input.action_release("p2_right")
		_check(tag + "a blocked hit opens no break",
			blocked and not block_broke and p2.breaker_invuln_frames == 0,
			"blocked=%s broke=%s" % [str(blocked), str(block_broke)])

		# 1i. Break during hitstop: a pair pressed ONCE on the exact impact
		# frame must still resolve once the hitstop is served. The 5-frame
		# hitstop buffer freeze (a pinned engine rule) bounds how long the
		# pair can wait — a 10-hitstop EX launcher is the worst legal case.
		_reset_pair(mroot, 100.0, 140.0)
		var ex_launcher: MoveData = p1.data.find_ex_move(
			MoveData.InputType.SPECIAL_FWD, MoveData.Stance.STAND)
		_land_hit(mroot, p1, ex_launcher)
		_press_pair(p2) # exactly one press, on the impact frame
		var hs_broke := false
		for i in 16:
			await _step(mroot, 1)
			if p2.breaker_invuln_frames > 0:
				hs_broke = true
				break
		_check(tag + "a single pair press at a 10f-hitstop EX impact still breaks",
			hs_broke,
			"hitstop=%d broke=%s grab_age=%s"
				% [ex_launcher.hitstop, str(hs_broke),
					str(p2.input_buffer.get("grab"))])

		# 1j. Round transition: the free break is round-scoped and must re-arm.
		_reset_pair(mroot, 100.0, 140.0)
		_land_hit(mroot, p1, heavy)
		var free_broke: bool = await _try_break(mroot, p2)
		var free_spent: bool = p2.breaker_free_uses_left == 0
		mroot._begin_round()
		_check(tag + "a new round re-arms the free break",
			free_broke and free_spent
				and p2.breaker_free_uses_left == p2.data.breaker_free_per_round
				and p2.breaker_cooldown_frames == 0
				and not p2.breaker_used_this_combo,
			"broke=%s free=%d/%d" % [str(free_broke), p2.breaker_free_uses_left,
				p2.data.breaker_free_per_round])

		# 1k. NEW-combo meter break after a NATURAL combo end: decision #1
		# promises extra breaks at 40 meter once the cooldown has lapsed —
		# the once-per-combo rail must be per COMBO, not per round.
		_reset_pair(mroot, 100.0, 140.0)
		p2.breaker_free_uses_left = 0
		p2.breaker_used_this_combo = false
		p2.breaker_cooldown_frames = 0
		p2.meter = 100.0
		_land_hit(mroot, p1, heavy)
		var first_paid: bool = await _try_break(mroot, p2)
		var meter_after_first: float = p2.meter
		await _step(mroot, 90) # combo ends naturally (grounded, >40f idle)
		var combo_ended: bool = p2.combo_hits == 0 and not p2.combo_tracker.active
		p2.breaker_cooldown_frames = 0 # the 5 s cooldown has lapsed by now
		# Bring the defender back into the attacker's range WITHOUT a
		# reset_state (reset_state would clear the very flag under test).
		p2.position = Vector2(140.0, mroot.stage.floor_y)
		p2.velocity = Vector2.ZERO
		_land_hit(mroot, p1, heavy) # a brand-new combo
		var in_new_hitstun: bool = p2.state == FighterBase.State.HITSTUN
		var second_paid: bool = await _try_break(mroot, p2)
		_check(tag + "a new combo after the cooldown lapse can pay the 40-meter break (decision #1)",
			first_paid and is_equal_approx(meter_after_first, 60.0)
				and combo_ended and in_new_hitstun and second_paid
				and is_equal_approx(p2.meter, 20.0),
			"first=%s meter1=%.1f ended=%s hitstun=%s second=%s meter2=%.1f used_flag=%s"
				% [str(first_paid), meter_after_first, str(combo_ended),
					str(in_new_hitstun), str(second_paid), p2.meter,
					str(p2.breaker_used_this_combo)])

		await _free_match(mroot)

# ---------------------------------------------------------------------------
# 2. The shared grab+special pair: Clip Cancel vs breaker
# ---------------------------------------------------------------------------

func _clip_cancel_vs_breaker() -> void:
	var mroot: Node = await _build_match(PEGGY, RICHARD, GAS_N_GO)
	await _to_fight(mroot)
	var p1: FighterBase = mroot.p1
	var p2: FighterBase = mroot.p2
	var heavy: MoveData = p1.data.find_move(MoveData.InputType.HEAVY, MoveData.Stance.STAND)

	# 2a. Baseline: with meter, the pair during recovery is a Clip Cancel.
	# (clip_cancel_used itself is cleared a frame later — the budget returns
	# once the opponent's combo is inactive — so the pinned observables are
	# the 25-meter spend and the recovery ending in an actionable state.)
	_reset_pair(mroot, 100.0, 280.0) # out of reach: the heavy whiffs
	p1.meter = 100.0
	p1._start_move(heavy)
	await _step(mroot, heavy.startup + heavy.active + 2) # inside recovery
	var rec_frame: int = p1.state_frame
	_press_pair(p1)
	await _step(mroot, 3)
	_check("pair baseline: grab+special in recovery is a Clip Cancel (25 meter)",
		is_equal_approx(p1.meter, 75.0) and _actionable(p1)
			and p1.state_frame < rec_frame,
		"meter=%.1f state=%d frame=%d" % [p1.meter, p1.state, p1.state_frame])

	# 2b. Owner ruling on A3 (2026-11-22): with NO meter the refused
	# Clip Cancel CONSUMES the buffered pair, so a punish in that same
	# window can no longer convert it into the (free) breaker. The
	# safe-cancel/break option-select is ruled out.
	_reset_pair(mroot, 100.0, 280.0) # out of reach: the heavy whiffs
	p1.meter = 0.0
	p1._start_move(heavy)
	await _step(mroot, heavy.startup + heavy.active + 2) # recovery, whiffs
	_press_pair(p1) # a clip-cancel attempt the meter cannot pay
	await _step(mroot, 1) # the refusal tick consumes the pair
	var pair_cleared: bool = not (p1.input_buffer.has("grab") \
			and p1.input_buffer.has("special"))
	var p2_heavy: MoveData = p2.data.find_move(MoveData.InputType.HEAVY,
			MoveData.Stance.STAND)
	p2.position = Vector2(p1.position.x + 40.0, mroot.stage.floor_y)
	p2._start_move(p2_heavy)
	p2.state_frame = p2_heavy.startup
	mroot._resolve_hits()
	var punished: bool = p1.state == FighterBase.State.HITSTUN
	await _step(mroot, 16)
	_check("pair collision (A3 ruling): the refused pair is consumed and never converts to a breaker on punish",
		pair_cleared and punished and not p1.breaker_used_this_combo
			and p1.breaker_invuln_frames == 0,
		"cleared=%s punished=%s break=%s invuln=%d"
			% [str(pair_cleared), str(punished), str(p1.breaker_used_this_combo),
				p1.breaker_invuln_frames])

	# 2c. Trade: both fighters in HITSTUN with the pair buffered — each side's
	# break is individually legal, costs are exact, and both recover to IDLE.
	_reset_pair(mroot, 100.0, 140.0)
	p1.breaker_free_uses_left = 0
	p2.breaker_free_uses_left = 0
	p1.breaker_used_this_combo = false
	p2.breaker_used_this_combo = false
	p1.meter = 100.0
	p2.meter = 100.0
	p1._start_move(heavy)
	p1.state_frame = heavy.startup
	p2._start_move(p2_heavy)
	p2.state_frame = p2_heavy.startup
	mroot._resolve_hits() # the trade: both connect this frame
	var traded: bool = p1.state == FighterBase.State.HITSTUN \
		and p2.state == FighterBase.State.HITSTUN
	_press_pair(p1)
	_press_pair(p2)
	await _step(mroot, 14)
	var both_recovered := false
	for i in 80:
		await _step(mroot, 1)
		if _actionable(p1) and _actionable(p2):
			both_recovered = true
			break
	_check("pair collision: a trade with both pairs buffered breaks both sides legally",
		traded and p1.breaker_used_this_combo and p2.breaker_used_this_combo
			and is_equal_approx(p1.meter, 60.0) and is_equal_approx(p2.meter, 60.0)
			and both_recovered,
		"traded=%s b1=%s b2=%s m1=%.1f m2=%.1f recovered=%s"
			% [str(traded), str(p1.breaker_used_this_combo),
				str(p2.breaker_used_this_combo), p1.meter, p2.meter,
				str(both_recovered)])

	await _free_match(mroot)

# ---------------------------------------------------------------------------
# 2d. Owner rulings on A2/A3 (2026-11-22): the breaker pair bridges hitstop
# like the tech window; a meter-refused Clip Cancel consumes the pair.
# Both characters defend, in both P1/P2 slots, on both stages.
# ---------------------------------------------------------------------------

# Press the pair once and step until a break resolves (or give up).
func _press_and_break(mroot: Node, who: FighterBase, max_frames: int) -> bool:
	_press_pair(who)
	for i in max_frames:
		await _step(mroot, 1)
		if who.breaker_invuln_frames > 0:
			return true
	return false

func _ruling_matrix() -> void:
	for stage_path in [GAS_N_GO, BUS_STOP]:
		var stage_label: String = stage_path.trim_prefix("res://resources/stages/").trim_suffix(".tres")
		for order in [0, 1]:
			# order 0: the defender holds the P2 slot; order 1: the P1 slot —
			# both characters defend, both sides, both stages.
			var atk_path: String = PEGGY if order == 0 else RICHARD
			var dfd_path: String = RICHARD if order == 0 else PEGGY
			var mroot: Node = await _build_match(atk_path, dfd_path, stage_path)
			await _to_fight(mroot)
			var atk: FighterBase = mroot.p1
			var dfd: FighterBase = mroot.p2
			var tag := "rulings (%s, %s defends from P%d): " % [stage_label,
				dfd.data.display_name, 2 if order == 0 else 1]
			var heavy: MoveData = atk.data.find_move(MoveData.InputType.HEAVY,
				MoveData.Stance.STAND)
			var ex_fwd: MoveData = atk.data.find_ex_move(
				MoveData.InputType.SPECIAL_FWD, MoveData.Stance.STAND)
			var meth: MoveData = atk.data.meth_move

			# A2, hitstop 6: a single press on a heavy's impact frame breaks.
			_reset_pair(mroot, 100.0, 140.0)
			_land_hit(mroot, atk, heavy)
			var hs6: bool = await _press_and_break(mroot, dfd, 14)
			_check(tag + "a single pair press at a hitstop-6 impact breaks",
				hs6, "broke=%s" % str(hs6))

			# A2, hitstop 10: a single press on an EX launcher's impact frame
			# breaks once hitstop has served.
			_reset_pair(mroot, 100.0, 140.0)
			_land_hit(mroot, atk, ex_fwd)
			var hs10: bool = await _press_and_break(mroot, dfd, 18)
			_check(tag + "a single pair press at a hitstop-10 EX impact breaks",
				hs10, "broke=%s" % str(hs10))

			# A2, hitstop 30 (METHtality): the landed METH is a KNOCKDOWN —
			# the breaker is NOT otherwise legal there, so the single press
			# must NOT fire, and the latch must not linger into a ghost break
			# after the knockdown and wake-up resolve.
			_reset_pair(mroot, 100.0, 140.0)
			dfd.health = meth.damage + 250.0 # survive the finisher on purpose
			atk.meter = atk.max_meter
			_land_hit(mroot, atk, meth)
			var meth_hit: bool = dfd.state in [FighterBase.State.KNOCKDOWN,
				FighterBase.State.HITSTUN]
			var hs30: bool = await _press_and_break(mroot, dfd, 80)
			_check(tag + "a single press at a hitstop-30 METH impact never breaks (knockdown) and leaves no ghost",
				meth_hit and not hs30,
				"meth_hit=%s broke=%s" % [str(meth_hit), str(hs30)])

			# A2, no-survive: with the breaker ILLEGAL (no budget, no meter),
			# a single press at an EX impact must not fire later either —
			# the latch expires with the input window once hitstop serves.
			_reset_pair(mroot, 100.0, 140.0)
			dfd.breaker_free_uses_left = 0
			dfd.breaker_used_this_combo = false
			dfd.breaker_cooldown_frames = 0
			dfd.meter = 0.0
			_land_hit(mroot, atk, ex_fwd)
			var ghost: bool = await _press_and_break(mroot, dfd, 20)
			_check(tag + "an illegal breaker's pair expires after hitstop with no late fire",
				not ghost, "broke=%s" % str(ghost))

			# A2, no-double-fire: after the hitstop-6 break, a fresh press
			# cannot spend the budget again — no invuln reset, no free-use
			# loss (the first break's invuln is still counting down, so the
			# detector is the reset, not the countdown itself).
			_reset_pair(mroot, 100.0, 140.0)
			_land_hit(mroot, atk, heavy)
			var first: bool = await _press_and_break(mroot, dfd, 14)
			var free_after_first: int = dfd.breaker_free_uses_left
			var invuln_before_second: int = dfd.breaker_invuln_frames
			_press_pair(dfd)
			await _step(mroot, 8)
			var second: bool = dfd.breaker_invuln_frames >= invuln_before_second \
					or dfd.breaker_free_uses_left != free_after_first
			_check(tag + "a second press inside the invuln window cannot break twice",
				first and not second,
				"first=%s second=%s free=%d invuln=%d/%d"
					% [str(first), str(second), dfd.breaker_free_uses_left,
						dfd.breaker_invuln_frames, invuln_before_second])

			# A3: a meter-refused clip-cancel pair is consumed and never
			# converts on punish (the attacker whiffs into recovery, presses
			# the pair it cannot pay for, then eats a punish heavy; the
			# whiff keeps the authored HIT routes from consuming the
			# buffered special before the refusal runs).
			_reset_pair(mroot, 100.0, 280.0) # out of reach: the heavy whiffs
			atk.meter = 0.0
			atk._start_move(heavy)
			await _step(mroot, heavy.startup + heavy.active + 2) # recovery
			_press_pair(atk)
			await _step(mroot, 1) # the refusal tick consumes the pair
			var pair_cleared: bool = not (atk.input_buffer.has("grab") \
					and atk.input_buffer.has("special"))
			dfd.position = Vector2(atk.position.x + 40.0, mroot.stage.floor_y)
			dfd._start_move(dfd.data.find_move(MoveData.InputType.HEAVY,
					MoveData.Stance.STAND))
			dfd.state_frame = dfd.data.find_move(MoveData.InputType.HEAVY,
					MoveData.Stance.STAND).startup
			mroot._resolve_hits()
			var punished: bool = atk.state == FighterBase.State.HITSTUN
			await _step(mroot, 16)
			_check(tag + "a meter-refused clip-cancel pair never converts to a breaker on punish",
				pair_cleared and punished
					and not atk.breaker_used_this_combo
					and atk.breaker_invuln_frames == 0,
				"cleared=%s punished=%s break=%s invuln=%d"
					% [str(pair_cleared), str(punished),
						str(atk.breaker_used_this_combo), atk.breaker_invuln_frames])

			# A3, with meter: the Clip Cancel still resolves exactly as
			# before (25 meter, recovery ends in an actionable state).
			_reset_pair(mroot, 100.0, 280.0) # out of reach: the heavy whiffs
			atk.meter = 100.0
			atk._start_move(heavy)
			await _step(mroot, heavy.startup + heavy.active + 2) # recovery
			_press_pair(atk)
			await _step(mroot, 3)
			_check(tag + "with meter the Clip Cancel still fires from recovery (25 meter)",
				is_equal_approx(atk.meter, 75.0) and _actionable(atk),
				"meter=%.1f state=%d" % [atk.meter, atk.state])

			await _free_match(mroot)

# ---------------------------------------------------------------------------
# 3. Stun edge cases
# ---------------------------------------------------------------------------

func _stun_edge_cases() -> void:
	# Both stun characters as the ATTACKER (Richard taser_buzz 45f/240f,
	# Peggy peg_lock 45f/60f), both stages.
	for stage_path in [GAS_N_GO, BUS_STOP]:
		var stage_label: String = stage_path.trim_prefix("res://resources/stages/").trim_suffix(".tres")
		for matchup in [[RICHARD, PEGGY], [PEGGY, RICHARD]]:
			var p1_path: String = matchup[0]
			var p2_path: String = matchup[1]
			var atk_name: String = "Richard" if p1_path == RICHARD else "Peggy"
			var mroot: Node = await _build_match(p1_path, p2_path, stage_path)
			await _to_fight(mroot)
			var p1: FighterBase = mroot.p1
			var p2: FighterBase = mroot.p2
			var stun_move: MoveData = p1.data.find_move(
				MoveData.InputType.SPECIAL_NEUTRAL, MoveData.Stance.STAND)
			var launcher: MoveData = p1.data.find_move(
				MoveData.InputType.SPECIAL_FWD, MoveData.Stance.STAND)
			var sweep: MoveData = p1.data.find_move(
				MoveData.InputType.HEAVY, MoveData.Stance.CROUCH)
			var stand_light: MoveData = p1.data.find_move(
				MoveData.InputType.LIGHT, MoveData.Stance.STAND)
			var tag := "stun edge (%s, %s stuns): " % [stage_label, atk_name]
			var stun_id: StringName = stun_move.stun.id
			var stun_dur: int = stun_move.stun.duration_frames
			var stun_min: int = stun_move.stun.minimum_frames
			var stun_immunity: int = stun_move.stun.immunity_frames
			var shake_per_press: int = stun_move.stun.shake_frames_per_press

			# 3a. Stun -> launcher -> stun attempt: the launcher consumes the
			# window (the authored immunity starts immediately), the mid-air
			# stun attempt fails (launcher_safe false), and the immunity is
			# live at that moment (checked before it can expire).
			_reset_pair(mroot, 100.0, 140.0)
			_land_hit(mroot, p1, stun_move)
			var stunned: bool = p2.stun_id == stun_id \
				and p2.stun_frames_remaining == stun_dur
			_land_hit(mroot, p1, launcher) # a string hit consumes the window
			var consumed: bool = p2.stun_id == &"" and not p2.grounded \
				and p2.stun_immunity_frames == stun_immunity
			_land_hit(mroot, p1, stun_move) # mid-air: may connect, must NOT stun
			var no_air_stun: bool = p2.stun_id == &"" and not p2.grounded
			_check(tag + "stun->launcher->mid-air stun attempt never double-stuns",
				stunned and consumed and no_air_stun,
				"stunned=%s consumed=%s air_stun=%s id=%s"
					% [str(stunned), str(consumed), str(no_air_stun),
						String(p2.stun_id)])

			# 3b. Stun at heavy scaling: the ladder floor (0.55) shrinks the
			# window to round(45*0.55)=25 (all-light fillers keep the stun
			# move variety-free and repeat-free); at hit 13 — past the
			# 12-hit cap — the damage is zero and there must be NO stun.
			_reset_pair(mroot, 100.0, 140.0)
			for i in 4:
				p2.receive_hit(p1, stand_light)
			p2.receive_hit(p1, stun_move) # hit 5: scale 0.55
			var floor_window: int = int(round(float(stun_dur) * 0.55))
			var shrunk: bool = p2.stun_id == stun_id \
				and p2.stun_frames_remaining == floor_window
			_reset_pair(mroot, 100.0, 140.0)
			for i in 12:
				p2.receive_hit(p1, stand_light)
			p2.receive_hit(p1, stun_move) # hit 13: capped, zero damage
			var no_stun_at_zero: bool = p2.stun_id == &"" \
				and p2.stun_frames_remaining == 0
			_check(tag + "heavy scaling shrinks the window and zero damage stuns nothing",
				shrunk and no_stun_at_zero,
				"shrunk=%s (window=%d want=%d) zero_ok=%s id=%s"
					% [str(shrunk), p2.stun_frames_remaining, floor_window,
						str(no_stun_at_zero), String(p2.stun_id)])

			# 3c. Stun on the exact frame immunity ends: with the combo already
			# ended (so once-per-combo cannot mask the boundary), at
			# immunity==1 a stun is rejected purely by immunity; one frame
			# later (immunity 0 at resolve time) it opens the full window.
			_reset_pair(mroot, 100.0, 140.0)
			_land_hit(mroot, p1, stun_move)
			_land_hit(mroot, p1, stand_light) # string hit consumes the window
			var immunity_live: bool = p2.stun_immunity_frames == stun_immunity
			for i in stun_immunity + 80:
				if p2.combo_hits == 0 and p2.stun_immunity_frames == 1:
					break
				await _step(mroot, 1)
			var at_one: bool = p2.combo_hits == 0 \
				and p2.stun_immunity_frames == 1
			p2.receive_hit(p1, stun_move) # no tick ran: immunity still 1
			var rejected: bool = p2.stun_id == &""
			# The rejected attempt still lands as a hit: its hitstop delays
			# the countdown AND its recorded id spends that combo's
			# once-per-stun budget, so the landing attempt waits for a fresh
			# combo after immunity is fully gone.
			for i in 100:
				if p2.combo_hits == 0 and p2.stun_immunity_frames == 0:
					break
				await _step(mroot, 1)
			var at_zero: bool = p2.combo_hits == 0 \
				and p2.stun_immunity_frames == 0
			p2.receive_hit(p1, stun_move)
			var landed_stun: bool = p2.stun_id == stun_id \
				and p2.stun_frames_remaining == stun_dur
			_check(tag + "the stun lands exactly when immunity expires, not a frame earlier",
				immunity_live and at_one and rejected and at_zero and landed_stun,
				"imm=%s at_one=%s rejected=%s at_zero=%s landed=%s"
					% [str(immunity_live), str(at_one), str(rejected),
						str(at_zero), str(landed_stun)])

			# 3d. Stun via counter-hit: the window is the same (counter-hit
			# adds hitstop, not stun).
			_reset_pair(mroot, 100.0, 140.0)
			p2.receive_hit(p1, stun_move, true)
			_check(tag + "a counter-hit stun opens the full authored window",
				p2.stun_id == stun_id and p2.stun_frames_remaining == stun_dur,
				"id=%s frames=%d" % [String(p2.stun_id), p2.stun_frames_remaining])

			# 3e. Shake-out: the authored minimum is unshakeable; the press on
			# the tick where the minimum ELAPSES is the first that shortens.
			_reset_pair(mroot, 100.0, 140.0)
			_land_hit(mroot, p1, stun_move)
			await _step(mroot, stun_move.hitstop) # hitstop served first
			var window_full: bool = p2.stun_frames_remaining == stun_dur
			for i in stun_min - 1:
				await _step(mroot, 1, "p2_up")
			var unshakeable: bool = p2.stun_shake_presses == 0 \
				and p2.stun_frames_remaining == stun_dur - (stun_min - 1)
			await _step(mroot, 1, "p2_up") # elapsed reaches the minimum
			var shook: bool = p2.stun_shake_presses == 1 \
				and p2.stun_frames_remaining == stun_dur - stun_min - shake_per_press
			_check(tag + "shake-out ignores presses before the minimum and shortens at it",
				window_full and unshakeable and shook,
				"full=%s unshakeable=%s shook=%s presses=%d remaining=%d"
					% [str(window_full), str(unshakeable), str(shook),
						p2.stun_shake_presses, p2.stun_frames_remaining])

			# 3f. Stun on a waking-up fighter: after the wake-up invuln tail
			# a stun connects — wake-up is stunnable, pinned here.
			_reset_pair(mroot, 100.0, 140.0)
			_land_hit(mroot, p1, sweep) # hard knockdown
			var downed: bool = p2.state == FighterBase.State.KNOCKDOWN
			var waking := false
			for i in 70:
				await _step(mroot, 1)
				if p2.state == FighterBase.State.WAKE_UP and p2.state_frame >= 6:
					waking = true
					break
			_land_hit(mroot, p1, stun_move)
			_check(tag + "a waking-up fighter past the invuln tail can be stunned",
				downed and waking and p2.stun_id == stun_id,
				"downed=%s waking=%s stun=%s" % [str(downed), str(waking),
					String(p2.stun_id)])

			# 3g. A blocked stun move is just a blocked move: no stun, no
			# meter, chip only.
			_reset_pair(mroot, 100.0, 140.0)
			Input.action_press("p2_right")
			var meter_before: float = p1.meter
			_land_hit(mroot, p1, stun_move)
			var blocked_nothing: bool = p2.state == FighterBase.State.BLOCKSTUN \
				and p2.stun_id == &"" and is_equal_approx(p1.meter, meter_before)
			Input.action_release("p2_right")
			_check(tag + "a blocked stun move stuns nothing and pays no meter",
				blocked_nothing,
				"state=%d stun=%s meter=%.1f" % [p2.state, String(p2.stun_id), p1.meter])

			await _free_match(mroot)

# ---------------------------------------------------------------------------
# 4. Combined loops: seeded stun/launcher/juggle/clip/break fuzz
# ---------------------------------------------------------------------------

func _combined_loops_fuzz() -> void:
	var seed_base := 31000
	for stage_path in [GAS_N_GO, BUS_STOP]:
		var stage_label: String = stage_path.trim_prefix("res://resources/stages/").trim_suffix(".tres")
		for matchup in [[PEGGY, RICHARD], [RICHARD, PEGGY]]:
			for seed in [11, 29]:
				seed_base += 1
				await _fuzz_run(stage_path, stage_label, matchup[0], matchup[1],
					seed_base, seed == 29)

func _fuzz_run(stage_path: String, stage_label: String, p1_path: String,
		p2_path: String, seed: int, corner_start: bool) -> void:
	var mroot: Node = await _build_match(p1_path, p2_path, stage_path)
	await _to_fight(mroot)
	mroot.fighters_can_pass_through = true
	var right_bound: float = mroot.stage.right_bound
	if corner_start:
		_reset_pair(mroot, right_bound - 200.0, right_bound) # defender pinned
	else:
		_reset_pair(mroot, 100.0, 140.0)
	var p1: FighterBase = mroot.p1
	var p2: FighterBase = mroot.p2
	var rng_state := seed
	var bad := false
	var bad_why := ""
	var breaks := 0
	var max_stun := 0
	var air_hits := 0
	var corner_breaks := 0
	var corner_escapes := 0
	var frame := 0
	var last_hash: int = 0
	var same_streak := 0
	var stun_neutral: MoveData = p1.data.find_move(
		MoveData.InputType.SPECIAL_NEUTRAL, MoveData.Stance.STAND)
	var fwd_special: MoveData = p1.data.find_move(
		MoveData.InputType.SPECIAL_FWD, MoveData.Stance.STAND)
	var stand_heavy: MoveData = p1.data.find_move(
		MoveData.InputType.HEAVY, MoveData.Stance.STAND)
	var air_l: MoveData = p1.data.find_move(
		MoveData.InputType.LIGHT, MoveData.Stance.AIR)
	var p2_stun: MoveData = p2.data.find_move(
		MoveData.InputType.SPECIAL_NEUTRAL, MoveData.Stance.STAND)
	var p2_fwd: MoveData = p2.data.find_move(
		MoveData.InputType.SPECIAL_FWD, MoveData.Stance.STAND)
	var p2_heavy: MoveData = p2.data.find_move(
		MoveData.InputType.HEAVY, MoveData.Stance.STAND)
	var p2_air: MoveData = p2.data.find_move(
		MoveData.InputType.LIGHT, MoveData.Stance.AIR)
	while frame < 420:
		rng_state = _lcg(rng_state)
		# Attack schedule: the LCG picks the attacker and the move; hits go
		# through the real resolver so invuln/immunity gates all apply.
		var who: FighterBase = p1 if rng_state % 2 == 0 else p2
		var other: FighterBase = p2 if who == p1 else p1
		var pick: int = rng_state % 7
		if pick == 0:
			var m: MoveData = stun_neutral if who == p1 else p2_stun
			who._start_move(m)
			who.state_frame = m.startup
			mroot._resolve_hits()
		elif pick == 1:
			var m2: MoveData = fwd_special if who == p1 else p2_fwd
			who._start_move(m2)
			who.state_frame = m2.startup
			mroot._resolve_hits()
		elif pick == 2 and not other.grounded:
			other.receive_hit(who, air_l if who == p1 else p2_air)
			air_hits += 1
		elif pick == 3:
			var m3: MoveData = stand_heavy if who == p1 else p2_heavy
			who._start_move(m3)
			who.state_frame = m3.startup
			mroot._resolve_hits()
		# Breaker mashing: inject the pair while the OTHER side is in hitstun.
		rng_state = _lcg(rng_state)
		if rng_state % 3 == 0 and other.state == FighterBase.State.HITSTUN:
			_press_pair(other)
		# Clip Cancel mashing from whoever is in recovery.
		rng_state = _lcg(rng_state)
		if rng_state % 5 == 0 and who.state == FighterBase.State.ATTACK \
				and who.current_move != null \
				and who.state_frame >= who.current_move.startup + who.current_move.active:
			_press_pair(who)
		await _step(mroot, 1)
		frame += 1
		max_stun = maxi(max_stun, maxi(p1.stun_frames_remaining, p2.stun_frames_remaining))
		if p1.breaker_invuln_frames > 0 or p2.breaker_invuln_frames > 0:
			breaks += 1
		# Corner-escape accounting: a defender break at the wall must move
		# SOMEBODY (the wall-pinned share transfers to the attacker).
		if corner_start and p2.breaker_invuln_frames == 19:
			corner_breaks += 1
			if p2.position.x > right_bound - 1.0 \
					or p1.position.x < (right_bound - 200.0) + 1.0:
				corner_escapes += 1
		if is_nan(p1.health) or is_nan(p2.health) or p1.health < 0.0 or p2.health < 0.0 \
				or p1.meter < 0.0 or p2.meter < 0.0 \
				or p1.stun_frames_remaining < 0 or p2.stun_frames_remaining < 0 \
				or p1.stun_immunity_frames < 0 or p2.stun_immunity_frames < 0 \
				or p1.breaker_invuln_frames < 0 or p2.breaker_invuln_frames < 0 \
				or p1.juggle_hits < 0 or p2.juggle_hits < 0 or p1.juggle_points < -1 \
				or p2.juggle_points < -1 or p1.combo_tracker.total_damage > 550.01 \
				or p2.combo_tracker.total_damage > 550.01:
			bad = true
			bad_why = "scalar bound at frame %d" % frame
			break
		var now_hash: int = _match_hash(mroot)
		if now_hash == last_hash:
			same_streak += 1
			if same_streak > 120:
				bad = true
				bad_why = "frozen fingerprint at frame %d" % frame
				break
		else:
			same_streak = 0
			last_hash = now_hash
	# Termination: no scripted input for 200 frames; both must reach actionable.
	var settled := false
	for i in 200:
		await _step(mroot, 1)
		if _actionable(p1) and _actionable(p2):
			settled = true
			break
	_check("fuzz (seed %d, %s, corner=%s): stun/launcher/break loops stay bounded and terminate"
		% [seed, stage_label, str(corner_start)],
		not bad and settled and max_stun <= 45,
		"bad=%s why=%s settled=%s max_stun=%d break_frames=%d air_hits=%d"
			% [str(bad), bad_why, str(settled), max_stun, breaks, air_hits])
	if corner_start:
		_check("fuzz (seed %d, %s): every defender break at the wall separated somebody"
			% [seed, stage_label],
			corner_breaks == 0 or corner_escapes == corner_breaks,
			"corner_breaks=%d corner_escapes=%d" % [corner_breaks, corner_escapes])
	await _free_match(mroot)

# ---------------------------------------------------------------------------
# 5. Every-frame serialize/restore during a stun and around a break
# ---------------------------------------------------------------------------

func _every_frame_restore() -> void:
	await _every_frame_stun()
	await _every_frame_break()

# Timeline driver: taser lands at frame 0, then `n` plain steps. Returns the
# per-frame snapshots (n) and n+1 match hashes — the state at each frame
# before stepping, plus the state after the final step.
func _stun_timeline(mroot: Node, n: int) -> Array:
	var p1: FighterBase = mroot.p1
	var taser: MoveData = p1.data.find_move(
		MoveData.InputType.SPECIAL_NEUTRAL, MoveData.Stance.STAND)
	_reset_pair(mroot, 100.0, 140.0)
	p1._start_move(taser)
	p1.state_frame = taser.startup
	mroot._resolve_hits()
	var snaps: Array = []
	var hashes: Array = []
	for f in n:
		snaps.append(mroot.serialize())
		hashes.append(_match_hash(mroot))
		await _step(mroot, 1)
	hashes.append(_match_hash(mroot))
	return [snaps, hashes]

func _every_frame_stun() -> void:
	const N := 58
	var a: Node = await _build_match(RICHARD, PEGGY, GAS_N_GO)
	await _to_fight(a)
	var timeline: Array = await _stun_timeline(a, N)
	var snaps: Array = timeline[0]
	var hashes_a: Array = timeline[1]
	await _free_match(a)

	var mismatches := 0
	var first_bad := -1
	for f in N:
		var b: Node = await _build_match(RICHARD, PEGGY, GAS_N_GO)
		await _to_fight(b)
		await _stun_timeline(b, f) # replay to frame f
		b.load(snaps[f])
		var ok := true
		for i in range(f, N):
			await _step(b, 1)
			if _match_hash(b) != hashes_a[i + 1]:
				ok = false
				mismatches += 1
				if first_bad < 0:
					first_bad = f
				break
		await _free_match(b)
		if not ok:
			break
	_check("every-frame restore: all %d stun frames replay identically after a load" % N,
		mismatches == 0, "mismatches=%d first_bad_frame=%d" % [mismatches, first_bad])

# Timeline driver for the break: a heavy lands, the pair is pressed once,
# the break fires inside the window; snapshots at every frame.
func _break_timeline(mroot: Node, n: int) -> Array:
	var p1: FighterBase = mroot.p1
	var p2: FighterBase = mroot.p2
	var heavy: MoveData = p1.data.find_move(
		MoveData.InputType.HEAVY, MoveData.Stance.STAND)
	_reset_pair(mroot, 100.0, 140.0)
	p2.meter = 60.0
	p2.breaker_free_uses_left = 0
	p1._start_move(heavy)
	p1.state_frame = heavy.startup
	mroot._resolve_hits()
	_press_pair(p2)
	var snaps: Array = []
	var hashes: Array = []
	for f in n:
		snaps.append(mroot.serialize())
		hashes.append(_match_hash(mroot))
		await _step(mroot, 1)
	hashes.append(_match_hash(mroot))
	return [snaps, hashes]

func _every_frame_break() -> void:
	const N := 24
	var a: Node = await _build_match(RICHARD, PEGGY, GAS_N_GO)
	await _to_fight(a)
	var timeline: Array = await _break_timeline(a, N)
	var snaps: Array = timeline[0]
	var hashes_a: Array = timeline[1]
	var broke_at := -1
	for f in N:
		var snap: Dictionary = snaps[f]
		if int(snap["p2"].get("breaker_invuln_frames", 0)) == 20:
			broke_at = f
			break
	await _free_match(a)

	var mismatches := 0
	var first_bad := -1
	for f in N:
		var b: Node = await _build_match(RICHARD, PEGGY, GAS_N_GO)
		await _to_fight(b)
		await _break_timeline(b, f) # replay to frame f
		b.load(snaps[f])
		var ok := true
		for i in range(f, N):
			await _step(b, 1)
			if _match_hash(b) != hashes_a[i + 1]:
				ok = false
				mismatches += 1
				if first_bad < 0:
					first_bad = f
				break
		await _free_match(b)
		if not ok:
			break
	_check("every-frame restore: all %d break frames replay identically after a load" % N,
		broke_at >= 0 and mismatches == 0,
		"broke_at=%d mismatches=%d first_bad_frame=%d" % [broke_at, mismatches, first_bad])

# ---------------------------------------------------------------------------
# 6. P1/P2 swap symmetry for the stun and breaker outcomes
# ---------------------------------------------------------------------------

func _p1_p2_symmetry() -> void:
	# Run 1: Richard is P1 (left), stuns Peggy (P2, right); Peggy breaks.
	# Run 2: the same fighters in swapped SLOTS, mirrored geometry: Peggy is
	# P1 on the left, Richard is P2 on the right and stuns her. Damage,
	# window, break cost, and the separation must be identical.
	var results: Array = []
	for order in [0, 1]:
		var mroot: Node
		if order == 0:
			mroot = await _build_match(RICHARD, PEGGY, GAS_N_GO)
		else:
			mroot = await _build_match(PEGGY, RICHARD, GAS_N_GO)
		await _to_fight(mroot)
		var richard: FighterBase = mroot.p1 if order == 0 else mroot.p2
		var peggy: FighterBase = mroot.p2 if order == 0 else mroot.p1
		_reset_pair(mroot, 100.0, 140.0)
		var taser: MoveData = richard.data.find_move(
			MoveData.InputType.SPECIAL_NEUTRAL, MoveData.Stance.STAND)
		richard._start_move(taser)
		richard.state_frame = taser.startup
		mroot._resolve_hits()
		var stun_ok: bool = peggy.stun_id == &"taser_buzz" \
			and peggy.stun_frames_remaining == 45
		var dmg: float = 1000.0 - peggy.health
		var broke: bool = await _try_break(mroot, peggy)
		await _step(mroot, 8) # the separation push runs out
		results.append({
			"stun_ok": stun_ok, "dmg": dmg, "broke": broke,
			"free_left": peggy.breaker_free_uses_left,
			"separation": absf(richard.position.x - peggy.position.x) - 40.0,
		})
		await _free_match(mroot)
	var r0: Dictionary = results[0]
	var r1: Dictionary = results[1]
	_check("P1/P2 swap symmetry: stun damage, window, break cost, and separation match",
		r0["stun_ok"] and r1["stun_ok"] and is_equal_approx(r0["dmg"], r1["dmg"])
			and r0["broke"] and r1["broke"]
			and r0["free_left"] == r1["free_left"]
			and is_equal_approx(float(r0["separation"]), float(r1["separation"])),
		"run1=%s run2=%s" % [str(r0), str(r1)])

# ---------------------------------------------------------------------------
# 7. Meter accounting
# ---------------------------------------------------------------------------

func _meter_checks() -> void:
	var mroot: Node = await _build_match(RICHARD, PEGGY, GAS_N_GO)
	await _to_fight(mroot)
	var p1: FighterBase = mroot.p1
	var p2: FighterBase = mroot.p2
	var heavy: MoveData = p1.data.find_move(MoveData.InputType.HEAVY, MoveData.Stance.STAND)

	# 7a. A stun hit pays the attacker nothing (the window is the reward).
	_reset_pair(mroot, 100.0, 140.0)
	var taser: MoveData = p1.data.find_move(
		MoveData.InputType.SPECIAL_NEUTRAL, MoveData.Stance.STAND)
	var meter_before: float = p1.meter
	_land_hit(mroot, p1, taser)
	_check("meter: the stun connection itself pays the attacker 0",
		is_equal_approx(p1.meter, meter_before), "meter=%.2f" % p1.meter)

	# 7b. A paid break costs exactly the authored 40.
	_reset_pair(mroot, 100.0, 140.0)
	p2.breaker_free_uses_left = 0
	p2.breaker_used_this_combo = false
	p2.breaker_cooldown_frames = 0
	p2.meter = 45.0
	_land_hit(mroot, p1, heavy)
	var paid: bool = await _try_break(mroot, p2)
	_check("meter: a paid break costs exactly 40 (45 -> 5)",
		paid and is_equal_approx(p2.meter, 5.0), "paid=%s meter=%.2f"
			% [str(paid), p2.meter])

	# 7c. A defender 1 meter short cannot pay, and repeated attempts never
	# drive the meter negative.
	_reset_pair(mroot, 100.0, 140.0)
	p2.breaker_free_uses_left = 0
	p2.breaker_used_this_combo = false
	p2.breaker_cooldown_frames = 0
	p2.meter = 39.0
	_land_hit(mroot, p1, heavy)
	var short_broke := false
	for i in 4:
		short_broke = short_broke or await _try_break(mroot, p2, 6)
	_check("meter: a 39-meter defender never pays a partial break",
		not short_broke and is_equal_approx(p2.meter, 39.0) and p2.meter >= 0.0,
		"broke=%s meter=%.2f" % [str(short_broke), p2.meter])

	await _free_match(mroot)

# ---------------------------------------------------------------------------
# 8. Re-verification of the earlier COMBO_FINDINGS entries
# ---------------------------------------------------------------------------

func _earlier_findings_recheck() -> void:
	var mroot: Node = await _build_match(PEGGY, RICHARD, GAS_N_GO)
	await _to_fight(mroot)
	var p1: FighterBase = mroot.p1
	var p2: FighterBase = mroot.p2

	# Finding 3 (snapshot aliasing): a snapshot held through a full stun +
	# combo reset must keep its contents.
	_reset_pair(mroot, 100.0, 140.0)
	var stun_move: MoveData = p1.data.find_move(
		MoveData.InputType.SPECIAL_NEUTRAL, MoveData.Stance.STAND)
	var stand_light: MoveData = p1.data.find_move(
		MoveData.InputType.LIGHT, MoveData.Stance.STAND)
	_land_hit(mroot, p1, stun_move)
	_land_hit(mroot, p1, stand_light)
	var snap: Dictionary = mroot.serialize()
	var snap_tracker: Dictionary = snap["p2"]["combo_tracker"]
	await _step(mroot, 120) # stun ends, immunity runs, combo fully resets
	_check("recheck finding 3: a held snapshot keeps its tracker contents",
		int(snap_tracker["hits"]) >= 1 and snap_tracker["move_ids"].size() >= 1
			and mroot.p2.combo_tracker.hits == 0,
		"snap_hits=%s live_hits=%d" % [str(snap_tracker["hits"]),
			mroot.p2.combo_tracker.hits])

	# Finding 4 (mid-air combo expiry): the combo window cannot expire while
	# the defender is airborne from a launch.
	_reset_pair(mroot, 100.0, 140.0)
	var ex_launcher: MoveData = p1.data.find_ex_move(
		MoveData.InputType.SPECIAL_FWD, MoveData.Stance.STAND)
	_land_hit(mroot, p1, ex_launcher)
	var combo_live: bool = p2.combo_hits == 1
	var still_live := true
	for i in 60:
		await _step(mroot, 1)
		if p2.grounded:
			break
		if p2.combo_hits == 0:
			still_live = false
	_check("recheck finding 4: the combo window survives the whole airborne arc",
		combo_live and still_live,
		"live=%s combo_hits=%d grounded=%s" % [str(combo_live), p2.combo_hits,
			str(p2.grounded)])

	# Finding 5 (Peggy's base launcher): the 2026-11-21 owner value (274)
	# must connect the authored route at the measured human timing (jump
	# f34, drift 90, air-light delay 7 for the BASE arc, heavy right after).
	# Input is disabled for the chase, exactly like the route probe: a held
	# direction would re-author the drift through _air_movement each tick.
	_reset_pair(mroot, 100.0, 140.0)
	var launcher: MoveData = p1.data.find_move(
		MoveData.InputType.SPECIAL_FWD, MoveData.Stance.STAND)
	_land_hit(mroot, p1, launcher)
	var launched: bool = not p2.grounded and p2.juggle_points == 5 \
		and launcher.knockback.y == 274.0
	for i in 34:
		await _step(mroot, 1)
	var actionable: bool = _actionable(p1)
	p1.input_enabled = false
	p1.grounded = false
	p1._force_state(FighterBase.State.JUMP_RISE)
	p1.velocity = Vector2(90.0 * p1.facing, -p1.jump_speed)
	for i in 7:
		await _step(mroot, 1)
	var air_l: MoveData = p1.data.find_move(MoveData.InputType.LIGHT, MoveData.Stance.AIR)
	var air_h: MoveData = p1.data.find_move(MoveData.InputType.HEAVY, MoveData.Stance.AIR)
	p1._start_move(air_l)
	p1.state_frame = air_l.startup
	mroot._resolve_hits()
	var first_hit: bool = p2.juggle_hits == 1
	p1._start_move(air_h)
	p1.state_frame = air_h.startup
	mroot._resolve_hits()
	var second_hit: bool = p2.juggle_hits == 2
	p1.input_enabled = true
	var route_dmg: float = 1000.0 - p2.health
	_check("recheck finding 5: Peggy's 274 launcher connects the authored route at human timing",
		launched and actionable and first_hit and second_hit
			and is_equal_approx(route_dmg, 221.40),
		"launched=%s actionable=%s l1=%s l2=%s dmg=%.2f (want 221.40)"
			% [str(launched), str(actionable), str(first_hit), str(second_hit),
				route_dmg])

	await _free_match(mroot)
