# Combo system suite. Phase 1: legacy pins, blocked/whiff cancel conditions,
# Clip Cancel, macros, data-driven scaling, caps, meter-in-combo, and combo
# state save/restore + determinism.
# Run: godot --headless --path game --script res://tests/combo_test.gd
#
# The simulation is stepped manually (mirroring the engine's physics
# priorities); each step yields one real engine physics tick so Input's
# just_pressed semantics match live play — same harness contract as
# cpu_test.gd (see docs/CPU_OPPONENT.md §7).
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
	await _legacy_pins()
	await _scaling_data()
	await _outcome_cancels()
	await _clip_cancel()
	await _macros()
	await _caps_and_meter()
	await _juggle_economics()
	await _juggle_routes()
	await _juggle_determinism_serialization()
	await _combo_state_save_restore()
	await _determinism()
	await _route_fuzz()
	print("combo_test: %d checks, %d failure(s)" % [checks, failures])
	quit(1 if failures > 0 else 0)

# ---------------- harness (same contract as cpu_test.gd) --------------------

func _build_match(p1_path: String, p2_path: String, stage_path: String) -> Node:
	var mroot: Node = load("res://scenes/match/MatchRoot.tscn").instantiate()
	mroot.selected_p1_data = load(p1_path)
	mroot.selected_p2_data = load(p2_path)
	mroot.selected_stage = load(stage_path)
	# The engine must NEVER tick this match (see cpu_test's _build_match for
	# the full story: Godot re-enables scene processing on entry in some
	# paths). Disable pre-add, post-add, and re-assert after the ready
	# awaits; the residual build drift is absorbed by phase-driven _to_fight.
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
	Input.action_release("p1_light")
	Input.action_release("p1_heavy")
	Input.action_release("p1_special")
	Input.action_release("p1_grab")
	Input.action_release("p1_right")
	Input.action_release("p2_left")
	mroot.queue_free()
	await process_frame
	await process_frame

func _step(mroot: Node, frames: int, press_action: String = "") -> void:
	var dt := 1.0 / 60.0
	for _i in frames:
		# Scripted HUMAN presses are injected at the exact points
		# _poll_input writes — the buffer entry and the macro dial capture —
		# before the fighters poll. The Input singleton's just_pressed latch
		# is wall-timing coupled (the #67 class of flake), so the harness
		# never routes scripted buttons through it; direction HOLDS stay on
		# Input because axis reads are not counter-gated. With no Input
		# dependency, the match steps manually with no engine interleave at
		# all: fully deterministic and fast.
		for entry in press_action.split("+"):
			if entry == "":
				continue
			var action: String = entry.trim_prefix("p1_")
			mroot.p1.input_buffer[action] = 0
			mroot.p1._macro_on_press(action)
		mroot.p1._physics_process(dt)
		mroot.p2._physics_process(dt)
		mroot._physics_process(dt)

func _to_fight(mroot: Node) -> void:
	# Drive by phase, not by a fixed step count: any 1-frame drift in when
	# the build's engine iterations landed must not shift the whole script.
	for i in 120:
		await _step(mroot, 1)
		if mroot.phase == mroot.Phase.FIGHT:
			return

func _reset_pair(mroot: Node, p1_x: float, p2_x: float) -> void:
	var stage: Node = mroot.stage
	mroot.p1.position = Vector2(p1_x, stage.floor_y)
	mroot.p2.position = Vector2(p2_x, stage.floor_y)
	mroot.p1.velocity = Vector2.ZERO
	mroot.p2.velocity = Vector2.ZERO
	mroot.p1.facing = 1
	mroot.p2.facing = -1
	mroot.p1.health = 1000.0
	mroot.p2.health = 1000.0
	mroot.p1.meter = 0.0
	mroot.p2.meter = 0.0
	mroot.p1.reset_state()
	mroot.p2.reset_state()
	mroot.p1.input_enabled = true
	mroot.p2.input_enabled = true

# Scripted attack: press `action` on every frame for `frames` frames.
func _script_press(mroot: Node, action: String, frames: int) -> void:
	await _step(mroot, frames, action)

# Scripted attack: one clean press, then wait for the hit to confirm.
# Returns false if the move ends without confirming (whiff/block/timeout).
func _press_and_confirm(mroot: Node, action: String, timeout: int = 40) -> bool:
	await _step(mroot, 1, action)
	for i in timeout:
		await _step(mroot, 1)
		if mroot.p1.move_hit_confirmed:
			return true
		if mroot.p1.state != FighterBase.State.ATTACK:
			return false
	return false

# Wait for both fighters to be back in a neutral state (no stun/attack).
func _wait_neutral(mroot: Node, max_frames: int = 90) -> void:
	for _i in max_frames:
		await _step(mroot, 1)
		if mroot.p1.state in [FighterBase.State.IDLE, FighterBase.State.WALK_F,
				FighterBase.State.WALK_B, FighterBase.State.CROUCH] \
				and mroot.p2.state in [FighterBase.State.IDLE,
					FighterBase.State.WALK_F, FighterBase.State.WALK_B,
					FighterBase.State.CROUCH]:
			return

# ---------------- 1. legacy pins: today's routes, damage, juggles ----------

