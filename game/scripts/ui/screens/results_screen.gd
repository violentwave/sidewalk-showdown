# ResultsScreen — Tripp's clip of the match (UI Phase 3b,
# docs/UI_SCREENS.md): the match's own stage art behind the 55% overlay,
# the winner lettering at the top, the winner's bust on the left, and one
# cardboard ui_panel on the right with dark-ink stat rows fed by the
# presentation-only MatchStatsTracker (per-round win-type letters are not
# recorded by MatchRoot, so the panel shows the plain rounds tally —
# listed in the docs rather than invented). Below the panel: REMATCH /
# CHARACTER SELECT / STAGE SELECT / MAIN MENU in Marker with the yellow
# focus bar. Replaces "Enter restarts": the finished match stays frozen
# (paused) underneath; every menu action unpauses and routes, and input is
# ignored for the first 30 frames.
extends Control

signal rematch_requested
signal character_select_requested
signal stage_select_requested
signal main_menu_requested

const THEME_RESOURCE := preload("res://resources/ui_theme.tres")
const WINNER := preload("res://art/ui/ui/results_winner.png")
const BUSTS := {
	"peg_leg_peggy": "res://art/ui/vs/vs_bust_pegleg_peg.png",
	"whiskey_richard": "res://art/ui/vs/vs_bust_whiskey_richard.png",
}

const WINNER_POS := Vector2(115, 10)  # 90x20 top-centre
const BUST_POS := Vector2(16, 42)     # 96x128 on the left
const PANEL_POS := Vector2(168, 34)
const PANEL_SIZE := Vector2(140, 78)
const ROW_X_LABEL := 176.0
const ROW_X_VALUE_RIGHT := 296.0
const ROW_Y := 42.0
const ROW_STEP := 12.0

const MENU_X := 168.0
const MENU_W := 140.0
const MENU_Y := 116.0
const MENU_STEP := 12.0
const MENU_ITEMS := ["REMATCH", "CHARACTER SELECT", "STAGE SELECT", "MAIN MENU"]

const INPUT_GUARD_FRAMES := 30

# Set by main before the screen is pushed.
var stats: Dictionary = {}
var winner_data: FighterData
# The match's own stage, drawn behind the dim overlay.
var stage: StageData

var index := 0
var _frames := 0
var _row_labels: Array[Label] = []
var _row_values: Array[Label] = []
var _menu_labels: Array[Label] = []
var _menu_bars: Array[ColorRect] = []


func _ready() -> void:
	# Runs above the paused, finished match.
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	# The match's own stage art behind the 55% overlay.
	if stage != null and stage.scene != null:
		var background: Node2D = stage.scene.instantiate()
		# Stage ambient sprites (the mosquitoes) use z_index 10; push the whole
		# backdrop below the UI so nothing flies over panels or text.
		background.z_index = -20
		add_child(background)
	add_child(UiText.dim_overlay())

	var winner_art := TextureRect.new()
	winner_art.texture = WINNER
	winner_art.position = WINNER_POS
	winner_art.size = Vector2(90, 20)
	winner_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	winner_art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(winner_art)

	var bust := TextureRect.new()
	var art_path := str(BUSTS.get(winner_data.id, "")) if winner_data != null else ""
	if not art_path.is_empty() and ResourceLoader.exists(art_path):
		bust.texture = load(art_path)
	bust.position = BUST_POS
	bust.size = Vector2(96, 128)
	bust.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bust.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(bust)

	var panel := Panel.new()
	panel.theme = THEME_RESOURCE
	panel.position = PANEL_POS
	panel.size = PANEL_SIZE
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel)

	var rows := _stat_rows()
	for row in rows.size():
		var row_label := UiText.body(str(rows[row][0]),
			Vector2(ROW_X_LABEL, ROW_Y + row * ROW_STEP), UiText.INK_MUTED)
		row_label.size = Vector2(72, UiText.M5X7_LINE_HEIGHT)
		add_child(row_label)
		_row_labels.append(row_label)
		var value_label := UiText.body(str(rows[row][1]),
			Vector2(0, ROW_Y + row * ROW_STEP), UiText.INK)
		value_label.size = Vector2(112, UiText.M5X7_LINE_HEIGHT)
		value_label.position = Vector2(ROW_X_VALUE_RIGHT - value_label.size.x, ROW_Y + row * ROW_STEP)
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		add_child(value_label)
		_row_values.append(value_label)

	# Menu rows below the panel, Marker with the yellow focus bar.
	for item in MENU_ITEMS.size():
		var bar := UiText.focus_bar(Vector2(MENU_X, MENU_Y + item * MENU_STEP - 1),
			Vector2(MENU_W, 12))
		add_child(bar)
		_menu_bars.append(bar)
		# The menu sits over stage art, not cardboard: outlined cream, with the
		# focused row in dark ink on its yellow bar (PM review of PR #91).
		var label := UiText.marker(MENU_ITEMS[item],
			Vector2(MENU_X, MENU_Y + item * MENU_STEP), UiText.CREAM_TEXT, true)
		label.size = Vector2(MENU_W, UiText.MARKER_LINE_HEIGHT)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		add_child(label)
		_menu_labels.append(label)

	add_child(UiPromptLine.new("SELECT", "MENU"))
	_refresh()


