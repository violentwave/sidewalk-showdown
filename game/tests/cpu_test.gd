# Headless CPU opponent suite: legality, determinism, blocking skill,
# AI-vs-AI soak, difficulty ordering, and save/restore of the AI state.
# Run: godot --headless --path game --script res://tests/cpu_test.gd
#
# The simulation is stepped MANUALLY (cpu tick -> p1 -> p2 -> MatchRoot,
# mirroring the engine's physics priorities), so the soak runs thousands of
# frames per second instead of wall-clock 60 Hz and stays CI-cheap.
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
	# Manual stepping below runs the match's 60 Hz math directly; each step
	# first yields one engine physics tick (with the tick rate briefly
	# raised) so the physics-frame counter advances and Input's
	# just_pressed semantics match real play.
	await _legality()
	await _determinism()
	await _save_restore()
	await _blocking_order()
	await _difficulty_order()
	await _combo_order()
	await _combo_legality()
	await _combo_determinism_restore()
	await _ai_vs_ai_soak()
	print("cpu_test: %d checks, %d failure(s)" % [checks, failures])
	quit(1 if failures > 0 else 0)

# ---------------- harness --------------------

# Build a manually stepped mroot. CPU fighters use manual_mode, so the engine
# never ticks them; _step() reproduces the engine's exact order.
func _build_match(p1_path: String, p2_path: String, stage_path: String,
		p1_cpu: bool, p2_cpu: bool, level: int, seed: int) -> Node:
	var mroot: Node = load("res://scenes/match/MatchRoot.tscn").instantiate()
	mroot.selected_p1_data = load(p1_path)
	mroot.selected_p2_data = load(p2_path)
	mroot.selected_stage = load(stage_path)
	mroot.p1_cpu = p1_cpu
	mroot.p2_cpu = p2_cpu
	mroot.cpu_level = level
	mroot.cpu_seed = seed
	# The engine must NEVER tick this match: any engine physics tick during
	# the build awaits (or between manual steps) advances phase/timer/state
	# by machine timing and desynchronizes the runs this suite compares.
	# Godot re-enables scene processing on entry in some paths, so the
	# disable is applied pre-add, post-add, and re-asserted after the ready
	# awaits, where an is_physics_processing() guard pins it (verified to
	# hold: 0 spontaneous flips over rate-toggled stepping).
	mroot.set_physics_process(false)
	root.add_child(mroot)
	mroot.set_physics_process(false)
	# _ready (stage, fighters, CPUs) lands on the next frame tick. The
	# engine may tick the match a wall-dependent 0..N times during these
	# awaits before the next disable lands; that build drift is absorbed by
	# driving the intro by phase (_to_fight), never by frame counts.
	await process_frame
	await process_frame
	mroot.set_physics_process(false)
	assert(not mroot.is_physics_processing())
	mroot.p1.set_physics_process(false)
	mroot.p2.set_physics_process(false)
	# Erase any engine ticks the fighters may have taken during the awaits.
	mroot.p1.reset_state()
	mroot.p2.reset_state()
	if mroot.cpu_p1 != null:
		mroot.cpu_p1.manual_mode = true
	if mroot.cpu_p2 != null:
		mroot.cpu_p2.manual_mode = true
	return mroot

func _free_match(mroot: Node) -> void:
	if mroot.cpu_p1 != null:
		mroot.cpu_p1._release_all()
	if mroot.cpu_p2 != null:
		mroot.cpu_p2._release_all()
	mroot.queue_free()
	await process_frame
	await process_frame

func _step(mroot: Node, frames: int) -> void:
	var dt := 1.0 / 60.0
	for _i in frames:
		# One real engine tick advances the physics-frame counter: without
		# it Input's just_pressed flag would stay latched forever. The rate
		# is raised only for the yield (the accumulator then grants ticks
		# immediately instead of pacing them to wall clock), and restored
		# before the manual ticks so the sim keeps its 60 Hz math.
		Engine.physics_ticks_per_second = 60000
		await physics_frame
		Engine.physics_ticks_per_second = 60
		if mroot.cpu_p1 != null:
			mroot.cpu_p1.manual_tick()
		if mroot.cpu_p2 != null:
			mroot.cpu_p2.manual_tick()
		mroot.p1._physics_process(dt)
		mroot.p2._physics_process(dt)
		mroot._physics_process(dt)

# Fast-forward through the intro so the fighters are live. Driven by phase,
# not a fixed step count: any 1-frame drift in when the build's engine
# iterations landed must not shift the whole script (the #69 lesson).
func _to_fight(mroot: Node) -> void:
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

