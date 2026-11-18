# Ambient, purely visual stage motion shared by the layered stage scenes.
#
# It runs in _process so the 60 Hz fight simulation is untouched, and the stage
# root is PAUSABLE, so the tree pause menu freezes every layer. Hitstop is not a
# tree pause, so the ambience keeps breathing while the fight is frozen. Nothing
# here reads gameplay state, touches combat data, rotates or scales a sprite, or
# allocates per frame; positions are snapped to whole pixels every update.
#
# Every layer is optional: a scene animates only the nodes it actually has, so
# the same script drives Gas-N-Go's clouds/mosquitoes/gator and the Bus Stop's
# clouds (and, in their scenes, fire and liquor sign).
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
const GATOR_FRAMES := [
	preload("res://art/stages/gas_n_go/gas_n_go_gator_f1.png"),
	preload("res://art/stages/gas_n_go/gas_n_go_gator_f2.png"),
	preload("res://art/stages/gas_n_go/gas_n_go_gator_f3.png"),
]

@export var freeze_ambient := false
# Seen at 320x180, 4-6 px/s is a readable drift rather than a slideshow.
@export_range(0.0, 20.0, 0.5) var cloud_speed := 5.0
# Two breathing poses cover one second; the blink is a short f3 interruption.
@export_range(0.2, 4.0, 0.1) var gator_breath_seconds := 1.0
@export_range(0.5, 30.0, 0.1) var gator_blink_min_seconds := 2.5
@export_range(0.5, 30.0, 0.1) var gator_blink_max_seconds := 6.0
@export_range(0.02, 1.0, 0.01) var gator_blink_seconds := 0.12

@onready var _cloud_a: Sprite2D = get_parent().get_node_or_null("Clouds/CloudA") as Sprite2D
@onready var _cloud_b: Sprite2D = get_parent().get_node_or_null("Clouds/CloudB") as Sprite2D
@onready var _gator: Sprite2D = get_parent().get_node_or_null("Gator") as Sprite2D

var _mosquitoes: Array[Sprite2D] = []
var _elapsed := 0.0
var _cloud_offset := 0.0
var _mosquito_clock := 0.0
var _mosquito_frame := 0
var _gator_breath_clock := 0.0
var _gator_breath_frame := 0
var _gator_frame := 0
var _gator_blink_timer := 0.0
var _gator_blink_remaining := 0.0
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	# Visual-only randomness: never shared with the fight simulation or replays.
	_rng.randomize()
	_gator_blink_timer = _rng.randf_range(
		gator_blink_min_seconds, gator_blink_max_seconds)
	for node_name in ["Mosquitoes/Mosquito1", "Mosquitoes/Mosquito2"]:
		var mosquito := get_parent().get_node_or_null(node_name) as Sprite2D
		if mosquito != null:
			_mosquitoes.append(mosquito)

func _process(delta: float) -> void:
	if freeze_ambient:
		return
	_elapsed += delta
	_advance_clouds(delta)
	_advance_mosquitoes(delta)
	_advance_gator(delta)

# Two copies of the 640 px cloud strip sit one texture-width apart and slide
# left together; wrapping the shared offset keeps the seam outside the 320 px
# camera without ever teleporting a visible cloud.
func _advance_clouds(delta: float) -> void:
	_cloud_offset = fposmod(_cloud_offset + cloud_speed * delta, CLOUD_TEXTURE_WIDTH)
	if _cloud_a == null:
		return
	var snapped := snappedf(_cloud_offset, 1.0)
	_cloud_a.position.x = -snapped
	if _cloud_b != null:
		_cloud_b.position.x = CLOUD_TEXTURE_WIDTH - snapped

# Wingbeat frames flip at 8 fps while each body traces its own small sine loop.
# Only the texture swap is conditional; the sin/cos maths allocate nothing.
func _advance_mosquitoes(delta: float) -> void:
	if _mosquitoes.is_empty():
		return
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

# One breathing cycle is two one-second poses; a random blink interrupts it for
# a couple of frames and then restores the breath pose that was current.
func _advance_gator(delta: float) -> void:
	if _gator == null:
		return
	var half_cycle := maxf(0.01, gator_breath_seconds * 0.5)
	_gator_breath_clock += delta
	if _gator_breath_clock >= half_cycle:
		_gator_breath_clock = fmod(_gator_breath_clock, half_cycle)
		_gator_breath_frame = 1 - _gator_breath_frame
		if _gator_blink_remaining <= 0.0:
			_apply_gator_frame(_gator_breath_frame)

	if _gator_blink_remaining > 0.0:
		_gator_blink_remaining -= delta
		if _gator_blink_remaining <= 0.0:
			_apply_gator_frame(_gator_breath_frame)
		return

	_gator_blink_timer -= delta
	if _gator_blink_timer <= 0.0:
		_apply_gator_frame(2)
		_gator_blink_remaining = gator_blink_seconds
		_gator_blink_timer = _rng.randf_range(
			gator_blink_min_seconds, gator_blink_max_seconds)

func _apply_gator_frame(frame: int) -> void:
	if frame == _gator_frame:
		return
	_gator_frame = frame
	if _gator != null:
		_gator.texture = GATOR_FRAMES[frame]

# Test/debug accessors.
func cloud_offset() -> float:
	return _cloud_offset

func mosquito_frame() -> int:
	return _mosquito_frame

func gator_frame() -> int:
	return _gator_frame
