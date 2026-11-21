# Juggle economics balance probe (COMBO_SYSTEM_DESIGN Phase 2).
# Deterministic, no assertions and no resource-file changes: enumerates every
# budget-legal launcher route for both fighters through the real receive_hit
# path and prints damage / budget / length data for docs/COMBO_FINDINGS.md.
#   godot --headless --path game --script res://tests/juggle_probe.gd
#
# The probe answers "what does the point budget buy?" — it does not claim the
# routes connect through hitboxes; combo_test.gd and combo_fuzz_test.gd cover
# the real-route connectability and termination.
extends SceneTree

const PEGGY := "res://resources/fighters/peg_leg_peggy.tres"
const RICHARD := "res://resources/fighters/whiskey_richard.tres"
const GAS_N_GO := "res://resources/stages/gas_n_go.tres"

var scene: Node
var p1: FighterBase
var p2: FighterBase
var floor_y := 158.0

func _initialize() -> void:
	scene = load("res://scenes/match/MatchRoot.tscn").instantiate()
	scene.selected_p1_data = load(PEGGY)
	scene.selected_p2_data = load(RICHARD)
	scene.selected_stage = load(GAS_N_GO)
	scene.set_physics_process(false)
	root.add_child(scene)
	scene.set_physics_process(false)
	await process_frame
	await process_frame
	scene.set_physics_process(false)
	scene.p1.set_physics_process(false)
	scene.p2.set_physics_process(false)
	p1 = scene.p1
	p2 = scene.p2
	floor_y = scene.stage.floor_y
	_run()

func _run() -> void:
	print("== juggle balance probe (data economics, direct receive_hit) ==")
	_report("Peggy", p1, p2)
	_report("Richard", p2, p1)
	_candidate_ladders()
	quit(0)

# Candidate scaling ladders for the owner's retune decision (report only; the
# resource is changed in memory and restored, never written).
func _candidate_ladders() -> void:
	var tuning: ComboTuning = p1.data.combo_tuning
	var original: Array[float] = tuning.scaling_curve.duplicate()
	var candidates := [
		["keep 1.0/1.0/0.85/0.70/0.55", [1.0, 1.0, 0.85, 0.70, 0.55]],
		["A 1.0/1.0/0.80/0.65/0.50", [1.0, 1.0, 0.80, 0.65, 0.50]],
		["B 1.0/0.95/0.80/0.65/0.50", [1.0, 0.95, 0.80, 0.65, 0.50]],
		["C 1.0/1.0/0.75/0.60/0.45", [1.0, 1.0, 0.75, 0.60, 0.45]],
	]
	print("\n-- candidate ladders (max launcher route / jab-only) --")
	for c in candidates:
		tuning.scaling_curve.assign(c[1])
		var peggy := _route_stats(p1, p2, _moves(p1))
		var richard := _route_stats(p2, p1, _moves(p2))
		print("  %-28s Peggy max %.2f avg %.2f jab %.2f | Richard max %.2f avg %.2f jab %.2f"
			% [c[0], peggy["max"], peggy["avg"], peggy["jab"],
				richard["max"], richard["avg"], richard["jab"]])
	tuning.scaling_curve.assign(original)

func _route_stats(attacker: FighterBase, defender: FighterBase,
		moves: Dictionary) -> Dictionary:
	var base_launcher: MoveData = attacker.data.find_move(
		MoveData.InputType.SPECIAL_FWD, MoveData.Stance.STAND)
	var best := 0.0
	var total := 0.0
	var count := 0
	for seq in _sequences():
		if _cost(seq) > 5:
			continue
		var r := _route(attacker, defender, base_launcher, seq, moves)
		if r["rejected"] > 0:
			continue
		best = maxf(best, r["damage"])
		total += r["damage"]
		count += 1
	_reset_pair(attacker, defender)
	var light: MoveData = attacker.data.find_move(MoveData.InputType.LIGHT, MoveData.Stance.STAND)
	for i in 12:
		defender.receive_hit(attacker, light)
	return {
		"max": best,
		"avg": total / maxf(1.0, float(count)),
		"jab": 1000.0 - defender.health,
	}

func _moves(fighter: FighterBase) -> Dictionary:
	return {
		"L": fighter.data.find_move(MoveData.InputType.LIGHT, MoveData.Stance.AIR),
		"H": fighter.data.find_move(MoveData.InputType.HEAVY, MoveData.Stance.AIR),
		"S": fighter.data.find_move(MoveData.InputType.SPECIAL_AIR, MoveData.Stance.AIR),
	}

