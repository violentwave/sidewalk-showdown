# One-shot data generator: builds FighterData resources via ResourceSaver so the
# .tres format is always engine-canonical. Re-run after tuning the tables below.
# Authors the base moves, the EX variants (PROPOSALS §5) and each fighter's
# METHtality finisher (PROPOSALS §4); re-running regenerates all of them.
extends SceneTree

const LIGHT := MoveData.InputType.LIGHT
const HEAVY := MoveData.InputType.HEAVY
const SP_NEUTRAL := MoveData.InputType.SPECIAL_NEUTRAL
const SP_FWD := MoveData.InputType.SPECIAL_FWD
const SP_DOWN := MoveData.InputType.SPECIAL_DOWN
const SP_BACK := MoveData.InputType.SPECIAL_BACK
const SP_AIR := MoveData.InputType.SPECIAL_AIR
const GRAB := MoveData.InputType.GRAB

const STAND := MoveData.Stance.STAND
const CROUCH := MoveData.Stance.CROUCH
const AIR := MoveData.Stance.AIR

const MID := MoveData.Level.MID
const LOW := MoveData.Level.LOW
const OVERHEAD := MoveData.Level.OVERHEAD
const THROW := MoveData.Level.THROW


func _init() -> void:
	_save(_peggy(), "peg_leg_peggy")
	_save(_richard(), "whiskey_richard")
	print("fighter resources saved")
	quit()


func _save(fighter: FighterData, file_name: String) -> void:
	var path := "res://resources/fighters/%s.tres" % file_name
	var err := ResourceSaver.save(fighter, path)
	if err != OK:
		push_error("failed to save %s: %d" % [path, err])


func _m(id: String, input: MoveData.InputType, stance: MoveData.Stance, level: MoveData.Level,
		startup: int, active: int, recovery: int, damage: float, block_damage: float,
		hitstun: int, blockstun: int, kb_x: float, knockdown: bool,
		hb_off: Vector2, hb_size: Vector2, hitstop: int, landing_recovery: int = 0) -> MoveData:
	var m := MoveData.new()
	m.id = id
	m.input = input
	m.stance = stance
	m.level = level
	m.startup = startup
	m.active = active
	m.recovery = recovery
	m.damage = damage
	m.block_damage = block_damage
	m.hitstun = hitstun
	m.blockstun = blockstun
	m.knockback = Vector2(kb_x, 0)
	m.knockdown = knockdown
	m.hitbox_offset = hb_off
	m.hitbox_size = hb_size
	m.hitstop = hitstop
	m.landing_recovery = landing_recovery
	return m


# Tags a row as an EX variant: it costs meter and is only reachable through the
# special+heavy input (PROPOSALS §5).
func _ex(m: MoveData) -> MoveData:
	m.meter_cost = 50.0
	m.ex = true
	return m


# Tags a row as a METHtality finisher; FighterData.meth_move references it and
# the ordinary move lookups never return it (PROPOSALS §4).
func _meth(m: MoveData) -> MoveData:
	m.meth = true
	return m


# PROPOSALS §6 migration: the legacy hit-confirm routes, authored as data. Every
# light/heavy-input row gets the window the hard-coded _try_cancel() used
# (first frame after startup through the move's total), and the target order
# matches the old code: special, then light, then heavy. Light rows chain into
# normals; heavy rows only cancel into specials.
#
# Authored route data on top (§6 "route examples"):
#   - jump_heavy chains into LIGHT on hit (jump-in starter route).
#   - heavy (punish starter) routes into the fighter's forward EX special, with
#     the base forward special as the documented fallback when meter cannot pay.
func _normals(light: Array, heavy: Array, clight: Array, cheavy: Array,
		jlight: float, jheavy: float) -> Array[MoveData]:
	var rows := _normal_rows(light, heavy, clight, cheavy, jlight, jheavy)
	for m in rows:
		if m.input == LIGHT:
			_cancel(m, CancelRule.Target.SPECIAL, CancelRule.Kind.CANCEL)
			_cancel(m, CancelRule.Target.LIGHT, CancelRule.Kind.CHAIN)
			_cancel(m, CancelRule.Target.HEAVY, CancelRule.Kind.CHAIN)
		elif m.input == HEAVY:
			_cancel(m, CancelRule.Target.EX, CancelRule.Kind.CANCEL)
			_cancel(m, CancelRule.Target.SPECIAL, CancelRule.Kind.CANCEL)
	# jump_heavy carries the §6 jump-in starter route: a HIT chain into light.
	for m in rows:
		if m.id == "jump_heavy":
			_cancel(m, CancelRule.Target.LIGHT, CancelRule.Kind.CHAIN)
	return rows