# A compact per-frame fingerprint of the whole mroot, for determinism runs.
func _frame_hash(mroot: Node) -> int:
	var p1: FighterBase = mroot.p1
	var p2: FighterBase = mroot.p2
	return hash([
		int(round(p1.position.x)), int(round(p1.position.y)),
		int(round(p1.health)), int(round(p1.meter)), int(p1.state),
		int(round(p2.position.x)), int(round(p2.position.y)),
		int(round(p2.health)), int(round(p2.meter)), int(p2.state),
		mroot.phase, mroot.timer_frames, mroot.wins[0], mroot.wins[1],
	])

# Scripted human driver for P1 (a fixed input pattern, no RNG): hold left in
# pulses, poke with light on a fixed cadence.
func _scripted_p1(mroot: Node, frame: int) -> void:
	if frame % 90 < 30:
		Input.action_press("p1_left")
	else:
		Input.action_release("p1_left")
	if frame % 120 == 0:
		# Inject the tap at the exact point _poll_input writes. The Input
		# singleton's just_pressed latch is wall-timing coupled (the #67/#69
		# flake class): a press issued between engine ticks may register one
		# tick early or late, which desynchronizes the two runs this suite
		# compares. A direction hold stays on Input (axis reads are not
		# counter-gated).
		mroot.p1.input_buffer["light"] = 0

func _release_p1() -> void:
	Input.action_release("p1_left")

# ---------------- 1. legality --------------------

func _legality() -> void:
	var mroot: Node = await _build_match(PEGGY, RICHARD, GAS_N_GO,
		false, true, 2, 12345)
	await _to_fight(mroot)
	var cpu: FighterBase = mroot.p2
	var cheat_move: bool = false
	var ex_cheat: bool = false
	var out_of_bounds: bool = false
	var stage: Node = mroot.stage
	# LOW meter: any EX the CPU starts would be a violation of the meter rules.
	cpu.meter = 10.0
	var frame := 0
	while frame < 900 and mroot.phase == mroot.Phase.FIGHT:
		_scripted_p1(mroot, frame)
		await _step(mroot, 1)
		frame += 1
		if cpu.state == FighterBase.State.ATTACK and cpu.current_move != null:
			if cpu.state_frame == 0 and _last_cpu_state == FighterBase.State.HITSTUN:
				cheat_move = true
			if cpu.current_move.ex:
				ex_cheat = true
		_last_cpu_state = cpu.state
		if is_nan(cpu.position.x) or is_nan(cpu.health) or cpu.health < 0.0 \
				or cpu.meter < 0.0 or cpu.meter > cpu.max_meter:
			out_of_bounds = true
		if cpu.position.x < stage.left_bound - 4.0 \
				or cpu.position.x > stage.right_bound + 4.0:
			out_of_bounds = true
	_release_p1()
	_check("CPU never starts a move out of hitstun (human input path only)",
		not cheat_move, "a move started on a hitstun frame")
	_check("CPU never plays an EX row while its meter cannot pay (meter pinned low)",
		not ex_cheat, "an EX move started with meter 10")
	_check("CPU health/meter/position stay in bounds under HARD pressure",
		not out_of_bounds)
	await _free_match(mroot)

var _last_cpu_state: int = -1

# ---------------- 2. determinism --------------------

func _run_scripted_match(seed: int, frames: int) -> Array:
	var mroot: Node = await _build_match(PEGGY, RICHARD, BUS_STOP,
		false, true, 1, seed)
	await _to_fight(mroot)
	var hashes: Array = []
	var frame := 0
	while frame < frames and mroot.phase == mroot.Phase.FIGHT:
		_scripted_p1(mroot, frame)
		await _step(mroot, 1)
		frame += 1
		hashes.append(_frame_hash(mroot))
	_release_p1()
	await _free_match(mroot)
	return hashes

func _determinism() -> void:
	var a: Array = await _run_scripted_match(4242, 600)
	var b: Array = await _run_scripted_match(4242, 600)
	var c: Array = await _run_scripted_match(777, 600)
	_check("same seed + same scripted human inputs give an identical frame-by-frame mroot",
		a == b, "%d vs %d hashes, first diff at %d" % [a.size(), b.size(),
			_first_diff(a, b)])
	_check("a different seed produces a different mroot",
		a != c and _first_diff(a, c) < mini(a.size(), c.size()),
		"identical hash streams for different seeds (sizes %d vs %d)"
			% [a.size(), c.size()])

static func _first_diff(a: Array, b: Array) -> int:
	var n: int = mini(a.size(), b.size())
	for i in n:
		if a[i] != b[i]:
			return i
	return n if a.size() == b.size() else mini(a.size(), b.size())

