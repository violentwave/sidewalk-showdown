# Difficulty select: solo-only screen after 1 PLAYER is chosen. Same text-only
# menu style and input conventions as ModeSelect (A/D or W/S move, J or click
# start, Backspace back). Defaults to NORMAL.
extends Control

signal difficulty_chosen(level: int)
signal selection_moved
signal selection_confirmed
signal back_requested

const P1_ACCENT := Color(0.98, 0.64, 0.18)
const MUTED := Color(0.68, 0.66, 0.62)

const LEVELS := [
	{
		"name": "EASY",
		"detail": "SLOW REACTIONS - OFTEN MISSES BLOCKS",
	},
	{
		"name": "NORMAL",
		"detail": "SOLID DEFENSE - FAIR FIGHT",
	},
	{
		"name": "HARD",
		"detail": "FAST REACTIONS - ANTI-AIRS AND PUNISHES",
	},
]

var index := 1
var _cards: Array[Panel] = []
var _chosen := false

func _ready() -> void:
	_build_ui()
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

func _build_ui() -> void:
	var background := ColorRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.color = Color(0.055, 0.05, 0.055)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	_add_label("SIDEWALK SHOWDOWN", Vector2(20, 9), Vector2(280, 20), 16,
		Color(1.0, 0.83, 0.48), HORIZONTAL_ALIGNMENT_CENTER)
	_add_label("SELECT CPU DIFFICULTY", Vector2(20, 31), Vector2(280, 12), 9,
		MUTED, HORIZONTAL_ALIGNMENT_CENTER)

	for level_index in LEVELS.size():
		var y := 50.0 + level_index * 46.0
		var card := Panel.new()
		card.position = Vector2(30, y)
		card.size = Vector2(260, 38)
		card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(card)
		_cards.append(card)
		var level: Dictionary = LEVELS[level_index]
		_add_label(str(level["name"]), Vector2(36, y + 5), Vector2(248, 15), 12,
			Color(0.96, 0.91, 0.83), HORIZONTAL_ALIGNMENT_CENTER)
		_add_label(str(level["detail"]), Vector2(36, y + 21), Vector2(248, 11), 7,
			MUTED, HORIZONTAL_ALIGNMENT_CENTER)

	_add_label("W/S OR A/D MOVE   -   J OR CLICK START   -   BACKSPACE BACK",
		Vector2(8, 144), Vector2(304, 10), 7, P1_ACCENT,
		HORIZONTAL_ALIGNMENT_CENTER)
	_add_label("P1 PICKS BOTH FIGHTERS - P2 IS THE CPU",
		Vector2(8, 158), Vector2(304, 10), 7, MUTED,
		HORIZONTAL_ALIGNMENT_CENTER)

func _add_label(text: String, at: Vector2, dimensions: Vector2, font_size: int,
		color: Color, alignment: HorizontalAlignment) -> Label:
	var label := Label.new()
	label.position = at
	label.size = dimensions
	label.text = text
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	return label

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
	for i in _cards.size():
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.17, 0.155, 0.15) if i == index else Color(0.13, 0.12, 0.13)
		style.set_border_width_all(2)
		style.border_color = P1_ACCENT if i == index else Color(0.5, 0.47, 0.42)
		_cards[i].add_theme_stylebox_override("panel", style)
