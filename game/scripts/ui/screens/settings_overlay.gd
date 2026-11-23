# SettingsOverlay — the settings screen (an overlay: pushed without freeing
# the screen below). One centered ui_panel (280x148) with a tab row in
# Sidewalk Marker across the top (the active tab rides a yellow highlight
# bar with the darkest ink, inactive tabs muted), option rows (label left,
# value right-aligned, both m5x7 in dark ink; the focused row rides a
# full-width yellow bar), RESET TO DEFAULTS last, and the one-line plain
# description in muted ink inside the panel bottom. Max 7 visible rows;
# the window scrolls if a tab ever grows past that (none does today).
#
# Opening the screen never saves: values are READ from the Settings autoload
# into the row list; nothing writes back until the player changes something
# (which goes through Settings.set_value -> apply + save + changed).
# Works above a paused match (PROCESS_MODE_ALWAYS).
extends Control

signal closed
signal selection_moved
signal selection_confirmed

const THEME_RESOURCE := preload("res://resources/ui_theme.tres")
const PANEL_POS := Vector2(20, 16)
const PANEL_SIZE := Vector2(280, 148)
const TAB_Y := 22
const TAB_ROW_X := 28
const TAB_ROW_W := 264
const ROW_X_LABEL := 32
const ROW_X_VALUE_RIGHT := 264
const ROW_Y := 44
const ROW_STEP := 14
const MAX_VISIBLE_ROWS := 7
const DESC_Y := 144

# Row data over the Settings schema. "desc" is the plain one-line
# description shown at the panel bottom. Tab titles use Sidewalk Marker;
# ACCESSIBILITY is abbreviated to ACCESS. to fit the row (the full name
# shows in the description line when the tab row is focused).
const TABS := [
	{
		"title": "VID",
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
		"title": "AUD",
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
		"title": "GAME",
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
		"title": "ACC",
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
		"title": "STRM",
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
	{
		"title": "CONTROLS",
		"section": "controls",
		"rows": [],
	},
]

var tab_index := 0
var row_index := 0  # 0 = tab header, 1.. options, last = reset
var control_player := "p1"
var pending_control_id := ""
var control_feedback := ""

var _tab_labels: Array[Label] = []
var _tab_bars: Array[ColorRect] = []
var _row_labels: Array[Label] = []
var _value_labels: Array[Label] = []
var _row_bars: Array[ColorRect] = []
var _desc_label: Label


func _ready() -> void:
	# Above a paused match the tree is frozen; this overlay must still run.
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.65)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)

	var panel := Panel.new()
	panel.theme = THEME_RESOURCE
	panel.position = PANEL_POS
	panel.size = PANEL_SIZE
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel)

	# Tab row: Sidewalk Marker titles distributed across the panel top.
	# The active tab sits on a yellow highlight bar with the darkest ink
	# (contrast rules); inactive tabs use the muted cardboard ink.
	var widths: Array[int] = []
	var total_w := 0
	for tab in TABS:
		widths.append(UiText.marker_width(str(tab["title"])))
		total_w += widths.back()
	var gap := (TAB_ROW_W - total_w) / float(TABS.size() - 1) if TABS.size() > 1 else 0.0
	var x := float(TAB_ROW_X)
	for tab in TABS.size():
		var bar := UiText.focus_bar(Vector2(roundi(x) - 2, TAB_Y - 1),
			Vector2(widths[tab] + 4, 12))
		add_child(bar)
		_tab_bars.append(bar)
		var label := UiText.marker(str(TABS[tab]["title"]), Vector2(roundi(x), TAB_Y),
			UiText.INK_MUTED)
		label.size = Vector2(widths[tab], UiText.MARKER_LINE_HEIGHT)
		add_child(label)
		_tab_labels.append(label)
		x += widths[tab] + gap

	# Option rows: m5x7 label left, value right-aligned. The focused row
	# rides a full-width yellow bar with the darkest ink.
	for row in MAX_VISIBLE_ROWS:
		var row_bar := UiText.focus_bar(
			Vector2(TAB_ROW_X - 4, 0), Vector2(ROW_X_VALUE_RIGHT - TAB_ROW_X + 4, 12))
		add_child(row_bar)
		_row_bars.append(row_bar)
		var row_label := UiText.body("", Vector2(ROW_X_LABEL, 0), UiText.INK)
		row_label.size = Vector2(150, UiText.M5X7_LINE_HEIGHT)
		add_child(row_label)
		_row_labels.append(row_label)
		var value_label := UiText.body("", Vector2(0, 0), UiText.INK_MUTED)
		value_label.size = Vector2(ROW_X_VALUE_RIGHT - ROW_X_LABEL - 8,
			UiText.M5X7_LINE_HEIGHT)
		value_label.position = Vector2(ROW_X_VALUE_RIGHT - value_label.size.x, 0)
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		add_child(value_label)
		_value_labels.append(value_label)

	_desc_label = UiText.body("", Vector2(ROW_X_LABEL, DESC_Y), UiText.INK_MUTED)
	_desc_label.size = Vector2(232, UiText.M5X7_LINE_HEIGHT)
	add_child(_desc_label)

	add_child(UiPromptLine.new("SELECT", "BACK"))
	_refresh()


