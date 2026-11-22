# Character select, street-junk reskin (PR A): a booking-room mugshot wall
# (select/select_mugshot_bg.png) with each playable fighter's
# select_portrait_<fighter>.png on the height chart, a rap sheet
# (select_rap_sheet.png) showing the focused fighter's booking details, and
# code-drawn marker-scribble cursors: an orange irregular circle for P1, a
# red irregular box for P2 (fixed point lists — no RNG). In versus mode each
# player drives their own cursor; in solo mode P1 picks both fighters in
# turn. Every behavior, pick, and signal from the text-only screen is kept;
# there is no palette cycling to preserve (none shipped).
extends Control

signal match_requested(p1_data: FighterData, p2_data: FighterData)
signal selection_moved
signal selection_confirmed
# Backspace (or P1's back action) leaving the screen, or stepping back one
# choice in solo mode.
signal back_requested

const THEME_RESOURCE := preload("res://resources/ui_theme.tres")
const MUGSHOT_BG := preload("res://art/ui/select/select_mugshot_bg.png")
const RAP_SHEET := preload("res://art/ui/select/select_rap_sheet.png")

const P1_ACCENT := Color("f29e26")   # #f29e26
const P2_ACCENT := Color("e5473a")   # #e5473a

# 64x64 portraits against the height chart, P1 column then P2 column.
const PORTRAIT_Y := 30.0
const PORTRAIT_X := [44.0, 148.0]
const PORTRAIT_SIZE := Vector2(64, 64)

# Rap sheet on the right, beside the focused fighter's column.
const SHEET_POS := Vector2(236, 42)
const SHEET_SIZE := Vector2(76, 66)

# Owner-editable booking copy (FighterData carries no archetype/tagline/
# difficulty fields — this is presentation copy, like the chat seeds, not
# invented data). "marks" is the pick-up difficulty tally.
const RAP_SHEETS := {
	"peg_leg_peggy": {
		"archetype": "ASSAULT, PROSTHETIC LEG",
		"tagline": "hops in on one leg swinging",
		"marks": 2,
	},
	"whiskey_richard": {
		"archetype": "GRAPPLER, SIPS BETWEEN COMBOS",
		"tagline": "smells like a bar mat",
		"marks": 3,
	},
}

# Portrait art per fighter id; a fighter without an entry gets a framed
# blank on the wall instead of a crash.
const PORTRAITS := {
	"peg_leg_peggy": "res://art/ui/select/select_portrait_pegleg_peg.png",
	"whiskey_richard": "res://art/ui/select/select_portrait_whiskey_richard.png",
}

# Set by Main from the mode-select screen. Solo means P1 picks both fighters and
# the match spawns P2 with input disabled.
@export var roster: MatchRoster
var FIGHTERS: Array[FighterData] = []

# Set by Main when returning from a match so the cursor restores the matchup
# that was just played. -1 means "use the defaults".
@export var solo := false
@export var initial_p1_choice := -1
@export var initial_p2_choice := -1

var p1_choice := 0
var p2_choice := 1
var p1_locked := false
var p2_locked := false
# Solo only: 1 = P1 is choosing, 2 = P1 is choosing the opponent.
var active_side := 1
# The rap sheet follows whoever moved last (P1 by default).
var focus_side := 1
var _p1_marks: Array[Label] = []
var _p2_marks: Array[Label] = []
var _status: Label
var _portraits: Array[TextureRect] = []
var _p1_scribble: Control
var _p2_scribble: Control
var _sheet_name: Label
var _sheet_archetype: Label
var _sheet_tagline: Label
var _sheet_tally: Array[ColorRect] = []


# A code-drawn marker scribble cursor: 1 px lines, fixed irregular point
# lists, no RNG. kind 0 = P1's lopsided circle, kind 1 = P2's boxy frame.
class ScribbleCursor extends Control:
	var kind := 0
	var accent := Color.WHITE

	func _draw() -> void:
		if kind == 0:
			# Lopsided circle: an octagon-ish loop with fixed jitter.
			var points := PackedVector2Array([
				Vector2(12, 2), Vector2(42, 1), Vector2(55, 8), Vector2(62, 20),
				Vector2(61, 46), Vector2(52, 58), Vector2(28, 63), Vector2(8, 55),
				Vector2(1, 34), Vector2(3, 14), Vector2(12, 2),
			])
			draw_polyline(points, accent, 1.0)
		else:
			# Irregular box: corners nudged off the grid.
			var points := PackedVector2Array([
				Vector2(2, 3), Vector2(62, 1), Vector2(63, 61), Vector2(1, 62),
				Vector2(2, 3),
			])
			draw_polyline(points, accent, 1.0)


