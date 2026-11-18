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
const MOSQUITO_FRAME_SECONDS := 1.0 / 8.0
const MOSQUITO_FRAMES := [
	preload("res://art/stages/gas_n_go/gas_n_go_mosquito_f1.png"),
	preload("res://art/stages/gas_n_go/gas_n_go_mosquito_f2.png"),
]
# Both loops stay in the upper sky, well above the fighters' heads.
const MOSQUITO_ANCHORS := [Vector2(60, 20), Vector2(250, 38)]
const MOSQUITO_PHASES := [0.0, 2.1]

@export var freeze_ambient := false
# Seen at 320x180, 4-6 px/s is a readable drift rather than a slideshow.
@export_range(0.0, 20.0, 0.5) var cloud_speed := 5.0

@onready var _cloud_a: Sprite2D = get_parent().get_node("Clouds/CloudA")
@onready var _cloud_b: Sprite2D = get_parent().get_node("Clouds/CloudB")
@onready var _mosquitoes: Array[Sprite2D] = [
	get_parent().get_node("Mosquitoes/Mosquito1"),
	get_parent().get_node("Mosquitoes/Mosquito2"),
]

var _elapsed := 0.0
var _cloud_offset := 0.0
var _mosquito_clock := 0.0
var _mosquito_frame := 0

func _process(delta: float) -> void:
	if freeze_ambient:
		return
	_elapsed += delta
	_advance_clouds(delta)
	_advance_mosquitoes(delta)

# Two copies of the 640 px cloud strip sit one texture-width apart and slide
# left together; wrapping the shared offset keeps the seam outside the 320 px
# camera without ever teleporting a visible cloud.
func _advance_clouds(delta: float) -> void:
	_cloud_offset = fposmod(_cloud_offset + cloud_speed * delta, CLOUD_TEXTURE_WIDTH)
	var snapped := snappedf(_cloud_offset, 1.0)
	_cloud_a.position.x = -snapped
	_cloud_b.position.x = CLOUD_TEXTURE_WIDTH - snapped

# Wingbeat frames flip at 8 fps while each body traces its own small sine loop.
# Only the texture swap is conditional; the sin/cos maths allocate nothing.
func _advance_mosquitoes(delta: float) -> void:
	_mosquito_clock += delta
	if _mosquito_clock >= MOSQUITO_FRAME_SECONDS:
		_mosquito_clock = fmod(_mosquito_clock, MOSQUITO_FRAME_SECONDS)
		_mosquito_frame = 1 - _mosquito_frame
		for mosquito: Sprite2D in _mosquitoes:
			mosquito.texture = MOSQUITO_FRAMES[_mosquito_frame]
	for i in _mosquitoes.size():
		var anchor: Vector2 = MOSQUITO_ANCHORS[i]
		var phase: float = MOSQUITO_PHASES[i]
		var offset := Vector2(
			sin(_elapsed * 1.7 + phase) * 12.0,
			sin(_elapsed * 2.6 + phase * 1.4) * 4.0)
		_mosquitoes[i].position = anchor + offset.snapped(Vector2.ONE)

# Test/debug accessors.
func cloud_offset() -> float:
	return _cloud_offset

func mosquito_frame() -> int:
	return _mosquito_frame