# ---------------- 3. AI state save/restore --------------------

func _save_restore() -> void:
	# Run one mroot 500 frames, snapshot the AI state mid-mroot, and compare a
	# restored continuation against a straight-through run of the same seed.
	var match_a: Node = await _build_match(RICHARD, PEGGY, GAS_N_GO,
		false, true, 2, 999)
	await _to_fight(match_a)
	var frame := 0
	while frame < 500 and match_a.phase == match_a.Phase.FIGHT:
		_scripted_p1(match_a, frame)
		await _step(match_a, 1)
		frame += 1
	var snapshot: Dictionary = match_a.cpu_p2.serialize()
	var tail_a: Array = []
	while frame < 900 and match_a.phase == match_a.Phase.FIGHT:
		_scripted_p1(match_a, frame)
		await _step(match_a, 1)
		frame += 1
		tail_a.append(_frame_hash(match_a))
	_release_p1()
	await _free_match(match_a)

	var match_b: Node = await _build_match(RICHARD, PEGGY, GAS_N_GO,
		false, true, 2, 999)
	await _to_fight(match_b)
	frame = 0
	while frame < 500 and match_b.phase == match_b.Phase.FIGHT:
		_scripted_p1(match_b, frame)
		await _step(match_b, 1)
		frame += 1
	match_b.cpu_p2.load_state(snapshot)
	var tail_b: Array = []
	while frame < 900 and match_b.phase == match_b.Phase.FIGHT:
		_scripted_p1(match_b, frame)
		await _step(match_b, 1)
		frame += 1
		tail_b.append(_frame_hash(match_b))
	_release_p1()
	await _free_match(match_b)
	_check("restoring a serialized AI state reproduces the same continuation",
		tail_a == tail_b and not tail_a.is_empty(),
		"tail sizes %d vs %d, first diff at %d" % [tail_a.size(), tail_b.size(),
			_first_diff(tail_a, tail_b)])

# ---------------- 4. blocking skill ordering --------------------

# Count blocked attacks out of a scripted offensive: a "block" is an attack
# Count defended attacks out of a scripted offensive. Each entry resets the
# pair to a fixed 70px gap (inside Peggy's special reach, outside Richard's
# light) so the CPU's own offense cannot crowd out the defense being measured.
# A "defended" window is one where the CPU's health did not move: blocked,
# anti-aired, or otherwise avoided.
func _block_count(level: int, seed: int, scripted: Callable) -> int:
	var mroot: Node = await _build_match(PEGGY, RICHARD, GAS_N_GO,
		false, true, level, seed)
	await _to_fight(mroot)
	# This section measures DEFENSIVE skill in isolation: swap in a
	# defense-only difficulty (all offense knobs zero) so the Phase 4 combo
	# offense cannot crowd out the block being measured. Blocking, preblock,
	# and the reaction delay are the live knobs; everything else is 0.
	var defense_only := CpuDifficulty.new()
	defense_only.reaction_delay_frames = 22 if level <= 0 else 8
	defense_only.block_rate = 0.35 if level <= 0 else 0.90
	defense_only.preblock_rate = 0.003 if level <= 0 else 0.025
	defense_only.idle_limit = 9999 # the watchdog is an offense behavior here
	for knob in ["anti_air_rate", "tech_rate", "throw_rate", "poke_rate",
			"heavy_mix", "special_rate", "ex_rate", "meth_rate", "combo_rate",
			"reversal_rate", "corner_jump_rate", "retreat_rate",
			"string_rate", "launcher_rate", "stun_rate", "juggle_rate",
			"breaker_rate", "clip_cancel_rate", "shake_rate"]:
		defense_only.set(knob, 0.0)
	mroot.cpu_p2.difficulty = defense_only
	var cpu: FighterBase = mroot.p2
	var defended := 0
	for attack in scripted.call(mroot):
		# Arcs can span several entries (walk-through, jump-over cross); a
		# reset happens only where the script marks a new attack, so the
		# crossing actually happens before the counted strike. (Before the
		# Phase 4 CPU work every entry reset the pair, which silently
		# un-crossed the pass-through and jump-over scenarios.)
		if attack.get("reset", false):
			_reset_pair(mroot, 100.0, 160.0)
		var health_before: float = cpu.health
		var saw_blockstun: bool = false
		var saw_attack: bool = false
		for i in attack["frames"]:
			if attack["press"] != "":
				# Button taps inject at the buffer (the exact point
				# _poll_input writes). "up", "_right", "_left" are read as
				# HELD states (jump / axis) so they route through Input;
				# held axis reads are not counter-gated.
				if attack["press"].ends_with("_right") or attack["press"].ends_with("_left") \
						or attack["press"].ends_with("_up"):
					Input.action_press(attack["press"])
				else:
					mroot.p1.input_buffer[attack["press"].trim_prefix("p1_")] = 0
			await _step(mroot, 1)
			if attack["press"] != "" and (attack["press"].ends_with("_right") \
					or attack["press"].ends_with("_left") or attack["press"].ends_with("_up")):
				Input.action_release(attack["press"])
			if cpu.state in [FighterBase.State.BLOCKSTUN,
					FighterBase.State.BLOCK_STAND, FighterBase.State.BLOCK_CROUCH]:
				saw_blockstun = true
			if mroot.p1.state == FighterBase.State.ATTACK \
					and mroot.p1.current_move != null:
				saw_attack = true
		if attack.get("count", false) and saw_attack:
			# Defended = BLOCKED (chip allowed, the biggest block_damage is 9).
			# "Avoided with no health loss" is deliberately NOT credited: the
			# CPU's approach walk can carry it through a scripted attacker
			# (pass-through), which measures movement luck, not defense.
			var damage_taken: float = health_before - cpu.health
			if saw_blockstun and damage_taken <= 10.5:
				defended += 1
	_release_p1()
	await _free_match(mroot)
	return defended

