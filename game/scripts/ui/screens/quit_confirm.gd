# QuitConfirm — the "Leave the sidewalk?" modal (an overlay: pushed without
# freeing the screen below). YES / NO on one row with the selection
# defaulting to NO. Used from the main menu, the title screen, and the
# pause menu (where it must keep working while the tree is paused, hence
# PROCESS_MODE_ALWAYS). One small centered ui_panel: dark ink text on the
# cardboard; the focused choice sits on a yellow highlight bar with the
# darkest ink (docs/UI_SCREENS.md contrast rules).
extends Control

signal quit_confirmed
signal dismissed

const THEME_RESOURCE := preload("res://resources/ui_theme.tres")
const CHOICES := ["YES", "NO"]

const PANEL_POS := Vector2(76, 54)
const PANEL_SIZE := Vector2(168, 64)
const CHOICE_ROW_Y := 84
# Each choice is a 40x12 row (1 px pad top/bottom on the 12 px bar).
const CHOICE_W := 40.0
const CHOICE_GAP := 24.0

# The brief requires the default answer to be NO.
var index := 1
var _labels: Array[Label] = []
var _bars: Array[ColorRect] = []


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
		Vector2(PANEL_POS.x, PANEL_POS.y + 8), UiText.INK)
	question.size = Vector2(PANEL_SIZE.x, UiText.MARKER_LINE_HEIGHT)
	question.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(question)

	for choice_index in CHOICES.size():
		var bar := UiText.focus_bar(Vector2.ZERO, Vector2(CHOICE_W, 12))
		add_child(bar)
		_bars.append(bar)
		var label := UiText.marker(CHOICES[choice_index], Vector2.ZERO,
			UiText.INK)
		label.size = Vector2(CHOICE_W, UiText.MARKER_LINE_HEIGHT)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		add_child(label)
		_labels.append(label)

	add_child(UiPromptLine.new("SELECT", "BACK"))
	_layout_choices()
	_refresh()


func _layout_choices() -> void:
	# YES / NO centered on the row, each with its yellow-bar slot.
	var start_x := 160.0 - (CHOICE_W * 2.0 + CHOICE_GAP) / 2.0
	for choice_index in CHOICES.size():
		var x := roundi(start_x + choice_index * (CHOICE_W + CHOICE_GAP))
		_bars[choice_index].position = Vector2(x, CHOICE_ROW_Y - 1)
		_bars[choice_index].size = Vector2(CHOICE_W, 12)
		_labels[choice_index].position = Vector2(x, CHOICE_ROW_Y - 1)


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
		_bars[choice_index].visible = selected
		_labels[choice_index].text = CHOICES[choice_index]
		_labels[choice_index].add_theme_color_override("font_color",
			UiText.INK_DARK if selected else UiText.INK)