func _legacy_pins() -> void:
	var mroot: Node = await _build_match(PEGGY, RICHARD, GAS_N_GO)
	await _to_fight(mroot)

	# Peggy L, L, H string on hit: exact legacy ladder damage.
	_reset_pair(mroot, 100.0, 145.0)
	_check("Peggy string opener lands (light hit-confirm)",
		await _press_and_confirm(mroot, "p1_light"))
	_check("Peggy chain light lands (second hit-confirm)",
		await _press_and_confirm(mroot, "p1_light"))
	_check("Peggy chain heavy lands (third hit-confirm)",
		await _press_and_confirm(mroot, "p1_heavy"))
	await _wait_neutral(mroot)
	_check("Peggy L,L,H legacy ladder damage pinned (142.25)",
		is_equal_approx(mroot.p2.health, 1000.0 - 142.25),
		"health=%.3f" % mroot.p2.health)

	# Richard L, L, H string on hit (his own match, Richard as P1).
	var rich_mroot: Node = await _build_match(RICHARD, PEGGY, GAS_N_GO)
	await _to_fight(rich_mroot)
	_reset_pair(rich_mroot, 100.0, 145.0)
	_check("Richard string opener lands (light hit-confirm)",
		await _press_and_confirm(rich_mroot, "p1_light"))
	_check("Richard chain light lands (second hit-confirm)",
		await _press_and_confirm(rich_mroot, "p1_light"))
	_check("Richard chain heavy lands (third hit-confirm)",
		await _press_and_confirm(rich_mroot, "p1_heavy"))
	await _wait_neutral(rich_mroot)
	_check("Richard L,L,H legacy ladder damage pinned (175.0)",
		is_equal_approx(rich_mroot.p2.health, 1000.0 - 175.0),
		"health=%.3f" % rich_mroot.p2.health)
	await _free_match(rich_mroot)

	# Heavy cancels into the special on hit (existing CANCEL rule).
	_reset_pair(mroot, 100.0, 145.0)
	_check("heavy hit-confirm lands before the cancel pin",
		await _press_and_confirm(mroot, "p1_heavy"))
	await _script_press(mroot, "p1_special", 6)
	var saw_special: bool = false
	for i in 20:
		await _step(mroot, 1)
		if mroot.p1.current_move != null and mroot.p1.current_move.input \
				in [MoveData.InputType.SPECIAL_NEUTRAL, MoveData.InputType.SPECIAL_FWD,
					MoveData.InputType.SPECIAL_DOWN, MoveData.InputType.SPECIAL_BACK]:
			saw_special = true
			break
		if mroot.p1.state != FighterBase.State.ATTACK \
				and mroot.p1.current_move == null:
			break
	_check("heavy hit-confirm cancels into the authored special",
		saw_special, "current move=%s" % str(mroot.p1.current_move))

	# Juggle pin: the forward special launches, and air hits beyond the flat
	# cap reject (each juggle attempt re-launches via the authored knockback).
	await _wait_neutral(mroot)
	_reset_pair(mroot, 100.0, 145.0)
	Input.action_press("p1_right") # forward-held special = peggy_forward
	await _step(mroot, 2)
	await _step(mroot, 1, "p1_special")
	for i in 40:
		await _step(mroot, 1)
		if mroot.p1.move_hit_confirmed or mroot.p1.state != FighterBase.State.ATTACK:
			break
	Input.action_release("p1_right")
	_check("peggy_forward launches the defender (authored knockback.y)",
		not mroot.p2.grounded and mroot.p2.velocity.y < 0.0,
		"grounded=%s vy=%.1f" % [str(mroot.p2.grounded), mroot.p2.velocity.y])
	var launcher: MoveData = mroot.p1.data.find_move(
		MoveData.InputType.SPECIAL_FWD, MoveData.Stance.STAND)
	# Phase 2 point budget: the launch granted 5 points; a launcher used as a
	# juggle hit is a normal-cost (2) air hit that refreshes the arc but does
	# NOT re-grant the budget — two land, the third cannot pay.
	var juggle_hits: int = 0
	var rejected: int = 0
	for i in 8:
		await _step(mroot, 6)
		if mroot.p2.grounded:
			break
		if mroot.p2.receive_hit(mroot.p1, launcher):
			juggle_hits += 1
		else:
			rejected += 1
	_check("juggle budget pins: two launcher-cost air hits land, the third rejects",
		juggle_hits == 2 and rejected >= 1,
		"landed=%d rejected=%d" % [juggle_hits, rejected])

	# Blocked hit: the attacker gains no meter, the defender none either.
	await _wait_neutral(mroot)
	_reset_pair(mroot, 100.0, 145.0)
	Input.action_press("p2_right") # defender holds away from the attacker
	await _step(mroot, 2)
	Input.action_press("p1_light")
	await _step(mroot, 1)
	Input.action_release("p1_light")
	for i in 40:
		await _step(mroot, 1)
		if mroot.p2.state == FighterBase.State.BLOCKSTUN:
			break
	Input.action_release("p2_right")
	await _wait_neutral(mroot)
	_check("a blocked hit resolves as a block and pays no meter to either side",
		mroot.p1.meter == 0.0 and mroot.p2.meter == 0.0,
		"p1 meter=%.1f p2 meter=%.1f" % [mroot.p1.meter, mroot.p2.meter])

	await _free_match(mroot)

# ---------------- 2. scaling: repeat penalty, variety bonus, air decay ------