func _sequences() -> Array:
	# Every ordered route whose total point cost is <= 5 (2 per normal,
	# 3 per air special), lengths 1..3. Longer routes cannot pay.
	var out: Array = []
	var alphabet := ["L", "H", "S"]
	for a in alphabet:
		out.append([a])
	for a in alphabet:
		for b in alphabet:
			out.append([a, b])
	for a in alphabet:
		for b in alphabet:
			for c in alphabet:
				out.append([a, b, c])
	return out

func _cost(seq: Array) -> int:
	var total := 0
	for s in seq:
		total += 3 if s == "S" else 2
	return total

func _reset_pair(attacker: FighterBase, defender: FighterBase) -> void:
	attacker.reset_state()
	defender.reset_state()
	attacker.position = Vector2(100.0, floor_y)
	defender.position = Vector2(140.0, floor_y)
	attacker.facing = 1
	defender.facing = -1
	attacker.health = 1000.0
	defender.health = 1000.0
	attacker.meter = 0.0
	defender.meter = 0.0

func _route(attacker: FighterBase, defender: FighterBase, launcher: MoveData,
		seq: Array, moves: Dictionary) -> Dictionary:
	_reset_pair(attacker, defender)
	var launch_ok := defender.receive_hit(attacker, launcher)
	var launch_damage := 1000.0 - defender.health
	var hit_damages: Array[float] = []
	var rejected := 0
	for key in seq:
		var before := defender.health
		if defender.receive_hit(attacker, moves[key]):
			hit_damages.append(before - defender.health)
		else:
			rejected += 1
	return {
		"launch_ok": launch_ok,
		"damage": 1000.0 - defender.health,
		"launch_damage": launch_damage,
		"air_damage": hit_damages,
		"air_hits": hit_damages.size(),
		"rejected": rejected,
		"points": defender.juggle_points,
		"juggle_hits": defender.juggle_hits,
	}

func _report(label: String, attacker: FighterBase, defender: FighterBase) -> void:
	var moves := _moves(attacker)
	var base_launcher: MoveData = attacker.data.find_move(
		MoveData.InputType.SPECIAL_FWD, MoveData.Stance.STAND)
	var ex_launcher: MoveData = attacker.data.find_ex_move(
		MoveData.InputType.SPECIAL_FWD, MoveData.Stance.STAND)
	print("\n-- %s (air L=%.0f H=%.0f S=%.0f; base launch=%.0f y=%.0f, EX launch=%.0f y=%.0f) --"
		% [label, moves["L"].damage, moves["H"].damage, moves["S"].damage,
			base_launcher.damage, base_launcher.knockback.y,
			ex_launcher.damage, ex_launcher.knockback.y])
	for launcher in [base_launcher, ex_launcher]:
		var rows: Array = []
		var total_damage := 0.0
		var count := 0
		var best: Dictionary = {}
		for seq in _sequences():
			if _cost(seq) > 5:
				continue
			var r := _route(attacker, defender, launcher, seq, moves)
			if r["rejected"] > 0:
				continue
			r["seq"] = "".join(PackedStringArray(seq))
			rows.append(r)
			total_damage += r["damage"]
			count += 1
			if best.is_empty() or r["damage"] > best["damage"]:
				best = r
		rows.sort_custom(func(a, b): return a["damage"] > b["damage"])
		print("  launcher %s: %d legal routes, avg %.2f, max %.2f (%s), "
			% [launcher.id, count, total_damage / maxf(1.0, float(count)),
				best["damage"], best["seq"]])
		for r in rows:
			print("    %-3s air_hits=%d dmg=%.2f (launch %.1f + air %s) points_left=%d"
				% [r["seq"], r["air_hits"], r["damage"], r["launch_damage"],
					str(r["air_damage"]), r["points"]])
	# Best jab-only route: repeat the light up to the 12-hit cap.
	_reset_pair(attacker, defender)
	var light: MoveData = attacker.data.find_move(MoveData.InputType.LIGHT, MoveData.Stance.STAND)
	for i in 12:
		defender.receive_hit(attacker, light)
	print("  jab-only (12 lights): %.2f damage" % (1000.0 - defender.health))
	# Legacy L,L,H string as a grounded reference.
	_reset_pair(attacker, defender)
	var heavy: MoveData = attacker.data.find_move(MoveData.InputType.HEAVY, MoveData.Stance.STAND)
	defender.receive_hit(attacker, light)
	defender.receive_hit(attacker, light)
	defender.receive_hit(attacker, heavy)
	print("  grounded L,L,H reference: %.2f damage" % (1000.0 - defender.health))
