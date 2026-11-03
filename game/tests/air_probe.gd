# Air-special balance probe — docs/PROPOSALS.md section 3.
# Prints metrics for the committed fighter data against the real hitbox/hurtbox
# code. Asserts nothing, changes no data, always exits 0.
#   godot --headless --path game --script res://tests/air_probe.gd
extends SceneTree

const DISTANCES := [0, 20, 40, 60, 80]
const TRADE_DISTANCES := [40, 60, 80]
const TRADE_START_OFFSETS := [3, 9, 15]
const BLOCK_DIST := 40.0
const START_STEP := 5
const START_MAX := 39
const MAX_AIR_FRAMES := 90
const WHIFF_DIST := 260.0

var scene: Node2D
var p1: FighterBase
var p2: FighterBase
var floor_y := 150.0
var p1_x := 110.0

func _initialize() -> void:
	scene = load("res://scenes/match/MatchRoot.tscn").instantiate()
	root.add_child(scene)
	_boot.call_deferred()

func _boot() -> void:
	p1 = scene.p1
	p2 = scene.p2
	floor_y = scene.stage.floor_y
	p1_x = scene.stage.spawn_p1_x
	# MATCH_END keeps the orchestrator (hit detection, timer, rounds) out of the
	# measurement while both fighters keep simulating their own state machines.
	scene.set("phase", 4)
	p1.input_enabled = false
	p2.input_enabled = false
	await _run()
	quit(0)

# ---------------- harness ----------------
func _step() -> void:
	await physics_frame

func _reset_pair(dist: float) -> void:
	p1.position = Vector2(p1_x, floor_y)
	p1.velocity = Vector2.ZERO
	p1.facing = 1
	p1.health = p1.max_health
	p1.reset_state()
	p1.input_enabled = false

	p2.position = Vector2(p1_x + dist, floor_y)
	p2.velocity = Vector2.ZERO
	p2.facing = -1
	p2.health = p2.max_health
	p2.reset_state()
	p2.input_enabled = false

func _launch() -> void:
	p1.velocity = Vector2(0.0, -p1.jump_speed)
	p1.grounded = false
	p1._force_state(FighterBase.State.JUMP_START)

func _actionable(f: FighterBase) -> bool:
	return f.state in [FighterBase.State.IDLE, FighterBase.State.WALK_F, FighterBase.State.WALK_B]

func _measure_airtime() -> int:
	_reset_pair(120.0)
	_launch()
	var frames := 0
	while not p1.grounded and frames < MAX_AIR_FRAMES:
		await _step()
		frames += 1
	return frames

# Does `move` connect at this spacing if started on `start_frame` of the jump?
func _measure(move: MoveData, start_frame: int, dist: float) -> Dictionary:
	_reset_pair(dist)
	_launch()
	var contact := -1
	var land := -1
	var last_active := -1
	for f in MAX_AIR_FRAMES:
		if f == start_frame:
			p1._start_move(move)
		await _step()
		var hb := p1.get_hitbox_rect()
		if hb.size != Vector2.ZERO:
			last_active = f
			if contact < 0 and hb.intersects(p2.hurtbox_rect()):
				contact = f
		if p1.grounded:
			land = f
			break
	var post := 0
	while not _actionable(p1) and post < 60:
		await _step()
		post += 1
	var whiff := post + maxi(0, land - last_active)
	return {"contact": contact, "land": land, "last_active": last_active, "whiff": whiff}

# Blocked hit: how long until each fighter is actionable again, from contact.
func _measure_block(move: MoveData, start_frame: int, dist: float) -> Dictionary:
	_reset_pair(dist)
	p2.input_enabled = true
	Input.action_press("p2_right") # p2 faces left, right is away = block
	_launch()
	var contact := -1
	var attacker := -1
	var defender := -1
	for f in MAX_AIR_FRAMES:
		# Blocking walks the defender away; pin it so spacing is measured, not drifted.
		p2.position = Vector2(p1_x + dist, floor_y)
		p2.velocity = Vector2.ZERO
		if f == start_frame:
			p1._start_move(move)
		await _step()
		var hb := p1.get_hitbox_rect()
		if contact < 0 and hb.size != Vector2.ZERO and hb.intersects(p2.hurtbox_rect()):
			contact = f
			if p2.receive_hit(p1, move):
				break # got through (not blocked); no advantage to measure
			var t := 0
			while t < 60 and (attacker < 0 or defender < 0):
				p2.position = Vector2(p1_x + dist, floor_y)
				p2.velocity = Vector2.ZERO
				await _step()
				t += 1
				if attacker < 0 and _actionable(p1):
					attacker = t
				if defender < 0 and p2.state != FighterBase.State.BLOCKSTUN:
					defender = t
			break
		if p1.grounded:
			break
	Input.action_release("p2_right")
	return {"contact": contact, "attacker": attacker, "defender": defender}

# First-to-hit between an air move and a defender's anti-air.
func _measure_trade(air: MoveData, start_frame: int, dist: float, def_move: MoveData) -> Dictionary:
	_reset_pair(dist)
	_launch()
	var atk := -1
	var dfd := -1
	for f in MAX_AIR_FRAMES:
		if f == 0:
			p2._start_move(def_move)
		if f == start_frame:
			p1._start_move(air)
		await _step()
		var ahb := p1.get_hitbox_rect()
		if atk < 0 and ahb.size != Vector2.ZERO and ahb.intersects(p2.hurtbox_rect()):
			atk = f
		var dhb := p2.get_hitbox_rect()
		if dfd < 0 and dhb.size != Vector2.ZERO and dhb.intersects(p1.hurtbox_rect()):
			dfd = f
		if p1.grounded:
			break
	return {"attacker": atk, "defender": dfd}

