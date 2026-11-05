# Headless Phase 1 round-flow test. Run:
#   godot --headless --path game --script res://tests/round_flow_test.gd
extends SceneTree

var scene: Node2D
var p1: FighterBase
var p2: FighterBase
var failures := 0


func _initialize() -> void:
	scene = load("res://scenes/match/MatchRoot.tscn").instantiate()
	root.add_child(scene)
	_run.call_deferred()


func _step(frames: int = 1) -> void:
	for i in frames:
		await physics_frame


func _check(label: String, condition: bool, detail: String = "") -> void:
	if condition:
		print("PASS: ", label)
	else:
		failures += 1
		print("FAIL: ", label, "  ", detail)


func _place_for_ko() -> void:
	p1.position = Vector2(120, 150)
	p2.position = Vector2(146, 150)
	p1.velocity = Vector2.ZERO
	p2.velocity = Vector2.ZERO
	p1.facing = 1
	p2.facing = -1
	p2.health = 1.0
	p2.reset_state()
	p1.reset_state()


func _place_for_double_ko() -> void:
	p1.position = Vector2(120, 150)
	p2.position = Vector2(146, 150)
	p1.velocity = Vector2.ZERO
	p2.velocity = Vector2.ZERO
	p1.facing = 1
	p2.facing = -1
	p1.health = 1.0
	p2.health = 1.0
	p1.reset_state()
	p2.reset_state()


# Burn a round on an equal-health clock-out, then let the next round's intro
# finish so the caller is back in FIGHT.
func _force_timeout_tie() -> void:
	p1.health = 1000.0
	p2.health = 1000.0
	p1.reset_state()
	p2.reset_state()
	scene.timer_frames = 1
	await _step(3)
	await _step(95)
	await _step(65)


