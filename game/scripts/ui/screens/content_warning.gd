# ContentWarning — the boot notice (shown once per launch).
# A plain, sober photosensitivity sentence on a ui_panel 9-slice with one
# Tripp-flavored line above it. Continues on confirm or after 3 s (180
# frames — UI timers count frames, never wall-clock). Pure presentation.
extends Control

signal warning_done

const THEME_RESOURCE := preload("res://resources/ui_theme.tres")
const AUTO_CONTINUE_FRAMES := 180  # 3 seconds at 60 Hz

var _frames := 0
var _done := false


func _ready() -> void:
	theme = THEME_RESOURCE
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.03, 0.04, 0.92)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)

	var panel := Panel.new()
	panel.position = Vector2(52, 52)
	panel.size = Vector2(216, 76)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel)

	_add_label("TRIPP VLOGS PRESENTS", Vector2(52, 24), Vector2(216, 16),
		Color(0.949, 0.82, 0.227), HORIZONTAL_ALIGNMENT_CENTER)
	_add_label("NOTICE", Vector2(52, 58), Vector2(216, 16),
		Color(0.96, 0.91, 0.83), HORIZONTAL_ALIGNMENT_CENTER)
	_add_label("THIS GAME CONTAINS FLASHING IMAGERY AND\nSTROBING LIGHTS THAT MAY POSE A RISK TO\nPHOTOSENSITIVE PLAYERS.",
		Vector2(60, 74), Vector2(200, 48),
		Color(0.96, 0.91, 0.83), HORIZONTAL_ALIGNMENT_CENTER)
	_add_label("PRESS CONTINUE OR WAIT", Vector2(52, 134),
		Vector2(216, 10), Color(0.68, 0.66, 0.62), HORIZONTAL_ALIGNMENT_CENTER)

	add_child(UiPromptLine.new("CONTINUE", ""))


func _physics_process(_delta: float) -> void:
	if _done:
		return
	_frames += 1
	if _frames >= AUTO_CONTINUE_FRAMES:
		_continue()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo():
		return
	ScreenRouter.note_input_device(event)
	if _done:
		return
	if event.is_action_pressed("ui_confirm") or event.is_action_pressed("p1_light"):
		get_viewport().set_input_as_handled()
		_continue()


func _continue() -> void:
	if _done:
		return
	_done = true
	warning_done.emit()


func _add_label(text: String, at: Vector2, dimensions: Vector2, color: Color,
		alignment: HorizontalAlignment) -> void:
	var label := Label.new()
	label.position = at
	label.size = dimensions
	label.text = text
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