# Direct resolver hits pin the exact arithmetic without reach/position noise.
func _scaling_data() -> void:
	var mroot: Node = await _build_match(PEGGY, RICHARD, GAS_N_GO)
	await _to_fight(mroot)
	_reset_pair(mroot, 100.0, 145.0)
	var p1: FighterBase = mroot.p1
	var p2: FighterBase = mroot.p2
	p1.input_enabled = false
	p2.input_enabled = false
	var light: MoveData = p1.data.find_move(
		MoveData.InputType.LIGHT, MoveData.Stance.STAND)
	var heavy: MoveData = p1.data.find_move(
		MoveData.InputType.HEAVY, MoveData.Stance.STAND)
	var neutral: MoveData = p1.data.find_move(
		MoveData.InputType.SPECIAL_NEUTRAL, MoveData.Stance.STAND)

	# Four lights: ladder 1.0/1.0/0.85/0.70, and the repeat-move penalty on
	# hits 3 and 4 (second and third reuse): 0.9^1 and 0.9^2.
	p2.receive_hit(p1, light)
	p2.receive_hit(p1, light)
	p2.receive_hit(p1, light)
	p2.receive_hit(p1, light)
	var expected_lights: float = 35.0 + 35.0 + 35.0 * 0.85 * 0.9 \
		+ 35.0 * 0.70 * 0.81
	_check("repeat-move penalty pins: four lights pay %.3f total" % expected_lights,
		is_equal_approx(1000.0 - p2.health, expected_lights),
		"damage=%.3f" % (1000.0 - p2.health))

	# Variety bonus: light, heavy, neutral special — three distinct ids, so
	# hit 3 pays x 0.85 x 1.05.
	p2.combo_tracker.reset()
	p2.combo_hits = 0
	p2.health = 1000.0
	p2.receive_hit(p1, light)
	p2.receive_hit(p1, heavy)
	p2.receive_hit(p1, neutral)
	var expected_variety: float = 35.0 + 85.0 + 95.0 * 0.85 * 1.05
	_check("variety bonus pins: three distinct moves pay +5% on hit 3",
		is_equal_approx(1000.0 - p2.health, expected_variety),
		"damage=%.3f expected=%.3f" % [1000.0 - p2.health, expected_variety])

	# Air hitstun decay: the exponent is the post-increment juggle count, so a
	# first air hit pays hitstun x decay (13 -> 12), deep air hits floor at 8.
	p2.reset_state()
	p2.grounded = false
	p2.juggle_hits = 0
	p2.receive_hit(p1, light)
	_check("air hitstun decays on airborne hits (13 -> 12)",
		p2.hitstun_frames == 12, "hitstun=%d" % p2.hitstun_frames)
	# The cap rejects deep juggle hits, so the floor is pinned with a steeper
	# authored decay (test-local tuning mutation, restored afterwards).
	p2.reset_state()
	p2.grounded = false
	var tuning_save: ComboTuning = p2.data.combo_tuning
	var steep := ComboTuning.new()
	steep.air_hitstun_decay = 0.5
	p2.data.combo_tuning = steep
	p2.juggle_hits = 2
	p2.receive_hit(p1, light)
	p2.data.combo_tuning = tuning_save
	_check("air hitstun decay is floored at 8",
		p2.hitstun_frames == 8, "hitstun=%d" % p2.hitstun_frames)

	await _free_match(mroot)

# ---------------- 3. BLOCK / WHIFF conditions and the outcome flags --------

func _outcome_cancels() -> void:
	var mroot: Node = await _build_match(PEGGY, RICHARD, GAS_N_GO)
	await _to_fight(mroot)

	# Blocked flag: set exactly when the contact resolves as a block. Close
	# gap so the backing defender stays in reach of the light.
	_reset_pair(mroot, 100.0, 135.0)
	Input.action_press("p2_right")
	await _step(mroot, 1)
	await _step(mroot, 1, "p1_light")
	await _step(mroot, 9)
	Input.action_release("p2_right")
	_check("a blocked contact sets move_was_blocked on the attacker",
		mroot.p1.move_was_blocked and not mroot.p1.move_whiffed,
		"blocked=%s whiffed=%s" % [str(mroot.p1.move_was_blocked),
			str(mroot.p1.move_whiffed)])

	# BLOCK chain: the authored Peggy blockstring continues L -> L on block.
	await _step(mroot, 1, "p1_light")
	var chained: bool = false
	for i in 30:
		await _step(mroot, 1)
		if mroot.p1.state == FighterBase.State.ATTACK \
				and mroot.p1.current_move != null \
				and mroot.p1.current_move.id == "light" \
				and mroot.p1.state_frame <= 2:
			chained = true
			break
		if mroot.p1.state != FighterBase.State.ATTACK and i > 12:
			break
	Input.action_release("p2_right")
	_check("the BLOCK chain route continues the string on block (decision data)",
		chained, "second light never started")

	# WHIFF condition: a synthetic rule proves the outcome gate works both
	# ways — whiffed light chains, blocked light does not fire the WHIFF rule.
	await _wait_neutral(mroot)
	_reset_pair(mroot, 100.0, 280.0) # out of reach: guaranteed whiff
	var light: MoveData = mroot.p1.data.find_move(
		MoveData.InputType.LIGHT, MoveData.Stance.STAND)
	var saved: Array = light.cancels.duplicate()
	var whiff_rule := CancelRule.new()
	whiff_rule.condition = CancelRule.Condition.WHIFF
	whiff_rule.kind = CancelRule.Kind.CHAIN
	whiff_rule.target = CancelRule.Target.LIGHT
	whiff_rule.from_frame = 5
	whiff_rule.to_frame = 12
	light.cancels.append(whiff_rule)
	await _step(mroot, 1, "p1_light")
	await _step(mroot, 2)
	await _step(mroot, 1, "p1_light") # buffered for the whiff route
	var whiff_chained: bool = false
	for i in 12:
		await _step(mroot, 1)
		if mroot.p1.state == FighterBase.State.ATTACK \
				and mroot.p1.current_move.id == "light" \
				and mroot.p1.state_frame <= 2:
			whiff_chained = true
			break
	_check("a WHIFF-condition route fires after the active window closes with no contact",
		whiff_chained, "chained=%s" % str(whiff_chained))
	light.cancels.assign(saved)

	# The same rule must NOT fire when the move is blocked instead.
	_reset_pair(mroot, 100.0, 135.0)
	light.cancels.append(whiff_rule)
	Input.action_press("p2_right")
	await _step(mroot, 1)
	await _step(mroot, 1, "p1_light")
	await _step(mroot, 2)
	await _step(mroot, 1, "p1_light")
	await _step(mroot, 12)
	Input.action_release("p2_right")
	light.cancels.assign(saved)
	# Peggy's light also carries an authored BLOCK chain, so a second light
	# MAY start here via BLOCK — what must hold is that the WHIFF flag never
	# set and the blocked flag did.
	_check("a blocked move never sets the whiff flag",
		mroot.p1.move_was_blocked and not mroot.p1.move_whiffed,
		"blocked=%s whiffed=%s" % [str(mroot.p1.move_was_blocked),
			str(mroot.p1.move_whiffed)])

	await _free_match(mroot)

# ---------------- 4. Clip Cancel (25 meter, recovery-only, once per combo) ----