func _settings():
	# The Settings autoload, resolved at runtime: the bare `Settings`
	# identifier does not compile inside headless --script harnesses, and
	# this path works in both the game and the test runner.
	return get_tree().root.get_node_or_null("Settings")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo() and pending_control_id.is_empty():
		return
	ScreenRouter.note_input_device(event)
	if not pending_control_id.is_empty():
		_capture_rebind_event(event)
		return
	var handled := true
	if event.is_action_pressed("p1_up") or event.is_action_pressed("p2_up"):
		_move_row(-1)
	elif event.is_action_pressed("p1_down") or event.is_action_pressed("p2_down"):
		_move_row(1)
	elif event.is_action_pressed("p1_left") or event.is_action_pressed("p2_left"):
		_adjust(-1)
	elif event.is_action_pressed("p1_right") or event.is_action_pressed("p2_right"):
		_adjust(1)
	elif event.is_action_pressed("p1_light") or event.is_action_pressed("p2_light") \
			or event.is_action_pressed("ui_confirm"):
		if _is_controls_tab() and row_index >= 2 \
				and row_index < row_count() - 1:
			_begin_rebind()
		else:
			_adjust(1)
	elif event.is_action_pressed("ui_back"):
		closed.emit()
	else:
		handled = false
	if handled:
		get_viewport().set_input_as_handled()


func row_count() -> int:
	# tab header + options + reset
	return 1 + _rows_for_current_tab().size() + 1


func _move_row(direction: int) -> void:
	row_index = wrapi(row_index + direction, 0, row_count())
	control_feedback = ""
	selection_moved.emit()
	_refresh()


func _adjust(direction: int) -> void:
	if row_index == 0:
		tab_index = wrapi(tab_index + direction, 0, TABS.size())
		row_index = 0
		pending_control_id = ""
		control_feedback = ""
		selection_confirmed.emit()
		_refresh()
		return
	if row_index == row_count() - 1:
		selection_confirmed.emit()
		if _is_controls_tab():
			_settings().controls.reset_player(control_player)
			control_feedback = "%s DEFAULTS RESTORED" % control_player.to_upper()
		else:
			# RESET TO DEFAULTS: resets, applies, refreshes, saves.
			_settings().reset_to_defaults()
		_refresh()
		return
	var row: Dictionary = _rows_for_current_tab()[row_index - 1]
	if row["kind"] == "player":
		control_player = "p2" if control_player == "p1" else "p1"
		control_feedback = ""
		selection_confirmed.emit()
		_refresh()
		return
	if row["kind"] == "binding":
		_begin_rebind()
		return
	if row["kind"] == "player" or _is_controls_tab():
		return
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


func _row_window() -> int:
	# First option row shown when more than MAX_VISIBLE_ROWS exist.
	var option_count := row_count() - 1
	if option_count <= MAX_VISIBLE_ROWS:
		return 0
	return clampi(row_index - 1 - (MAX_VISIBLE_ROWS - 1), 0,
		option_count - MAX_VISIBLE_ROWS)