# Frontal pressure: the reactable neutral special (9f startup + active
# window: HARD's 8f reaction can block it on sight, EASY's 22 cannot).
func _scripted_frontal(mroot: Node) -> Array:
	var script: Array = []
	for i in 16:
		script.append({"frames": 26, "press": "p1_special", "count": true,
			"reset": true})
		script.append({"frames": 20, "press": ""})
	return script

# Forced stale-facing cross-up trial: the CPU faces LEFT (the side p1
# attacked from in a previous, unshown beat) while p1 strikes from its
# RIGHT. Blocking must resolve from POSITIONS through the shared side
# helper, never from the stale facing — and the strike is reactable
# (special 9f startup, air special 12f), so HARD (8f reaction) defends and
# EASY (22f) cannot. Phase 4 note: the old scripted walk-through/jump-over
# scenarios were rebuilt here — their per-entry pair resets silently
# un-crossed every arc, and the CPU's new combo offense crowded out what
# they were measuring.
func _forced_crossup_count(level: int, seed: int, airborne: bool) -> int:
	var mroot: Node = await _build_match(PEGGY, RICHARD, GAS_N_GO,
		false, true, level, seed)
	await _to_fight(mroot)
	var defense_only := CpuDifficulty.new()
	defense_only.reaction_delay_frames = 22 if level <= 0 else 8
	defense_only.block_rate = 0.35 if level <= 0 else 0.90
	defense_only.preblock_rate = 0.003 if level <= 0 else 0.025
	defense_only.idle_limit = 9999
	for knob in ["anti_air_rate", "tech_rate", "throw_rate", "poke_rate",
			"heavy_mix", "special_rate", "ex_rate", "meth_rate", "combo_rate",
			"reversal_rate", "corner_jump_rate", "retreat_rate",
			"string_rate", "launcher_rate", "stun_rate", "juggle_rate",
			"breaker_rate", "clip_cancel_rate", "shake_rate"]:
		defense_only.set(knob, 0.0)
	mroot.cpu_p2.difficulty = defense_only
	var cpu: FighterBase = mroot.p2
	var defended := 0
	for trial in 6:
		_reset_pair(mroot, 100.0, 160.0)
		cpu.facing = -1 # stale: facing the side p1 is NOT on
		if airborne:
			mroot.p1.position = Vector2(cpu.position.x + 30.0,
				mroot.stage.floor_y - 64.0)
			mroot.p1.velocity = Vector2(0.0, 40.0)
			mroot.p1.grounded = false
			mroot.p1._force_state(FighterBase.State.JUMP_FALL)
		else:
			mroot.p1.position = Vector2(cpu.position.x + 34.0,
				mroot.stage.floor_y)
			mroot.p1.velocity = Vector2.ZERO
		# The teleport leaves p1's authored facing stale too; facing only
		# auto-updates on grounded neutral ticks, and the buffered strike
		# must fire TOWARD the CPU.
		mroot.p1.facing = -1
		var hp_before: float = cpu.health
		var saw_block := false
		for i in 30:
			if i < 18:
				mroot.p1.input_buffer["special"] = 0
			await _step(mroot, 1)
			if cpu.state in [FighterBase.State.BLOCKSTUN,
					FighterBase.State.BLOCK_STAND, FighterBase.State.BLOCK_CROUCH]:
				saw_block = true
		var dmg: float = hp_before - cpu.health
		if saw_block and dmg <= 10.5:
			defended += 1
	_release_p1()
	await _free_match(mroot)
	return defended