func _clip_cancel() -> void:
	var mroot: Node = await _build_match(PEGGY, RICHARD, GAS_N_GO)
	await _to_fight(mroot)

	# During startup/active: refused. (Positions out of reach so the heavy
	# whiffs and no hit-confirm route can consume the buffered pair first.)
	_reset_pair(mroot, 100.0, 280.0)
	mroot.p1.meter = 100.0
	await _step(mroot, 1, "p1_heavy")
	await _step(mroot, 4) # heavy startup is 7: still before active ends
	await _step(mroot, 1, "p1_special+p1_grab")
	await _step(mroot, 2)
	_check("Clip Cancel is refused during startup/active frames",
		mroot.p1.state == FighterBase.State.ATTACK
			and absf(mroot.p1.meter - 100.0) < 0.001,
		"state=%d meter=%.1f" % [mroot.p1.state, mroot.p1.meter])
	# The refused pair is still buffered; clear it so it cannot fire the clip
	# the moment recovery opens.
	mroot.p1.input_buffer.erase("special")
	mroot.p1.input_buffer.erase("grab")

	# Wait into recovery, then cancel.
	for i in 20:
		await _step(mroot, 1)
		if mroot.p1.state == FighterBase.State.ATTACK \
				and mroot.p1.state_frame >= mroot.p1.current_move.startup \
				+ mroot.p1.current_move.active:
			break
	var meter_before: float = mroot.p1.meter
	await _step(mroot, 1, "p1_special+p1_grab")
	_check("Clip Cancel resolves from recovery: 25 meter, back to neutral",
		mroot.p1.state in [FighterBase.State.IDLE, FighterBase.State.WALK_F,
			FighterBase.State.WALK_B, FighterBase.State.CROUCH]
			and is_equal_approx(meter_before - 25.0, mroot.p1.meter),
		"state=%d meter=%.1f" % [mroot.p1.state, mroot.p1.meter])

	# Once per combo: a second burn is refused while the opponent's combo is
	# ACTIVE (resetting the tracker is what returns the budget, so the test
	# keeps an active combo). The heavy whiffs so no authored route competes.
	_reset_pair(mroot, 100.0, 280.0)
	mroot.p2.combo_tracker.reset()
	mroot.p2.combo_tracker.record(&"light", 35.0)
	mroot.p1.clip_cancel_used = true
	mroot.p1.meter = 100.0
	await _step(mroot, 1, "p1_heavy")
	for i in 24:
		await _step(mroot, 1)
		if mroot.p1.state != FighterBase.State.ATTACK:
			break
	await _step(mroot, 1, "p1_special+p1_grab")
	await _step(mroot, 1)
	# The refused pair legitimately remains buffered and may start a grab
	# afterwards; the pinned outcome is the meter and the budget flag.
	_check("Clip Cancel is once per combo while the flag is set",
		is_equal_approx(mroot.p1.meter, 100.0) and mroot.p1.clip_cancel_used,
		"meter=%.1f used=%s" % [mroot.p1.meter, str(mroot.p1.clip_cancel_used)])

	# Too little meter: refused outright.
	_reset_pair(mroot, 100.0, 280.0)
	mroot.p1.clip_cancel_used = false
	mroot.p1.meter = 10.0
	await _step(mroot, 1, "p1_heavy")
	for i in 24:
		await _step(mroot, 1)
		if mroot.p1.state != FighterBase.State.ATTACK:
			break
	await _step(mroot, 1, "p1_special+p1_grab")
	await _step(mroot, 1)
	_check("Clip Cancel refuses when the meter cannot pay",
		is_equal_approx(mroot.p1.meter, 10.0) and not mroot.p1.clip_cancel_used,
		"meter=%.1f used=%s" % [mroot.p1.meter, str(mroot.p1.clip_cancel_used)])

	await _free_match(mroot)

# ---------------- 5. macros: dial-ahead, continue-on-hit, die-on-block ------

# Dial a macro: press the steps quickly. The harness presses each step once,
# within the gap window, while the opener is still resolving. Presses are
# issued inside the tick (see _step) so the dial is deterministic.
func _dial_macro(mroot: Node, steps: Array, gap: int) -> void:
	await _step(mroot, 1, "p1_" + String(steps[0]))
	for i in range(1, steps.size()):
		await _step(mroot, maxi(1, gap))
		await _step(mroot, 1, "p1_" + String(steps[i]))

func _macros() -> void:
	var mroot: Node = await _build_match(PEGGY, RICHARD, GAS_N_GO)
	await _to_fight(mroot)

	# BENCH WARMER: dial L, L, H fast — replays ride the authored chain
	# rules, so the string lands with the exact scripted damage. (GDScript
	# lambdas capture locals by value, so the replay counter lives in a
	# Dictionary.)
	_reset_pair(mroot, 100.0, 145.0)
	var replays := {"n": 0}
	mroot.p1.macro_step_replayed.connect(
		func(_n: String, _s: int) -> void: replays["n"] += 1)
	await _dial_macro(mroot, ["light", "light", "heavy"], 3)
	await _wait_neutral(mroot)
	_check("BENCH WARMER dials clean: both held steps replay through the authored chain",
		replays["n"] == 2 and is_equal_approx(mroot.p2.health, 1000.0 - 142.25),
		"replays=%d health=%.3f" % [replays["n"], mroot.p2.health])
	_check("the macro tracker is empty after a completed macro",
		mroot.p1.macro_active == &"" and mroot.p1.macro_pending.is_empty(),
		"active=%s pending=%d" % [String(mroot.p1.macro_active),
			mroot.p1.macro_pending.size()])

	# Too slow: the dial gap kills the macro, so no held step replays (the
	# late presses simply become separate ordinary moves).
	_reset_pair(mroot, 100.0, 145.0)
	replays["n"] = 0
	await _dial_macro(mroot, ["light", "light", "heavy"], 30)
	await _wait_neutral(mroot)
	_check("a dial slower than max_gap_frames never replays a held step",
		replays["n"] == 0, "replays=%d" % replays["n"])

	# Dies on block (decision #3): the defender blocks, the macro dies.
	_reset_pair(mroot, 100.0, 145.0)
	replays["n"] = 0
	Input.action_press("p2_right")
	await _step(mroot, 2)
	await _dial_macro(mroot, ["light", "light", "heavy"], 3)
	await _wait_neutral(mroot)
	Input.action_release("p2_right")
	_check("a macro dies on block: no held step replays",
		replays["n"] == 0, "replays=%d" % replays["n"])

	# Buffered inputs never outlive the window: during the whole dial, no
	# buffered entry is ever older than the buffer max age while hitstop
	# freezing keeps the clocks in step (the ring ages under the same cap).
	var aged_ok: bool = true
	_reset_pair(mroot, 100.0, 145.0)
	await _step(mroot, 1, "p1_light")
	for i in 40:
		await _step(mroot, 1)
		for key in mroot.p1.input_buffer.keys():
			if mroot.p1.input_buffer[key] > FighterBase.BUFFER_MAX_AGE:
				aged_ok = false
	_check("no buffered input outlives the buffer max age during a macro exchange",
		aged_ok)

	await _free_match(mroot)

