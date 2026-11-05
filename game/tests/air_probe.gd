# Air-special balance probe — docs/PROPOSALS.md section 3.
# Coarse deterministic sample, no assertions and no resource-file changes.
# Geometry candidates are recorded separately from contacts resolved by MatchRoot.
#   godot --headless --path game --script res://tests/air_probe.gd
extends SceneTree

const DISTANCES := [0, 20, 40, 60, 80]
const TRADE_DISTANCES := [40, 60, 80]
const TRADE_START_OFFSETS := [3, 9, 15]
const START_FRAMES := [1, 6, 11, 16, 21, 26, 31, 36]
const BLOCK_DIST := 40.0
const MAX_AIR_FRAMES := 90
# Keep both fighters inside this stage's [24, 296] x bounds: at start_x=110,
# a nominal 260px gap is silently clamped to only 186px before the probe runs.
const WHIFF_DIST := 170.0

var scene: Node2D
var attacker: FighterBase
var defender: FighterBase
var floor_y := 150.0
var start_x := 110.0

func _initialize() -> void:
	scene = load("res://scenes/match/MatchRoot.tscn").instantiate()
	root.add_child(scene)
	_boot.call_deferred()

func _boot() -> void:
	floor_y = scene.stage.floor_y
	start_x = scene.stage.spawn_p1_x
	# Keep the fighters' own state machines active while disabling MatchRoot's
	# timer/round transitions. The probe calls the real two-sided resolver itself.
	scene.set("phase", 4)
	scene.p1.input_enabled = false
	scene.p2.input_enabled = false
	await _run()
	quit(0)

# ---------------- harness ----------------
func _step() -> void:
	await physics_frame

func _reset_pair(dist: float) -> void:
	attacker.position = Vector2(start_x, floor_y)
	attacker.velocity = Vector2.ZERO
	attacker.facing = 1
	attacker.health = attacker.max_health
	attacker.reset_state()
	attacker.move_hit_confirmed = false
	attacker.move_already_hit = false
	attacker.input_enabled = false

	defender.position = Vector2(start_x + dist, floor_y)
	defender.velocity = Vector2.ZERO
	defender.facing = -1
	defender.health = defender.max_health
	defender.reset_state()
	defender.move_hit_confirmed = false
	defender.move_already_hit = false
	defender.input_enabled = false

func _launch() -> void:
	attacker.velocity = Vector2(0.0, -attacker.jump_speed)
	attacker.grounded = false
	attacker._force_state(FighterBase.State.JUMP_START)

func _actionable(f: FighterBase) -> bool:
	return f.state in [FighterBase.State.IDLE, FighterBase.State.WALK_F, FighterBase.State.WALK_B]

func _measure_airtime(f: FighterBase) -> int:
	attacker = f
	defender = scene.p2 if f == scene.p1 else scene.p1
	_reset_pair(120.0)
	_launch()
	var frames := 0
	while not attacker.grounded and frames < MAX_AIR_FRAMES:
		await _step()
		frames += 1
	return frames

# A geometry candidate is a sampled active hitbox/hurtbox overlap before the
# resolver runs. A resolved connection is reported only if MatchRoot's real
# _resolve_hits() marks the move as connected. This includes hit/block rules,
# invulnerability, previous-hit suppression, and interruption from earlier hits.
func _measure(move: MoveData, start_frame: int, dist: float) -> Dictionary:
	_reset_pair(dist)
	_launch()
	var geometry_contact := -1
	var resolved_contact := -1
	var resolved_kind := "none"
	var resolved_damage := 0.0
	var contact_hitstop := 0
	var last_active := -1
	var elapsed := -1
	var landing_frame := -1
	for f in MAX_AIR_FRAMES:
		if f == start_frame:
			attacker._start_move(move)
		await _step()
		elapsed = f
		var hb := attacker.get_hitbox_rect()
		if hb.size != Vector2.ZERO and not attacker.move_already_hit:
			last_active = f
			if geometry_contact < 0 and hb.intersects(defender.hurtbox_rect()):
				geometry_contact = f
		var defender_hp_before := defender.health
		scene._resolve_hits()
		if resolved_contact < 0 and attacker.move_already_hit:
			resolved_contact = f
			resolved_damage = defender_hp_before - defender.health
			resolved_kind = "block" if defender.state == FighterBase.State.BLOCKSTUN else "hit"
			contact_hitstop = maxi(attacker.hitstop_frames, defender.hitstop_frames)
		if attacker.grounded:
			landing_frame = f
			break
	var actionable_frame := -1
	while not _actionable(attacker) and elapsed < MAX_AIR_FRAMES + 60:
		await _step()
		elapsed += 1
		scene._resolve_hits()
	if _actionable(attacker):
		actionable_frame = elapsed
	var whiff_window := -1
	if resolved_contact < 0 and last_active >= 0 and actionable_frame >= 0:
		whiff_window = actionable_frame - last_active
	return {
		"geometry_contact": geometry_contact,
		"resolved_contact": resolved_contact,
		"resolved_kind": resolved_kind,
		"resolved_damage": resolved_damage,
		"contact_hitstop": contact_hitstop,
		"land": landing_frame,
		"last_active": last_active,
		"actionable": actionable_frame,
		"whiff_window": whiff_window,
	}