func _cancel(m: MoveData, target: CancelRule.Target, kind: CancelRule.Kind) -> void:
	var rule := CancelRule.new()
	rule.target = target
	rule.kind = kind
	rule.condition = CancelRule.Condition.HIT
	rule.from_frame = m.startup + 1
	rule.to_frame = m.total_frames()
	m.cancels.append(rule)


func _normal_rows(light: Array, heavy: Array, clight: Array, cheavy: Array,
		jlight: float, jheavy: float) -> Array[MoveData]:
	# Whiffed aerial normals use an authored 8f LAND lockout; hit/block landings
	# keep the legacy 2f delay in FighterBase.
	return [
		_m("light", LIGHT, STAND, MID, light[0], 2, light[1], light[2], 2.0, 13, 8, 55, false, Vector2(22, -44), Vector2(28, 16), 4),
		_m("heavy", HEAVY, STAND, MID, heavy[0], 3, heavy[1], heavy[2], heavy[3], 18, 12, 90, false, Vector2(26, -42), Vector2(34, 22), 6),
		_m("crouch_light", LIGHT, CROUCH, LOW, clight[0], 2, clight[1], clight[2], 2.0, 12, 8, 45, false, Vector2(22, -24), Vector2(30, 14), 4),
		_m("crouch_heavy", HEAVY, CROUCH, LOW, cheavy[0], 3, cheavy[1], cheavy[2], cheavy[3], 16, 12, 70, true, Vector2(28, -20), Vector2(36, 16), 6),
		_m("jump_light", LIGHT, AIR, OVERHEAD, 4, 3, 10, jlight, 3.0, 14, 9, 50, false, Vector2(22, -38), Vector2(30, 18), 4, 8),
		_m("jump_heavy", HEAVY, AIR, OVERHEAD, 7, 3, 13, jheavy, 5.0, 18, 11, 80, false, Vector2(26, -36), Vector2(36, 24), 6, 8),
	]


func _specials(prefix: String, neutral: float, fwd: float, down: float,
		back: float, air: float, grab: float) -> Array[MoveData]:
	# Air specials are slower/narrower and lower-damage after the measured probe.
	# Their 12f whiff LAND lockout is data, not an engine constant.
	return [
		_m(prefix + "_neutral", SP_NEUTRAL, STAND, MID, 9, 3, 19, neutral, 6.0, 20, 13, 110, false, Vector2(26, -40), Vector2(40, 20), 8),
		_m(prefix + "_forward", SP_FWD, STAND, MID, 11, 4, 22, fwd, 7.0, 22, 14, 130, true, Vector2(30, -40), Vector2(44, 22), 8),
		_m(prefix + "_down", SP_DOWN, STAND, LOW, 10, 3, 20, down, 6.0, 18, 12, 80, false, Vector2(28, -18), Vector2(42, 14), 8),
		_m(prefix + "_back", SP_BACK, STAND, MID, 8, 3, 18, back, 5.0, 18, 12, 60, false, Vector2(24, -40), Vector2(34, 20), 8),
		_m(prefix + "_air", SP_AIR, AIR, OVERHEAD, 12, 2, 16, air, 5.0, 18, 12, 90, false, Vector2(26, -40), Vector2(34, 22), 8, 12),
		_m("grab", GRAB, STAND, THROW, 5, 2, 16, grab, 0.0, 0, 0, 100, true, Vector2(20, -36), Vector2(30, 40), 6),
	]


func _fighter(id: String, display_name: String, speed_f: float, speed_b: float,
		jump: float, width: float, height: float, color: Color) -> FighterData:
	var f := FighterData.new()
	f.id = id
	f.display_name = display_name
	f.max_health = 1000.0
	f.walk_speed_fwd = speed_f
	f.walk_speed_back = speed_b
	f.jump_speed = jump
	f.body_width = width
	f.body_height = height
	f.body_color = color
	f.moves = []
	return f


