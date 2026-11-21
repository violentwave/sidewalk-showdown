# Title — the logo over the Gas-N-Go night art with PRESS START pulsing
# at most once per second (a 60-frames-on / 60-frames-off frame counter;
# UI timers count frames, never wall-clock). No attract demo in Phase 1.
# Nothing else is on screen (owner playtest change, 2026-11-21: the
# tagline is gone). PRESS START is Sidewalk Marker with its baked outline,
# in yellow, over the stage art. Confirm goes to the main menu; back opens
# the quit confirm.
extends Control

signal start_pressed
signal back_requested

const STAGE_SCENE := preload("res://scenes/stages/gas_n_go.tscn")
const LOGO := preload("res://art/ui/ui/ui_logo.png")
const PULSE_ON_FRAMES := 60
const PULSE_OFF_FRAMES := 60

const LOGO_POS := Vector2(90, 16)  # 139x74, centred in the upper third
const PRESS_START_Y := 140

var _pulse_frame := 0
var _press_start: Label
var _done := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var background: Node2D = STAGE_SCENE.instantiate()
	add_child(background)

	var logo := TextureRect.new()
	logo.texture = LOGO
	logo.position = LOGO_POS
	logo.size = Vector2(139, 74)
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	logo.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(logo)

	_press_start = UiText.marker("PRESS START", Vector2(0, PRESS_START_Y - 6),
		UiText.YELLOW, true)
	_press_start.size = Vector2(320, UiText.MARKER_LINE_HEIGHT)
	_press_start.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_press_start)

	add_child(UiPromptLine.new("START", "QUIT"))


func _physics_process(_delta: float) -> void:
	# Pulse at most once per second: 60 frames on, 60 frames off.
	_pulse_frame += 1
	_press_start.visible = _pulse_frame % (PULSE_ON_FRAMES + PULSE_OFF_FRAMES) < PULSE_ON_FRAMES


func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo():
		return
	ScreenRouter.note_input_device(event)
	if _done:
		return
	if event.is_action_pressed("ui_confirm") or event.is_action_pressed("p1_light"):
		get_viewport().set_input_as_handled()
		_done = true
		start_pressed.emit()
	elif event.is_action_pressed("ui_back"):
		get_viewport().set_input_as_handled()
		back_requested.emit()