# Resolve a real block via MatchRoot. The defender is held at the sample spacing
# while the normal fighter state machine consumes shared hitstop and blockstun.
func _measure_block(move: MoveData, start_frame: int, dist: float) -> Dictionary:
	_reset_pair(dist)
	defender.input_enabled = true
	var block_action := "p%d_right" % defender.player_index # facing left: right is away
	Input.action_press(block_action)
	_launch()
	var geometry_contact := -1
	var contact := -1
	var contact_hitstop := 0
	var resolved_damage := 0.0
	var attacker_actionable := -1
	var defender_actionable := -1
	var blocked := false
	var elapsed := -1
	for f in MAX_AIR_FRAMES:
		defender.position = Vector2(start_x + dist, floor_y)
		defender.velocity = Vector2.ZERO
		if f == start_frame:
			attacker._start_move(move)
		await _step()
		elapsed = f
		var hb := attacker.get_hitbox_rect()
		if hb.size != Vector2.ZERO and geometry_contact < 0 \
				and hb.intersects(defender.hurtbox_rect()):
			geometry_contact = f
		var defender_hp_before := defender.health
		scene._resolve_hits()
		if contact < 0 and attacker.move_already_hit:
			contact = f
			blocked = defender.state == FighterBase.State.BLOCKSTUN
			contact_hitstop = maxi(attacker.hitstop_frames, defender.hitstop_frames)
			resolved_damage = defender_hp_before - defender.health
			break
		if attacker.grounded:
			break
	if blocked:
		var t := 0
		while t < 90 and (attacker_actionable < 0 or defender_actionable < 0):
			defender.position = Vector2(start_x + dist, floor_y)
			defender.velocity = Vector2.ZERO
			await _step()
			scene._resolve_hits()
			t += 1
			if attacker_actionable < 0 and _actionable(attacker):
				attacker_actionable = t
			if defender_actionable < 0 and _actionable(defender):
				defender_actionable = t
	Input.action_release(block_action)
	return {
		"geometry_contact": geometry_contact,
		"contact": contact,
		"blocked": blocked,
		"hitstop": contact_hitstop,
		"damage": resolved_damage,
		"attacker": attacker_actionable,
		"defender": defender_actionable,
	}

# Record geometric candidate frames and actual move connections separately.
# Both moves are polled together by _resolve_hits(), preserving true same-frame
# trades and interrupting later attacks after a hit.
func _measure_trade(air_move: MoveData, start_frame: int, dist: float, def_move: MoveData) -> Dictionary:
	_reset_pair(dist)
	_launch()
	var geometry_air := -1
	var geometry_anti := -1
	var resolved_air := -1
	var resolved_anti := -1
	for f in MAX_AIR_FRAMES:
		if f == 0:
			defender._start_move(def_move)
		if f == start_frame:
			attacker._start_move(air_move)
		await _step()
		var ahb := attacker.get_hitbox_rect()
		var dhb := defender.get_hitbox_rect()
		if geometry_air < 0 and ahb.size != Vector2.ZERO and ahb.intersects(defender.hurtbox_rect()):
			geometry_air = f
		if geometry_anti < 0 and dhb.size != Vector2.ZERO and dhb.intersects(attacker.hurtbox_rect()):
			geometry_anti = f
		scene._resolve_hits()
		if resolved_air < 0 and attacker.move_already_hit:
			resolved_air = f
		if resolved_anti < 0 and defender.move_already_hit:
			resolved_anti = f
		if (resolved_air >= 0 and resolved_anti >= 0) or attacker.grounded:
			break
	return {
		"geometry_air": geometry_air,
		"geometry_anti": geometry_anti,
		"attacker": resolved_air,
		"defender": resolved_anti,
	}

