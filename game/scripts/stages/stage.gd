# Stage metadata node. Fighters read bounds/floor from here.
extends Node2D

@export var floor_y: float = 150.0
@export var left_bound: float = 24.0
@export var right_bound: float = 296.0
@export var spawn_p1_x: float = 110.0
@export var spawn_p2_x: float = 210.0
# Optional readability control for stages with a bright background element
# (the Bus Stop fire). White leaves the art untouched; lower it to dim the fire
# without editing the texture.
@export var fire_modulate: Color = Color.WHITE:
	set(value):
		fire_modulate = value
		_sync_fire_modulate()

func _ready() -> void:
	_sync_fire_modulate()

func _sync_fire_modulate() -> void:
	var fire := get_node_or_null("Fire") as CanvasItem
	if fire != null:
		fire.modulate = fire_modulate