# ---------------- 6. caps and meter-in-combo -------------------------------

func _caps_and_meter() -> void:
	var mroot: Node = await _build_match(PEGGY, RICHARD, GAS_N_GO)
	await _to_fight(mroot)
	var p1: FighterBase = mroot.p1
	var p2: FighterBase = mroot.p2

	# Direct resolver hits, cycling five distinct non-knockdown,
	# non-launcher moves so the ladder and repeat rules both engage, through
	# the 12-hit cap. (crouch_heavy is a sweep and ends the combo by design,
	# so it is excluded.)
	_reset_pair(mroot, 100.0, 145.0)
	var cycle: Array = [
		p1.data.find_move(MoveData.InputType.LIGHT, MoveData.Stance.STAND),
		p1.data.find_move(MoveData.InputType.HEAVY, MoveData.Stance.STAND),
		p1.data.find_move(MoveData.InputType.SPECIAL_NEUTRAL, MoveData.Stance.STAND),
		p1.data.find_move(MoveData.InputType.LIGHT, MoveData.Stance.CROUCH),
		p1.data.find_move(MoveData.InputType.SPECIAL_BACK, MoveData.Stance.STAND),
	]
	var over_cap_hp: float = 0.0
	for i in 13:
		p2.receive_hit(p1, cycle[i % cycle.size()])
		if i == 11:
			over_cap_hp = p2.health
	_check("the 12-hit combo cap zeroes the 13th hit's damage",
		is_equal_approx(p2.health, over_cap_hp) and p2.combo_tracker.hits == 13,
		"hp12=%.3f hp13=%.3f hits=%d" % [over_cap_hp, p2.health,
			p2.combo_tracker.hits])
	_check("the per-combo damage total never exceeds the 550 data cap",
		p2.combo_tracker.total_damage <= 550.0 + 0.01,
		"total=%.1f" % p2.combo_tracker.total_damage)

	# Meter in combos: opener full, second hit x0.5, deep hits floored.
	_reset_pair(mroot, 100.0, 145.0)
	p1.meter = 0.0
	p2.receive_hit(p1, cycle[0])
	var after_one: float = p1.meter
	p2.receive_hit(p1, cycle[1])
	var after_two: float = p1.meter
	_check("meter: the combo opener pays meter_gain_hit in full",
		is_equal_approx(after_one, 6.0), "meter=%.2f" % after_one)
	_check("meter: the second combo hit pays x0.5 (decision #2)",
		is_equal_approx(after_two - after_one, 3.0),
		"gain=%.2f" % (after_two - after_one))
	for i in 6:
		p2.receive_hit(p1, cycle[i % cycle.size()])
	_check("meter: deep combo hits never drop below the 0.25 floor of the award",
		p1.meter - after_two >= 6.0 * 0.25 * 6.0 - 0.01,
		"meter=%.2f" % p1.meter)

	await _free_match(mroot)

# ---------------- 7. Phase 2 juggle economics ------------------------------

