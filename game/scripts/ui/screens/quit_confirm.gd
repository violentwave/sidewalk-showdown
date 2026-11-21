# QuitConfirm — the "Leave the sidewalk?" modal (an overlay: pushed without
# freeing the screen below). YES / NO with the selection defaulting to NO.
# Used from the main menu, the title screen, and the pause menu (where it
# must keep working while the tree is paused, hence PROCESS_MODE_ALWAYS).
extends Control

signal quit_confirmed
signal dismissed

const THEME_RESOURCE := preload("res://resources/ui_theme.tres")
const MUTED := Color(0.75, 0.72, 0.68)
const ITEM_TEXT := Color(0.96, 0.91, 0.83)

const CHOICES := ["YES", "NO"]

# The brief requires the default answer to be NO.
var index := 1
var _labels: Array[Label] = []


func _ready() -> void:
	# Above a paused match the tree is frozen; this overlay must still run.
	process_mode = Node.PROCESS_MODE_ALWAYS
	theme = THEME_RESOURCE
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.65)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)

	var panel := Panel.new()
	panel.position = Vector2(88, 56)
	panel.size = Vector2(144, 68)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel)

	var question := Label.new()
	question.text = "LEAVE THE SIDEWALK?"
	question.position = Vector2(88, 64)
	question.size = Vector2(144, 16)
	question.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	question.add_theme_font_size_override("font_size", 16)
	question.add_theme_color_override("font_color", ITEM_TEXT)
	question.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(question)

	for choice_index in CHOICES.size():
		var label := Label.new()
		label.text = CHOICES[choice_index]
		label.position = Vector2(88 + 40 + choice_index * 44, 90)
		label.size = Vector2(32, 16)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 16)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(label)
		_labels.append(label)

	var hint := Label.new()
	hint.text = "PROGRESS IS SAVED WHEN YOU CHANGE IT"
	hint.position = Vector2(88, 112)
	hint.size = Vector2(144, 10)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 16)
	hint.add_theme_color_override("font_color", MUTED)
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hint)

	add_child(UiPromptLine.new("SELECT", "BACK"))
	_refresh()


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
		_labels[choice_index].text = "> %s <" % CHOICES[choice_index] if selected else CHOICES[choice_index]
		_labels[choice_index].add_theme_color_override("font_color",
			Color(0.949, 0.82, 0.227) if selected else MUTED)