# PROPOSALS §7 command grab rows: THROW level, UNTECHABLE (slow punishable
# startup per owner decision), forward+grab selection, knockdown, no EX variant.
func _cg(id: String, startup: int, recovery: int, damage: float, whiff_recovery: int,
		meter_hit: float, meter_whiff: float, meter_recv: float) -> MoveData:
	var m := _m(id, MoveData.InputType.COMMAND_GRAB, STAND, THROW, startup, 3, recovery,
		damage, 0.0, 0, 0, 100, true, Vector2(20, -36), Vector2(30, 40), 8)
	m.whiff_recovery = whiff_recovery
	m.meter_gain_hit = meter_hit
	m.meter_gain_whiff = meter_whiff
	m.meter_gain_receive = meter_recv
	return m


func _peggy() -> FighterData:
	var f := _fighter("peg_leg_peggy", "Peg Leg Peggy", 95.0, 72.0, 285.0, 26.0, 54.0,
		Color(0.95, 0.55, 0.15, 1.0))
	var moves: Array[MoveData] = _normals([3, 7, 35], [7, 15, 85, 5], [4, 9, 30], [8, 18, 75, 4], 40, 80)
	moves.append_array(_specials("peggy", 95, 110, 90, 85, 70, 95))
	moves.append(_ex(_m("peggy_neutral_ex", SP_NEUTRAL, STAND, MID, 7, 3, 17, 120, 7.0,
		22, 14, 120, false, Vector2(28, -40), Vector2(44, 20), 10)))
	moves.append(_ex(_m("peggy_forward_ex", SP_FWD, STAND, MID, 9, 4, 20, 145, 9.0,
		24, 15, 150, true, Vector2(32, -40), Vector2(48, 24), 10)))
	# §7 command grab (owner values, first pass): untechable, slow startup.
	moves.append(_cg("peggy_command_grab", 14, 24, 120.0, 24, 6.0, 1.5, 4.0))
	f.moves = moves
	f.meth_name = "Walk the Plank"
	f.meth_health_threshold = 250.0
	f.meth_move = _meth(_m("peggy_meth", SP_NEUTRAL, STAND, MID, 3, 2, 24, 1000, 0.0,
		0, 8, 150, true, Vector2(30, -40), Vector2(60, 44), 30))
	# PROPOSALS §6 block-pushback parity: 45 px/s authored on every strike row;
	# throws (never blocked) author 0.
	for m in f.moves:
		if m.level == MoveData.Level.THROW:
			m.block_pushback = 0.0
	return f


func _richard() -> FighterData:
	var f := _fighter("whiskey_richard", "Whiskey Richard", 70.0, 55.0, 250.0, 32.0, 60.0,
		Color(0.85, 0.2, 0.18, 1.0))
	var moves: Array[MoveData] = _normals([4, 9, 45], [9, 17, 100, 5], [5, 10, 35], [10, 19, 90, 5], 45, 90)
	moves.append_array(_specials("richard", 105, 120, 95, 100, 60, 105))
	moves.append(_ex(_m("richard_neutral_ex", SP_NEUTRAL, STAND, MID, 7, 4, 17, 135, 8.0,
		24, 14, 120, false, Vector2(28, -40), Vector2(44, 20), 10)))
	moves.append(_ex(_m("richard_forward_ex", SP_FWD, STAND, MID, 9, 4, 20, 150, 9.0,
		26, 15, 160, true, Vector2(32, -40), Vector2(48, 24), 10)))
	# §7 command grab (owner values, first pass): untechable, slow startup.
	moves.append(_cg("richard_command_grab", 16, 26, 140.0, 26, 8.0, 1.5, 4.0))
	f.moves = moves
	f.meth_name = "Flaming Belch"
	f.meth_health_threshold = 250.0
	f.meth_move = _meth(_m("richard_meth", SP_NEUTRAL, STAND, MID, 3, 2, 24, 1000, 0.0,
		0, 8, 160, true, Vector2(32, -40), Vector2(64, 44), 30))
	# PROPOSALS §6 block-pushback parity: 45 px/s authored on every strike row;
	# throws (never blocked) author 0.
	for m in f.moves:
		if m.level == MoveData.Level.THROW:
			m.block_pushback = 0.0
	return f
