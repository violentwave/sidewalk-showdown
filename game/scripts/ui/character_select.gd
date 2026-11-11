# Text-only local two-player character-select mockup for the approved slice cast.
extends Control

signal match_requested(p1_data: FighterData, p2_data: FighterData)

const FIGHTERS: Array[FighterData] = [
	preload("res://resources/fighters/peg_leg_peggy.tres"),
	preload("res://resources/fighters/whiskey_richard.tres"),
]
const P1_ACCENT := Color(0.98, 0.64, 0.18)
const P2_ACCENT := Color(0.95, 0.34, 0.28)
const MUTED := Color(0.68, 0.66, 0.62)

var p1_choice := 0
var p2_choice := 1
var p1_locked := false
var p2_locked := false
var _cards: Array[Panel] = []
var _p1_marks: Array[Label] = []
var _p2_marks: Array[Label] = []
var _status: Label

func _ready() -> void:
	_build_ui()
	_refresh()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo():
		return
	var handled := true
	if event.is_action_pressed("p1_left"):
		_move_choice(1, -1)
	elif event.is_action_pressed("p1_right"):
		_move_choice(1, 1)
	elif event.is_action_pressed("p2_left"):
		_move_choice(2, -1)
	elif event.is_action_pressed("p2_right"):
		_move_choice(2, 1)
	elif event.is_action_pressed("p1_light") or event.is_action_pressed("ui_confirm"):
		_confirm(1)
	elif event.is_action_pressed("p2_light"):
		_confirm(2)
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
	_add_label("CHOOSE YOUR FIGHTER", Vector2(20, 30), Vector2(280, 12), 9,
		MUTED, HORIZONTAL_ALIGNMENT_CENTER)

	for fighter_index in FIGHTERS.size():
		var x := 22.0 + fighter_index * 140.0
		var card := Panel.new()
		card.position = Vector2(x, 50)
		card.size = Vector2(136, 76)
		card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(card)
		_cards.append(card)

		_add_label(FIGHTERS[fighter_index].display_name.to_upper(),
			Vector2(x + 5, 59), Vector2(126, 17), 11, Color(0.96, 0.91, 0.83),
			HORIZONTAL_ALIGNMENT_CENTER)
		_add_label("METHtality", Vector2(x + 5, 82), Vector2(126, 10), 8,
			MUTED, HORIZONTAL_ALIGNMENT_CENTER)
		_add_label(FIGHTERS[fighter_index].meth_name.to_upper(),
			Vector2(x + 5, 94), Vector2(126, 13), 9, Color(0.93, 0.75, 0.4),
			HORIZONTAL_ALIGNMENT_CENTER)

		var p1_mark := _add_label("", Vector2(x + 7, 108), Vector2(53, 10), 8,
			P1_ACCENT, HORIZONTAL_ALIGNMENT_LEFT)
		var p2_mark := _add_label("", Vector2(x + 76, 108), Vector2(53, 10), 8,
			P2_ACCENT, HORIZONTAL_ALIGNMENT_RIGHT)
		_p1_marks.append(p1_mark)
		_p2_marks.append(p2_mark)

	_add_label("P1: A / D TO MOVE   -   J TO CONFIRM",
		Vector2(8, 135), Vector2(150, 12), 7, P1_ACCENT, HORIZONTAL_ALIGNMENT_CENTER)
	_add_label("P2: ARROWS TO MOVE   -   NUM 1 TO CONFIRM",
		Vector2(162, 135), Vector2(150, 12), 7, P2_ACCENT, HORIZONTAL_ALIGNMENT_CENTER)
	_status = _add_label("BOTH PLAYERS CONFIRM TO START",
		Vector2(10, 155), Vector2(300, 12), 8, Color(0.9, 0.88, 0.82),
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

func _move_choice(player: int, direction: int) -> void:
	if player == 1:
		p1_choice = wrapi(p1_choice + direction, 0, FIGHTERS.size())
		p1_locked = false
	else:
		p2_choice = wrapi(p2_choice + direction, 0, FIGHTERS.size())
		p2_locked = false
	_refresh()

func _confirm(player: int) -> void:
	if player == 1:
		p1_locked = true
	else:
		p2_locked = true
	_refresh()
	if p1_locked and p2_locked:
		match_requested.emit(FIGHTERS[p1_choice], FIGHTERS[p2_choice])

func _refresh() -> void:
	for i in _cards.size():
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.13, 0.12, 0.13)
		style.set_border_width_all(2)
		style.border_color = Color(0.82, 0.78, 0.7)
		if i == p1_choice and i == p2_choice:
			style.border_color = Color(0.98, 0.87, 0.52)
		elif i == p1_choice:
			style.border_color = P1_ACCENT
		elif i == p2_choice:
			style.border_color = P2_ACCENT
		_cards[i].add_theme_stylebox_override("panel", style)
		_p1_marks[i].text = "P1 READY" if p1_choice == i and p1_locked else (
			"P1" if p1_choice == i else "")
		_p2_marks[i].text = "P2 READY" if p2_choice == i and p2_locked else (
			"P2" if p2_choice == i else "")

	if p1_locked and p2_locked:
		_status.text = "STARTING MATCH..."
	elif p1_locked:
		_status.text = "P1 READY  -  WAITING FOR P2"
	elif p2_locked:
		_status.text = "P2 READY  -  WAITING FOR P1"
	else:
		_status.text = "BOTH PLAYERS CONFIRM TO START"
