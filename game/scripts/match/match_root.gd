# MatchRoot — Phase 1 match orchestrator.
extends Node2D

const STAGE_SCENE := preload("res://scenes/stages/bus_stop_night.tscn")
const FIGHTER_SCENE := preload("res://scenes/fighters/FighterBase.tscn")

var stage: Node2D
var p1: FighterBase
var p2: FighterBase

func _ready() -> void:
	stage = STAGE_SCENE.instantiate()
	add_child(stage)

	p1 = _spawn_fighter(1, Color(0.95, 0.55, 0.15))
	p2 = _spawn_fighter(2, Color(0.85, 0.2, 0.18))
	p1.opponent = p2
	p2.opponent = p1

	_start_round()

func _spawn_fighter(index: int, color: Color) -> FighterBase:
	var f: FighterBase = FIGHTER_SCENE.instantiate()
	f.player_index = index
	f.body_color = color
	f.stage = stage
	add_child(f)
	return f

func _start_round() -> void:
	p1.begin_round(Vector2(stage.spawn_p1_x, stage.floor_y), stage.spawn_p2_x)
	p2.begin_round(Vector2(stage.spawn_p2_x, stage.floor_y), stage.spawn_p1_x)

func _physics_process(_delta: float) -> void:
	_separate_pushboxes()

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
