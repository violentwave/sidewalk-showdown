# MatchRoot — match orchestrator: rounds, timer, KO, HUD, pause.
extends Node2D

enum Phase { INTRO, FIGHT, KO, ROUND_END, MATCH_END }

const STAGE_SCENE := preload("res://scenes/stages/bus_stop_night.tscn")
const HUD_SCENE := preload("res://scenes/match/MatchHUD.tscn")
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
var p1: FighterBase
var p2: FighterBase

var phase: Phase = Phase.INTRO
var phase_frame := 0
var round_number := 1
var wins: Array[int] = [0, 0]
var timer_frames := ROUND_SECONDS * 60
var ko_loser: FighterBase

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

	_begin_round()

func _spawn_fighter(index: int, data: FighterData) -> FighterBase:
	var f: FighterBase = FIGHTER_SCENE.instantiate()
	f.player_index = index
	f.data = data
	f.stage = stage
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
	if phase != Phase.FIGHT:
		return
	ko_loser = loser
	phase = Phase.KO
	phase_frame = 0
	p1.input_enabled = false
	p2.input_enabled = false
	var winner := p2 if loser == p1 else p1
	winner._force_state(FighterBase.State.WIN)
	hud.show_message("K.O.")

func _finish_round(winner_index: int, label: String) -> void:
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
			hud.show_message("DRAW")
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
	_finish_round(winner, "TIME")

func _reset_match() -> void:
	wins = [0, 0]
	round_number = 1
	_begin_round()

# ---------------- Simulation ----------------
func _physics_process(_delta: float) -> void:
	if get_tree().paused:
		return

	phase_frame += 1
	match phase:
		Phase.INTRO:
			if phase_frame >= INTRO_FRAMES:
				_start_fight()
		Phase.FIGHT:
			timer_frames -= 1
			hud.set_timer(float(timer_frames) / 60.0)
			if timer_frames <= 0:
				_timeout_round()
				return
			_separate_pushboxes()
			_detect_hits(p1, p2)
			_detect_hits(p2, p1)
		Phase.KO:
			_separate_pushboxes()
			if phase_frame >= KO_FRAMES:
				var winner_index := 0 if ko_loser == p2 else 1
				_finish_round(winner_index, "K.O.")
		Phase.ROUND_END:
			if phase_frame >= ROUND_END_FRAMES:
				round_number += 1
				_begin_round()
		Phase.MATCH_END:
			if Input.is_action_just_pressed("ui_confirm"):
				_reset_match()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("p1_pause"):
		var paused := not get_tree().paused
		get_tree().paused = paused
		hud.set_paused(paused)

func _detect_hits(attacker: FighterBase, defender: FighterBase) -> void:
	if attacker.state != FighterBase.State.ATTACK:
		return
	if attacker.current_move == null or attacker.move_already_hit:
		return
	var hb := attacker.get_hitbox_rect()
	if hb.size == Vector2.ZERO:
		return
	if not hb.intersects(defender.hurtbox_rect()):
		return
	var was_hit := defender.receive_hit(attacker, attacker.current_move)
	attacker.on_attack_connected(was_hit)

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