# The point budget is data (ComboTuning), spent by move type, never regen'd
# mid-combo, and a hit it cannot pay is rejected meaty-safe. Knockback decay
# and the gravity ramp are the unchanged Phase 1-era policy.
func _juggle_economics() -> void:
	var mroot: Node = await _build_match(PEGGY, RICHARD, GAS_N_GO)
	await _to_fight(mroot)
	var p1: FighterBase = mroot.p1
	var p2: FighterBase = mroot.p2
	var t: ComboTuning = p1.data.combo_tuning
	_check("juggle economics live in ComboTuning (5 start / 2 normal / 3 air special)",
		t.juggle_points_start == 5 and t.juggle_cost_normal == 2
			and t.juggle_cost_air_special == 3,
		"start=%d normal=%d special=%d" % [t.juggle_points_start,
			t.juggle_cost_normal, t.juggle_cost_air_special])
	var peggy_fwd: MoveData = p1.data.find_move(
		MoveData.InputType.SPECIAL_FWD, MoveData.Stance.STAND)
	var peggy_fwd_ex: MoveData = p1.data.find_ex_move(
		MoveData.InputType.SPECIAL_FWD, MoveData.Stance.STAND)
	var rich_fwd: MoveData = p2.data.find_move(
		MoveData.InputType.SPECIAL_FWD, MoveData.Stance.STAND)
	var rich_fwd_ex: MoveData = p2.data.find_ex_move(
		MoveData.InputType.SPECIAL_FWD, MoveData.Stance.STAND)
	_check("both fighters' forward specials and EX rows are marked launchers in data",
		peggy_fwd.launcher and peggy_fwd_ex.launcher
			and rich_fwd.launcher and rich_fwd_ex.launcher,
		"peggy=%s/%s richard=%s/%s" % [str(peggy_fwd.launcher),
			str(peggy_fwd_ex.launcher), str(rich_fwd.launcher),
			str(rich_fwd_ex.launcher)])
	var air_l: MoveData = p1.data.find_move(MoveData.InputType.LIGHT, MoveData.Stance.AIR)
	var air_h: MoveData = p1.data.find_move(MoveData.InputType.HEAVY, MoveData.Stance.AIR)
	var air_s: MoveData = p1.data.find_move(MoveData.InputType.SPECIAL_AIR, MoveData.Stance.AIR)

	# Launch grants 5; two normals spend 4; the third cannot pay.
	_reset_pair(mroot, 100.0, 140.0)
	_check("a grounded launcher starts the air sequence with 5 points",
		p2.receive_hit(p1, peggy_fwd) and not p2.grounded
			and p2.juggle_points == 5 and p2.juggle_hits == 0,
		"grounded=%s points=%d hits=%d" % [str(p2.grounded), p2.juggle_points,
			p2.juggle_hits])
	_check("an air normal spends 2 points",
		p2.receive_hit(p1, air_l) and p2.juggle_points == 3 and p2.juggle_hits == 1,
		"points=%d hits=%d" % [p2.juggle_points, p2.juggle_hits])
	_check("a second air normal spends 2 points",
		p2.receive_hit(p1, air_h) and p2.juggle_points == 1 and p2.juggle_hits == 2,
		"points=%d hits=%d" % [p2.juggle_points, p2.juggle_hits])
	var rejected_hp: float = p2.health
	var rejected := p2.receive_hit(p1, air_l)
	_check("a hit the remaining 1 point cannot pay is rejected and stays live",
		not rejected and p2.health == rejected_hp and p2.juggle_points == 1
			and p2.juggle_hits == 2 and p2.is_invulnerable_to(air_l),
		"connected=%s hp=%.2f points=%d" % [str(rejected), p2.health,
			p2.juggle_points])

	# Air specials cost 3: one special plus one normal exactly spends 5.
	_reset_pair(mroot, 100.0, 140.0)
	p2.receive_hit(p1, peggy_fwd)
	_check("an air special spends 3 points",
		p2.receive_hit(p1, air_s) and p2.juggle_points == 2 and p2.juggle_hits == 1,
		"points=%d hits=%d" % [p2.juggle_points, p2.juggle_hits])
	_check("one air special plus one normal exhausts the 5-point budget",
		p2.receive_hit(p1, air_l) and p2.juggle_points == 0 and p2.juggle_hits == 2,
		"points=%d hits=%d" % [p2.juggle_points, p2.juggle_hits])
	_check("the exhausted budget rejects the next air hit",
		not p2.receive_hit(p1, air_h), "points=%d" % p2.juggle_points)

	# A launcher used as a juggle hit refreshes the arc but never re-grants
	# the budget, so repeat launchers cannot self-sustain an infinite.
	_reset_pair(mroot, 100.0, 140.0)
	p2.receive_hit(p1, peggy_fwd)
	p2.receive_hit(p1, air_l)
	_check("a launcher used as a juggle hit drains the existing budget (no re-grant)",
		p2.receive_hit(p1, peggy_fwd) and p2.juggle_points == 1
			and p2.juggle_hits == 2,
		"points=%d hits=%d" % [p2.juggle_points, p2.juggle_hits])

	# Air hitstun decay is unchanged (x0.9 per air hit, floored) and the
	# gravity ramp still engages from the second air hit.
	_reset_pair(mroot, 100.0, 140.0)
	p2.receive_hit(p1, peggy_fwd)
	p2.receive_hit(p1, air_l)
	var stun_one := maxi(t.air_hitstun_floor,
		int(round(air_l.hitstun * pow(t.air_hitstun_decay, 1.0))))
	_check("the first air hit decays hitstun by the tuning factor",
		p2.hitstun_frames == stun_one,
		"stun=%d expected=%d" % [p2.hitstun_frames, stun_one])
	p2.receive_hit(p1, air_h)
	var stun_two := maxi(t.air_hitstun_floor,
		int(round(air_h.hitstun * pow(t.air_hitstun_decay, 2.0))))
	_check("the second air hit decays hitstun again",
		p2.hitstun_frames == stun_two,
		"stun=%d expected=%d" % [p2.hitstun_frames, stun_two])
	p2.grounded = false
	p2._force_state(FighterBase.State.HITSTUN)
	var vy_two: float = p2.velocity.y
	p2._apply_gravity(1.0 / 60.0)
	_check("gravity x1.25 still engages from the second air hit",
		is_equal_approx(p2.velocity.y - vy_two,
			p2.gravity * FighterBase.JUGGLE_GRAVITY_MULT / 60.0),
		"dv=%.4f" % (p2.velocity.y - vy_two))
	p2.juggle_hits = 1
	p2.velocity.y = 0.0
	p2._apply_gravity(1.0 / 60.0)
	_check("the first air hit keeps authored gravity",
		is_equal_approx(p2.velocity.y, p2.gravity / 60.0),
		"vy=%.4f" % p2.velocity.y)

	# Combo end clears the budget back to inactive (-1).
	p2.frames_since_hit = 41
	p2.grounded = true
	p2._force_state(FighterBase.State.IDLE)
	p2._tick_combo()
	_check("combo end resets the juggle budget to inactive (-1) with the counter",
		p2.juggle_points == -1 and p2.juggle_hits == 0 and p2.combo_hits == 0,
		"points=%d hits=%d combo=%d" % [p2.juggle_points, p2.juggle_hits,
			p2.combo_hits])

	await _free_match(mroot)

