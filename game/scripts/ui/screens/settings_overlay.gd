# SettingsOverlay — the settings screen (an overlay: pushed without freeing
# the screen below). Six-section layout on one ui_panel 9-slice: a TAB row at
# the top (left/right switches sections), the section's option rows below
# (up/down moves, left/right adjusts, confirm also steps right), RESET TO
# DEFAULTS last, and a one-line plain description of the focused row at the
# bottom so the joke copy never hides what an option does.
#
# Opening the screen never saves: values are READ from the Settings autoload
# into the row list; nothing writes back until the player changes something
# (which goes through Settings.set_value -> apply + save + changed).
# Works above a paused match (PROCESS_MODE_ALWAYS). No Controls tab yet.
extends Control

signal closed
signal selection_moved
signal selection_confirmed

const THEME_RESOURCE := preload("res://resources/ui_theme.tres")
const MUTED := Color(0.75, 0.72, 0.68)
const ITEM_TEXT := Color(0.96, 0.91, 0.83)
const WARM_YELLOW := Color(0.949, 0.82, 0.227)
const ROW_STEP := 14
const FIRST_ROW_Y := 38

# Tab 0 is the header row; rows are data-driven over the Settings schema.
# "desc" is the plain one-line description shown at the bottom.
const TABS := [
	{
		"title": "VIDEO",
		"section": "video",
		"rows": [
			{"key": "window_mode", "label": "WINDOW MODE",
				"desc": "Windowed, or a borderless fullscreen.",
				"kind": "cycle",
				"values": ["windowed", "fullscreen"],
				"names": ["WINDOWED", "FULLSCREEN"]},
			{"key": "integer_scale", "label": "WINDOW SCALE",
				"desc": "Integer pixel multiplier for the window, 2x to 6x.",
				"kind": "range", "min": 2, "max": 6, "suffix": "X"},
			{"key": "vsync", "label": "VSYNC",
				"desc": "Sync the frame rate to the display.",
				"kind": "bool"},
		],
	},
	{
		"title": "AUDIO",
		"section": "audio",
		"rows": [
			{"key": "master", "label": "MASTER",
				"desc": "Everything at once, 0 to 10. Zero is silence.",
				"kind": "slider"},
			{"key": "music", "label": "MUSIC",
				"desc": "The fight and menu tracks, 0 to 10.",
				"kind": "slider"},
			{"key": "sfx", "label": "SFX",
				"desc": "Hits, blocks and knockdowns, 0 to 10.",
				"kind": "slider"},
			{"key": "voice", "label": "VOICE",
				"desc": "Reserved for commentary voice lines, 0 to 10.",
				"kind": "slider"},
			{"key": "ui", "label": "UI",
				"desc": "Menu clicks and confirms, 0 to 10.",
				"kind": "slider"},
			{"key": "mute_when_unfocused", "label": "MUTE WHEN UNFOCUSED",
				"desc": "Go quiet whenever the window loses focus.",
				"kind": "bool"},
		],
	},
	{
		"title": "GAMEPLAY",
		"section": "gameplay",
		"rows": [
			{"key": "input_display", "label": "INPUT DISPLAY",
				"desc": "Show the inputs you press. Not wired up yet.",
				"kind": "cycle",
				"values": ["off", "p1", "both"],
				"names": ["OFF", "P1", "BOTH"]},
			{"key": "commentary", "label": "TRIPP COMMENTARY",
				"desc": "How much Tripp talks during matches.",
				"kind": "cycle",
				"values": ["full", "minimal", "off"],
				"names": ["FULL", "MINIMAL", "OFF"]},
			{"key": "show_combo_damage", "label": "SHOW COMBO DAMAGE",
				"desc": "Print the damage total under the combo counter.",
				"kind": "bool"},
		],
	},
	{
		"title": "ACCESSIBILITY",
		"section": "accessibility",
		"rows": [
			{"key": "reduce_flashing", "label": "REDUCE FLASHING",
				"desc": "Swap flashes for tints. Not wired up yet.",
				"kind": "bool"},
			{"key": "screen_shake", "label": "SCREEN SHAKE",
				"desc": "Camera kick on hits. Not wired up yet.",
				"kind": "cycle",
				"values": ["off", "low", "full"],
				"names": ["OFF", "LOW", "FULL"]},
			{"key": "high_contrast_hud", "label": "HIGH-CONTRAST HUD",
				"desc": "Stronger bar outlines. Lands with the HUD pass.",
				"kind": "bool"},
			{"key": "readable_font", "label": "READABLE FONT",
				"desc": "A larger font in menus. Not wired up yet.",
				"kind": "bool"},
			{"key": "hold_to_confirm_meth", "label": "HOLD TO CONFIRM METH",
				"desc": "Hold instead of tap for the finisher. Not wired yet.",
				"kind": "bool"},
		],
	},
	{
		"title": "STREAM",
		"section": "stream",
		"rows": [
			{"key": "streamer_safe_music", "label": "STREAMER-SAFE MUSIC",
				"desc": "Mute the tracks with unclear rights. Not wired yet.",
				"kind": "bool"},
			{"key": "hide_tripp_text", "label": "HIDE TRIPP TEXT",
				"desc": "Hide Tripp's commentary and chat. Not wired yet.",
				"kind": "bool"},
		],
	},
]

var tab_index := 0
var row_index := 0  # 0 = tab header, 1.. rows, last = reset
var _title_label: Label
var _row_labels: Array[Label] = []
var _value_labels: Array[Label] = []
var _desc_label: Label


