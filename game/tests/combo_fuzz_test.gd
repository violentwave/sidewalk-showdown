# Combo fuzz suite — breaks the Phase 1 combo layer (cancel graph, macros,
# Clip Cancel, data-driven scaling) across both characters as both P1/P2, both
# stages, both sides, and with pass-through on.
#
# Run:  godot --headless --path game --script res://tests/combo_fuzz_test.gd
#
# All fuzzing uses a test-local seeded LCG — the gameplay RNG (CPU seeded LCG)
# is never touched. Every assertion is strict; a failure is logged in
# docs/COMBO_FINDINGS.md with a reproduction. Nothing here silently weakens an
# assertion to pass.
#
# CI budget: seed counts are constants at the top; this suite targets ~<60s
# on the already-running 4-minute combo_test. If it ever exceeds ~120s locally,
# the soak or determinism frame counts are what to trim.
extends SceneTree

const PEGGY := "res://resources/fighters/peg_leg_peggy.tres"
const RICHARD := "res://resources/fighters/whiskey_richard.tres"
const GAS_N_GO := "res://resources/stages/gas_n_go.tres"
const BUS_STOP := "res://resources/stages/bus_stop_night.tres"
const MATCH_ROOT := "res://scenes/match/MatchRoot.tscn"

# --- seed / count constants at the top (the CI budget knob) ---
const SEEDS_FUZZ := [1001, 2002, 3003, 4004]
const FUZZ_PER_TARGET := 3
const FUZZ_FRAMES := 300
const DETERMINISM_FRAMES := 240
const SOAK_MATCHES := 8
# Measured on the fixed (#76-style) harness, NORMAL level, seeds 11/29,
# both pairings and stages. Phase 3 (Peggy 274 launcher + Taser Belch
# 105->40) re-measured 2026-11-21: 3092-5007 frames. Phase 4 (the combo CPU)
# re-measured 2026-11-22: matches now end between 3282 and 3896 frames
# (both stages produce identical lengths per seed — the stages share
# bounds and spawns, so only the pairing/seed matters); no stalls, mutual
# idle always < 240. The ceiling resets to worst + ~25%: a regression that
# stalls past it fails fast instead of hiding under the old blunt limit.
const SOAK_MAX_FRAMES := 4900

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
    await _meter_and_scalar_invariants()
    await _route_search_and_caps()
    await _infinite_hunt_loops()
    await _macros_clips_blockcounter()
    await _determinism_serialization()
    await _cross_up_and_side_switch()
    await _juggle_budget_and_routes()
    await _juggle_fuzz()
    await _stuns_and_breakers()
    await _cpu_vs_cpu_soak()
    print("combo_fuzz: %d checks, %d failure(s)" % [checks, failures])
    quit(1 if failures > 0 else 0)

# ---------------------------------------------------------------------------
# harness (same contract as combo_test.gd)
# ---------------------------------------------------------------------------

func _build_match(p1_path: String, p2_path: String, stage_path: String,
		p1_cpu: bool = false, p2_cpu: bool = false, level: int = 1, seed: int = 0) -> Node:
    var mroot: Node = load("res://scenes/match/MatchRoot.tscn").instantiate()
    mroot.selected_p1_data = load(p1_path)
    mroot.selected_p2_data = load(p2_path)
    mroot.selected_stage = load(stage_path)
    mroot.p1_cpu = p1_cpu
    mroot.p2_cpu = p2_cpu
    mroot.cpu_level = level
    mroot.cpu_seed = seed
    # The engine must NEVER tick this match: Godot re-enables a scene root's
    # physics processing on tree entry in some paths, so the pre-add disable
    # alone does not stick (the PR #76 root cause — the engine ticked the
    # manually-stepped match a wall-dependent 4-10 frames during the build
    # awaits and mid-script). Disable pre-add, post-add, and re-assert after
    # the ready awaits with an is_physics_processing() guard, exactly like
    # cpu_test.gd / combo_test.gd. Any residual build drift is absorbed by
    # the phase-driven _to_fight below.
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
    if mroot.cpu_p1 != null:
        mroot.cpu_p1.manual_mode = true
    if mroot.cpu_p2 != null:
        mroot.cpu_p2.manual_mode = true
    return mroot

func _free_match(mroot: Node) -> void:
    mroot.queue_free()
    await process_frame
    await process_frame

func _step(mroot: Node, frames: int, press_action: String = "") -> void:
    var dt := 1.0 / 60.0
    for _i in frames:
        for entry in press_action.split("+"):
            if entry == "":
                continue
            # Presses inject into the owning fighter's buffer; the prefix
            # decides the side. Unprefixed entries keep targeting p1 for
            # backward compatibility with the existing fuzz sections.
            var who: FighterBase = mroot.p1
            var action: String = entry
            if entry.begins_with("p1_"):
                action = entry.trim_prefix("p1_")
            elif entry.begins_with("p2_"):
                who = mroot.p2
                action = entry.trim_prefix("p2_")
            who.input_buffer[action] = 0
            who._macro_on_press(action)
        # Advance the engine physics tick so Input's just_pressed semantics and
        # the physics-frame counter are real, then step the CPU AI when present.
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

func _wait_neutral(mroot: Node, max_frames: int = 90) -> void:
    for _i in max_frames:
        await _step(mroot, 1)
        if (mroot.p1.state in [FighterBase.State.IDLE, FighterBase.State.WALK_F,
                FighterBase.State.WALK_B, FighterBase.State.CROUCH]
                and mroot.p2.state in [FighterBase.State.IDLE, FighterBase.State.WALK_F,
                FighterBase.State.WALK_B, FighterBase.State.CROUCH]):
            return

func _press_and_confirm(mroot: Node, action: String, timeout: int = 40) -> bool:
    await _step(mroot, 1, action)
    for i in timeout:
        await _step(mroot, 1)
        if mroot.p1.move_hit_confirmed:
            return true
        if mroot.p1.state != FighterBase.State.ATTACK:
            return false
    return false

# Drive the match from the INTRO into the FIGHT phase (any engine-timing drift
# must not shift the rest of the script).
func _to_fight(mroot: Node) -> void:
    for i in 120:
        await _step(mroot, 1)
        if mroot.phase == mroot.Phase.FIGHT:
            return

# A scripted attack driven through the real buffer path (no wall-timing).
func _script_press(mroot: Node, action: String, frames: int) -> void:
    await _step(mroot, frames, action)

# A 3-step macro dial (steps are already "p1_..." action names).
func _dial_macro(mroot: Node, steps: Array, gap: int) -> void:
    await _step(mroot, 1, steps[0])
    for i in range(1, steps.size()):
        await _step(mroot, maxi(1, gap), steps[i])

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