# The doc's §13 routes, priced through the real receive_hit path. The
# launcher is hit 1; the two air hits are hits 2-3 of the same combo, so the
# ladder applies and the third hit also pays the +5% variety bonus (launcher,
# air hit, and the second air hit are three distinct ids).
func _juggle_routes() -> void:
	var mroot: Node = await _build_match(PEGGY, RICHARD, GAS_N_GO)
	await _to_fight(mroot)
	var peggy: FighterBase = mroot.p1
	var richard: FighterBase = mroot.p2
	var peggy_l: MoveData = peggy.data.find_move(MoveData.InputType.LIGHT, MoveData.Stance.AIR)
	var peggy_h: MoveData = peggy.data.find_move(MoveData.InputType.HEAVY, MoveData.Stance.AIR)
	var rich_h: MoveData = richard.data.find_move(MoveData.InputType.HEAVY, MoveData.Stance.AIR)
	var rich_s: MoveData = richard.data.find_move(MoveData.InputType.SPECIAL_AIR, MoveData.Stance.AIR)
	var cases := [
		{"label": "Peggy base launch -> jump_light -> jump_heavy",
			"attacker": peggy, "defender": richard,
			"launcher": peggy.data.find_move(MoveData.InputType.SPECIAL_FWD, MoveData.Stance.STAND),
			"seq": [peggy_l, peggy_h], "expected": 221.40, "points": 1},
		{"label": "Peggy EX launch -> jump_light -> jump_heavy",
			"attacker": peggy, "defender": richard,
			"launcher": peggy.data.find_ex_move(MoveData.InputType.SPECIAL_FWD, MoveData.Stance.STAND),
			"seq": [peggy_l, peggy_h], "expected": 256.40, "points": 1},
		{"label": "Richard base launch -> jump_heavy -> richard_air",
			"attacker": richard, "defender": peggy,
			"launcher": richard.data.find_move(MoveData.InputType.SPECIAL_FWD, MoveData.Stance.STAND),
			"seq": [rich_h, rich_s], "expected": 263.55, "points": 0},
		{"label": "Richard EX launch -> jump_heavy -> richard_air",
			"attacker": richard, "defender": peggy,
			"launcher": richard.data.find_ex_move(MoveData.InputType.SPECIAL_FWD, MoveData.Stance.STAND),
			"seq": [rich_h, rich_s], "expected": 293.55, "points": 0},
	]
	for c in cases:
		_reset_pair(mroot, 100.0, 140.0)
		var attacker: FighterBase = c["attacker"]
		var defender: FighterBase = c["defender"]
		var launch_ok := defender.receive_hit(attacker, c["launcher"])
		var hits_ok := true
		for move in c["seq"]:
			hits_ok = hits_ok and defender.receive_hit(attacker, move)
		var damage := 1000.0 - defender.health
		_check("%s connects both air hits and pays the authored ladder" % c["label"],
			launch_ok and hits_ok and is_equal_approx(damage, c["expected"])
				and defender.combo_tracker.hits == 3
				and defender.juggle_hits == 2
				and defender.juggle_points == c["points"],
			"launch=%s hits=%s dmg=%.2f expected=%.2f tracker=%d juggle=%d points=%d"
				% [str(launch_ok), str(hits_ok), damage, c["expected"],
					defender.combo_tracker.hits, defender.juggle_hits,
					defender.juggle_points])
		# The combo terminates: the defender lands and can act again.
		var landed := false
		for i in 300:
			await _step(mroot, 1)
			if defender.grounded and defender.state in [FighterBase.State.IDLE,
					FighterBase.State.WALK_F, FighterBase.State.WALK_B,
					FighterBase.State.CROUCH]:
				landed = true
				break
		_check("%s terminates: the defender lands and can act" % c["label"],
			landed, "grounded=%s state=%d" % [str(defender.grounded),
				defender.state])
	await _free_match(mroot)

# ---------------- 8. mid-juggle save/restore and determinism ---------------

func _juggle_hash(mroot: Node) -> int:
	var p1: FighterBase = mroot.p1
	var p2: FighterBase = mroot.p2
	return hash([
		int(round(p1.position.x)), int(round(p1.position.y)),
		int(round(p2.position.x)), int(round(p2.position.y)),
		int(round(p2.velocity.x * 100.0)), int(round(p2.velocity.y * 100.0)),
		int(p2.state), int(p2.state_frame), int(round(p2.health)),
		p2.juggle_hits, p2.juggle_points, p2.hitstun_frames,
		int(round(p2.combo_tracker.total_damage * 100.0)),
	])

func _juggle_tail(mroot: Node) -> Array:
	var p1: FighterBase = mroot.p1
	var p2: FighterBase = mroot.p2
	var air_h: MoveData = p1.data.find_move(MoveData.InputType.HEAVY, MoveData.Stance.AIR)
	var air_l: MoveData = p1.data.find_move(MoveData.InputType.LIGHT, MoveData.Stance.AIR)
	var hashes: Array = []
	for i in 120:
		if i == 4:
			p2.receive_hit(p1, air_h)
		if i == 18:
			p2.receive_hit(p1, air_l) # cannot pay: rejected, stays live
		await _step(mroot, 1)
		hashes.append(_juggle_hash(mroot))
	return hashes

func _juggle_determinism_serialization() -> void:
	var launcher_path := MoveData.InputType.SPECIAL_FWD
	var a: Node = await _build_match(PEGGY, RICHARD, GAS_N_GO)
	await _to_fight(a)
	_reset_pair(a, 100.0, 140.0)
	var a_launcher: MoveData = a.p1.data.find_move(launcher_path, MoveData.Stance.STAND)
	var a_air_l: MoveData = a.p1.data.find_move(MoveData.InputType.LIGHT, MoveData.Stance.AIR)
	a.p2.receive_hit(a.p1, a_launcher)
	a.p2.receive_hit(a.p1, a_air_l)
	var snap: Dictionary = a.serialize()
	_check("the mid-juggle snapshot carries juggle_points and juggle_hits",
		typeof(snap.get("p2")) == TYPE_DICTIONARY
			and snap["p2"].get("juggle_points") == 3
			and snap["p2"].get("juggle_hits") == 1,
		"p2=%s" % str(snap.get("p2", {})))
	var tail_a: Array = await _juggle_tail(a)
	await _free_match(a)

	var b: Node = await _build_match(PEGGY, RICHARD, GAS_N_GO)
	await _to_fight(b)
	_reset_pair(b, 100.0, 140.0)
	b.p2.receive_hit(b.p1, b.p1.data.find_move(launcher_path, MoveData.Stance.STAND))
	b.p2.receive_hit(b.p1, b.p1.data.find_move(MoveData.InputType.LIGHT, MoveData.Stance.AIR))
	b.load(snap)
	_check("loading a mid-juggle snapshot restores the budget and counter",
		b.p2.juggle_points == 3 and b.p2.juggle_hits == 1,
		"points=%d hits=%d" % [b.p2.juggle_points, b.p2.juggle_hits])
	var tail_b: Array = await _juggle_tail(b)
	_check("a mid-juggle save/restore reproduces the same continuation",
		tail_a == tail_b, "%d vs %d hashes, first diff at %d"
			% [tail_a.size(), tail_b.size(), _first_diff(tail_a, tail_b)])
	await _free_match(b)

