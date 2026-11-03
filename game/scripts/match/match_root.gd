# MatchRoot — Phase 1 match orchestrator (expanded in commit 4).
extends Node2D

const STAGE_SCENE := preload("res://scenes/stages/bus_stop_night.tscn")

var stage: Node2D

func _ready() -> void:
	stage = STAGE_SCENE.instantiate()
	add_child(stage)