func _stat_rows() -> Array:
	# Plain, honest stats from the tracker snapshot. Win-type letters per
	# round are not recorded by MatchRoot (see match_stats_tracker.gd).
	var wins: Array = stats.get("wins", [0, 0])
	var damage: Array = stats.get("damage", [0.0, 0.0])
	var max_combo: Array = stats.get("max_combo", [0, 0])
	var meth_used: Array = stats.get("meth_used", [false, false])
	var time_left := int(stats.get("time_left_frames", 0))
	var seconds := ceili(time_left / 60.0)
	var meth := "NO"
	if bool(meth_used[0]) and bool(meth_used[1]):
		meth = "BOTH"
	elif bool(meth_used[0]):
		meth = "P1"
	elif bool(meth_used[1]):
		meth = "P2"
	return [
		["ROUNDS", "%d - %d" % [wins[0], wins[1]]],
		["DAMAGE", "%.0f / %.0f" % [damage[0], damage[1]]],
		["MAX COMBO", "%d / %d" % [max_combo[0], max_combo[1]]],
		["METH", meth],
		["TIME LEFT", "%d:%02d" % [seconds / 60, seconds % 60]],
	]


func _physics_process(_delta: float) -> void:
	_frames += 1


func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo():
		return
	ScreenRouter.note_input_device(event)
	if _frames < INPUT_GUARD_FRAMES:
		# A key held from the match's last frame cannot grab the menu.
		if event.is_action_pressed("ui_confirm") or event.is_action_pressed("p1_light") \
				or event.is_action_pressed("ui_back"):
			get_viewport().set_input_as_handled()
		return
	var handled := true
	if event.is_action_pressed("p1_up"):
		index = wrapi(index - 1, 0, MENU_ITEMS.size())
	elif event.is_action_pressed("p1_down"):
		index = wrapi(index + 1, 0, MENU_ITEMS.size())
	elif event.is_action_pressed("p1_light") or event.is_action_pressed("ui_confirm"):
		_choose()
	elif event.is_action_pressed("ui_back"):
		main_menu_requested.emit()
	else:
		handled = false
	if handled:
		get_viewport().set_input_as_handled()
		_refresh()


func _choose() -> void:
	match index:
		0:
			rematch_requested.emit()
		1:
			character_select_requested.emit()
		2:
			stage_select_requested.emit()
		3:
			main_menu_requested.emit()


func _refresh() -> void:
	for item in _menu_labels.size():
		var focused := item == index
		_menu_bars[item].visible = focused
		_menu_labels[item].add_theme_color_override("font_color",
			UiText.INK_DARK if focused else UiText.CREAM_TEXT)
		# Plain Marker on the yellow bar (a dark outline around dark ink smears
		# into a blob); outlined Marker when the row sits on bare stage art.
		_menu_labels[item].add_theme_font_override("font",
			UiText.MARKER if focused else UiText.MARKER_OUTLINE)