func _ready() -> void:
	# Above a paused match the tree is frozen; this overlay must still run.
	process_mode = Node.PROCESS_MODE_ALWAYS
	theme = THEME_RESOURCE
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.65)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)

	var panel := Panel.new()
	panel.position = Vector2(20, 14)
	panel.size = Vector2(280, 142)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel)

	_title_label = _make_label("", Vector2(32, 20), Vector2(256, 16), ITEM_TEXT)
	add_child(_title_label)

	for row in 9:  # header + up to 7 options + reset
		var row_label := _make_label("", Vector2(32, FIRST_ROW_Y + row * ROW_STEP),
			Vector2(150, 16), ITEM_TEXT)
		add_child(row_label)
		_row_labels.append(row_label)
		var value_label := _make_label("", Vector2(184, FIRST_ROW_Y + row * ROW_STEP),
			Vector2(96, 16), WARM_YELLOW)
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		add_child(value_label)
		_value_labels.append(value_label)

	_desc_label = Label.new()
	_desc_label.position = Vector2(12, 160)
	_desc_label.size = Vector2(296, 16)
	_desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_desc_label.add_theme_font_size_override("font_size", 16)
	_desc_label.add_theme_color_override("font_color", MUTED)
	_desc_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_desc_label)

	add_child(UiPromptLine.new("SELECT", "BACK"))
	_refresh()


func _settings():
	# The Settings autoload, resolved at runtime: the bare `Settings`
	# identifier does not compile inside headless --script harnesses, and
	# this path works in both the game and the test runner.
	return get_tree().root.get_node_or_null("Settings")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo():
		return
	ScreenRouter.note_input_device(event)
	var handled := true
	if event.is_action_pressed("p1_up"):
		_move_row(-1)
	elif event.is_action_pressed("p1_down"):
		_move_row(1)
	elif event.is_action_pressed("p1_left"):
		_adjust(-1)
	elif event.is_action_pressed("p1_right"):
		_adjust(1)
	elif event.is_action_pressed("p1_light") or event.is_action_pressed("ui_confirm"):
		_adjust(1)
	elif event.is_action_pressed("ui_back"):
		closed.emit()
	else:
		handled = false
	if handled:
		get_viewport().set_input_as_handled()


func row_count() -> int:
	# header + options + reset
	return 1 + TABS[tab_index]["rows"].size() + 1


func _move_row(direction: int) -> void:
	row_index = wrapi(row_index + direction, 0, row_count())
	selection_moved.emit()
	_refresh()


func _adjust(direction: int) -> void:
	if row_index == 0:
		tab_index = wrapi(tab_index + direction, 0, TABS.size())
		row_index = 0
		selection_confirmed.emit()
		_refresh()
		return
	if row_index == row_count() - 1:
		# RESET TO DEFAULTS: resets, applies, refreshes, saves.
		selection_confirmed.emit()
		_settings().reset_to_defaults()
		_refresh()
		return
	var row: Dictionary = TABS[tab_index]["rows"][row_index - 1]
	var section: String = TABS[tab_index]["section"]
	var key: String = row["key"]
	var value = _settings().get_value(section, key)
	match row["kind"]:
		"bool":
			_settings().set_value(section, key, not bool(value))
		"cycle":
			var values: Array = row["values"]
			var position := values.find(value)
			position = wrapi(position + direction, 0, values.size())
			_settings().set_value(section, key, values[position])
		"range":
			_settings().set_value(section, key,
				clampi(int(value) + direction, row["min"], row["max"]))
		"slider":
			_settings().set_value(section, key, clampi(int(value) + direction, 0, 10))
	selection_confirmed.emit()
	_refresh()


func _refresh() -> void:
	var tab: Dictionary = TABS[tab_index]
	_title_label.text = "SETTINGS"
	var header_row := 0
	_row_labels[header_row].text = "TAB"
	_value_labels[header_row].text = "< %s >" % tab["title"]

	var rows: Array = tab["rows"]
	for row in rows.size():
		var definition: Dictionary = rows[row]
		var value = _settings().get_value(tab["section"], definition["key"])
		_row_labels[row + 1].text = str(definition["label"])
		_value_labels[row + 1].text = _format_value(definition, value)

	var reset_row := rows.size() + 1
	_row_labels[reset_row].text = "RESET TO DEFAULTS"
	_value_labels[reset_row].text = ""

	# Hide unused rows (max 9 built, tabs have at most 8 used).
	for unused in range(row_count(), _row_labels.size()):
		_row_labels[unused].text = ""
		_value_labels[unused].text = ""

	# Selection styling and the description line.
	for row in row_count():
		var selected := row == row_index
		var color: Color = WARM_YELLOW if selected else ITEM_TEXT
		if row == row_count() - 1 and not selected:
			color = MUTED
		_row_labels[row].add_theme_color_override("font_color", color)
		if row == 0:
			_value_labels[row].add_theme_color_override("font_color", color)

	if row_index == 0:
		_desc_label.text = "Left and right change the section."
	elif row_index == row_count() - 1:
		_desc_label.text = "Put every option back the way it shipped."
	else:
		_desc_label.text = str(rows[row_index - 1]["desc"])


func _format_value(definition: Dictionary, value) -> String:
	match definition["kind"]:
		"bool":
			return "ON" if value else "OFF"
		"cycle":
			var names: Array = definition["names"]
			return str(names[definition["values"].find(value)])
		"range":
			return str(int(value)) + str(definition["suffix"])
		"slider":
			return str(int(value)) + "/10"
	return str(value)


func _make_label(text: String, at: Vector2, dimensions: Vector2, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.position = at
	label.size = dimensions
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label
