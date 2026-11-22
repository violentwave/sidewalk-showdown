# Stage select, street-junk reskin (PR A): every stage is a scratch-off
# lottery ticket (stage/stage_scratch_ticket.png) with its 80x45 thumbnail
# center-cropped into the ticket's measured silver panel (36x16 at local
# x 18..53 / y 16..31 — a crop, never a non-integer scale) and its name in
# Marker under it. The focused ticket lifts 2 px with a 1 px yellow frame.
# RANDOM stays covered; confirming it plays an 18-frame integer-pixel
# scratch-off reveal of the drawn stage before the same hand-off as a
# concrete pick. The random source is exactly the screen's existing
# visual/meta RNG (never part of the deterministic fight simulation), and
# the list, wrap order, ids, and signals are unchanged.
extends Control

signal stage_chosen(stage: StageData, stage_id: String)
signal back_requested
signal selection_moved
signal selection_confirmed

const STAGE_SCENE := preload("res://scenes/stages/gas_n_go.tscn")
const TICKET := preload("res://art/ui/stage/stage_scratch_ticket.png")

const TICKET_SIZE := Vector2(72, 44)
const TICKET_Y := 46.0
const TICKET_X := [28.0, 124.0, 220.0]
# Measured silver panel inside the ticket art (local space).
const SILVER_POS := Vector2(18, 16)
const SILVER_SIZE := Vector2(36, 16)
# The reveal: 18 one-frame steps clear 18 cover columns over the silver.
const REVEAL_FRAMES := 18
const REVEAL_COLUMNS := 18

@export var roster: MatchRoster
# Stable id restored when returning from a match; "" falls back to the first
# stage in the roster.
@export var initial_stage_id := ""

var stages: Array[StageData] = []
var index := 0
# The concrete stage picked by the last confirm, including a RANDOM result.
var resolved_stage_id := ""
var rng := RandomNumberGenerator.new()

# Ticket visuals, indexed 0..stages.size() (RANDOM last).
var _tickets: Array[TextureRect] = []
var _thumbnails: Array[TextureRect] = []
var _frames: Array[Control] = []
var _chosen := false
# RANDOM scratch-off state.
var _reveal_stage: StageData = null
var _reveal_frame := 0
var _reveal_covers: Array[ColorRect] = []


# A 1 px focus frame drawn around the lifted ticket.
class TicketFrame extends Control:
	func _draw() -> void:
		draw_rect(Rect2(0, 0, size.x, size.y), UiText.YELLOW, false, 1.0)


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
	# yank the shared stage choice away from P1. No input leaves mid-reveal.
	if event is InputEventKey and event.is_action_pressed("ui_back"):
		if _reveal_stage == null:
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


# Center-crop an 80x45 thumbnail into the ticket's silver panel: an integer
# region select on the source art, never a scale.
func _silver_crop(thumbnail: Texture2D) -> AtlasTexture:
	var crop := AtlasTexture.new()
	crop.atlas = thumbnail
	var source := thumbnail.get_size()
	var region := Rect2(
		(source.x - SILVER_SIZE.x) / 2.0, (source.y - SILVER_SIZE.y) / 2.0,
		SILVER_SIZE.x, SILVER_SIZE.y)
	crop.region = Rect2i(region.position.round(), SILVER_SIZE)
	return crop


func _ticket_pos(entry: int) -> Vector2:
	var x: float = TICKET_X[entry] if entry < TICKET_X.size() \
		else TICKET_X[0] + entry * (TICKET_SIZE.x + 24.0)
	return Vector2(x, TICKET_Y)