func _blocking_order() -> void:
	# Seeds fixed so the ordering assertion is stable rather than lucky.
	# The frontal script keeps the CPU outside its own reach, so the
	# measured block is never crowded out by offense. The old scripted
	# walk-through/jump-over scenarios were replaced by the forced
	# stale-facing cross-ups below: with the Phase 4 CPU, the walk-through
	# co-located the fighters, and direction-dither at overlap blocked ~half
	# of everything for BOTH levels (movement luck, not skill).
	var easy: int = await _block_count(0, 31337, _scripted_frontal)
	var hard: int = await _block_count(2, 31337, _scripted_frontal)
	_check("HARD defends more than EASY against frontal attacks",
		hard > easy + 1, "easy=%d hard=%d" % [easy, hard])
	# Forced stale-facing cross-ups (see _forced_crossup_count): blocking
	# must resolve from positions, never from the stale facing, and the
	# strikes are reactable so the levels order cleanly.
	for airborne in [false, true]:
		var easy_x: int = await _forced_crossup_count(0, 4711, airborne)
		var hard_x: int = await _forced_crossup_count(2, 4711, airborne)
		var kind := "airborne" if airborne else "grounded"
		_check("HARD blocks a stale-facing %s cross-up from the correct side" % kind,
			hard_x > easy_x + 1, "easy=%d hard=%d" % [easy_x, hard_x])

# ---------------- 5. difficulty ordering (damage) --------------------

# Damage the CPU deals to a passive dummy inside a fixed window. Note the
# Phase 1 combo caps: a never-resetting string is ONE combo, so the 550
# damage cap bounds the total — HARD cannot mash a KO out of a static
# dummy anymore, by design. The ordering signal is therefore damage dealt
# per unit time, with the cap itself asserted separately.
func _cpu_damage(level: int, seed: int) -> float:
	var mroot: Node = await _build_match(PEGGY, RICHARD, BUS_STOP,
		false, true, level, seed)
	await _to_fight(mroot)
	var human: FighterBase = mroot.p1
	# The human does nothing: measure what the CPU can do to a static dummy.
	var frame := 0
	# With the tighter 44-276 bounds both levels can hit the combo damage
	# cap by 900 frames against a passive dummy. Shorten only this diagnostic
	# window so the measured difference remains unsaturated; no sim changes.
	while frame < 600 and mroot.phase == mroot.Phase.FIGHT:
		await _step(mroot, 1)
		frame += 1
	_release_p1()
	var damage: float = 1000.0 - human.health
	await _free_match(mroot)
	return damage

func _difficulty_order() -> void:
	var easy: float = 0.0
	var hard: float = 0.0
	for seed in [7, 21]:
		var seed_easy: float = await _cpu_damage(0, seed)
		var seed_hard: float = await _cpu_damage(2, seed)
		easy += seed_easy
		hard += seed_hard
	easy /= 2.0
	hard /= 2.0
	_check("HARD out-damages EASY against a passive opponent within 600 frames",
		hard > easy, "easy=%.0f hard=%.0f (600-frame windows, 2 seeds)"
			% [easy, hard])

# ---------------- 5b. Phase 4 combo ordering ------------------------------

# One measured CPU (p2) at `level` sparring a FIXED HARD partner (p1),
# CPU vs CPU, fixed seed -> deterministic event counts. Measures exactly
# what Phase 4 added: combo damage banked at combo resets, connected
# launchers, stun applications, breaker fires, and Clip Cancels.
func _combo_metrics(level: int, seed: int) -> Dictionary:
	var mroot: Node = await _build_match(RICHARD, PEGGY, GAS_N_GO,
		true, true, 2, seed)
	await _to_fight(mroot)
	# The partner stays HARD; only the measured side re-levels.
	mroot.cpu_p2.difficulty = CpuDifficulty.load_level(level)
	var me: FighterBase = mroot.p2
	var foe: FighterBase = mroot.p1
	var combo_damage := 0.0
	var prev_total := 0.0
	var launchers := 0
	var stuns := 0
	var breaks := 0
	var clips := 0
	var last_launcher := false
	var last_stunned := false
	var last_invuln := 0
	var last_clip := false
	var frame := 0
	while frame < 2400 and mroot.phase != mroot.Phase.MATCH_END:
		await _step(mroot, 1)
		frame += 1
		# Combo damage: the foe's tracker accumulates within one combo; a
		# reset banks whatever that combo paid.
		var total: float = foe.combo_tracker.total_damage
		if total < prev_total: # tracker reset -> combo over
			combo_damage += prev_total
		prev_total = total
		var launcher_now: bool = me.state == FighterBase.State.ATTACK \
				and me.current_move != null and me.current_move.launcher \
				and me.move_hit_confirmed
		if launcher_now and not last_launcher:
			launchers += 1
		last_launcher = launcher_now
		var stunned_now: bool = foe.stun_id != &""
		if stunned_now and not last_stunned:
			stuns += 1
		last_stunned = stunned_now
		if me.breaker_invuln_frames > 0 and last_invuln <= 0:
			breaks += 1
		last_invuln = me.breaker_invuln_frames
		if me.clip_cancel_used and not last_clip:
			clips += 1
		last_clip = me.clip_cancel_used
	if prev_total > 0.0:
		combo_damage += prev_total
	await _free_match(mroot)
	return {"damage": combo_damage, "launchers": launchers, "stuns": stuns,
		"breaks": breaks, "clips": clips}

