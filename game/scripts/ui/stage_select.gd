# Stage select: one shared stage choice between character select and the match.
# The list comes from the shared roster; RANDOM is always the last entry and is
# resolved here, before the match exists, using a non-gameplay RNG. The screen
# reports both the StageData and its stable id, so the flow never stores an
# index into a list that can be reordered.
extends Control

signal stage_chosen(stage: StageData, stage_id: String)
signal back_requested
signal selection_moved
signal selection_confirmed

const P1_ACCENT := Color(0.98, 0.64, 0.18)
const MUTED := Color(0.68, 0.66, 0.62)
const CARD_SIZE := Vector2(92, 74)
const CARD_Y := 46.0
const THUMBNAIL_SIZE := Vector2(80, 45)

@export var roster: MatchRoster
# Stable id restored when returning from a match; "" falls back to the first
# stage in the roster.
@export var initial_stage_id := ""

var stages: Array[StageData] = []
var index := 0
# The concrete stage picked by the last confirm, including a RANDOM result.
var resolved_stage_id := ""
var rng := RandomNumberGenerator.new()

var _cards: Array[Panel] = []
var _description: Label
var _chosen := false

func _ready() -> void:
	if roster == null:
		roster = MatchRoster.load_default()
	if roster != null:
		stages = roster.stages
	if stages.is_empty():
		push_error("StageSelect: roster has no stages")
		return
	rng.randomize()
	var restored := index_of_stage_id(initial_stage_id)
	if restored >= 0:
		index = restored
	_build_ui()
	_refresh()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo():
		return
	# As on character select, only the keyboard backs out; P2's pad must not
	# yank the shared stage choice away from P1.
	if event is InputEventKey and event.is_action_pressed("ui_back"):
		back_requested.emit()
		get_viewport().set_input_as_handled()
		return
	var handled := true
	if event.is_action_pressed("p1_left") or event.is_action_pressed("p2_left") \
			or event.is_action_pressed("p1_up") or event.is_action_pressed("p2_up"):
		_move(-1)
	elif event.is_action_pressed("p1_right") or event.is_action_pressed("p2_right") \
			or event.is_action_pressed("p1_down") or event.is_action_pressed("p2_down"):
		_move(1)
	elif event.is_action_pressed("p1_light") or event.is_action_pressed("p2_light") \
			or event.is_action_pressed("ui_confirm"):
		_choose()
	else:
		handled = false
	if handled:
		get_viewport().set_input_as_handled()

func stage_count() -> int:
	return stages.size() + 1

func random_index() -> int:
	return stages.size()

func index_of_stage_id(stage_id: String) -> int:
	for i in stages.size():
		if stages[i] != null and stages[i].id == stage_id:
			return i
	return -1

func selected_stage() -> StageData:
	if index < 0 or index >= stages.size():
		return null
	return stages[index]

func _build_ui() -> void:
	var background := ColorRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.color = Color(0.055, 0.05, 0.055)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	_add_label("SIDEWALK SHOWDOWN", Vector2(20, 9), Vector2(280, 20), 16,
		Color(1.0, 0.83, 0.48), HORIZONTAL_ALIGNMENT_CENTER)
	_add_label("CHOOSE YOUR STAGE", Vector2(20, 30), Vector2(280, 12), 9,
		MUTED, HORIZONTAL_ALIGNMENT_CENTER)

	for entry in stage_count():
		var x := 12.0 + entry * (CARD_SIZE.x + 8.0)
		var card := Panel.new()
		card.position = Vector2(x, CARD_Y)
		card.size = CARD_SIZE
		card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(card)
		_cards.append(card)

		var thumbnail := TextureRect.new()
		thumbnail.position = card.position + Vector2(6, 5)
		thumbnail.size = THUMBNAIL_SIZE
		thumbnail.mouse_filter = Control.MOUSE_FILTER_IGNORE
		thumbnail.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		thumbnail.stretch_mode = TextureRect.STRETCH_KEEP
		if entry < stages.size() and stages[entry] != null:
			thumbnail.texture = stages[entry].thumbnail
		add_child(thumbnail)

		if entry == random_index():
			var mark := _add_label("?", card.position + Vector2(6, 5),
				THUMBNAIL_SIZE, 30, Color(0.93, 0.75, 0.4),
				HORIZONTAL_ALIGNMENT_CENTER)
			mark.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			_add_label("RANDOM", card.position + Vector2(4, 53),
				Vector2(CARD_SIZE.x - 8, 16), 8, Color(0.96, 0.91, 0.83),
				HORIZONTAL_ALIGNMENT_CENTER)
		else:
			var name_label := _add_label(stages[entry].display_name.to_upper(),
				card.position + Vector2(4, 52), Vector2(CARD_SIZE.x - 8, 18), 7,
				Color(0.96, 0.91, 0.83), HORIZONTAL_ALIGNMENT_CENTER)
			name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			name_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP

	_description = _add_label("", Vector2(16, 124), Vector2(288, 18), 7, MUTED,
		HORIZONTAL_ALIGNMENT_CENTER)
	_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	_add_label("A/D OR STICK MOVE   -   J/X CONFIRM   -   BACKSPACE BACK",
		Vector2(8, 150), Vector2(304, 10), 7, P1_ACCENT,
		HORIZONTAL_ALIGNMENT_CENTER)
	_add_label("THE MATCH STARTS ON THE STAGE YOU PICK",
		Vector2(8, 163), Vector2(304, 10), 7, MUTED,
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
	index = wrapi(index + direction, 0, stage_count())
	_refresh()
	selection_moved.emit()

func _choose() -> void:
	if _chosen or stages.is_empty():
		return
	_chosen = true
	selection_confirmed.emit()
	var stage: StageData = selected_stage()
	if stage == null:
		# RANDOM: draw once, before the match is created, from a visual/meta RNG
		# that is never part of the deterministic fight simulation.
		stage = stages[rng.randi_range(0, stages.size() - 1)]
	resolved_stage_id = stage.id
	stage_chosen.emit(stage, stage.id)

func _refresh() -> void:
	for i in _cards.size():
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.17, 0.155, 0.15) if i == index else Color(0.13, 0.12, 0.13)
		style.set_border_width_all(2)
		style.border_color = P1_ACCENT if i == index else Color(0.5, 0.47, 0.42)
		_cards[i].add_theme_stylebox_override("panel", style)

	var stage := selected_stage()
	if stage == null:
		_description.text = "A random stage is drawn before the match."
	elif stage.description.is_empty():
		_description.text = stage.display_name
	else:
		_description.text = stage.description