func _run() -> void:
	await _step(65)
	p1 = scene.p1
	p2 = scene.p2
	_check("intro -> fight", scene.phase == 1 and scene.round_number == 1, "phase=%d" % scene.phase)

	# --- Round 1: KO ---
	_place_for_ko()
	var light: MoveData = p1.data.find_move(MoveData.InputType.LIGHT, MoveData.Stance.STAND)
	p1._start_move(light)
	await _step(20)
	_check("KO phase entered", scene.phase == 2, "phase=%d" % scene.phase)
	await _step(105)
	_check("p1 awarded round win", scene.wins[0] == 1, str(scene.wins))
	_check("round end phase", scene.phase == 3, "phase=%d" % scene.phase)

	# --- Round 2: timeout ---
	await _step(95)
	_check("round 2 starts", scene.round_number == 2 and scene.phase == 0, "round=%d phase=%d" % [scene.round_number, scene.phase])
	await _step(65)
	_check("round 2 fighting", scene.phase == 1, "phase=%d" % scene.phase)
	p1.health = 500.0
	p2.health = 800.0
	scene.timer_frames = 3
	await _step(5)
	_check("timeout awards higher health", scene.wins[1] == 1, str(scene.wins))

	# --- Round 3: simultaneous KO resolves as a draw ---
	await _step(95)
	await _step(65)
	_check("round 3 starts", scene.round_number == 3 and scene.phase == 1,
		"round=%d phase=%d" % [scene.round_number, scene.phase])
	_place_for_double_ko()
	# Both fighters throw the same move on the same frame, so both sets of active
	# frames line up and the exchange is a true same-frame trade.
	p1._start_move(light)
	p2._start_move(light)
	await _step(20)
	_check("double KO detected", scene.ko_draw and scene.phase == 2,
		"ko_draw=%s phase=%d" % [scene.ko_draw, scene.phase])
	await _step(105)
	_check("double KO awards a pip to both", scene.wins[0] == 2 and scene.wins[1] == 2,
		str(scene.wins))
	_check("draw round ends", scene.phase == 3, "phase=%d" % scene.phase)
	await _step(95)
	_check("round advances after double KO", scene.round_number == 4 and scene.phase == 0,
		"round=%d phase=%d" % [scene.round_number, scene.phase])

	# --- Round 4: 2-2 is decisive; an outright win ends the match ---
	await _step(65)
	_check("2-2 shows the decisive-round message", scene.hud.message.text == "DECISIVE ROUND",
		"msg='%s'" % scene.hud.message.text)
	_place_for_ko()
	p1._start_move(light)
	await _step(20)
	await _step(105)
	_check("2-2 continues into a decisive round and ends on an outright win",
		scene.phase == 4 and scene.wins[0] == 3 and scene.wins[1] == 2,
		"phase=%d wins=%s" % [scene.phase, str(scene.wins)])

	# --- Fresh match: round clock vs hitstop ---
	scene._reset_match()
	await _step(65)
	_check("fresh match fighting", scene.phase == 1 and scene.wins[0] == 0 and scene.wins[1] == 0,
		"phase=%d wins=%s" % [scene.phase, str(scene.wins)])

	# (a) hitstop freezes the clock
	p1.health = 1000.0
	p2.health = 1000.0
	p1.position = Vector2(100, 150)
	p2.position = Vector2(120, 150)
	p1.facing = 1
	p2.facing = -1
	p1.reset_state()
	p2.reset_state()
	p2.receive_hit(p1, light)
	var hitstop := maxi(p1.hitstop_frames, p2.hitstop_frames)
	var frozen: int = scene.timer_frames
	await _step(maxi(1, hitstop - 1))
	_check("timer frozen during hitstop",
		scene.timer_frames == frozen and maxi(p1.hitstop_frames, p2.hitstop_frames) > 0,
		"timer %d -> %d, hitstop=%d" % [frozen, scene.timer_frames, maxi(p1.hitstop_frames, p2.hitstop_frames)])
	await _step(12)
	_check("timer resumes after hitstop", scene.timer_frames < frozen,
		"timer %d -> %d" % [frozen, scene.timer_frames])

	# (b) a hit landing on the clock's final frame still counts. Measure the
	# impact frame first, then replay with the timer expiring on exactly it.
	p1.health = 990.0
	p2.health = 1000.0
	p1.position = Vector2(120, 150)
	p2.position = Vector2(146, 150)
	p1.reset_state()
	p2.reset_state()
	p1._start_move(light)
	var impact := 0
	while p2.health >= 1000.0 and impact < 30:
		scene.timer_frames = 999
		await _step(1)
		impact += 1
	_check("attack connects", p2.health < 1000.0, "hp=%.1f after %d frames" % [p2.health, impact])

	p1.health = 990.0
	p2.health = 1000.0
	p1.position = Vector2(120, 150)
	p2.position = Vector2(146, 150)
	p1.reset_state()
	p2.reset_state()
	p1._start_move(light)
	scene.timer_frames = impact
	await _step(impact + 20)
	# p2 is ahead on health until this hit lands; if the timeout discarded it,
	# p2 would take the round instead.
	_check("hit on the timer's final frame counts", scene.wins[0] == 1,
		"wins=%s p1=%.1f p2=%.1f" % [str(scene.wins), p1.health, p2.health])

	# --- Draw resolution: three timeout ties reach sudden death ---
	scene._reset_match()
	await _step(65)
	_check("reset clears draw-resolution state",
		not scene.sudden_death and scene.timeout_ties == 0 and scene.wins == [0, 0],
		"sd=%s ties=%d wins=%s" % [str(scene.sudden_death), scene.timeout_ties, str(scene.wins)])

	await _force_timeout_tie()
	_check("first timeout tie awards no pip",
		scene.wins == [0, 0] and scene.timeout_ties == 1
			and not scene.sudden_death and scene.phase == 1,
		"wins=%s ties=%d sd=%s" % [str(scene.wins), scene.timeout_ties, str(scene.sudden_death)])
	await _force_timeout_tie()
	_check("second timeout tie still awards no pip",
		scene.wins == [0, 0] and scene.timeout_ties == 2
			and not scene.sudden_death and scene.phase == 1,
		"wins=%s ties=%d sd=%s" % [str(scene.wins), scene.timeout_ties, str(scene.sudden_death)])
	await _force_timeout_tie()
	_check("third timeout tie reaches sudden death",
		scene.sudden_death and scene.phase == 1 and scene.wins == [0, 0],
		"wins=%s sd=%s phase=%d" % [str(scene.wins), str(scene.sudden_death), scene.phase])
	_check("sudden death uses a 30-second clock",
		scene.timer_frames <= 30 * 60 and scene.timer_frames > 29 * 60,
		"timer=%d" % scene.timer_frames)

	# A tie inside sudden death resolves by remaining health, then by damage
	# dealt this round — this clock-out is equal health, p2 out-damaged p1.
	p1.health = 800.0
	p2.health = 800.0
	scene.round_damage[0] = 40.0
	scene.round_damage[1] = 300.0
	scene.timer_frames = 1
	await _step(3)
	_check("a sudden-death timeout tie resolves by damage dealt",
		scene.phase == 4 and scene.wins[1] == 1 and scene.wins[0] == 0,
		"phase=%d wins=%s" % [scene.phase, str(scene.wins)])
	_check("the tiebreak is announced", scene.hud.message.text.contains("TIEBREAK"),
		"msg='%s'" % scene.hud.message.text)
	p1.health = 500.0
	p2.health = 500.0
	scene.round_damage[0] = 0.0
	scene.round_damage[1] = 0.0
	p1.meter = 0.0
	p2.meter = 0.0
	_check("fully equal tiebreak fields fall back to P1 deterministically",
		scene._sudden_death_tiebreak() == 0)

	# --- Sudden death: the first clean win ends the match ---
	scene._reset_match()
	scene.sudden_death = true
	scene._begin_round()
	await _step(65)
	_check("sudden death round starts fighting", scene.phase == 1 and scene.round_number == 1,
		"phase=%d round=%d" % [scene.phase, scene.round_number])
	_place_for_ko()
	p1._start_move(light)
	await _step(20)
	_check("KO inside sudden death enters the KO phase", scene.phase == 2, "phase=%d" % scene.phase)
	await _step(105)
	_check("first clean win in sudden death ends the match",
		scene.phase == 4 and scene.wins[0] == 1 and scene.wins[1] == 0,
		"phase=%d wins=%s" % [scene.phase, str(scene.wins)])

	print("\n%d failure(s)" % failures)
	quit(1 if failures > 0 else 0)