func _ready() -> void:
	if roster == null:
		roster = MatchRoster.load_default()
	if roster != null:
		FIGHTERS = roster.fighters
	if FIGHTERS.size() < 2:
		push_error("CharacterSelect: roster needs at least two fighters")
		return
	p2_choice = 1
	if initial_p1_choice >= 0 and initial_p1_choice < FIGHTERS.size():
		p1_choice = initial_p1_choice
	if initial_p2_choice >= 0 and initial_p2_choice < FIGHTERS.size():
		p2_choice = initial_p2_choice
	_build_ui()
	_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo():
		return
	# Only the keyboard backs out, so P2's pad B (special) cannot yank a versus
	# pair off the select screen.
	if event is InputEventKey and event.is_action_pressed("ui_back"):
		_back()
		get_viewport().set_input_as_handled()
		return
	var handled := true
	if solo:
		handled = _solo_input(event)
	else:
		handled = _versus_input(event)
	if handled:
		get_viewport().set_input_as_handled()


func _solo_input(event: InputEvent) -> bool:
	if event.is_action_pressed("p1_left"):
		_move_choice(active_side, -1)
	elif event.is_action_pressed("p1_right"):
		_move_choice(active_side, 1)
	elif event.is_action_pressed("p1_light") or event.is_action_pressed("ui_confirm"):
		_confirm(active_side)
	else:
		return false
	return true


func _versus_input(event: InputEvent) -> bool:
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
		return false
	return true


func _build_ui() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var background := TextureRect.new()
	background.texture = MUGSHOT_BG
	background.position = Vector2.ZERO
	background.size = Vector2(320, 180)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(background)

	# "BOOKING" header over the art: outlined marker so it reads on the wall.
	var header := UiText.marker("BOOKING", Vector2(0, 8), Color.WHITE, true)
	header.size = Vector2(320, UiText.MARKER_LINE_HEIGHT)
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(header)

	for fighter_index in FIGHTERS.size():
		var x: float = PORTRAIT_X[fighter_index] if fighter_index < PORTRAIT_X.size() \
			else PORTRAIT_X[0] + fighter_index * 104.0
		var portrait := TextureRect.new()
		portrait.position = Vector2(x, PORTRAIT_Y)
		portrait.size = PORTRAIT_SIZE
		portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
		portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		var art_path := str(PORTRAITS.get(FIGHTERS[fighter_index].id, ""))
		if not art_path.is_empty() and ResourceLoader.exists(art_path):
			portrait.texture = load(art_path)
		add_child(portrait)
		_portraits.append(portrait)

		var p1_mark := UiText.marker("", Vector2(x + 2, 96), P1_ACCENT, true)
		p1_mark.size = Vector2(30, UiText.MARKER_LINE_HEIGHT)
		add_child(p1_mark)
		_p1_marks.append(p1_mark)
		var p2_mark := UiText.marker("", Vector2(x + 34, 96), P2_ACCENT, true)
		p2_mark.size = Vector2(30, UiText.MARKER_LINE_HEIGHT)
		p2_mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		add_child(p2_mark)
		_p2_marks.append(p2_mark)

	# Rap sheet with the focused fighter's booking details, dark ink in the
	# ruled area (name from FighterData; archetype/tagline/tally are the
	# owner-editable presentation copy in RAP_SHEETS).
	var sheet := TextureRect.new()
	sheet.texture = RAP_SHEET
	sheet.position = SHEET_POS
	sheet.size = SHEET_SIZE
	sheet.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sheet.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(sheet)

	_sheet_name = UiText.body("", SHEET_POS + Vector2(4, 5), UiText.INK)
	_sheet_name.size = Vector2(68, UiText.M5X7_LINE_HEIGHT)
	add_child(_sheet_name)
	_sheet_archetype = UiText.body("", SHEET_POS + Vector2(4, 19), UiText.INK_MUTED)
	_sheet_archetype.size = Vector2(68, UiText.M5X7_LINE_HEIGHT)
	add_child(_sheet_archetype)
	_sheet_tagline = UiText.body("", SHEET_POS + Vector2(4, 34), UiText.INK)
	_sheet_tagline.size = Vector2(68, UiText.M5X7_LINE_HEIGHT)
	add_child(_sheet_tagline)
	for mark in 3:
		var stroke := ColorRect.new()
		stroke.color = UiText.INK
		stroke.position = SHEET_POS + Vector2(4 + mark * 3.0, 52)
		stroke.size = Vector2(1, 8)
		stroke.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stroke.visible = false
		add_child(stroke)
		_sheet_tally.append(stroke)

	# Cursors: code-drawn scribbles around the focused portraits.
	_p1_scribble = ScribbleCursor.new()
	_p1_scribble.kind = 0
	_p1_scribble.accent = P1_ACCENT
	_p1_scribble.size = Vector2(64, 64)
	_p1_scribble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_p1_scribble)
	_p2_scribble = ScribbleCursor.new()
	_p2_scribble.kind = 1
	_p2_scribble.accent = P2_ACCENT
	_p2_scribble.size = Vector2(64, 64)
	_p2_scribble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_p2_scribble)

	# Status and the stage hand-off note, outlined marker over the wall art.
	_status = UiText.marker("", Vector2(0, 138), UiText.MUTED, true)
	_status.size = Vector2(320, UiText.MARKER_LINE_HEIGHT)
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_status)
	var stage_note := UiText.marker("STAGE: CHOOSE NEXT", Vector2(0, 152),
		UiText.MUTED, true)
	stage_note.size = Vector2(320, UiText.MARKER_LINE_HEIGHT)
	stage_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(stage_note)

	add_child(UiPromptLine.new("CONFIRM", "BACK"))


