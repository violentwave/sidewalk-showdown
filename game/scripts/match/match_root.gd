# MatchRoot — match orchestrator: rounds, timer, KO, HUD, pause.
extends Node2D

enum Phase { INTRO, FIGHT, KO, ROUND_END, MATCH_END }

const STAGE_SCENE := preload("res://scenes/stages/bus_stop_night.tscn")
const HUD_SCENE := preload("res://scenes/match/MatchHUD.tscn")
const DEBUG_SCRIPT := preload("res://scripts/debug/debug_overlay.gd")
const FIGHTER_SCENE := preload("res://scenes/fighters/FighterBase.tscn")
const PEGGY_DATA := preload("res://resources/fighters/peg_leg_peggy.tres")
const RICHARD_DATA := preload("res://resources/fighters/whiskey_richard.tres")

const ROUND_SECONDS := 99
const INTRO_FRAMES := 60
const KO_FRAMES := 100
const ROUND_END_FRAMES := 90
const WINS_TO_TAKE_MATCH := 2

var stage: Node2D
var hud: MatchHUD
var debug_overlay: DebugOverlay
var p1: FighterBase
var p2: FighterBase

var phase: Phase = Phase.INTRO
var phase_frame := 0
var round_number := 1
var wins: Array[int] = [0, 0]
var timer_frames := ROUND_SECONDS * 60
var ko_loser: FighterBase
var ko_draw := false
var ko_frame := -1
var sim_frame := 0
var pause_index := 0
var pause_menu_open := false

func _ready() -> void:
	process_physics_priority = 100 # run after fighters update their state
	process_mode = Node.PROCESS_MODE_ALWAYS

	stage = STAGE_SCENE.instantiate()
	add_child(stage)

	hud = HUD_SCENE.instantiate()
	add_child(hud)

	p1 = _spawn_fighter(1, PEGGY_DATA)
	p2 = _spawn_fighter(2, RICHARD_DATA)
	p1.opponent = p2
	p2.opponent = p1
	hud.bind(p1, p2)

	p1.ko.connect(_on_fighter_ko.bind(p1))
	p2.ko.connect(_on_fighter_ko.bind(p2))

	debug_overlay = DEBUG_SCRIPT.new()
	add_child(debug_overlay)
	debug_overlay.bind(p1, p2)

	_begin_round()

func _spawn_fighter(index: int, data: FighterData) -> FighterBase:
	var f: FighterBase = FIGHTER_SCENE.instantiate()
	f.player_index = index
	f.data = data
	f.stage = stage
	# MatchRoot runs with PROCESS_MODE_ALWAYS so the pause key keeps working;
	# fighters must not inherit that or they keep simulating while paused.
	f.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(f)
	return f

# ---------------- Round flow ----------------
func _begin_round() -> void:
	p1.begin_round(Vector2(stage.spawn_p1_x, stage.floor_y), stage.spawn_p2_x)
	p2.begin_round(Vector2(stage.spawn_p2_x, stage.floor_y), stage.spawn_p1_x)
	p1.input_enabled = false
	p2.input_enabled = false
	timer_frames = ROUND_SECONDS * 60
	phase = Phase.INTRO
	phase_frame = 0
	ko_loser = null
	ko_draw = false
	ko_frame = -1
	hud.set_timer(float(ROUND_SECONDS))
	hud.set_pips(wins[0], wins[1])
	hud.show_message("ROUND %d" % round_number)

func _start_fight() -> void:
	phase = Phase.FIGHT
	phase_frame = 0
	p1.input_enabled = true
	p2.input_enabled = true
	hud.clear_message()

func _on_fighter_ko(loser: FighterBase) -> void:
	if phase == Phase.KO:
		# A second KO inside the same simulation frame means both fighters died
		# on the trade: make it a draw round instead of crediting the first signal.
		if ko_frame == sim_frame and p1.health <= 0.0 and p2.health <= 0.0:
			ko_draw = true
			ko_loser = null
			for f: FighterBase in [p1, p2]:
				if f.health <= 0.0 and f.state != FighterBase.State.KO:
					f._force_state(FighterBase.State.KO)
			hud.show_message("DOUBLE K.O.")
		return
	if phase != Phase.FIGHT:
		return
	ko_loser = loser
	ko_frame = sim_frame
	ko_draw = false
	phase = Phase.KO
	phase_frame = 0
	p1.input_enabled = false
	p2.input_enabled = false
	var winner := p2 if loser == p1 else p1
	winner._force_state(FighterBase.State.WIN)
	hud.show_message("K.O.")

func _finish_round(winner_index: int, double_ko := false) -> void:
	if winner_index >= 0:
		wins[winner_index] += 1
	hud.set_pips(wins[0], wins[1])
	phase_frame = 0
	if wins[0] >= WINS_TO_TAKE_MATCH or wins[1] >= WINS_TO_TAKE_MATCH:
		phase = Phase.MATCH_END
		var champion := p1 if wins[0] >= WINS_TO_TAKE_MATCH else p2
		hud.show_message("%s WINS THE MATCH\nENTER TO RESTART" % champion.data.display_name.to_upper())
	else:
		phase = Phase.ROUND_END
		if winner_index < 0:
			hud.show_message("DOUBLE K.O.\nDRAW" if double_ko else "DRAW")
		else:
			var winner := p1 if winner_index == 0 else p2
			hud.show_message("%s\nTAKES THE ROUND" % winner.data.display_name.to_upper())

func _timeout_round() -> void:
	p1.input_enabled = false
	p2.input_enabled = false
	var winner := -1
	if p1.health > p2.health + 0.1:
		winner = 0
	elif p2.health > p1.health + 0.1:
		winner = 1
	_finish_round(winner)