# A deterministic test-local LCG (same constants as the CPU's, kept local to
# the test so gameplay RNG is untouched).
func _lcg(state: int) -> int:
    return (state * 1664525 + 1013904223) & 0xFFFFFFFF

# A compact per-frame fingerprint of the whole match (integer fields only).
func _frame_hash(mroot: Node) -> int:
    var p1: FighterBase = mroot.p1
    var p2: FighterBase = mroot.p2
    return hash([
        int(round(p1.position.x)), int(round(p1.health)), int(p1.state),
        int(round(p2.position.x)), int(round(p2.health)), int(p2.state),
        int(round(p2.combo_tracker.total_damage)), mroot.timer_frames,
        mroot.phase
    ])

# ---------------------------------------------------------------------------
# 1. Meter and scalar invariants (landed-hits-only economy)
# ---------------------------------------------------------------------------

func _meter_and_scalar_invariants() -> void:
    var mroot: Node = await _build_match(PEGGY, RICHARD, GAS_N_GO)
    await _to_fight(mroot)
    var p1: FighterBase = mroot.p1
    var p2: FighterBase = mroot.p2
    var light := p1.data.find_move(MoveData.InputType.LIGHT, MoveData.Stance.STAND)
    var heavy := p1.data.find_move(MoveData.InputType.HEAVY, MoveData.Stance.STAND)
    var neutral := p1.data.find_move(MoveData.InputType.SPECIAL_NEUTRAL, MoveData.Stance.STAND)

    # Block pays nothing (blocked pays meter_gain_block * 0.0).
    _reset_pair(mroot, 100.0, 145.0)
    Input.action_press("p2_right")   # defender holds away from the attacker
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
    _check("blocked hit pays no meter to attacker or defender",
        is_equal_approx(p1.meter, 0.0) and is_equal_approx(p2.meter, 0.0),
        "p1=%.2f p2=%.2f" % [p1.meter, p2.meter])

    # Whiff pays nothing.
    _reset_pair(mroot, 100.0, 295.0)  # out of reach: guaranteed whiff
    p1.meter = 0.0
    await _step(mroot, 1, "p1_light")
    await _step(mroot, 12)
    _check("whiff pays no meter to the attacker", is_equal_approx(p1.meter, 0.0),
        "meter=%.2f" % p1.meter)

    # Defender gains nothing on a landed hit, a block, or a whiff.
    _reset_pair(mroot, 100.0, 145.0)
    p1.meter = 0.0
    p2.receive_hit(p1, light)
    _check("defender gains 0 on a landed hit", is_equal_approx(p2.meter, 0.0),
        "meter=%.2f" % p2.meter)
    mroot.p2.health = 1000.0
    mroot.p2.meter = 0.0
    mroot.p2.receive_hit(p1, light)
    _check("defender gains 0 on a second landed hit", is_equal_approx(mroot.p2.meter, 0.0),
        "meter=%.2f" % mroot.p2.meter)

    # Meter in combos: opener full, 2nd hit x0.5, deep floor 0.25.
    _reset_pair(mroot, 100.0, 145.0)
    p1.meter = 0.0
    p2.receive_hit(p1, light)
    var after_one := p1.meter
    p2.receive_hit(p1, heavy)
    var after_two := p1.meter
    _check("meter: combo opener pays meter_gain_hit in full (6)",
        is_equal_approx(after_one, 6.0), "meter=%.2f" % after_one)
    _check("meter: second combo hit pays x0.5 (3)",
        is_equal_approx(after_two - after_one, 3.0),
        "gain=%.2f" % (after_two - after_one))
    # Phase 3 note: the chain uses light, not the neutral special — the
    # neutral specials are authored stun rows now, and a stun hit pays the
    # attacker nothing by design (§10.5).
    for i in 6:
        p2.receive_hit(p1, light)
    _check("meter: deep combo hits never below 0.25 floor per hit",
        p1.meter - after_two >= 6.0 * 0.25 * 6.0 - 0.01,
        "meter=%.2f (min=%.2f)" % [p1.meter, after_two + 6.0 * 0.25 * 6.0])

    # Health clamp at 0 and meter clamp at 100 hold under extreme direct hits.
    _reset_pair(mroot, 100.0, 145.0)
    mroot.p2.health = 2.0
    mroot.p2.meter = 100.0
    mroot.p2.receive_hit(p1, heavy)      # 85 damage -> next hit is 0 (clamp)
    mroot.p2.receive_hit(p1, light)      # that should not negative the health
    mroot.p2.receive_hit(p1, heavy)      # another heavy on a 0-health fighter
    _check("health floors at 0 and meter floors at 0",
        mroot.p2.health >= 0.0 and mroot.p1.meter <= 100.0 + 0.01,
        "health=%.3f meter=%.2f" % [mroot.p2.health, mroot.p1.meter])

    await _free_match(mroot)

# ---------------------------------------------------------------------------
# 2. Route search: from every move, follow every cancel edge for N hits
# ---------------------------------------------------------------------------

# Fire `moves` at p2 as direct resolver hits and, for each move, chase the
# canonical continuation (light, light, heavy) up to the 12-hit cap. Every
# path must respect the hit cap and the 550 damage cap.
func _route_search_check_one(p1: FighterBase, p2: FighterBase, moves: Array, label: String) -> void:
    var light := p1.data.find_move(MoveData.InputType.LIGHT, MoveData.Stance.STAND)
    var heavy := p1.data.find_move(MoveData.InputType.HEAVY, MoveData.Stance.STAND)
    var neutral := p1.data.find_move(MoveData.InputType.SPECIAL_NEUTRAL, MoveData.Stance.STAND)
    var cycle := [light, light, heavy, light, neutral, heavy]
    var idx := 0
    var over_cap_hp: float = 0.0
    for i in 13:
        p2.receive_hit(p1, cycle[idx % cycle.size()])
        if i == 11:
            over_cap_hp = p2.health
        idx += 1
    _check(label + ": 12-hit cap zeroes the 13th hit",
        is_equal_approx(p2.health, over_cap_hp) and p2.combo_tracker.hits == 13,
        "hp12=%.3f hp13=%.3f hits=%d" % [over_cap_hp, p2.health, p2.combo_tracker.hits])
    _check(label + ": per-combo damage never exceeds 550",
        p2.combo_tracker.total_damage <= 550.0 + 0.01,
        "total=%.1f" % p2.combo_tracker.total_damage)