func _move_choice(player: int, direction: int) -> void:
	if player == 1:
		p1_choice = wrapi(p1_choice + direction, 0, FIGHTERS.size())
		p1_locked = false
		focus_side = 1
	else:
		p2_choice = wrapi(p2_choice + direction, 0, FIGHTERS.size())
		p2_locked = false
		focus_side = 2
	_refresh()
	selection_moved.emit()


func _confirm(player: int) -> void:
	if player == 1:
		p1_locked = true
		focus_side = 1
		if solo:
			active_side = 2
	else:
		p2_locked = true
		focus_side = 2
	_refresh()
	selection_confirmed.emit()
	if p1_locked and p2_locked:
		match_requested.emit(FIGHTERS[p1_choice], FIGHTERS[p2_choice])


# Solo is a three-step flow (own fighter -> opponent -> match), so back undoes
# one step first and only leaves the screen when there is nothing to undo.
func _back() -> void:
	if solo and (p1_locked or p2_locked or active_side == 2):
		active_side = 1
		p1_locked = false
		p2_locked = false
		focus_side = 1
		_refresh()
		selection_moved.emit()
		return
	back_requested.emit()


func _portrait_x_for(fighter_index: int) -> float:
	return _portraits[fighter_index].position.x


func _refresh() -> void:
	# In solo the opponent cursor stays hidden until P1 has locked their pick, so
	# the screen never implies a second player is active.
	var show_p2 := not solo or p1_locked

	for i in _portraits.size():
		_p1_marks[i].text = "P1 READY" if p1_choice == i and p1_locked else (
			"P1" if p1_choice == i else "")
		_p2_marks[i].text = "" if not show_p2 else (
			"P2 READY" if p2_choice == i and p2_locked else (
				"P2" if p2_choice == i else ""))

	# The scribbles frame the focused portraits.
	_p1_scribble.position = Vector2(_portrait_x_for(p1_choice), PORTRAIT_Y)
	_p2_scribble.visible = show_p2
	if show_p2:
		_p2_scribble.position = Vector2(_portrait_x_for(p2_choice), PORTRAIT_Y)

	# Rap sheet follows whoever moved last.
	var sheet_fighter: FighterData = FIGHTERS[p1_choice] if focus_side == 1 \
		else FIGHTERS[p2_choice]
	_sheet_name.text = sheet_fighter.display_name.to_upper()
	var details: Dictionary = RAP_SHEETS.get(sheet_fighter.id, {})
	if details.is_empty():
		_sheet_archetype.text = ""
		_sheet_tagline.text = ""
		for stroke in _sheet_tally:
			stroke.visible = false
	else:
		_sheet_archetype.text = str(details["archetype"])
		_sheet_tagline.text = str(details["tagline"])
		var marks := mini(int(details["marks"]), _sheet_tally.size())
		for stroke_index in _sheet_tally.size():
			_sheet_tally[stroke_index].visible = stroke_index < marks

	if p1_locked and p2_locked:
		_status.text = "STARTING MATCH..."
	elif solo:
		if p1_locked:
			_status.text = "P1: CHOOSE YOUR OPPONENT - P2 IS IDLE"
		else:
			_status.text = "P1: CHOOSE YOUR FIGHTER"
	elif p1_locked:
		_status.text = "P1 READY  -  WAITING FOR P2"
	elif p2_locked:
		_status.text = "P2 READY  -  WAITING FOR P1"
	else:
		_status.text = "BOTH PLAYERS CONFIRM TO START"
