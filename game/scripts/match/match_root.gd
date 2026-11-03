# MatchRoot — Phase 1 match orchestrator + hit detection.
extends Node2D

const STAGE_SCENE := preload("res://scenes/stages/bus_stop_night.tscn")
const FIGHTER_SCENE := preload("res://scenes/fighters/FighterBase.tscn")
const PEGGY_DATA := preload("res://resources/fighters/peg_leg_peggy.tres")
const RICHARD_DATA := preload("res://resources/fighters/whiskey_richard.tres")

var stage: Node2D
var p1: FighterBase
var p2: FighterBase

func _ready() -> void:
	process_physics_priority = 100 # run after fighters update their state

	stage = STAGE_SCENE.instantiate()
	add_child(stage)

	p1 = _spawn_fighter(1, PEGGY_DATA)
	p2 = _spawn_fighter(2, RICHARD_DATA)
	p1.opponent = p2
	p2.opponent = p1

	_start_round()

func _spawn_fighter(index: int, data: FighterData) -> FighterBase:
	var f: FighterBase = FIGHTER_SCENE.instantiate()
	f.player_index = index
	f.data = data
	f.stage = stage
	add_child(f)
	return f

func _start_round() -> void:
	p1.begin_round(Vector2(stage.spawn_p1_x, stage.floor_y), stage.spawn_p2_x)
	p2.begin_round(Vector2(stage.spawn_p2_x, stage.floor_y), stage.spawn_p1_x)

func _physics_process(_delta: float) -> void:
	_separate_pushboxes()
	_detect_hits(p1, p2)
	_detect_hits(p2, p1)

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