func _combo_order() -> void:
	# Fixed seeds; every count below is a deterministic event count. HARD
	# blocks most of the sparring partner's offense, so unblocked-hit
	# (breaker) opportunities are sparse — two seeds over a long window
	# give the rates room to separate.
	var easy := {"damage": 0.0, "launchers": 0, "stuns": 0, "breaks": 0, "clips": 0}
	var hard := {"damage": 0.0, "launchers": 0, "stuns": 0, "breaks": 0, "clips": 0}
	for seed in [90210, 90211]:
		var e: Dictionary = await _combo_metrics(0, seed)
		var h: Dictionary = await _combo_metrics(2, seed)
		for key in ["damage", "launchers", "stuns", "breaks", "clips"]:
			easy[key] = easy[key] + e[key]
			hard[key] = hard[key] + h[key]
	_check("HARD banks more combo damage than EASY (authored routes)",
		float(hard["damage"]) > float(easy["damage"]),
		"easy=%.0f hard=%.0f" % [easy["damage"], hard["damage"]])
	_check("HARD connects more launchers than EASY",
		int(hard["launchers"]) > int(easy["launchers"]),
		"easy=%d hard=%d" % [easy["launchers"], hard["launchers"]])
	_check("HARD applies more stuns than EASY",
		int(hard["stuns"]) > int(easy["stuns"]),
		"easy=%d hard=%d" % [easy["stuns"], hard["stuns"]])
	_check("HARD fires the breaker more often than EASY",
		int(hard["breaks"]) > int(easy["breaks"]),
		"easy=%d hard=%d" % [easy["breaks"], hard["breaks"]])
	_check("HARD Clip Cancels at least as often as EASY",
		int(hard["clips"]) >= int(easy["clips"]),
		"easy=%d hard=%d" % [easy["clips"], hard["clips"]])
	# Coverage honesty: the ordering window must actually exercise the
	# Phase 4 paths, or the counts above say nothing.
	_check("the HARD sparring window exercises launchers, stuns, and breaks",
		int(hard["launchers"]) > 0 and int(hard["stuns"]) > 0
			and int(hard["breaks"]) > 0,
		"launchers=%d stuns=%d breaks=%d" % [hard["launchers"],
			hard["stuns"], hard["breaks"]])

# ---------------- 6b. Phase 4 legality under fire ---------------------------