func _refresh() -> void:
	var tab: Dictionary = TABS[tab_index]
	var rows := _rows_for_current_tab()
	var controls_tab := _is_controls_tab()

	# Tab row: the active tab rides a yellow bar with the darkest ink;
	# inactive tabs stay muted on the cardboard.
	for t in TABS.size():
		var active := t == tab_index
		_tab_bars[t].visible = active
		_tab_labels[t].add_theme_color_override("font_color",
			UiText.INK_DARK if active else UiText.INK_MUTED)

	# Option rows (options + RESET), windowed to MAX_VISIBLE_ROWS. The
	# focused row rides a full-width yellow bar with the darkest ink.
	var option_count := rows.size() + 1  # options + reset
	var window := _row_window()
	var reset_row_index := rows.size()  # option index of the reset row

	for slot in MAX_VISIBLE_ROWS:
		var option := window + slot
		var y := ROW_Y + slot * ROW_STEP
		var row_label := _row_labels[slot]
		var value_label := _value_labels[slot]
		var row_bar := _row_bars[slot]
		row_label.position.y = y
		value_label.position.y = y
		row_bar.position.y = y - 1
		if controls_tab:
			row_label.size.x = 112
			value_label.size.x = ROW_X_VALUE_RIGHT - ROW_X_LABEL - 120
			value_label.position.x = ROW_X_VALUE_RIGHT - value_label.size.x
		else:
			row_label.size.x = 150
			value_label.size.x = ROW_X_VALUE_RIGHT - ROW_X_LABEL - 8
			value_label.position.x = ROW_X_VALUE_RIGHT - value_label.size.x
		if option >= option_count:
			row_label.text = ""
			value_label.text = ""
			row_bar.visible = false
			continue
		var focused_row := row_index == option + 1
		var color := UiText.INK_DARK if focused_row else UiText.INK
		if option == reset_row_index:
			row_label.text = "RESET %s DEFAULTS" % control_player.to_upper() \
				if controls_tab else "RESET TO DEFAULTS"
			value_label.text = ""
			if not focused_row:
				color = UiText.INK_MUTED
		else:
			var definition: Dictionary = rows[option]
			row_label.text = str(definition["label"])
			match str(definition["kind"]):
				"player":
					value_label.text = "P1 KEYBOARD" if control_player == "p1" \
						else "P2 CONTROLLER"
				"binding":
					if pending_control_id == str(definition["control_id"]):
						value_label.text = "PRESS A KEY" if control_player == "p1" \
							else "PRESS PAD INPUT"
					else:
						value_label.text = _settings().controls.binding_label(
							control_player, str(definition["control_id"]))
				_:
					var value = _settings().get_value(tab["section"], definition["key"])
					value_label.text = _format_value(definition, value)
		row_label.add_theme_color_override("font_color", color)
		value_label.add_theme_color_override("font_color", color)
		row_bar.visible = focused_row

	# Description line inside the panel bottom.
	if row_index == 0:
		_desc_label.text = "TAB: %s. LEFT / RIGHT CHANGE SECTION." % tab["title"]
	elif row_index == row_count() - 1:
		_desc_label.text = "Restore this player's shipped controls." if controls_tab \
			else "Put every option back the way it shipped."
	else:
		var focused: Dictionary = rows[row_index - 1]
		if controls_tab:
			if not control_feedback.is_empty():
				_desc_label.text = control_feedback
			elif not pending_control_id.is_empty():
				_desc_label.text = "PRESS A KEY / PAD INPUT. ESC CANCELS."
			elif focused["kind"] == "player":
				_desc_label.text = "LEFT / RIGHT OR SELECT TO SWITCH PLAYER."
			else:
				_desc_label.text = "SELECT TO REBIND. CONFLICTS SWAP."
		else:
			_desc_label.text = str(focused["desc"])


func _rows_for_current_tab() -> Array:
	if not _is_controls_tab():
		return TABS[tab_index]["rows"]
	var rows: Array = [{
		"label": "PLAYER",
		"desc": "P1 keyboard or P2 controller.",
		"kind": "player",
	}]
	for definition: Dictionary in _settings().controls.control_definitions(control_player):
		rows.append({
			"label": definition["label"],
			"desc": "Select to rebind this action.",
			"kind": "binding",
			"control_id": definition["id"],
		})
	return rows


func _is_controls_tab() -> bool:
	return str(TABS[tab_index]["section"]) == "controls"


func _begin_rebind() -> void:
	if row_index < 2 or row_index >= row_count() - 1:
		return
	var row: Dictionary = _rows_for_current_tab()[row_index - 1]
	if row["kind"] != "binding":
		return
	pending_control_id = str(row["control_id"])
	control_feedback = ""
	selection_confirmed.emit()
	_refresh()


func _capture_rebind_event(event: InputEvent) -> void:
	var cancel_key: bool = event is InputEventKey and event.pressed \
		and not event.echo and (event.keycode == KEY_ESCAPE \
			or event.physical_keycode == KEY_ESCAPE)
	if cancel_key:
		pending_control_id = ""
		control_feedback = "REBIND CANCELLED"
		get_viewport().set_input_as_handled()
		_refresh()
		return

	if control_player == "p1" and event is InputEventKey \
			and event.pressed and not event.echo:
		_finish_rebind(event)
	elif control_player == "p2" and event is InputEventJoypadButton \
			and event.pressed:
		_finish_rebind(event)
	elif control_player == "p2" and event is InputEventJoypadMotion:
		# Keep listening through the DualSense's small center-rest events.
		if absf(event.axis_value) >= InputBindings.AXIS_CAPTURE_DEADZONE:
			_finish_rebind(event)
	get_viewport().set_input_as_handled()


func _finish_rebind(event: InputEvent) -> void:
	var result: Dictionary = _settings().controls.rebind_control(
		control_player, pending_control_id, event)
	control_feedback = str(result["message"])
	if bool(result["ok"]):
		pending_control_id = ""
	selection_confirmed.emit()
	_refresh()


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