# ---------------- 9. combo state save/restore mid-combo --------------------

func _combo_state_save_restore() -> void:
	# Run a two-hit string, snapshot the defender's full state (tracker
	# included), continue; then replay the same scripted string in a fresh
	# match, load the snapshot, and continue — the two continuations must
	# match frame for frame.
	var a: Node = await _build_match(PEGGY, RICHARD, GAS_N_GO)
	await _to_fight(a)
	_reset_pair(a, 100.0, 145.0)
	await _press_and_confirm(a, "p1_light")
	await _press_and_confirm(a, "p1_heavy")
	var snap: Dictionary = a.p2.serialize()
	_check("the mid-combo snapshot carries the tracker record",
		typeof(snap.get("combo_tracker")) == TYPE_DICTIONARY
			and snap["combo_tracker"]["hits"] >= 1
			and snap["combo_tracker"]["total_damage"] >= 35.0,
		"tracker=%s" % str(snap.get("combo_tracker")))
	var tail_a: Array[float] = []
	for i in 60:
		await _step(a, 1)
		tail_a.append(a.p2.health)
	await _free_match(a)

	var b: Node = await _build_match(PEGGY, RICHARD, GAS_N_GO)
	await _to_fight(b)
	_reset_pair(b, 100.0, 145.0)
	await _press_and_confirm(b, "p1_light")
	await _press_and_confirm(b, "p1_heavy")
	b.p2.load(snap)
	var tail_b: Array[float] = []
	for i in 60:
		await _step(b, 1)
		tail_b.append(b.p2.health)
	await _free_match(b)
	_check("a mid-combo save/restore reproduces the same continuation",
		tail_a == tail_b, "sizes %d vs %d" % [tail_a.size(), tail_b.size()])

# ---------------- 10. determinism -------------------------------------------

func _frame_hash(mroot: Node) -> int:
	var p1: FighterBase = mroot.p1
	var p2: FighterBase = mroot.p2
	return hash([
		int(round(p1.position.x)), int(round(p1.health)), int(p1.state),
		int(round(p2.position.x)), int(round(p2.health)), int(p2.state),
		int(round(p2.combo_tracker.total_damage)), mroot.timer_frames,
	])

func _run_combo_script() -> Array:
	var mroot: Node = await _build_match(PEGGY, RICHARD, GAS_N_GO)
	await _to_fight(mroot)
	_reset_pair(mroot, 100.0, 145.0)
	var hashes: Array = []
	var frame := 0
	while frame < 420:
		if frame % 90 == 0:
			await _dial_macro(mroot, ["light", "light", "heavy"], 3)
			frame += 10
		if frame % 130 == 40:
			Input.action_press("p2_right")
		if frame % 130 == 80:
			Input.action_release("p2_right")
		await _step(mroot, 1)
		frame += 1
		hashes.append(_frame_hash(mroot))
	Input.action_release("p2_right")
	await _free_match(mroot)
	return hashes

func _determinism() -> void:
	var a: Array = await _run_combo_script()
	var b: Array = await _run_combo_script()
	_check("the combo system is deterministic: identical scripted dials replay identically",
		a == b, "%d vs %d hashes, first diff at %d" % [a.size(), b.size(),
			_first_diff(a, b)])

static func _first_diff(a: Array, b: Array) -> int:
	var n: int = mini(a.size(), b.size())
	for i in n:
		if a[i] != b[i]:
			return i
	return n if a.size() == b.size() else mini(a.size(), b.size())

# ---------------- 11. seeded fuzz over the cancel routes --------------------

# Test-local LCG so the fuzz is reproducible without engine RNG.
func _fuzz_run(p1_path: String, p2_path: String, seed: int) -> void:
	var mroot: Node = await _build_match(p1_path, p2_path, GAS_N_GO)
	await _to_fight(mroot)
	_reset_pair(mroot, 100.0, 160.0)
	var rng_state: int = seed
	var actions: Array = ["p1_light", "p1_heavy", "p1_special", "p1_grab",
		"p2_light", "p2_heavy", "p2_special"]
	var bad: bool = false
	var frame := 0
	# Stuck watchdog: the whole-match fingerprint (positions, states, clocks)
	# may hold still only for hitstop-length stretches, never 240 frames.
	var last_hash: int = 0
	var same_streak := 0
	while frame < 900:
		rng_state = (rng_state * 1664525 + 1013904223) & 0xFFFFFFFF
		var action: String = actions[rng_state % actions.size()]
		await _step(mroot, 1, action)
		frame += 1
		var f1: FighterBase = mroot.p1
		var f2: FighterBase = mroot.p2
		if is_nan(f1.health) or is_nan(f2.health) or f1.health < 0.0 \
				or f2.health < 0.0 or f1.meter < 0.0 or f2.meter < 0.0 \
				or f1.combo_tracker.total_damage > 550.01 \
				or f2.combo_tracker.total_damage > 550.01:
			bad = true
			break
		var now_hash: int = hash([int(round(f1.position.x)), int(round(f2.position.x)),
			f1.state, f2.state, f1.state_frame, f2.state_frame, mroot.timer_frames])
		if now_hash == last_hash:
			same_streak += 1
			if same_streak > 240:
				bad = true # frozen: nothing in the match moved for 4 seconds
				break
		else:
			same_streak = 0
			last_hash = now_hash
	_check("fuzz (seed %d): %s vs %s mash stays in bounds, capped, and never stuck"
		% [seed, mroot.p1.data.display_name, mroot.p2.data.display_name],
		not bad and frame == 900, "bad=%s at frame %d" % [str(bad), frame])
	await _free_match(mroot)

func _route_fuzz() -> void:
	await _fuzz_run(PEGGY, RICHARD, 1001)
	await _fuzz_run(RICHARD, PEGGY, 2002)
	await _fuzz_run(PEGGY, PEGGY, 3003)
	await _fuzz_run(RICHARD, RICHARD, 4004)
