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
# Wall booking text below the clipboard (x 232-316), from y 112.
const WALL_NAME_POS := Vector2(232, 112)
const WALL_NAME_WIDTH := 84.0
const WALL_DETAIL_POS := Vector2(232, 138)
const WALL_DETAIL_WIDTH := 80.0
const WALL_DETAIL_STEP := 10.0
const WALL_TEXT_ROWS := 4

# Owner-editable booking copy (FighterData carries no archetype/tagline/
# difficulty fields — this is presentation copy, like the chat seeds, not
# invented data). "marks" is the pick-up difficulty tally. Keep archetype +
# tagline short enough for three 80 px rows.
const RAP_SHEETS := {
	"peg_leg_peggy": {
		"archetype": "ASSAULT",
		"tagline": "one-leg fury",
		"marks": 2,
	},
	"whiskey_richard": {
		"archetype": "GRAPPLER",
		"tagline": "bar-mat chic",
		"marks": 3,
	},
}

# Portrait art per fighter id; a fighter without an entry gets a framed
# blank on the wall instead of a crash.
const PORTRAITS := {
	"peg_leg_peggy": "res://art/ui/select/select_portrait_pegleg_peg.png",
	"whiskey_richard": "res://art/ui/select/select_portrait_whiskey_richard.png",
}

# The focused fighter's booking photo in the clipboard's box (22x22).
const BOOKING_PHOTOS := {
	"peg_leg_peggy": "res://art/ui/hud/hud_portrait_pegleg_peg_normal.png",
	"whiskey_richard": "res://art/ui/hud/hud_portrait_whiskey_richard_normal.png",
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
var _sheet_portrait: TextureRect
var _sheet_name_lines: Array[Label] = []
var _sheet_detail_lines: Array[Label] = []
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
		p1_mark.size = Vector2(60, UiText.MARKER_LINE_HEIGHT)
		add_child(p1_mark)
		_p1_marks.append(p1_mark)
		# The marks stack on two rows: "P1 READY"/"P2 READY" are wider than
		# half a portrait, so side-by-side marks would overlap on a shared
		# fighter (ui_typography_test's no-overlap check).
		var p2_mark := UiText.marker("", Vector2(x + 2, 108), P2_ACCENT, true)
		p2_mark.size = Vector2(60, UiText.MARKER_LINE_HEIGHT)
		add_child(p2_mark)
		_p2_marks.append(p2_mark)

	# Rap sheet (PM review fix): no text on the clipboard — it is too small.
	# The focused fighter's 22x22 hud portrait sits in the clipboard's photo
	# box (art-space x 9-31 / y 18-41, centred) and the tally marks go in the
	# blank lower-left area (art-space x 6-30 / y 46-58). Name, archetype and
	# tagline live on the WALL below the clipboard (x 232-316, from y 112).
	var sheet := TextureRect.new()
	sheet.texture = RAP_SHEET
	sheet.position = SHEET_POS
	sheet.size = SHEET_SIZE
	sheet.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sheet.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(sheet)

	_sheet_portrait = TextureRect.new()
	_sheet_portrait.position = SHEET_POS + Vector2(9, 18)
	_sheet_portrait.size = Vector2(22, 22)
	_sheet_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sheet_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_sheet_portrait)
	for mark in 3:
		var stroke := ColorRect.new()
		stroke.color = UiText.INK
		stroke.position = SHEET_POS + Vector2(6 + mark * 3.0, 48)
		stroke.size = Vector2(1, 8)
		stroke.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stroke.visible = false
		add_child(stroke)
		_sheet_tally.append(stroke)

	# Wall booking text: the name in outlined marker cream (wrapped to two
	# lines), then archetype and tagline in m5x7 cream wrapped to 80 px with
	# a 10 px line spacing.
	for line in 2:
		var name_line := UiText.marker("",
			WALL_NAME_POS + Vector2(0, line * 12.0), UiText.CREAM_TEXT, true)
		name_line.size = Vector2(WALL_NAME_WIDTH, UiText.MARKER_LINE_HEIGHT)
		add_child(name_line)
		_sheet_name_lines.append(name_line)
	for line in WALL_TEXT_ROWS:
		var detail_line := UiText.body("",
			WALL_DETAIL_POS + Vector2(0, line * WALL_DETAIL_STEP), UiText.CREAM_TEXT)
		detail_line.size = Vector2(WALL_DETAIL_WIDTH, UiText.M5X7_LINE_HEIGHT)
		add_child(detail_line)
		_sheet_detail_lines.append(detail_line)

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
	# PM review fix: the status centers in x 8-228 so it never meets the
	# booking block on the right.
	_status = UiText.marker("", Vector2(8, 138), UiText.CREAM_TEXT, true)
	_status.size = Vector2(220, UiText.MARKER_LINE_HEIGHT)
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_status)
	var stage_note := UiText.marker("STAGE: CHOOSE NEXT", Vector2(8, 152),
		UiText.MUTED, true)
	stage_note.size = Vector2(220, UiText.MARKER_LINE_HEIGHT)
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


func _wrap_marker_name(name: String) -> Array[String]:
	# The wall name wraps to at most two lines inside 84 px; split at the
	# space nearest the middle when it does not fit.
	if UiText.marker_width(name) <= WALL_NAME_WIDTH:
		return [name]
	var space := name.rfind(" ")
	if space < 0:
		return [name]
	return [name.substr(0, space).strip_edges(), name.substr(space + 1)]


func _wrap_body_80(text: String) -> Array[String]:
	# Greedy word wrap at 80 px for m5x7 wall text.
	var rows: Array[String] = []
	var current := ""
	for word in text.split(" "):
		var candidate := word if current.is_empty() else current + " " + word
		if UiText.body_width(candidate) <= WALL_DETAIL_WIDTH:
			current = candidate
		else:
			if not current.is_empty():
				rows.append(current)
			current = word
	if not current.is_empty():
		rows.append(current)
	return rows


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

	# Rap sheet follows whoever moved last. PM review fix: the clipboard
	# carries only the booking photo and tally marks; name, archetype and
	# tagline are wrapped wall text below it.
	var sheet_fighter: FighterData = FIGHTERS[p1_choice] if focus_side == 1 \
		else FIGHTERS[p2_choice]
	var photo_path := str(BOOKING_PHOTOS.get(sheet_fighter.id, ""))
	if not photo_path.is_empty() and ResourceLoader.exists(photo_path):
		_sheet_portrait.texture = load(photo_path)
	else:
		_sheet_portrait.texture = null

	var name_lines := _wrap_marker_name(sheet_fighter.display_name.to_upper())
	for line in _sheet_name_lines.size():
		_sheet_name_lines[line].text = name_lines[line] if line < name_lines.size() else ""

	var details: Dictionary = RAP_SHEETS.get(sheet_fighter.id, {})
	var detail_rows: Array[String] = []
	if not details.is_empty():
		for row in _wrap_body_80(str(details["archetype"])):
			detail_rows.append(row)
		for row in _wrap_body_80(str(details["tagline"])):
			detail_rows.append(row)
	for line in _sheet_detail_lines.size():
		_sheet_detail_lines[line].text = detail_rows[line] if line < detail_rows.size() else ""

	var marks := mini(int(details.get("marks", 0)), _sheet_tally.size())
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
