# Mode select: choose solo (P1 picks both fighters) or local versus before
# the character-select screen. Street-junk reskin (PR A): the Gas-N-Go
# night art dimmed 55%, one centered cardboard ui_panel with a "VERSUS"
# header, the two choices as full-width rows with the yellow focus bar,
# and the focused choice's description on the prompt plate at the bottom.
# Input contract unchanged (A/D or W/S move, J/click or Enter confirm,
# Backspace back).
extends Control

signal mode_chosen(solo: bool)
signal back_requested
signal selection_moved
signal selection_confirmed

const STAGE_SCENE := preload("res://scenes/stages/gas_n_go.tscn")
const THEME_RESOURCE := preload("res://resources/ui_theme.tres")

const PANEL_POS := Vector2(96, 44)
const PANEL_SIZE := Vector2(128, 76)
const ROW_X := 8.0
const ROW_W := 112.0
const ROW_Y := [26.0, 46.0]

const MODES := [
	{
		"name": "1 PLAYER",
		"detail": "Fight the CPU.",
	},
	{
		"name": "2 PLAYERS",
		"detail": "Grab a friend and a second controller.",
	},
]

# Default to solo: the immediate use case is testing without a controller, and
# a versus pair only needs one keypress to move over.
var index := 0
var _rows: Array[Label] = []
var _bars: Array[ColorRect] = []
var _prompt: UiPromptLine
var _chosen := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var background: Node2D = STAGE_SCENE.instantiate()
	# Stage ambient sprites (the mosquitoes) use z_index 10; push the whole
	# backdrop below the UI so nothing flies over panels or text.
	background.z_index = -20
	add_child(background)
	add_child(UiText.dim_overlay())

	var panel := Panel.new()
	panel.theme = THEME_RESOURCE
	panel.position = PANEL_POS
	panel.size = PANEL_SIZE
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel)

	var header := UiText.marker("VERSUS", Vector2(PANEL_POS.x, PANEL_POS.y + 6),
		UiText.INK)
	header.size = Vector2(PANEL_SIZE.x, UiText.MARKER_LINE_HEIGHT)
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(header)

	for mode_index in MODES.size():
		var bar := UiText.focus_bar(
			PANEL_POS + Vector2(ROW_X, ROW_Y[mode_index] - 1),
			Vector2(ROW_W, 12))
		add_child(bar)
		_bars.append(bar)
		var label := UiText.marker(str(MODES[mode_index]["name"]),
			PANEL_POS + Vector2(ROW_X, ROW_Y[mode_index]), UiText.INK)
		label.size = Vector2(ROW_W, UiText.MARKER_LINE_HEIGHT)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		add_child(label)
		_rows.append(label)

	_prompt = UiPromptLine.new("SELECT", "BACK", str(MODES[0]["detail"]))
	add_child(_prompt)
	_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo():
		return
	var handled := true
	if event.is_action_pressed("p1_left") or event.is_action_pressed("p1_up"):
		_move(-1)
	elif event.is_action_pressed("p1_right") or event.is_action_pressed("p1_down"):
		_move(1)
	elif event.is_action_pressed("p1_light") or event.is_action_pressed("ui_confirm"):
		_choose()
	elif event.is_action_pressed("ui_back"):
		back_requested.emit()
	else:
		handled = false
	if handled:
		get_viewport().set_input_as_handled()


func _move(direction: int) -> void:
	index = wrapi(index + direction, 0, MODES.size())
	_refresh()
	selection_moved.emit()


func _choose() -> void:
	if _chosen:
		return
	_chosen = true
	selection_confirmed.emit()
	mode_chosen.emit(index == 0)


func _refresh() -> void:
	for mode_index in _rows.size():
		var focused := mode_index == index
		_bars[mode_index].visible = focused
		_rows[mode_index].add_theme_color_override("font_color",
			UiText.INK_DARK if focused else UiText.INK)
	_prompt.set_left_text(str(MODES[index]["detail"]))
