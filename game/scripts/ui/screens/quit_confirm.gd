# QuitConfirm — the "Leave the sidewalk?" modal (an overlay: pushed without
# freeing the screen below). YES / NO on one row with the selection
# defaulting to NO. Used from the main menu, the title screen, and the
# pause menu (where it must keep working while the tree is paused, hence
# PROCESS_MODE_ALWAYS). One small centered ui_panel, items in Sidewalk
# Marker, the focused item in yellow with a ">" marker.
extends Control

signal quit_confirmed
signal dismissed

const THEME_RESOURCE := preload("res://resources/ui_theme.tres")
const CHOICES := ["YES", "NO"]

const PANEL_POS := Vector2(76, 54)
const PANEL_SIZE := Vector2(168, 64)

# The brief requires the default answer to be NO.
var index := 1
var _labels: Array[Label] = []


func _ready() -> void:
	# Above a paused match the tree is frozen; this overlay must still run.
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.65)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)

	var panel := Panel.new()
	panel.theme = THEME_RESOURCE
	panel.position = PANEL_POS
	panel.size = PANEL_SIZE
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel)

	var question := UiText.marker("LEAVE THE SIDEWALK?",
		Vector2(PANEL_POS.x, PANEL_POS.y + 8), UiText.CREAM_TEXT)
	question.size = Vector2(PANEL_SIZE.x, UiText.MARKER_LINE_HEIGHT)
	question.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(question)

	for choice_index in CHOICES.size():
		var label := UiText.marker(CHOICES[choice_index], Vector2.ZERO,
			UiText.CREAM_TEXT)
		label.size = Vector2(64, UiText.MARKER_LINE_HEIGHT)
		add_child(label)
		_labels.append(label)

	add_child(UiPromptLine.new("SELECT", "BACK"))
	_layout_choices()
	_refresh()


func _layout_choices() -> void:
	# YES / NO on one centered row, "> " marker included in the width.
	var yes_w := UiText.marker_width("> YES")
	var no_w := UiText.marker_width("> NO")
	var gap := 24
	var start_x := 160 - (yes_w + gap + no_w) / 2.0
	_labels[0].position = Vector2(roundi(start_x), PANEL_POS.y + 36)
	_labels[1].position = Vector2(roundi(start_x + yes_w + gap), PANEL_POS.y + 36)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo():
		return
	ScreenRouter.note_input_device(event)
	var handled := true
	if event.is_action_pressed("p1_left") or event.is_action_pressed("p1_up"):
		_move(-1)
	elif event.is_action_pressed("p1_right") or event.is_action_pressed("p1_down"):
		_move(1)
	elif event.is_action_pressed("p1_light") or event.is_action_pressed("ui_confirm"):
		_choose()
	elif event.is_action_pressed("ui_back"):
		dismissed.emit()
	else:
		handled = false
	if handled:
		get_viewport().set_input_as_handled()


func _move(direction: int) -> void:
	index = wrapi(index + direction, 0, CHOICES.size())
	_refresh()


func _choose() -> void:
	if index == 0:
		quit_confirmed.emit()
	else:
		dismissed.emit()


func _refresh() -> void:
	for choice_index in _labels.size():
		var selected := choice_index == index
		_labels[choice_index].text = "> %s" % CHOICES[choice_index] if selected else CHOICES[choice_index]
		_labels[choice_index].add_theme_color_override("font_color",
			UiText.YELLOW if selected else UiText.CREAM_TEXT)