func _verdict(r: Dictionary, air_key := "attacker", anti_key := "defender") -> String:
	var a: int = r[air_key]
	var d: int = r[anti_key]
	if a >= 0 and d >= 0:
		if a < d:
			return "air"
		if d < a:
			return "anti"
		return "trade"
	if a >= 0:
		return "air"
	if d >= 0:
		return "anti"
	return "none"

func _stat(values: Array) -> String:
	if values.is_empty():
		return "n/a"
	var sorted := values.duplicate()
	sorted.sort()
	var middle := sorted.size() / 2
	var median: float
	if sorted.size() % 2 == 0:
		median = (float(sorted[middle - 1]) + float(sorted[middle])) / 2.0
	else:
		median = float(sorted[middle])
	return "%s/%.1f/%s" % [str(sorted[0]), median, str(sorted[-1])]

# ---------------- report ----------------
func _run() -> void:
	var pairs := [[scene.p1, scene.p2], [scene.p2, scene.p1]]
	for pair in pairs:
		attacker = pair[0] as FighterBase
		defender = pair[1] as FighterBase
		await _report_pair()
	print("\nProbe complete: coarse samples; overlap candidates and resolver-confirmed results are separate.")
	print("(values are finite samples from current code/data; targets in §3 are project hypotheses, not validated rules)")

