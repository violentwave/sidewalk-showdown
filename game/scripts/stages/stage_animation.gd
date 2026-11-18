# Ambient, purely visual stage motion shared by the layered stage scenes.
#
# It runs in _process so the 60 Hz fight simulation is untouched, and the stage
# root is PAUSABLE, so the tree pause menu freezes every layer. Hitstop is not a
# tree pause, so the ambience keeps breathing while the fight is frozen. Nothing
# here reads gameplay state, touches combat data, rotates or scales a sprite, or
# allocates per frame; positions are snapped to whole pixels every update.
#
# `freeze_ambient` is the debug toggle: enable it in the remote inspector to
# hold every animation on its current frame.
extends Node

const CLOUD_TEXTURE_WIDTH := 640.0

@export var freeze_ambient := false
# Seen at 320x180, 4-6 px/s is a readable drift rather than a slideshow.
@export_range(0.0, 20.0, 0.5) var cloud_speed := 5.0

@onready var _cloud_a: Sprite2D = get_parent().get_node("Clouds/CloudA")
@onready var _cloud_b: Sprite2D = get_parent().get_node("Clouds/CloudB")

var _cloud_offset := 0.0

func _process(delta: float) -> void:
	if freeze_ambient:
		return
	_advance_clouds(delta)

# Two copies of the 640 px cloud strip sit one texture-width apart and slide
# left together; wrapping the shared offset keeps the seam outside the 320 px
# camera without ever teleporting a visible cloud.
func _advance_clouds(delta: float) -> void:
	_cloud_offset = fposmod(_cloud_offset + cloud_speed * delta, CLOUD_TEXTURE_WIDTH)
	var snapped := snappedf(_cloud_offset, 1.0)
	_cloud_a.position.x = -snapped
	_cloud_b.position.x = CLOUD_TEXTURE_WIDTH - snapped

# Test/debug accessor, in pixels scrolled from the starting layout.
func cloud_offset() -> float:
	return _cloud_offset
