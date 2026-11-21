# Title — the logo over the Gas-N-Go night art with PRESS START pulsing
# at most once per second (a 60-frames-on / 60-frames-off frame counter;
# UI timers count frames, never wall-clock). No attract demo in Phase 1.
# Confirm goes to the main menu; back opens the quit confirm.
extends Control

signal start_pressed
signal back_requested

const THEME_RESOURCE := preload("res://resources/ui_theme.tres")
const STAGE_SCENE := preload("res://scenes/stages/gas_n_go.tscn")
const LOGO := preload("res://art/ui/ui/ui_logo.png")
const PULSE_ON_FRAMES := 60
const PULSE_OFF_FRAMES := 60
const MUTED := Color(0.75, 0.72, 0.68)

var _pulse_frame := 0
var _press_start: Label
var _done := false


func _ready() -> void:
	theme = THEME_RESOURCE
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var background: Node2D = STAGE_SCENE.instantiate()
	add_child(background)

	var logo := TextureRect.new()
	logo.texture = LOGO
	logo.position = Vector2(90, 26)  # 139x74 centred on 320
	logo.size = Vector2(139, 74)
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	logo.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(logo)

	_press_start = Label.new()
	_press_start.text = "PRESS START"
	_press_start.position = Vector2(20, 118)
	_press_start.size = Vector2(280, 16)
	_press_start.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_press_start.add_theme_font_size_override("font_size", 16)
	_press_start.add_theme_color_override("font_color", Color(0.96, 0.91, 0.83))
	_press_start.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_press_start)

	var tagline := Label.new()
	tagline.text = "A TRIPP VLOGS JOINT - $100K SIDEWALK TOURNAMENT"
	tagline.position = Vector2(8, 138)
	tagline.size = Vector2(304, 16)
	tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tagline.add_theme_font_size_override("font_size", 16)
	tagline.add_theme_color_override("font_color", MUTED)
	tagline.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tagline)

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