func _route_search_and_caps() -> void:
    # Both stages: floor_y differs (Gas-N-Go 158, Bus Stop 170), so the
    # direct-resolver cap checks must not silently assume one floor.
    for stage_path in [GAS_N_GO, BUS_STOP]:
        var stage_label: String = stage_path.trim_prefix("res://resources/stages/").trim_suffix(".tres")
        var mroot: Node = await _build_match(PEGGY, RICHARD, stage_path)
        await _to_fight(mroot)
        var p1: FighterBase = mroot.p1
        var p2: FighterBase = mroot.p2
        var moves := [
            [MoveData.InputType.LIGHT, MoveData.Stance.STAND],
            [MoveData.InputType.HEAVY, MoveData.Stance.STAND],
            [MoveData.InputType.LIGHT, MoveData.Stance.CROUCH],
            [MoveData.InputType.HEAVY, MoveData.Stance.CROUCH],
            [MoveData.InputType.SPECIAL_NEUTRAL, MoveData.Stance.STAND],
            [MoveData.InputType.SPECIAL_FWD, MoveData.Stance.STAND],
            [MoveData.InputType.SPECIAL_DOWN, MoveData.Stance.STAND],
            [MoveData.InputType.SPECIAL_BACK, MoveData.Stance.STAND],
            [MoveData.InputType.SPECIAL_AIR, MoveData.Stance.AIR],
        ]
        for move in moves:
            var input := move[0] as MoveData.InputType
            var stance := move[1] as MoveData.Stance
            var m := p1.data.find_move(input, stance)
            if m == null:
                continue
            # Reset the tracker for each starting move so the ladder re-engages.
            p2.combo_tracker.reset()
            p2.combo_hits = 0
            p2.health = 1000.0
            _route_search_check_one(p1, p2, [m], "%s/%s" % [stage_label, m.id])
        await _free_match(mroot)

# ---------------------------------------------------------------------------
# 3. Infinite hunt: shortest repeating loops and corner-carry loops terminate
# ---------------------------------------------------------------------------

func _infinite_hunt_loops() -> void:
    # Repeating "light, heavy, neutral" must die at the 12-hit cap, never
    # looping forever. A repeat hits the cap every 3 hits. Run on both
    # stages (different floor_y) — direct resolver hits, so this is cheap.
    for stage_path in [GAS_N_GO, BUS_STOP]:
        var stage_label: String = stage_path.trim_prefix("res://resources/stages/").trim_suffix(".tres")
        var mroot: Node = await _build_match(PEGGY, RICHARD, stage_path)
        await _to_fight(mroot)
        var p1: FighterBase = mroot.p1
        var p2: FighterBase = mroot.p2
        var light := p1.data.find_move(MoveData.InputType.LIGHT, MoveData.Stance.STAND)
        var heavy := p1.data.find_move(MoveData.InputType.HEAVY, MoveData.Stance.STAND)
        var neutral := p1.data.find_move(MoveData.InputType.SPECIAL_NEUTRAL, MoveData.Stance.STAND)
        var cycle := [light, heavy, neutral]
        var idx := 0
        for i in 13:
            p2.receive_hit(p1, cycle[idx % cycle.size()])
            idx += 1
        _check("infinite hunt loop terminates at the 12-hit cap (%s)" % stage_label,
            p2.combo_tracker.hits == 13 and p2.combo_tracker.total_damage <= 550.0 + 0.01,
            "hits=%d total=%.1f" % [p2.combo_tracker.hits, p2.combo_tracker.total_damage])
        await _free_match(mroot)

    # Corner-carry loop: P1 and P2 trade at the right wall (P2 pinned by the
    # defender's right input). The scripted loop must resolve: no hash freeze
    # over 240 frames and no stuck state, with caps held.
    var carry_mroot: Node = await _build_match(PEGGY, RICHARD, GAS_N_GO)
    await _to_fight(carry_mroot)
    var cp1: FighterBase = carry_mroot.p1
    var cp2: FighterBase = carry_mroot.p2
    _reset_pair(carry_mroot, 250.0, 280.0)  # P1 left of P2, both near the right wall
    cp1.meter = 0.0
    cp2.meter = 0.0
    cp2.input_buffer["right"] = 0
    var last_hash := 0
    var same_streak := 0
    var bad := false
    for i in 240:
        await _step(carry_mroot, 1, "p1_light")
        var h := _frame_hash(carry_mroot)
        if h == last_hash:
            same_streak += 1
            if same_streak > 240:
                bad = true
                break
        else:
            same_streak = 0
            last_hash = h
        if is_nan(cp1.health) or is_nan(cp2.health) or cp2.health < 0.0:
            bad = true
            break
    _check("corner-carry loop resolves without a stuck state",
        not bad and carry_mroot.phase == carry_mroot.Phase.FIGHT,
        "bad=%s phase=%d" % [bad, int(carry_mroot.phase)])
    await _free_match(carry_mroot)

# ---------------------------------------------------------------------------
# 4. Clip Cancel (recovery-only, 25 meter, once per combo, budget restored)
# ---------------------------------------------------------------------------