func _report_pair() -> void:
	var light: MoveData = attacker.data.find_move(MoveData.InputType.LIGHT, MoveData.Stance.AIR)
	var heavy: MoveData = attacker.data.find_move(MoveData.InputType.HEAVY, MoveData.Stance.AIR)
	var special: MoveData = attacker.data.find_move(MoveData.InputType.SPECIAL_AIR, MoveData.Stance.AIR)
	var moves: Array[MoveData] = [light, heavy, special]
	var names := ["jump_light", "jump_heavy", "air_special"]
	var airtime := await _measure_airtime(attacker)
	var move_start_frames: Array[int] = []
	for start_frame in START_FRAMES:
		if start_frame < airtime:
			move_start_frames.append(start_frame)
	var anti_heavy: MoveData = defender.data.find_move(MoveData.InputType.HEAVY, MoveData.Stance.CROUCH)
	var anti_special: MoveData = defender.data.find_move(MoveData.InputType.SPECIAL_NEUTRAL, MoveData.Stance.STAND)

	print("\n=== AIR SPECIAL PROBE: %s attacking %s ===" % [attacker.data.display_name, defender.data.display_name])
	print("jump %.0f px/s, gravity %.0f px/s^2; sampled airtime %d frames (apex ~%d)" % [
		attacker.jump_speed, attacker.gravity, airtime, airtime / 2])
	print("sample grid: distances %s; airborne start frames %s (%d samples; not exhaustive)" % [
		str(DISTANCES), str(move_start_frames), move_start_frames.size()])

	# --- reach: candidate overlaps vs actual resolver connections ---
	print("-- REACH at sampled distance: geometry candidates / resolved contacts --")
	print("%-12s %s" % ["move", " ".join(DISTANCES.map(func(d): return "d=%-4d" % d))])
	var reach_counts: Dictionary = {}
	for i in moves.size():
		var cells: Array[String] = []
		var move_counts: Array = []
		var move_hitstop_samples: Array[int] = []
		var move_damage_samples: Array[int] = []
		for d in DISTANCES:
			var geometry_count := 0
			var resolved_count := 0
			var hitstop_samples: Array[int] = []
			for sf in move_start_frames:
				var r := await _measure(moves[i], sf, float(d))
				if r.geometry_contact >= 0:
					geometry_count += 1
				if r.resolved_contact >= 0:
					resolved_count += 1
					hitstop_samples.append(r.contact_hitstop)
					move_hitstop_samples.append(r.contact_hitstop)
					move_damage_samples.append(int(round(r.resolved_damage)))
			move_counts.append({"geometry": geometry_count, "resolved": resolved_count,
				"hitstop": _stat(hitstop_samples)})
			cells.append("%d/%d : %d/%d" % [geometry_count, move_start_frames.size(),
				resolved_count, move_start_frames.size()])
		reach_counts[names[i]] = move_counts
		print("%-12s %s" % [names[i], " ".join(cells)])
		print("  resolved hit damage min/median/max=%s; shared hitstop frames=%s" % [
			_stat(move_damage_samples), _stat(move_hitstop_samples)])

	# --- direct authored damage comparisons (not combo damage or air-to-anti results) ---
	print("-- NOMINAL DIRECT DAMAGE RATIOS (unscaled; follow-ups not simulated) --")
	print("move         damage  vs jump-heavy  vs %s crouch-heavy  vs %s neutral-special" % [
		defender.data.display_name, defender.data.display_name])
	for i in moves.size():
		print("%-12s %6.1f  %13.3f  %20.3f  %24.3f" % [
			names[i], moves[i].damage, moves[i].damage / heavy.damage,
			moves[i].damage / anti_heavy.damage, moves[i].damage / anti_special.damage])
	var special_reach: Array = reach_counts["air_special"]
	var heavy_reach: Array = reach_counts["jump_heavy"]
	var envelope_parts: Array[String] = []
	for i in DISTANCES.size():
		envelope_parts.append("d=%d geom %d/%d resolved %d/%d; heavy %d/%d" % [
			DISTANCES[i], special_reach[i].geometry, move_start_frames.size(),
			special_reach[i].resolved, move_start_frames.size(), heavy_reach[i].resolved,
			move_start_frames.size()])
	print("air-special vs jump-heavy reach by distance: %s" % "; ".join(envelope_parts))
	print("air-special vs anti-air damage ratios: crouch-heavy %.3f; neutral-special %.3f" % [
		special.damage / anti_heavy.damage, special.damage / anti_special.damage])

	# --- first-to-hit chart: geometric overlaps and actual outcomes ---
	print("-- TRADE SAMPLE at distances %s, air start offsets %s --" % [
		str(TRADE_DISTANCES), str(TRADE_START_OFFSETS)])
	print("dist move         vs                 geometry air/anti/trade/none | resolved air/anti/trade/none")
	var defs: Array = [["crouch_heavy", anti_heavy], ["neutral_special", anti_special]]
	for d in TRADE_DISTANCES:
		for i in moves.size():
			for dm in defs:
				var geometry := {"air": 0, "anti": 0, "trade": 0, "none": 0}
				var resolved := {"air": 0, "anti": 0, "trade": 0, "none": 0}
				for sf in TRADE_START_OFFSETS:
					var r := await _measure_trade(moves[i], sf, float(d), dm[1])
					geometry[_verdict(r, "geometry_air", "geometry_anti")] += 1
					resolved[_verdict(r)] += 1
				print("%d %-12s %-18s %d/%d/%d/%d | %d/%d/%d/%d" % [d, names[i], dm[0],
					geometry.air, geometry.anti, geometry.trade, geometry.none,
					resolved.air, resolved.anti, resolved.trade, resolved.none])

	# --- blocked advantage: actual block, hitstop and both state machines ---
	print("-- ACTUAL BLOCK: d=%d; advantage = defender-actionable minus attacker-actionable" % int(BLOCK_DIST))
	print("move         advantage min/median/max   hitstop min/median/max   blocked samples")
	for i in moves.size():
		var advantages: Array[int] = []
		var hitstops: Array[int] = []
		var chip_samples: Array[int] = []
		var geometry_samples := 0
		var block_samples := 0
		for sf in move_start_frames:
			var r := await _measure_block(moves[i], sf, BLOCK_DIST)
			if r.geometry_contact >= 0:
				geometry_samples += 1
			if r.blocked and r.attacker >= 0 and r.defender >= 0:
				block_samples += 1
				advantages.append(r.defender - r.attacker)
				hitstops.append(r.hitstop)
				chip_samples.append(int(round(r.damage)))
		print("%-12s %-25s hitstop %-10s chip %-10s geometry %d/%d; resolved blocks %d/%d" % [
			names[i], _stat(advantages), _stat(hitstops), _stat(chip_samples), geometry_samples,
			move_start_frames.size(), block_samples, move_start_frames.size()])

	# --- whiff: actual actionability of the attacker-side state machine ---
	print("-- WHIFF d=%d: frames from last active frame to first actionable frame --" % int(WHIFF_DIST))
	print("move         min/median/max    measured samples")
	for i in moves.size():
		var values: Array[int] = []
		for sf in move_start_frames:
			var r := await _measure(moves[i], sf, WHIFF_DIST)
			if r.resolved_contact < 0 and r.whiff_window >= 0:
				values.append(r.whiff_window)
		print("%-12s %-16s %d/%d" % [names[i], _stat(values), values.size(),
			move_start_frames.size()])
