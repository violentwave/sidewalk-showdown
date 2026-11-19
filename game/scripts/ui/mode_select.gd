# Mode select: choose solo (P1 picks both fighters) or local versus before the
# character-select screen. Text-only, matching the existing menu style.
extends Control

signal mode_chosen(solo: bool)
signal selection_moved
signal selection_confirmed

const P1_ACCENT := Color(0.98, 0.64, 0.18)
const MUTED := Color(0.68, 0.66, 0.62)

const MODES := [
	{
		"name": "1 PLAYER",
		"detail": "PICK BOTH FIGHTERS - P2 IS THE CPU",
	},
	{
		"name": "2 PLAYERS",
		"detail": "P1 KEYBOARD + MOUSE - P2 CONTROLLER",
	},
]

# Default to solo: the immediate use case is testing without a controller, and
# a versus pair only needs one keypress to move over.
var index := 0
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
	_add_label("SELECT MODE", Vector2(20, 31), Vector2(280, 12), 9,
		MUTED, HORIZONTAL_ALIGNMENT_CENTER)

	for mode_index in MODES.size():
		var y := 50.0 + mode_index * 46.0
		var card := Panel.new()
		card.position = Vector2(30, y)
		card.size = Vector2(260, 38)
		card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(card)
		_cards.append(card)
		var mode: Dictionary = MODES[mode_index]
		_add_label(str(mode["name"]), Vector2(36, y + 5), Vector2(248, 15), 12,
			Color(0.96, 0.91, 0.83), HORIZONTAL_ALIGNMENT_CENTER)
		_add_label(str(mode["detail"]), Vector2(36, y + 21), Vector2(248, 11), 7,
			MUTED, HORIZONTAL_ALIGNMENT_CENTER)

	_add_label("W/S OR A/D MOVE   -   J OR CLICK START",
		Vector2(8, 144), Vector2(304, 10), 7, P1_ACCENT,
		HORIZONTAL_ALIGNMENT_CENTER)
	_add_label("P1 IS KEYBOARD + MOUSE   -   P2 NEEDS A CONTROLLER",
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
	for i in _cards.size():
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.17, 0.155, 0.15) if i == index else Color(0.13, 0.12, 0.13)
		style.set_border_width_all(2)
		style.border_color = P1_ACCENT if i == index else Color(0.5, 0.47, 0.42)
		_cards[i].add_theme_stylebox_override("panel", style)
