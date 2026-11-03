# Greybox placeholder, replaced by real stage scene later.
extends Node2D

func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.13, 0.11, 0.1) # asphalt-ish night gray
	bg.size = Vector2(320, 180)
	add_child(bg)

	var floor_edge := ColorRect.new()
	floor_edge.color = Color(0.4, 0.38, 0.34)
	floor_edge.position = Vector2(0, 130)
	floor_edge.size = Vector2(320, 50)
	bg.add_child(floor_edge)
