# MainMenu — the hub (docs/UI_SCREENS.md). The Gas-N-Go price board is
# the menu: the five slats are VERSUS, TRAINING (greyed, coming soon),
# SETTINGS, EXTRAS (greyed), QUIT; the focused slat lights up and its
# m5x7 label sits on top. On the right, Tripp's stream chat cycles fake
# lines on a frame counter in a fixed order — no RNG anywhere.
#
# Slat geometry is measured from menu_price_sign.png (79x124, 2026-11-21):
# the cream board spans art x 1..73 / y 34..73 with content rows
# 35-43, 46-51, 54-60, 63-69, 72-73 and darker divider rows 44-45, 52-53,
# 61-62, 70-71. Constants below are art-space; SIGN_POS places the board.
extends Control

signal versus_chosen
signal settings_requested
signal quit_requested
signal back_requested
signal selection_moved
signal selection_confirmed

const THEME_RESOURCE := preload("res://resources/ui_theme.tres")
const STAGE_SCENE := preload("res://scenes/stages/gas_n_go.tscn")
const SIGN := preload("res://art/ui/menu/menu_price_sign.png")
const SLAT_LIT := preload("res://art/ui/menu/menu_price_slat_lit.png")
const CHAT_PANEL := preload("res://art/ui/stream/stream_chat_panel.png")
const LIVE_TAG := preload("res://art/ui/stream/stream_live_tag.png")

# --- measured price-sign geometry (art space, 79x124) --------------------
const SIGN_POS := Vector2(10, 22)
# Cream board interior: art x 1..73 (73 px wide).
const SLAT_X := 1.0
const SLAT_W := 73.0
# Content rows of the five slats (art-space y, inclusive).
const SLAT_ROWS := [
	[35, 43],  # VERSUS
	[46, 51],  # TRAINING
	[54, 60],  # SETTINGS
	[63, 69],  # EXTRAS
	[72, 73],  # QUIT (the thin bottom strip)
]
# Lit-slat overlay (66x7) y per item, centered on each content row.
const SLAT_LIT_Y := [36, 45, 54, 63, 69]

const MUTED := Color(0.6, 0.57, 0.53)
const GREYED := Color(0.52, 0.5, 0.47)
const WARM_YELLOW := Color(0.949, 0.82, 0.227)
const ITEM_TEXT := Color(0.13, 0.11, 0.09)

const ITEMS := [
	{"name": "VERSUS", "detail": "1P VS CPU OR 2P LOCAL"},
	{"name": "TRAINING", "detail": "COMING SOON", "disabled": true},
	{"name": "SETTINGS", "detail": "TWEAK YOUR LITTLE SETTINGS"},
	{"name": "EXTRAS", "detail": "COMING SOON", "disabled": true},
	{"name": "QUIT", "detail": "LEAVE THE SIDEWALK"},
]

# Owner-seeded placeholder chat lines (docs: owner rewrites them later).
const CHAT_LINES := [
	"who let these two outside",
	"peg is gonna snap",
	"richard smells like a bar mat",
	"BRB grabbing a slurpee",
	"is this even legal in florida",
]
const CHAT_CYCLE_FRAMES := 75
const CHAT_ROW_CHARS := 12  # 12 m5x7 chars = 72 px inside the 80 px panel
const CHAT_MAX_ROWS := 6

var index := 0
var _chat_frame := 0
var _chat_rows: Array[String] = []
var _chat_labels: Array[Label] = []
var _slat_lit: TextureRect
var _detail: Label