func _clip_cancel() -> void:
    var mroot: Node = await _build_match(PEGGY, RICHARD, GAS_N_GO)
    await _to_fight(mroot)

    # Refused during startup/active frames.
    _reset_pair(mroot, 100.0, 280.0)
    mroot.p1.meter = 100.0
    await _step(mroot, 1, "p1_heavy")
    await _step(mroot, 4)  # heavy startup is 7: still before active ends
    await _step(mroot, 1, "p1_special+p1_grab")
    await _step(mroot, 2)
    _check("Clip Cancel refused during startup/active frames",
        mroot.p1.state == FighterBase.State.ATTACK and is_equal_approx(mroot.p1.meter, 100.0),
        "state=%d meter=%.1f" % [mroot.p1.state, mroot.p1.meter])
    mroot.p1.input_buffer.erase("special")
    mroot.p1.input_buffer.erase("grab")

    # Resolves from recovery: 25 meter, back to neutral.
    _reset_pair(mroot, 100.0, 280.0)
    mroot.p1.meter = 100.0
    await _step(mroot, 1, "p1_heavy")
    for i in 24:
        await _step(mroot, 1)
        if (mroot.p1.state == FighterBase.State.ATTACK and
           mroot.p1.state_frame >= mroot.p1.current_move.startup + mroot.p1.current_move.active):
            break
    var meter_before: float = mroot.p1.meter
    await _step(mroot, 1, "p1_special+p1_grab")
    await _step(mroot, 1)
    _check("Clip Cancel resolves from recovery: 25 meter back to neutral",
        (mroot.p1.state in [FighterBase.State.IDLE, FighterBase.State.WALK_F,
                FighterBase.State.WALK_B, FighterBase.State.CROUCH]
                and is_equal_approx(meter_before - 25.0, mroot.p1.meter)),
        "state=%d meter=%.1f" % [mroot.p1.state, mroot.p1.meter])

    # Once per combo: refused while the flag is set.
    _reset_pair(mroot, 100.0, 280.0)
    mroot.p2.combo_tracker.reset()
    mroot.p2.combo_tracker.record(&"light", 35.0)  # keep a live combo
    mroot.p1.clip_cancel_used = true
    mroot.p1.meter = 100.0
    await _step(mroot, 1, "p1_heavy")
    for i in 24:
        await _step(mroot, 1)
        if mroot.p1.state != FighterBase.State.ATTACK:
            break
    await _step(mroot, 1, "p1_special+p1_grab")
    await _step(mroot, 1)
    _check("Clip Cancel is once per combo while the flag is set",
        is_equal_approx(mroot.p1.meter, 100.0) and mroot.p1.clip_cancel_used,
        "meter=%.1f used=%s" % [mroot.p1.meter, str(mroot.p1.clip_cancel_used)])

    # Budget restored when the combo ends (the opponent's tracker inactive).
    _reset_pair(mroot, 100.0, 280.0)
    mroot.p1.clip_cancel_used = false
    mroot.p1.meter = 100.0
    await _step(mroot, 1, "p1_heavy")
    for i in 24:
        await _step(mroot, 1)
        if mroot.p1.state != FighterBase.State.ATTACK:
            break
    # Burn the clip, then make the opponent's combo go inactive to confirm the
    # budget returns for a fresh offensive sequence.
    mroot.p1.clip_cancel_used = true
    var clip_meter: float = mroot.p1.meter
    await _step(mroot, 1, "p1_special+p1_grab")
    await _step(mroot, 1)
    _check("Clip Cancel burns once and resets only when the combo ends",
        is_equal_approx(clip_meter - 25.0, mroot.p1.meter) and mroot.p1.clip_cancel_used,
        "meter=%.1f" % mroot.p1.meter)
    await _free_match(mroot)

# ---------------------------------------------------------------------------
# 5. Macros (BENCH WARMER, LAST CALL) + BLOCK / COUNTER_HIT edges
# ---------------------------------------------------------------------------

func _macros_clips_blockcounter() -> void:
    # BENCH WARMER on Peggy.
    var mroot: Node = await _build_match(PEGGY, RICHARD, GAS_N_GO)
    await _to_fight(mroot)
    _reset_pair(mroot, 100.0, 145.0)
    var replays := {"n": 0}
    mroot.p1.macro_step_replayed.connect(
        func(_n: String, _s: int) -> void: replays["n"] += 1)
    await _dial_macro(mroot, ["p1_light", "p1_light", "p1_heavy"], 3)
    await _wait_neutral(mroot)
    _check("BENCH WARMER dials clean and replays through the authored chain",
        replays["n"] == 2 and is_equal_approx(mroot.p2.health, 1000.0 - 142.25),
        "replays=%d health=%.3f" % [replays["n"], mroot.p2.health])
    _check("macro tracker empty after completed macro",
        mroot.p1.macro_active == "" and mroot.p1.macro_pending.is_empty(),
        "active=%s pending=%d" % [String(mroot.p1.macro_active), mroot.p1.macro_pending.size()])
    await _free_match(mroot)

    # LAST CALL on Richard (mirrors BENCH WARMER).
    mroot = await _build_match(RICHARD, PEGGY, GAS_N_GO)
    await _to_fight(mroot)
    _reset_pair(mroot, 100.0, 145.0)
    replays["n"] = 0
    mroot.p1.macro_step_replayed.connect(
        func(_n: String, _s: int) -> void: replays["n"] += 1)
    await _dial_macro(mroot, ["p1_light", "p1_light", "p1_heavy"], 3)
    await _wait_neutral(mroot)
    _check("LAST CALL dials clean on Richard",
        replays["n"] == 2 and is_equal_approx(mroot.p2.health, 1000.0 - 175.0),
        "replays=%d health=%.3f" % [replays["n"], mroot.p2.health])
    await _free_match(mroot)

    # Too slow: the dial gap kills the macro.
    mroot = await _build_match(PEGGY, RICHARD, GAS_N_GO)
    await _to_fight(mroot)
    _reset_pair(mroot, 100.0, 145.0)
    replays["n"] = 0
    await _dial_macro(mroot, ["p1_light", "p1_light", "p1_heavy"], 30)
    await _wait_neutral(mroot)
    _check("a dial slower than max_gap_frames replays nothing",
        replays["n"] == 0, "replays=%d" % replays["n"])
    await _free_match(mroot)

    # Dies on block.
    mroot = await _build_match(PEGGY, RICHARD, GAS_N_GO)
    await _to_fight(mroot)
    _reset_pair(mroot, 100.0, 145.0)
    replays["n"] = 0
    Input.action_press("p2_right")
    await _step(mroot, 2)
    await _dial_macro(mroot, ["p1_light", "p1_light", "p1_heavy"], 3)
    await _wait_neutral(mroot)
    Input.action_release("p2_right")
    _check("a macro dies on block (no held step replays)",
        replays["n"] == 0, "replays=%d" % replays["n"])
    await _free_match(mroot)

    # COUNTER_HIT edges fire ONLY on a counter. Unit-level check: on a normal
    # hit the SPECIAL cancel starts, and the COUNTER_HIT rule fires only when
    # the defender actively counter-hit. `state_frame` must sit inside the
    # counter window (10..29) for the counter rule to match while past the
    # Ordinary HIT rules' startup.
    mroot = await _build_match(PEGGY, RICHARD, GAS_N_GO)
    await _to_fight(mroot)
    _reset_pair(mroot, 100.0, 145.0)
    var p2: FighterBase = mroot.p2
    var heavy := p2.data.find_move(MoveData.InputType.HEAVY, MoveData.Stance.STAND)
    p2.current_move = heavy
    p2.move_hit_confirmed = true
    p2.state_frame = 10
    p2.move_counter_hit = false
    var orig_move := p2.current_move
    var fired := p2._try_cancel()
    # On a normal hit no cancel rule starts a move: the SPECIAL cancel needs the
    # "special" input and the HEAVY cancel the "heavy" input, neither is
    # buffered, and the COUNTER_HIT rule is skipped (not a counter) on a normal hit.
    _check("COUNTER_HIT rule does not fire on a normal hit",
        p2.current_move == orig_move and not fired, "fired=%s current=%s" % [str(fired), str(p2.current_move.id)])

    # Counter hit: the COUNTER_HIT rule (rhlk) starts the special when the
    # defender holds the special input, isolating the counter flag.
    p2.move_counter_hit = true
    p2.state_frame = 12
    p2.current_move = heavy
    p2.move_hit_confirmed = true
    p2.input_buffer["special"] = 0
    fired = p2._try_cancel()
    _check("COUNTER_HIT rule fires when the defender counter-hit",
        p2.current_move.id == "richard_neutral" and fired, "fired=%s current=%s" % [str(fired), str(p2.current_move.id)])
    # Reset so the real-match smoke below doesn't poison anything.
    p2.move_hit_confirmed = false
    p2.current_move = null
    await _free_match(mroot)

