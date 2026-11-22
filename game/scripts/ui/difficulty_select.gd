# Difficulty select: solo-only screen after 1 PLAYER is chosen. Street-junk
# reskin (PR A): dimmed Gas-N-Go art, one centered cardboard ui_panel with a
# "CPU LEVEL" header, the three levels as full-width rows (names and order
# unchanged) each with a code-drawn tally-mark difficulty (1/2/3 one-pixel
# ink marks), and the focused level's description on the prompt plate.
# Input contract unchanged (A/D or W/S move, J/click or Enter confirm,
# Backspace back). Defaults to NORMAL.
extends Control

signal difficulty_chosen(level: int)
signal selection_moved
signal selection_confirmed
signal back_requested

const STAGE_SCENE := preload("res://scenes/stages/gas_n_go.tscn")
const THEME_RESOURCE := preload("res://resources/ui_theme.tres")

const PANEL_POS := Vector2(96, 40)
const PANEL_SIZE := Vector2(128, 88)
const ROW_X := 8.0
const ROW_W := 112.0
const ROW_Y := [28.0, 46.0, 64.0]

# Tally marks sit at the right end of each row: `count` one-pixel-wide
# vertical ink strokes, 5 px tall, 2 px apart.
const TALLY_X := 100.0
const TALLY_Y_OFFSET := 2.0

const LEVELS := [
	{
		"name": "EASY",
		"detail": "SLOW REACTIONS - OFTEN MISSES BLOCKS",
		"marks": 1,
	},
	{
		"name": "NORMAL",
		"detail": "SOLID DEFENSE - FAIR FIGHT",
		"marks": 2,
	},
	{
		"name": "HARD",
		"detail": "FAST REACTIONS - ANTI-AIRS AND PUNISHES",
		"marks": 3,
	},
]

var index := 1
var _rows: Array[Label] = []
var _tallies: Array = []
var _bars: Array[ColorRect] = []
var _prompt: UiPromptLine
var _chosen := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var background: Node2D = STAGE_SCENE.instantiate()
	add_child(background)
	add_child(UiText.dim_overlay())

	var panel := Panel.new()
	panel.theme = THEME_RESOURCE
	panel.position = PANEL_POS
	panel.size = PANEL_SIZE
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel)

	var header := UiText.marker("CPU LEVEL", Vector2(PANEL_POS.x, PANEL_POS.y + 6),
		UiText.INK)
	header.size = Vector2(PANEL_SIZE.x, UiText.MARKER_LINE_HEIGHT)
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(header)

	for level_index in LEVELS.size():
		var bar := UiText.focus_bar(
			PANEL_POS + Vector2(ROW_X, ROW_Y[level_index] - 1),
			Vector2(ROW_W, 12))
		add_child(bar)
		_bars.append(bar)
		var label := UiText.marker(str(LEVELS[level_index]["name"]),
			PANEL_POS + Vector2(ROW_X, ROW_Y[level_index]), UiText.INK)
		label.size = Vector2(ROW_W - 24, UiText.MARKER_LINE_HEIGHT)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		add_child(label)
		_rows.append(label)
		var marks: Array[ColorRect] = []
		var count := int(LEVELS[level_index]["marks"])
		for mark in count:
			var stroke := ColorRect.new()
			stroke.color = UiText.INK
			stroke.position = PANEL_POS + Vector2(
				TALLY_X + mark * 3.0, ROW_Y[level_index] + TALLY_Y_OFFSET)
			stroke.size = Vector2(1, 8)
			stroke.mouse_filter = Control.MOUSE_FILTER_IGNORE
			add_child(stroke)
			marks.append(stroke)
		_tallies.append(marks)

	_prompt = UiPromptLine.new("SELECT", "BACK", str(LEVELS[index]["detail"]))
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
	elif event is InputEventKey and event.pressed \
			and event.keycode == KEY_BACKSPACE and not event.is_echo():
		_back()
	else:
		handled = false
	if handled:
		get_viewport().set_input_as_handled()


func _move(direction: int) -> void:
	index = wrapi(index + direction, 0, LEVELS.size())
	_refresh()
	selection_moved.emit()


func _choose() -> void:
	if _chosen:
		return
	_chosen = true
	selection_confirmed.emit()
	difficulty_chosen.emit(index)


func _back() -> void:
	if _chosen:
		return
	back_requested.emit()


func _refresh() -> void:
	for level_index in _rows.size():
		var focused := level_index == index
		_bars[level_index].visible = focused
		_rows[level_index].add_theme_color_override("font_color",
			UiText.INK_DARK if focused else UiText.INK)
		for stroke in _tallies[level_index]:
			stroke.color = UiText.INK_DARK if focused else UiText.INK
	_prompt.set_left_text(str(LEVELS[index]["detail"]))