func _build_ui() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var background: Node2D = STAGE_SCENE.instantiate()
	add_child(background)
	add_child(UiText.dim_overlay())

	# "PICK YOUR SPOT" over the art: outlined marker.
	var header := UiText.marker("PICK YOUR SPOT", Vector2(0, 12), Color.WHITE, true)
	header.size = Vector2(320, UiText.MARKER_LINE_HEIGHT)
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(header)

	for entry in stage_count():
		var at := _ticket_pos(entry)
		var ticket := TextureRect.new()
		ticket.texture = TICKET
		ticket.position = at
		ticket.size = TICKET_SIZE
		ticket.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ticket.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		add_child(ticket)
		_tickets.append(ticket)

		# The thumbnail sits IN the ticket's silver panel (a crop, not a
		# scale); RANDOM stays covered with a "?".
		var thumbnail := TextureRect.new()
		thumbnail.position = at + SILVER_POS
		thumbnail.size = SILVER_SIZE
		thumbnail.mouse_filter = Control.MOUSE_FILTER_IGNORE
		thumbnail.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		if entry < stages.size() and stages[entry] != null:
			thumbnail.texture = _silver_crop(stages[entry].thumbnail)
		add_child(thumbnail)
		_thumbnails.append(thumbnail)

		if entry == random_index():
			var question := UiText.marker("?", at + SILVER_POS + Vector2(0, 1),
				Color.WHITE, true)
			question.size = Vector2(SILVER_SIZE.x, 12)
			question.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			add_child(question)
			var random_note := UiText.marker("RANDOM", Vector2(at.x, at.y + 46),
				Color.WHITE, true)
			random_note.size = Vector2(TICKET_SIZE.x, UiText.MARKER_LINE_HEIGHT)
			random_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			add_child(random_note)
		else:
			var name_label := UiText.marker(stages[entry].display_name.to_upper(),
				Vector2(at.x, at.y + 46), Color.WHITE, true)
			name_label.size = Vector2(TICKET_SIZE.x, UiText.MARKER_LINE_HEIGHT)
			name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			add_child(name_label)

		var frame := TicketFrame.new()
		frame.position = at
		frame.size = TICKET_SIZE
		frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frame.visible = false
		add_child(frame)
		_frames.append(frame)

	add_child(UiPromptLine.new("CONFIRM", "BACK"))
	_refresh()


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
		_begin_reveal(stage)
		return
	resolved_stage_id = stage.id
	stage_chosen.emit(stage, stage.id)


# The RANDOM scratch-off: the drawn stage's thumbnail appears in the RANDOM
# ticket's silver panel under 18 cover columns; one column clears per frame,
# then the hand-off fires exactly like a concrete pick.
func _begin_reveal(stage: StageData) -> void:
	_reveal_stage = stage
	_reveal_frame = 0
	var at := _ticket_pos(random_index())
	_thumbnails[random_index()].texture = _silver_crop(stage.thumbnail)
	_reveal_covers.clear()
	for column in REVEAL_COLUMNS:
		var cover := ColorRect.new()
		cover.color = Color(0.83, 0.83, 0.83)  # the ticket's silver tone
		cover.position = at + SILVER_POS + Vector2(column * (SILVER_SIZE.x / REVEAL_COLUMNS), 0)
		cover.size = Vector2(ceil(SILVER_SIZE.x / REVEAL_COLUMNS), SILVER_SIZE.y)
		cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(cover)
		_reveal_covers.append(cover)


func _physics_process(_delta: float) -> void:
	if _reveal_stage == null:
		return
	if _reveal_frame < REVEAL_FRAMES:
		var clear_count := _reveal_frame + 1
		for cover_index in _reveal_covers.size():
			_reveal_covers[cover_index].visible = cover_index >= clear_count
		_reveal_frame += 1
		return
	# 18 frames done: same hand-off as a concrete pick.
	for cover in _reveal_covers:
		cover.queue_free()
	_reveal_covers.clear()
	var stage: StageData = _reveal_stage
	_reveal_stage = null
	resolved_stage_id = stage.id
	stage_chosen.emit(stage, stage.id)


func _refresh() -> void:
	for i in _tickets.size():
		var focused := i == index
		# The focused ticket lifts 2 px and gets the 1 px yellow frame.
		var lift := -2.0 if focused else 0.0
		_tickets[i].position = _ticket_pos(i) + Vector2(0, lift)
		_thumbnails[i].position = _ticket_pos(i) + SILVER_POS + Vector2(0, lift)
		_frames[i].position = _ticket_pos(i) + Vector2(0, lift)
		_frames[i].visible = focused
		# Ticket names/notes sit under the tickets and do not move with them.