func _ready() -> void:
	theme = THEME_RESOURCE
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var background: Node2D = STAGE_SCENE.instantiate()
	add_child(background)

	var sign_rect := TextureRect.new()
	sign_rect.texture = SIGN
	sign_rect.position = SIGN_POS
	sign_rect.size = Vector2(79, 124)
	sign_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sign_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(sign_rect)

	_slat_lit = TextureRect.new()
	_slat_lit.texture = SLAT_LIT
	_slat_lit.position = SIGN_POS + Vector2(6, SLAT_LIT_Y[0])
	_slat_lit.size = Vector2(66, 7)
	_slat_lit.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_slat_lit.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_slat_lit)

	for item_index in ITEMS.size():
		var rows: Array = SLAT_ROWS[item_index]
		var center_y: float = (rows[0] + rows[1]) / 2.0
		var label := Label.new()
		label.text = ITEMS[item_index]["name"]
		label.position = SIGN_POS + Vector2(SLAT_X, center_y - 8.0)
		label.size = Vector2(SLAT_W, 16)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 16)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(label)
		if ITEMS[item_index].get("disabled", false):
			label.add_theme_color_override("font_color", GREYED)
		else:
			label.add_theme_color_override("font_color", ITEM_TEXT)

	_build_chat()
	_detail = Label.new()
	_detail.position = Vector2(8, 148)
	_detail.size = Vector2(216, 16)
	_detail.add_theme_font_size_override("font_size", 16)
	_detail.add_theme_color_override("font_color", WARM_YELLOW)
	_detail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_detail)

	add_child(UiPromptLine.new("SELECT", "BACK"))
	_refresh()


func _build_chat() -> void:
	var live := TextureRect.new()
	live.texture = LIVE_TAG
	live.position = Vector2(232, 34)
	live.size = Vector2(24, 7)
	live.mouse_filter = Control.MOUSE_FILTER_IGNORE
	live.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(live)

	var panel := TextureRect.new()
	panel.texture = CHAT_PANEL
	panel.position = Vector2(232, 44)
	panel.size = Vector2(80, 100)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(panel)

	for row in CHAT_MAX_ROWS:
		var label := Label.new()
		label.position = Vector2(236, 48 + row * 10)
		label.size = Vector2(74, 10)
		label.add_theme_font_size_override("font_size", 16)
		label.add_theme_color_override("font_color", Color(0.9, 0.88, 0.85))
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(label)
		_chat_labels.append(label)


func _physics_process(_delta: float) -> void:
	_chat_frame += 1
	if _chat_frame % CHAT_CYCLE_FRAMES == 0:
		_push_chat_line(CHAT_LINES[(_chat_frame / CHAT_CYCLE_FRAMES - 1) % CHAT_LINES.size()])


func _push_chat_line(line: String) -> void:
	for wrapped in _wrap_chat(line):
		_chat_rows.append(wrapped)
	while _chat_rows.size() > CHAT_MAX_ROWS:
		_chat_rows.pop_front()
	for row in _chat_rows.size():
		_chat_labels[row].text = _chat_rows[row]


func _wrap_chat(line: String) -> Array[String]:
	var words := line.split(" ")
	var rows: Array[String] = []
	var current := ""
	for word in words:
		var candidate := word if current.is_empty() else current + " " + word
		if candidate.length() <= CHAT_ROW_CHARS:
			current = candidate
		else:
			if not current.is_empty():
				rows.append(current)
			current = word
	if not current.is_empty():
		rows.append(current)
	return rows


func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo():
		return
	ScreenRouter.note_input_device(event)
	var handled := true
	if event.is_action_pressed("p1_up"):
		_move(-1)
	elif event.is_action_pressed("p1_down"):
		_move(1)
	elif event.is_action_pressed("p1_light") or event.is_action_pressed("ui_confirm"):
		_choose()
	elif event.is_action_pressed("ui_back"):
		back_requested.emit()
	else:
		handled = false
	if handled:
		get_viewport().set_input_as_handled()


func _move(direction: int) -> void:
	index = wrapi(index + direction, 0, ITEMS.size())
	selection_moved.emit()
	_refresh()


func _choose() -> void:
	var item: Dictionary = ITEMS[index]
	if item.get("disabled", false):
		# Greyed items can never be confirmed.
		return
	selection_confirmed.emit()
	match index:
		0:
			versus_chosen.emit()
		2:
			settings_requested.emit()
		4:
			quit_requested.emit()


func _refresh() -> void:
	_slat_lit.position = SIGN_POS + Vector2(6, SLAT_LIT_Y[index])
	_slat_lit.visible = true
	_detail.text = str(ITEMS[index]["detail"])
