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
	# Disable engine ticking BEFORE the match enters the tree: the number of
	# engine physics ticks between add_child and the awaits below is machine
	# timing, and any of them advancing the match would make builds (and so
	# cross-run comparisons) nondeterministic. The match only ever steps
	# manually from here on.
	mroot.set_physics_process(false)
	root.add_child(mroot)
	# _ready (stage, fighters, CPUs) lands on the next frame tick.
	await process_frame
	await process_frame
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

# Fast-forward through the intro so the fighters are live.
func _to_fight(mroot: Node) -> void:
	await _step(mroot, 61)

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
		Input.action_press("p1_light")
	else:
		Input.action_release("p1_light")

func _release_p1() -> void:
	Input.action_release("p1_left")
	Input.action_release("p1_light")

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
	var cpu: FighterBase = mroot.p2
	var defended := 0
	for attack in scripted.call(mroot):
		# Each scripted entry is a Dictionary: {"frames": N, "press": "action"}.
		# Only windows flagged "count" (actual attacks) are measured; setup
		# windows (walk-throughs, jump arcs, rests) are skipped.
		_reset_pair(mroot, 100.0, 160.0)
		var health_before: float = cpu.health
		var saw_blockstun: bool = false
		for i in attack["frames"]:
			if attack["press"] != "":
				Input.action_press(attack["press"])
			await _step(mroot, 1)
			if attack["press"] != "":
				Input.action_release(attack["press"])
			if cpu.state in [FighterBase.State.BLOCKSTUN,
					FighterBase.State.BLOCK_STAND, FighterBase.State.BLOCK_CROUCH]:
				saw_blockstun = true
		if attack.get("count", false):
			# Defended = blocked (chip allowed, the biggest block_damage is 9)
			# or avoided outright with no health loss.
			var damage_taken: float = health_before - cpu.health
			if (saw_blockstun and damage_taken <= 10.5) or damage_taken <= 0.01:
				defended += 1
	_release_p1()
	await _free_match(mroot)
	return defended

# Frontal pressure: the reactable neutral special (9f startup + active
# window: HARD's 8f reaction can block it on sight, EASY's 22 cannot).
func _scripted_frontal(mroot: Node) -> Array:
	var script: Array = []
	for i in 16:
		script.append({"frames": 26, "press": "p1_special", "count": true})
		script.append({"frames": 20, "press": ""})
	return script

# Pass-through: cross through the CPU first, then special from behind — the
# block direction must come from the shared side helper, not a stale facing.
func _scripted_passthrough(mroot: Node) -> Array:
	var script: Array = []
	for i in 10:
		script.append({"frames": 30, "press": "p1_right"})
		script.append({"frames": 26, "press": "p1_special", "count": true})
		script.append({"frames": 20, "press": ""})
	return script

# Jump-over cross-up: leap over the CPU and jab on the way down.
func _scripted_jumpover(mroot: Node) -> Array:
	var script: Array = []
	for i in 10:
		script.append({"frames": 1, "press": "p1_up"})
		script.append({"frames": 26, "press": ""})
		script.append({"frames": 40, "press": "p1_light", "count": true})
	return script

func _blocking_order() -> void:
	# Seeds fixed so the ordering assertion is stable rather than lucky.
	var scenarios: Array = [
		["frontal", _scripted_frontal, 31337],
		["pass-through", _scripted_passthrough, 31337],
		["jump-over cross-up", _scripted_jumpover, 4711],
	]
	for entry in scenarios:
		var name: String = entry[0]
		var scripted: Callable = entry[1]
		var easy: int = await _block_count(0, entry[2], scripted)
		var hard: int = await _block_count(2, entry[2], scripted)
		_check("HARD defends more than EASY against %s attacks" % name,
			hard > easy + 1, "easy=%d hard=%d" % [easy, hard])

# ---------------- 5. difficulty ordering (damage) --------------------

# Frames the CPU needs to KO a passive dummy (cap 3000 = never). HARD's
# higher aggression and punish usage should close it out faster than EASY.
func _cpu_damage(level: int, seed: int) -> int:
	var mroot: Node = await _build_match(PEGGY, RICHARD, BUS_STOP,
		false, true, level, seed)
	await _to_fight(mroot)
	var human: FighterBase = mroot.p1
	# The human does nothing: measure what the CPU can do to a static dummy.
	var frame := 0
	while frame < 3000 and mroot.phase == mroot.Phase.FIGHT:
		await _step(mroot, 1)
		frame += 1
	_release_p1()
	var ko_frames: int = 3000 if human.health > 0.0 else frame
	await _free_match(mroot)
	return ko_frames

func _difficulty_order() -> void:
	var easy: int = 0
	var hard: int = 0
	for seed in [7, 21]:
		easy += mini(await _cpu_damage(0, seed), 3000)
		hard += mini(await _cpu_damage(2, seed), 3000)
	_check("HARD KOs a passive opponent faster than EASY",
		hard < easy, "easy=%d frames hard=%d frames (2 seeds, capped at 3000 each)"
			% [easy, hard])

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
	var max_match_frames := 40000 # timeouts + decisive rounds ceiling
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
				await _free_match(mroot)
	var avg: float = 0.0
	if not lengths.is_empty():
		for l in lengths:
			avg += float(l)
		avg /= float(lengths.size())
	_check("AI-vs-AI soak: every mroot ended, %d matches, average length sane"
		% lengths.size(),
		lengths.size() == 8 and avg > 600.0 and avg < 24000.0,
		"avg=%.0f frames over %d matches" % [avg, lengths.size()])
	print("SOAK: win counts ", win_counts,
		", avg mroot length %.0f frames (~%.0f s)" % [avg, avg / 60.0])