func _reset_match() -> void:
	wins = [0, 0]
	round_number = 1
	_begin_round()

# Debug frame-step: advance exactly one simulation frame while the tree stays
# paused. Fighters tick first, then the match, mirroring process_physics_priority.
func step_simulation_frame() -> void:
	if p1 == null or p2 == null:
		return
	var tree := get_tree()
	var was_paused := tree.paused
	var dt := 1.0 / float(Engine.physics_ticks_per_second)
	tree.paused = false
	p1._physics_process(dt)
	p2._physics_process(dt)
	_physics_process(dt)
	tree.paused = was_paused

# ---------------- Simulation ----------------
func _physics_process(_delta: float) -> void:
	if get_tree().paused:
		return

	sim_frame += 1
	phase_frame += 1
	match phase:
		Phase.INTRO:
			if phase_frame >= INTRO_FRAMES:
				_start_fight()
		Phase.FIGHT:
			_separate_pushboxes()
			# Both attackers' hits are polled before either is applied, so a
			# same-frame trade lands both hits (double-ko), and the hits resolve
			# before the clock so a hit on the timer's final frame still counts
			# and a KO there beats the timeout (timer-hitstop).
			_resolve_hits()
			if phase != Phase.FIGHT:
				return
			# Hitstop freezes the whole exchange, so it must not burn the clock.
			if p1.hitstop_frames > 0 or p2.hitstop_frames > 0:
				return
			timer_frames -= 1
			hud.set_timer(float(timer_frames) / 60.0)
			if timer_frames <= 0:
				_timeout_round()
		Phase.KO:
			_separate_pushboxes()
			if phase_frame >= KO_FRAMES:
				if ko_draw:
					_finish_round(-1, true)
				else:
					var winner_index := 0 if ko_loser == p2 else 1
					_finish_round(winner_index)
		Phase.ROUND_END:
			if phase_frame >= ROUND_END_FRAMES:
				round_number += 1
				_begin_round()
		Phase.MATCH_END:
			if Input.is_action_just_pressed("ui_confirm"):
				_reset_match()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo():
		return
	if event.is_action_pressed("p1_pause") or event.is_action_pressed("p2_pause"):
		_toggle_pause()
		return
	if not get_tree().paused:
		return
	# Menu navigation uses the players' own actions rather than ui_up/ui_down,
	# which also match the arrow keys and would step the selection twice.
	if event.is_action_pressed("p1_up") or event.is_action_pressed("p2_up"):
		_move_pause_selection(-1)
	elif event.is_action_pressed("p1_down") or event.is_action_pressed("p2_down"):
		_move_pause_selection(1)
	elif (event.is_action_pressed("p1_light") or event.is_action_pressed("p2_light")
			or event.is_action_pressed("ui_confirm")):
		_confirm_pause_selection()

# ---------------- Pause menu ----------------
func _toggle_pause() -> void:
	var paused := not get_tree().paused
	get_tree().paused = paused
	pause_menu_open = paused
	if paused:
		pause_index = 0
	hud.set_paused(paused)

func _unpause() -> void:
	get_tree().paused = false
	pause_menu_open = false
	hud.set_paused(false)

# Debug frame-step asks before stepping: the sim must never advance underneath
# the pause menu.
func is_pause_menu_open() -> bool:
	return pause_menu_open

func _move_pause_selection(dir: int) -> void:
	var count := hud.pause_option_count()
	if count <= 0:
		return
	pause_index = wrapi(pause_index + dir, 0, count)
	hud.set_pause_selection(pause_index)

func _confirm_pause_selection() -> void:
	match pause_index:
		1:
			# Start the new match unpaused so its intro frames actually run.
			_unpause()
			_reset_match()
		2:
			_unpause()
			get_tree().quit()
		_:
			_unpause()

# Poll both fighters before applying either hit, so a same-frame trade lands
# both hits. Resolving them in sequence let the first KO interrupt the second
# attacker (state leaves ATTACK) and silently win every exchange.
func _resolve_hits() -> void:
	var move_a := _poll_hit(p1, p2)
	var move_b := _poll_hit(p2, p1)
	if move_a != null:
		p1.on_attack_connected(p2.receive_hit(p1, move_a))
	if move_b != null:
		p2.on_attack_connected(p1.receive_hit(p2, move_b))

func _poll_hit(attacker: FighterBase, defender: FighterBase) -> MoveData:
	if attacker.state != FighterBase.State.ATTACK:
		return null
	if attacker.current_move == null or attacker.move_already_hit:
		return null
	var hb := attacker.get_hitbox_rect()
	if hb.size == Vector2.ZERO:
		return null
	if not hb.intersects(defender.hurtbox_rect()):
		return null
	# A grounded throw cannot grab a defender who has left the ground. This is
	# rejected before the move is returned on purpose: _resolve_hits() only calls
	# on_attack_connected() for a non-null move, so the brush does not consume the
	# throw's active window and the grab still lands on a later active frame if the
	# defender touches down inside it.
	if attacker.current_move.level == MoveData.Level.THROW and not defender.grounded:
		return null
	return attacker.current_move

func _separate_pushboxes() -> void:
	if p1.state == FighterBase.State.KO or p2.state == FighterBase.State.KO:
		return
	var r1 := p1.pushbox_rect()
	var r2 := p2.pushbox_rect()
	if not r1.intersects(r2):
		return
	var overlap := minf(r1.end.x, r2.end.x) - maxf(r1.position.x, r2.position.x)
	if overlap <= 0.0:
		return
	var half := overlap * 0.5
	var dir := 1.0 if p1.position.x <= p2.position.x else -1.0
	p1.position.x -= half * dir
	p2.position.x += half * dir
	p1.clamp_to_stage()
	p2.clamp_to_stage()