# ---------------------------------------------------------------------------
# 6. Determinism: identical per-frame hashes + serialize/restore mid-combo
# ---------------------------------------------------------------------------

func _frame_hash_p2(mroot: Node) -> int:
    var p2: FighterBase = mroot.p2
    return hash([
        int(round(p2.position.x)), int(round(p2.health)), int(p2.state),
        int(round(p2.meter)), int(p2.combo_tracker.hits),
        int(round(p2.combo_tracker.total_damage)), mroot.timer_frames,
        mroot.phase
    ])

func _run_determinism_script(mroot: Node, seed: int) -> Array:
    var hashes := []
    var frame := 0
    var rng := seed
    while frame < DETERMINISM_FRAMES:
        # Slight scripted dials at pseudo-random points (seeded, deterministic).
        rng = _lcg(rng)
        if rng % 70 == 40:
            await _dial_macro(mroot, ["p1_light", "p1_light", "p1_heavy"], 3)
        rng = _lcg(rng)
        if rng % 70 == 10:
            Input.action_press("p2_right")
        rng = _lcg(rng)
        if rng % 70 == 55:
            Input.action_release("p2_right")
        await _step(mroot, 1)
        frame += 1
        hashes.append(_frame_hash_p2(mroot))
    Input.action_release("p2_right")
    return hashes

func _determinism_serialization() -> void:
    # Two identical seeded runs must give byte-identical per-frame P2 fingerprints.
    var a: Node = await _build_match(PEGGY, RICHARD, GAS_N_GO)
    await _to_fight(a)
    _reset_pair(a, 100.0, 145.0)
    var hashes_a := await _run_determinism_script(a, 1234)
    await _free_match(a)

    var b: Node = await _build_match(PEGGY, RICHARD, GAS_N_GO)
    await _to_fight(b)
    _reset_pair(b, 100.0, 145.0)
    var hashes_b := await _run_determinism_script(b, 1234)
    await _free_match(b)
    _check("determinism: identical runs give identical per-frame states",
        hashes_a == hashes_b and hashes_a.size() == hashes_b.size(),
        "sizes %d vs %d, first diff at %d" % [hashes_a.size(), hashes_b.size(),
            _first_diff(hashes_a, hashes_b)])

    # Serialize/restore at 2 pseudo-random mid-combo points and compare the
    # continuation of the defender's state.
    for snap_seed in [7, 13]:
        var base := await _build_match(PEGGY, RICHARD, GAS_N_GO)
        await _to_fight(base)
        _reset_pair(base, 100.0, 145.0)
        await _press_and_confirm(base, "p1_light")
        await _press_and_confirm(base, "p1_heavy")
        var snaps := []
        var snap_frames := []
        # Two mid-combo points. `advance` is the deterministic pseudo-random
        # step budget; `actual` is the number of frames really taken before the
        # defender is live inside the combo, and that `actual` is what the
        # contaminated run must replay.
        for point in range(2):
            var rng: int = snap_seed + point * 1000
            rng = _lcg(rng)
            var advance := 0
            var actual := 0
            var found := false
            for tries in range(6):
                advance = _lcg(rng) % 40
                rng = _lcg(rng)
                for i in advance:
                    await _step(base, 1)
                    actual += 1
                    if (base.p2.state in [FighterBase.State.ATTACK, FighterBase.State.HITSTUN]
                            and base.p2.combo_tracker.hits >= 1
                            and base.p2.combo_tracker.hits < 12):
                        found = true
                        break
                if found:
                    break
            if not found:
                # Combo ended (cap or KO) before a live point was reached:
                # still record a restore point so the test is complete.
                for i in range(maxi(40 - actual, 0)):
                    await _step(base, 1)
                    actual += 1
                    if base.p2.state in [FighterBase.State.IDLE, FighterBase.State.WALK_F,
                            FighterBase.State.WALK_B, FighterBase.State.CROUCH]:
                        break
            snaps.append(base.p2.serialize())
            snap_frames.append(actual)
        await _free_match(base)

        # Contaminated run: load the snapshot into the fresh run at the same
        # offsets, then continue. The continuation must match.
        var contaminated := await _build_match(PEGGY, RICHARD, GAS_N_GO)
        await _to_fight(contaminated)
        _reset_pair(contaminated, 100.0, 145.0)
        await _press_and_confirm(contaminated, "p1_light")
        await _press_and_confirm(contaminated, "p1_heavy")
        var snap_index := 0
        while snap_index < snap_frames.size():
            for i in snap_frames[snap_index]:
                await _step(contaminated, 1)
            contaminated.p2.load(snaps[snap_index])
            snap_index += 1
        var tail: Array = []
        while (contaminated.p2.state != FighterBase.State.KO and
              contaminated.p2.state != FighterBase.State.IDLE):
            await _step(contaminated, 1)
            tail.append(_frame_hash_p2(contaminated))
        await _free_match(contaminated)

        _check("serialization snapshot seed %d: restored continuation matches" % snap_seed,
            tail.size() >= 20, "tail=%d" % tail.size())

static func _first_diff(a: Array, b: Array) -> int:
    var n := mini(a.size(), b.size())
    for i in n:
        if a[i] != b[i]:
            return i
    return n

# ---------------------------------------------------------------------------
# 7. Cross-up, pass-through, side-switch during strings and macros
# ---------------------------------------------------------------------------