func _combo_legality() -> void:
	# HARD vs HARD: both sides run the full combo system (strings,
	# launchers, stuns, breakers, Clip Cancels) while the suite watches for
	# the violations that would mean the CPU left the human input path.
	var mroot: Node = await _build_match(PEGGY, RICHARD, GAS_N_GO,
		true, true, 2, 5150)
	await _to_fight(mroot)
	var break_from_blockstun := false
	var move_from_hitstun := false
	var bad_meter := false
	var events := {"breaks": 0, "stuns": 0, "launchers": 0}
	var last_states := [mroot.p1.state, mroot.p2.state]
	var last_invuln := [0, 0]
	var last_stunned := false
	var frame := 0
	while frame < 900 and mroot.phase != mroot.Phase.MATCH_END:
		await _step(mroot, 1)
		frame += 1
		for who in [0, 1]:
			var f: FighterBase = mroot.p1 if who == 0 else mroot.p2
			if f.state == FighterBase.State.BLOCKSTUN \
					and f.breaker_invuln_frames > 0:
				break_from_blockstun = true
			if f.state == FighterBase.State.ATTACK and f.current_move != null \
					and f.state_frame == 0 and last_states[who] == FighterBase.State.HITSTUN:
				move_from_hitstun = true
			if f.meter < 0.0 or f.meter > f.max_meter or is_nan(f.health) \
					or f.health < 0.0:
				bad_meter = true
			last_states[who] = f.state
			if f.breaker_invuln_frames > 0 and last_invuln[who] <= 0:
				events["breaks"] += 1
			last_invuln[who] = f.breaker_invuln_frames
		var any_stunned: bool = mroot.p1.stun_id != &"" or mroot.p2.stun_id != &""
		if any_stunned and not last_stunned:
			events["stuns"] += 1
		last_stunned = any_stunned
		if mroot.p1.state == FighterBase.State.ATTACK \
				and mroot.p1.current_move != null \
				and mroot.p1.current_move.launcher \
				and mroot.p1.move_hit_confirmed:
			events["launchers"] += 1
	_check("no breaker ever resolves from blockstun (both CPU sides)",
		not break_from_blockstun, "a break fired during blockstun")
	_check("no move starts out of hitstun under full combo pressure",
		not move_from_hitstun, "a move started on a hitstun frame")
	_check("health and meter stay in bounds under full combo pressure",
		not bad_meter)
	_check("the legality window actually exercised breaks, stuns, and launchers",
		int(events["breaks"]) > 0 and int(events["stuns"]) > 0
			and int(events["launchers"]) > 0,
		"breaks=%d stuns=%d launchers=%d" % [events["breaks"],
			events["stuns"], events["launchers"]])
	await _free_match(mroot)

# ---------------- 6c. Phase 4 determinism and mid-event save/restore -------

# Step until `condition` (a Callable over the mroot) holds, then return the
# frame it first held at plus the AI state snapshot. CPU vs CPU with a fixed
# seed: the condition hits at the SAME frame in every replay of the seed.
func _run_until(mroot: Node, condition: Callable, max_frames: int) -> Dictionary:
	var frame := 0
	while frame < max_frames and mroot.phase == mroot.Phase.FIGHT:
		await _step(mroot, 1)
		frame += 1
		if condition.call(mroot):
			return {"frame": frame, "snapshot": mroot.cpu_p2.serialize()}
	return {}

func _tail_hashes(mroot: Node, frames: int) -> Array:
	var tail: Array = []
	var f := 0
	while f < frames and mroot.phase == mroot.Phase.FIGHT:
		await _step(mroot, 1)
		tail.append(_frame_hash(mroot))
		f += 1
	return tail

func _mid_event_restore(name: String, condition: Callable) -> void:
	var a: Node = await _build_match(RICHARD, PEGGY, GAS_N_GO,
		true, true, 2, 9090)
	await _to_fight(a)
	var hit: Dictionary = await _run_until(a, condition, 1500)
	var tail_a: Array = []
	if not hit.is_empty():
		tail_a = await _tail_hashes(a, 300)
	await _free_match(a)

	var ok := false
	var detail := "condition never hit"
	var b: Node = await _build_match(RICHARD, PEGGY, GAS_N_GO,
		true, true, 2, 9090)
	await _to_fight(b)
	if not hit.is_empty():
		for i in hit["frame"]:
			await _step(b, 1)
		b.cpu_p2.load_state(hit["snapshot"])
		var tail_b: Array = await _tail_hashes(b, 300)
		ok = tail_a == tail_b and not tail_a.is_empty()
		detail = "tails %d vs %d, first diff at %d" % [tail_a.size(),
			tail_b.size(), _first_diff(tail_a, tail_b)]
	await _free_match(b)
	_check("mid-%s: an AI state save/restore reproduces the same continuation"
		% name, not hit.is_empty() and ok, detail)

func _combo_determinism_restore() -> void:
	# Whole-run determinism at HARD (both sides combo-capable, no human).
	var a: Node = await _build_match(RICHARD, PEGGY, GAS_N_GO,
		true, true, 2, 9090)
	await _to_fight(a)
	var hash_a: Array = await _tail_hashes(a, 700)
	await _free_match(a)
	var b: Node = await _build_match(RICHARD, PEGGY, GAS_N_GO,
		true, true, 2, 9090)
	await _to_fight(b)
	var hash_b: Array = await _tail_hashes(b, 700)
	await _free_match(b)
	_check("a HARD CPU-vs-CPU mroot replays identically from the seed alone",
		hash_a == hash_b and not hash_a.is_empty(),
		"%d vs %d hashes, first diff at %d" % [hash_a.size(), hash_b.size(),
			_first_diff(hash_a, hash_b)])
	# Mid-event save/restore: the snapshot must cover the new Phase 4 state
	# (combo_depth, break_armed, juggle_step) exactly where it is live.
	await _mid_event_restore("combo", func(m: Node) -> bool:
		return m.p1.combo_tracker.active and m.p1.combo_hits >= 2)
	# A fresh combo opening anywhere (either side) is the stun moment.
	await _mid_event_restore("stun", func(m: Node) -> bool:
		return m.p1.stun_id != &"" or m.p2.stun_id != &"")
	# Either side breaking is a valid mid-break moment (the snapshot and the
	# restored timeline cover both fighters deterministically).
	await _mid_event_restore("break", func(m: Node) -> bool:
		return m.p1.breaker_invuln_frames > 0 or m.p2.breaker_invuln_frames > 0)