func _verdict(r: Dictionary) -> String:
	var a: int = r.attacker
	var d: int = r.defender
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
	var mid: int = sorted[sorted.size() / 2]
	return "%d/%d/%d" % [sorted[0], mid, sorted[-1]]

# ---------------- report ----------------
func _run() -> void:
	var light: MoveData = p1.data.find_move(MoveData.InputType.LIGHT, MoveData.Stance.AIR)
	var heavy: MoveData = p1.data.find_move(MoveData.InputType.HEAVY, MoveData.Stance.AIR)
	var special: MoveData = p1.data.find_move(MoveData.InputType.SPECIAL_AIR, MoveData.Stance.AIR)
	var moves: Array[MoveData] = [light, heavy, special]
	var names := ["jump_light", "jump_heavy", "air_special"]

	var airtime := await _measure_airtime()
	print("=== AIR SPECIAL BALANCE PROBE ===")
	print("attacker: %s (jump %.0f px/s, gravity %.0f px/s^2)" % [
		p1.data.display_name, p1.jump_speed, p1.gravity])
	print("defender: %s" % p2.data.display_name)
	print("air time: %d frames (apex ~%d)" % [airtime, airtime / 2])

	# --- 1. reach envelope ---
	print("\n-- 1. REACH ENVELOPE (connecting start frames per distance) --")
	print("%-12s %s" % ["move", " ".join(DISTANCES.map(func(d): return "d=%-4d" % d))])
	var reach: Dictionary = {}
	for i in moves.size():
		var cells: Array[String] = []
		var per_dist: Array = []
		for d in DISTANCES:
			var connecting: Array[int] = []
			for sf in range(1, START_MAX + 1, START_STEP):
				var r := await _measure(moves[i], sf, float(d))
				if r.contact >= 0:
					connecting.append(sf)
			per_dist.append(connecting)
			cells.append("%-7s" % ("%d/%d" % [connecting.size(), range(1, START_MAX + 1, START_STEP).size()]))
		reach[names[i]] = per_dist
		print("%-12s %s" % [names[i], " ".join(cells)])

	# --- 2. damage per arc ---
	print("\n-- 2. DAMAGE PER ARC (jump-in damage vs this fighter's jump heavy) --")
	print("%-12s %8s %8s %10s" % ["move", "damage", "startup", "vs heavy"])
	for i in moves.size():
		print("%-12s %8.1f %8d %10.3f" % [
			names[i], moves[i].damage, moves[i].startup, moves[i].damage / heavy.damage])

	# --- 3. trade matrix ---
	print("\n-- 3. FIRST-TO-HIT TRADE MATRIX (air move vs defender anti-air) --")
	print("   air/anti/trade/none counts over start offsets %s" % str(TRADE_START_OFFSETS))
	var defs: Array = [
		["crouch_heavy", p2.data.find_move(MoveData.InputType.HEAVY, MoveData.Stance.CROUCH)],
		["neutral_special", p2.data.find_move(MoveData.InputType.SPECIAL_NEUTRAL, MoveData.Stance.STAND)],
	]
	print("%-8s %-12s %-18s %s" % ["dist", "air move", "vs", "air/anti/trade/none"])
	for d in TRADE_DISTANCES:
		for i in moves.size():
			for dm in defs:
				var tally := {"air": 0, "anti": 0, "trade": 0, "none": 0}
				for sf in TRADE_START_OFFSETS:
					var r := await _measure_trade(moves[i], sf, float(d), dm[1])
					tally[_verdict(r)] += 1
				print("%-8d %-12s %-18s %d/%d/%d/%d" % [d, names[i], dm[0],
					tally["air"], tally["anti"], tally["trade"], tally["none"]])

	# --- 4. blocked advantage ---
	print("\n-- 4. BLOCKED ADVANTAGE at d=%d (defender blockstun minus attacker recovery) --" % int(BLOCK_DIST))
	print("%-12s %10s   (+ = attacker recovers first)" % ["move", "frames"])
	for i in moves.size():
		var values: Array = []
		for sf in range(3, START_MAX + 1, 9):
			var r := await _measure_block(moves[i], sf, BLOCK_DIST)
			if r.contact >= 0 and r.attacker >= 0 and r.defender >= 0:
				values.append(r.defender - r.attacker)
		print("%-12s %10s" % [names[i], _stat(values)])

	# --- 5. whiff-punish window ---
	print("\n-- 5. WHIFF-PUNISH WINDOW at d=%d (frames from last active frame to actionable) --" % int(WHIFF_DIST))
	print("%-12s %14s" % ["move", "min/median/max"])
	for i in moves.size():
		var values: Array = []
		for sf in range(1, START_MAX + 1, START_STEP):
			var r := await _measure(moves[i], sf, WHIFF_DIST)
			if r.contact < 0 and r.last_active >= 0:
				values.append(r.whiff)
		print("%-12s %14s" % [names[i], _stat(values)])

	print("\n(all numbers measured on the committed data; no assertions, no tuning)")