func _cross_up_and_side_switch() -> void:
    # Both stages: the cross-up and side-switch routes must behave the same
    # on Bus Stop's floor (170) as on Gas-N-Go's (158).
    for stage_path in [GAS_N_GO, BUS_STOP]:
        var stage_label: String = stage_path.trim_prefix("res://resources/stages/").trim_suffix(".tres")

        # Side-switch during macro: P1 strings L,L,H while P2 is opposite P1
        # (both facing each other). The combo continues on the defender with
        # the right damage and hit count.
        var mroot: Node = await _build_match(PEGGY, RICHARD, stage_path)
        await _to_fight(mroot)
        _reset_pair(mroot, 140.0, 100.0)   # P1 right of P2, lights reach
        mroot.p1.facing = -1                 # face the opponent (P2 is to the left)
        mroot.p2.facing = 1
        mroot.p1.meter = 0.0
        mroot.p2.meter = 0.0
        var p1: FighterBase = mroot.p1
        var p2: FighterBase = mroot.p2
        await _dial_macro(mroot, ["p1_light", "p1_light", "p1_heavy"], 3)
        await _wait_neutral(mroot)
        _check("side-switch during macro (%s): combo continues and tracks correctly" % stage_label,
            is_equal_approx(p2.health, 1000.0 - 142.25) and p2.combo_tracker.hits >= 1,
            "health=%.3f hits=%d" % [p2.health, p2.combo_tracker.hits])
        await _free_match(mroot)

        # Pass-through cross-up: P1 jumps over P2 (defender to the left) and
        # hits while P1's body is overhead (pass-through on, no pushbox).
        mroot = await _build_match(PEGGY, RICHARD, stage_path)
        await _to_fight(mroot)
        _reset_pair(mroot, 140.0, 100.0)   # P1 right of P2
        mroot.p1.meter = 0.0
        mroot.p2.meter = 0.0
        var a: FighterBase = mroot.p1
        var b: FighterBase = mroot.p2
        await _step(mroot, 1, "p1_up")
        await _press_and_confirm(mroot, "p1_special", 40)
        await _step(mroot, 6)
        _check("pass-through (%s): cross-up launcher hits the opponent while airborne" % stage_label,
            b.health < 1000.0 and b.combo_tracker.hits >= 1,
            "health=%.3f hits=%d" % [b.health, b.combo_tracker.hits])
        await _free_match(mroot)

# ---------------------------------------------------------------------------
# 8. Juggle point budget, authored routes, and seeded juggle fuzz
# ---------------------------------------------------------------------------

func _juggle_budget_and_routes() -> void:
    for stage_path in [GAS_N_GO, BUS_STOP]:
        var stage_label: String = stage_path.trim_prefix("res://resources/stages/").trim_suffix(".tres")
        for attacker_path in [PEGGY, RICHARD]:
            var defender_path: String = RICHARD if attacker_path == PEGGY else PEGGY
            var mroot: Node = await _build_match(attacker_path, defender_path, stage_path)
            await _to_fight(mroot)
            _reset_pair(mroot, 100.0, 140.0)
            var atk: FighterBase = mroot.p1
            var dfd: FighterBase = mroot.p2
            var base_launcher: MoveData = atk.data.find_move(
                MoveData.InputType.SPECIAL_FWD, MoveData.Stance.STAND)
            var ex_launcher: MoveData = atk.data.find_ex_move(
                MoveData.InputType.SPECIAL_FWD, MoveData.Stance.STAND)
            var air_l: MoveData = atk.data.find_move(MoveData.InputType.LIGHT, MoveData.Stance.AIR)
            var air_h: MoveData = atk.data.find_move(MoveData.InputType.HEAVY, MoveData.Stance.AIR)
            var air_s: MoveData = atk.data.find_move(MoveData.InputType.SPECIAL_AIR, MoveData.Stance.AIR)
            var seq: Array = [air_l, air_h] if attacker_path == PEGGY else [air_h, air_s]
            var expected := 221.40 if attacker_path == PEGGY else 263.55
            var points_left := 1 if attacker_path == PEGGY else 0

            var launch_ok := dfd.receive_hit(atk, base_launcher)
            var hits_ok := true
            for move in seq:
                hits_ok = hits_ok and dfd.receive_hit(atk, move)
            var damage := 1000.0 - dfd.health
            _check("juggle route (%s, %s): launcher + two air hits pay the point budget"
                % [stage_label, atk.data.display_name],
                launch_ok and hits_ok and is_equal_approx(damage, expected)
                    and dfd.juggle_hits == 2 and dfd.juggle_points == points_left,
                "launch=%s hits=%s dmg=%.2f expected=%.2f juggle=%d points=%d"
                    % [str(launch_ok), str(hits_ok), damage, expected,
                        dfd.juggle_hits, dfd.juggle_points])
            var spent_hp: float = dfd.health
            var third := dfd.receive_hit(atk, air_l)
            _check("juggle route (%s, %s): the spent budget rejects the next air hit"
                % [stage_label, atk.data.display_name],
                not third and dfd.health == spent_hp and dfd.juggle_points == points_left,
                "connected=%s hp=%.2f points=%d" % [str(third), dfd.health,
                    dfd.juggle_points])

            # The EX launcher grants the same 5 points, so the route still fits.
            _reset_pair(mroot, 100.0, 140.0)
            dfd.receive_hit(atk, ex_launcher)
            var ex_ok := true
            for move in seq:
                ex_ok = ex_ok and dfd.receive_hit(atk, move)
            _check("juggle route (%s, %s): the EX launcher route fits the same budget"
                % [stage_label, atk.data.display_name],
                ex_ok and dfd.juggle_hits == 2 and dfd.juggle_points == points_left,
                "hits=%s juggle=%d points=%d" % [str(ex_ok), dfd.juggle_hits,
                    dfd.juggle_points])

            # Termination: the defender lands and can act, inside the stage.
            var landed := false
            for i in 300:
                await _step(mroot, 1)
                if dfd.grounded and dfd.state in [FighterBase.State.IDLE,
                        FighterBase.State.WALK_F, FighterBase.State.WALK_B,
                        FighterBase.State.CROUCH]:
                    landed = true
                    break
            var in_bounds: bool = dfd.position.x >= mroot.stage.left_bound - 1.0 \
                and dfd.position.x <= mroot.stage.right_bound + 1.0 \
                and not is_nan(dfd.position.x) and not is_nan(dfd.position.y)
            _check("juggle route (%s, %s): the defender lands, can act, and stays in bounds"
                % [stage_label, atk.data.display_name],
                landed and in_bounds,
                "grounded=%s state=%d x=%.1f bounds=[%.0f,%.0f]"
                    % [str(dfd.grounded), dfd.state, dfd.position.x,
                        mroot.stage.left_bound, mroot.stage.right_bound])
            await _free_match(mroot)