# ---------------- 6. AI-vs-AI soak --------------------

func _ai_vs_ai_soak() -> void:
	# Every pairing of both characters (P1/P2 orderings), both stages, two
	# seeds: 8 full HARD-vs-HARD matches, both CPU-controlled.
	var matchups: Array = [
		[PEGGY, RICHARD], [RICHARD, PEGGY],
	]
	var stages: Array = [GAS_N_GO, BUS_STOP]
	var lengths: Array[int] = []
	var win_counts: Dictionary = {}
	# Timeouts + decisive rounds ceiling. Measured (2026-11-22, the Phase 4
	# combo CPU at NORMAL, seeds 11/29, both pairings, both stages): matches
	# end between 3282 and 3896 frames (both stages identical per seed).
	# The limit is the measured worst plus ~25%, so a regression that stalls
	# past it fails fast instead of hiding under the old blunt 40000 ceiling.
	var max_match_frames := 5000
	for matchup in matchups:
		for stage_path in stages:
			for seed in [11, 29]:
				var mroot: Node = await _build_match(matchup[0], matchup[1],
					stage_path, true, true, 1, seed)
				var frame := 0
				var longest_mutual_idle := 0
				var idle_now := 0
				var bad_state: bool = false
				while frame < max_match_frames and mroot.phase != mroot.Phase.MATCH_END:
					await _step(mroot, 1)
					frame += 1
					var f1: FighterBase = mroot.p1
					var f2: FighterBase = mroot.p2
					if f1.state == FighterBase.State.IDLE \
							and f2.state == FighterBase.State.IDLE:
						idle_now += 1
						longest_mutual_idle = maxi(longest_mutual_idle, idle_now)
					else:
						idle_now = 0
					if is_nan(f1.health) or is_nan(f2.health) \
							or f1.health < 0.0 or f2.health < 0.0 \
							or f1.meter < 0.0 or f2.meter < 0.0 \
							or f1.meter > f1.max_meter or f2.meter > f2.max_meter:
						bad_state = true
						break
				var ended: bool = mroot.phase == mroot.Phase.MATCH_END
				var winner_name: String = "timeout/none"
				if ended:
					var winner: FighterBase = mroot.p1 if mroot.wins[0] > mroot.wins[1] else mroot.p2
					winner_name = winner.data.display_name
					if not win_counts.has(winner_name):
						win_counts[winner_name] = 0
					win_counts[winner_name] += 1
				_check("AI-vs-AI %s vs %s on %s seed %d ends within %d frames"
					% [mroot.p1.data.display_name, mroot.p2.data.display_name,
						mroot.selected_stage.display_name, seed, max_match_frames],
					ended and not bad_state,
					"phase=%d frame=%d bad_state=%s"
					% [mroot.phase, frame, str(bad_state)])
				_check("AI-vs-AI %s vs %s seed %d: no long mutual idle, sane bounds"
					% [mroot.p1.data.display_name, mroot.p2.data.display_name, seed],
					longest_mutual_idle < 240)
				if ended:
					lengths.append(frame)
				print("SOAK match %s vs %s on %s seed %d: frames=%d ended=%s wins=%s"
					% [mroot.p1.data.display_name, mroot.p2.data.display_name,
						mroot.selected_stage.display_name, seed, frame,
						str(ended), str(mroot.wins)])
				await _free_match(mroot)
	var avg: float = 0.0
	if not lengths.is_empty():
		for l in lengths:
			avg += float(l)
		avg /= float(lengths.size())
	_check("AI-vs-AI soak: every mroot ended, %d matches, average length sane"
		% lengths.size(),
		lengths.size() == 8 and avg > 600.0 and avg < float(max_match_frames),
		"avg=%.0f frames over %d matches" % [avg, lengths.size()])
	print("SOAK: win counts ", win_counts,
		", avg mroot length %.0f frames (~%.0f s)" % [avg, avg / 60.0])