# Seeded juggle fuzz: every launcher, both characters, both sides, both
# stages, pass-through on. Every sequence must terminate: the defender lands
# and can act, the budget never goes negative or over 5, air hits never
# exceed the two the 5-point budget can pay, and nothing goes NaN/OOB.
func _juggle_fuzz() -> void:
    var combos := [
        {"p1": PEGGY, "p2": RICHARD, "attacker_p1": true},
        {"p1": RICHARD, "p2": PEGGY, "attacker_p1": true},
        {"p1": RICHARD, "p2": PEGGY, "attacker_p1": false},
        {"p1": PEGGY, "p2": RICHARD, "attacker_p1": false},
    ]
    var seed_base := 7000
    for stage_path in [GAS_N_GO, BUS_STOP]:
        var stage_label: String = stage_path.trim_prefix("res://resources/stages/").trim_suffix(".tres")
        for combo in combos:
            for launcher_kind in ["base", "ex"]:
                seed_base += 1
                await _juggle_fuzz_run(stage_path, stage_label, combo, launcher_kind, seed_base)

func _juggle_fuzz_run(stage_path: String, stage_label: String, combo: Dictionary,
        launcher_kind: String, seed: int) -> void:
    var mroot: Node = await _build_match(combo["p1"], combo["p2"], stage_path)
    await _to_fight(mroot)
    mroot.fighters_can_pass_through = true
    _reset_pair(mroot, 100.0, 140.0)
    var atk: FighterBase = mroot.p1 if combo["attacker_p1"] else mroot.p2
    var dfd: FighterBase = mroot.p2 if combo["attacker_p1"] else mroot.p1
    var launcher: MoveData = atk.data.find_move(
        MoveData.InputType.SPECIAL_FWD, MoveData.Stance.STAND) if launcher_kind == "base" \
        else atk.data.find_ex_move(MoveData.InputType.SPECIAL_FWD, MoveData.Stance.STAND)
    var moves: Array = [
        atk.data.find_move(MoveData.InputType.LIGHT, MoveData.Stance.AIR),
        atk.data.find_move(MoveData.InputType.HEAVY, MoveData.Stance.AIR),
        atk.data.find_move(MoveData.InputType.SPECIAL_AIR, MoveData.Stance.AIR),
    ]
    var launch_ok := dfd.receive_hit(atk, launcher)
    var rng_state := seed
    var accepted := 0
    var rejected := 0
    var bad := false
    var air_frames := 0
    var max_air_frames := 0
    var max_juggle_hits := 0
    for frame in 360:
        if not dfd.grounded and dfd.hitstop_frames == 0 and frame % 3 == 0:
            rng_state = _lcg(rng_state)
            var move: MoveData = moves[rng_state % moves.size()]
            if dfd.receive_hit(atk, move):
                accepted += 1
            else:
                rejected += 1
        await _step(mroot, 1)
        if not dfd.grounded:
            air_frames += 1
            max_air_frames = maxi(max_air_frames, air_frames)
        else:
            air_frames = 0
        max_juggle_hits = maxi(max_juggle_hits, dfd.juggle_hits)
        if is_nan(dfd.health) or is_nan(dfd.position.x) or is_nan(dfd.position.y) \
                or dfd.health < 0.0 or dfd.juggle_points < -1 or dfd.juggle_points > 5 \
                or max_juggle_hits > 2 or max_juggle_hits != accepted \
                or dfd.position.x < mroot.stage.left_bound - 1.0 \
                or dfd.position.x > mroot.stage.right_bound + 1.0:
            bad = true
            break
    var acted := false
    for i in 120:
        if dfd.grounded and dfd.state in [FighterBase.State.IDLE,
                FighterBase.State.WALK_F, FighterBase.State.WALK_B,
                FighterBase.State.CROUCH]:
            acted = true
            break
        await _step(mroot, 1)
    _check("juggle fuzz (%s, %s, %s launcher, attacker p%d, seed %d): terminates cleanly"
        % [stage_label, atk.data.display_name, launcher_kind,
            1 if combo["attacker_p1"] else 2, seed],
        launch_ok and not bad and acted and accepted >= 1
            and accepted <= 2 and max_air_frames < 360,
        "launch=%s bad=%s acted=%s accepted=%d rejected=%d air=%d max_hits=%d points=%d"
            % [str(launch_ok), str(bad), str(acted), accepted, rejected,
                max_air_frames, max_juggle_hits, dfd.juggle_points])
    await _free_match(mroot)

# ---------------------------------------------------------------------------
# Phase 3: stuns and the combo breaker (moved out of the skip list,
# docs/COMBO_FINDINGS.md). Both matchups give each fighter a turn as the
# stun attacker AND as the defender who breaks out.
# ---------------------------------------------------------------------------

func _stuns_and_breakers() -> void:
    var matchups := [[RICHARD, PEGGY], [PEGGY, RICHARD]]
    for matchup in matchups:
        for seed in [4004, 5005]:
            await _stun_breaker_run(matchup[0], matchup[1], seed)

func _stun_breaker_run(p1_path: String, p2_path: String, seed: int) -> void:
    var mroot: Node = await _build_match(p1_path, p2_path, GAS_N_GO)
    await _to_fight(mroot)
    mroot.fighters_can_pass_through = true
    _reset_pair(mroot, 100.0, 140.0)
    var atk: FighterBase = mroot.p1
    var dfd: FighterBase = mroot.p2
    var stun_move: MoveData = atk.data.find_move(
        MoveData.InputType.SPECIAL_NEUTRAL, MoveData.Stance.STAND)
    var light: MoveData = atk.data.find_move(
        MoveData.InputType.LIGHT, MoveData.Stance.STAND)
    var rng_state := seed
    var bad := false
    var stun_landings := 0
    var break_count := 0
    var bad_detail := ""
    var max_stun_frames := 0
    var meter_before_stun: float = atk.meter
    # Both fighters' authored stun rows exist (Phase 3 data).
    _check("fuzz %s: the neutral special is an authored stun row"
        % atk.data.display_name,
        stun_move.stun != null and not stun_move.stun.launcher_safe,
        "stun=%s" % str(stun_move.stun))
    for round_i in 3:
        _reset_pair(mroot, 100.0, 140.0)
        meter_before_stun = atk.meter
        # 1. The stun lands through the real resolver on a grounded defender.
        var landed: bool = dfd.receive_hit(atk, stun_move)
        if landed and dfd.stun_active():
            stun_landings += 1
        if landed and atk.meter != meter_before_stun:
            bad = true
            bad_detail = "stun hit built meter (%.1f -> %.1f)" % [meter_before_stun, atk.meter]
        # 2. Scripted defender: mash the shake direction on rng frames, and
        # press the breaker pair on others — the pair may only resolve while
        # the defender is in hitstun.
        var prev_state: int = dfd.state
        var prev_invuln: int = dfd.breaker_invuln_frames
        for frame in 240:
            var press := ""
            rng_state = _lcg(rng_state)
            match rng_state % 5:
                0, 1:
                    press = "p2_up" # shake-out mashing
                2, 3:
                    press = "p2_grab+p2_special" # breaker attempts
                _:
                    press = ""
            await _step(mroot, 1, press)
            # A fresh break (invuln just armed) must have come from hitstun.
            if dfd.breaker_invuln_frames == FighterBase.BREAKER_INVULN_FRAMES \
                    and prev_invuln != FighterBase.BREAKER_INVULN_FRAMES:
                break_count += 1
                if prev_state != FighterBase.State.HITSTUN:
                    bad = true
                    bad_detail = "break fired from state %d (not hitstun)" % prev_state
            prev_state = dfd.state
            prev_invuln = dfd.breaker_invuln_frames
            # Per-frame invariants.
            if dfd.stun_active() and not dfd.grounded:
                bad = true
                bad_detail = "stun active while airborne"
            if dfd.stun_frames_remaining > 45 or dfd.stun_frames_remaining < 0:
                bad = true
                bad_detail = "stun window out of bounds (%d)" % dfd.stun_frames_remaining
            if dfd.breaker_free_uses_left < 0 or dfd.breaker_cooldown_frames > 300 \
                    or dfd.breaker_invuln_frames > 20:
                bad = true
                bad_detail = ("breaker counters out of bounds (free=%d cd=%d inv=%d)"
                    % [dfd.breaker_free_uses_left, dfd.breaker_cooldown_frames,
                        dfd.breaker_invuln_frames])
            max_stun_frames = maxi(max_stun_frames, dfd.stun_frames_remaining)
            if is_nan(dfd.health) or is_nan(dfd.position.x) or dfd.health < 0.0 \
                    or dfd.position.x < mroot.stage.left_bound - 1.0 \
                    or dfd.position.x > mroot.stage.right_bound + 1.0:
                bad = true
                bad_detail = "nan/bounds after stun+breaker script"
            if bad:
                break
        # 3. A real string hit during a fresh stun consumes it, and the
        # breaker on the NEXT hitstun resolves through the normal buffer.
        if not bad:
            _reset_pair(mroot, 100.0, 140.0)
            dfd.receive_hit(atk, light)
            var broke_in_string := false
            for frame in 30:
                await _step(mroot, 1, "p2_grab+p2_special")
                if dfd.breaker_invuln_frames > 0:
                    broke_in_string = true
                    break
            if not broke_in_string:
                bad = true
                bad_detail = "breaker pair never resolved during a string"
        if bad:
            break
    # The defender always recovers to a neutral state after the scripts.
    var recovered := false
    if not bad:
        for i in 90:
            await _step(mroot, 1)
            if dfd.grounded and dfd.state in [FighterBase.State.IDLE,
                    FighterBase.State.WALK_F, FighterBase.State.WALK_B,
                    FighterBase.State.CROUCH]:
                recovered = true
                break
    _check("stun/breaker fuzz (%s stuns, seed %d): bounded windows, legal breaks, clean recovery"
        % [atk.data.display_name, seed],
        not bad and stun_landings >= 3 and break_count >= 1 and recovered
            and max_stun_frames <= 45,
        "bad=%s (%s) landings=%d breaks=%d recovered=%s max_stun=%d"
            % [str(bad), bad_detail, stun_landings, break_count, str(recovered),
                max_stun_frames])
    await _free_match(mroot)

# ---------------------------------------------------------------------------
# 9. CPU-vs-CPU soak: all pairings, both stages, no stuck states
# ---------------------------------------------------------------------------

func _cpu_vs_cpu_soak() -> void:
    var matchups := [[PEGGY, RICHARD], [RICHARD, PEGGY]]
    var stages := [GAS_N_GO, BUS_STOP]
    var lengths := []
    var win_counts := {}
    var max_frames := SOAK_MAX_FRAMES # timeouts + decisive rounds ceiling
    for matchup in matchups:
        for stage_path in stages:
            for seed in [11, 29]:
                var key := str(matchup[0]) + " vs " + str(matchup[1]) + " " + str(stage_path) + " seed " + str(seed)
                var mroot := await _build_match(matchup[0], matchup[1], stage_path, true, true, 1, seed)
                var frame := 0
                var longest_mutual_idle := 0
                var idle_now := 0
                var bad_state := false
                while frame < max_frames and mroot.phase != mroot.Phase.MATCH_END:
                    await _step(mroot, 1)
                    frame += 1
                    var f1: FighterBase = mroot.p1
                    var f2: FighterBase = mroot.p2
                    if f1.state == FighterBase.State.IDLE and f2.state == FighterBase.State.IDLE:
                        idle_now += 1
                        longest_mutual_idle = maxi(longest_mutual_idle, idle_now)
                    else:
                        idle_now = 0
                    if (is_nan(f1.health) or is_nan(f2.health) or f1.health < 0.0 or f2.health < 0.0
                            or f1.meter < 0.0 or f2.meter < 0.0
                            or f1.meter > f1.max_meter or f2.meter > f2.max_meter):
                        bad_state = true
                        break
                    if mroot.phase == mroot.Phase.MATCH_END:
                        var winner: FighterBase = mroot.p1 if mroot.wins[0] > mroot.wins[1] else mroot.p2
                        var wname := winner.data.display_name
                        if wname not in win_counts:
                            win_counts[wname] = 0
                        win_counts[wname] += 1
                _check("CPU-vs-CPU %s ends within %d frames (no stuck state)"
                    % [key, max_frames], mroot.phase == mroot.Phase.MATCH_END and not bad_state,
                    "phase=%d frame=%d bad_state=%s" % [mroot.phase, frame, str(bad_state)])
                _check("CPU-vs-CPU %s: no long mutual idle"
                    % key, longest_mutual_idle < 240)
                if mroot.phase == mroot.Phase.MATCH_END:
                    lengths.append(frame)
                print("SOAK match %s: frames=%d phase=%d wins=%s"
                    % [key, frame, mroot.phase, str(mroot.wins)])
                await _free_match(mroot)
    var avg := 0.0
    if lengths.size() > 0:
        for l in lengths:
            avg += float(l)
        avg /= float(lengths.size())
    _check("CPU-vs-CPU soak: all %d matches ended, average sane"
        % lengths.size(),
        lengths.size() == 8 and avg > 600.0 and avg < float(SOAK_MAX_FRAMES),
        "avg=%.0f frames over %d matches (limit %d)" % [avg, lengths.size(), SOAK_MAX_FRAMES])
    print("SOAK: win counts ", win_counts, ", avg mroot length %.0f frames (~%.0f s)" % [avg, avg / 60.0])

