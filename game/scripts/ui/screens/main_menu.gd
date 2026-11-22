# MainMenu — the hub (docs/UI_SCREENS.md). The Gas-N-Go price board is
# the menu: slats 1-4 are VERSUS, TRAINING (greyed), SETTINGS, EXTRAS
# (greyed) in m5x7 dark ink, vertically centered on the measured slat
# rows; the focused slat shows the lit overlay with a darker label. QUIT
# is a ui_button "taped" to the pole below the slats, labeled in Sidewalk
# Marker. The owner removed the chat strip (2026-11-21): no chat panel,
# LIVE tag or fake chat lines. One m5x7 description line on a dark plate
# at the bottom left; the prompt line is bottom right. No RNG anywhere.
#
# Slat geometry is measured from menu_price_sign.png (79x124, 2026-11-21):
# the cream board spans art x 1..73 / y 34..73 with content rows
# 35-43, 46-51, 54-60, 63-69 and darker divider rows 44-45, 52-53, 61-62,
# 70-71. The pole runs art x 36..43 down to the art bottom. The sign sits
# in the left third (review fix 2026-11-22): left edge x 24, pole base on
# the stage floor line (Gas-N-Go floor_y 158) -> SIGN_POS (24, 34). The
# sign's orange header band (measured) spans art x 5..72 / y 5..29 and
# carries a white outlined "MENU" (over art, so marker_outline).
extends Control

signal versus_chosen
signal settings_requested
signal quit_requested
signal back_requested
signal selection_moved
signal selection_confirmed

const STAGE_SCENE := preload("res://scenes/stages/gas_n_go.tscn")
const SIGN := preload("res://art/ui/menu/menu_price_sign.png")
const SLAT_LIT := preload("res://art/ui/menu/menu_price_slat_lit.png")
const BUTTON_TEX := preload("res://art/ui/ui/ui_button.png")

# --- measured price-sign geometry (art space, 79x124) --------------------
const SIGN_POS := Vector2(24, 34)
const SIGN_SIZE := Vector2(79, 124)
# Cream board interior: art x 1..73 (73 px wide).
const SLAT_X := 1.0
const SLAT_W := 73.0
# Content rows of slats 1-4 (art-space y, inclusive; QUIT left the board).
const SLAT_ROWS := [
	[35, 43],  # VERSUS
	[46, 51],  # TRAINING
	[54, 60],  # SETTINGS
	[63, 69],  # EXTRAS
]
# Integer vertical centers of the content rows.
const SLAT_CENTER_Y := [39, 48, 57, 66]
# Lit-slat overlay (66x7) y per slat, centered on each content row.
const SLAT_LIT_Y := [36, 45, 54, 63]

# "MENU" in the sign's orange header (art x 5..72 / y 5..29, measured).
const MENU_LABEL_POS := Vector2(29, 45)  # centered on screen x 62.5
const MENU_LABEL_W := 68.0

# QUIT: a 48x16 ui_button taped to the pole (art x 36..43 -> screen
# 60..67; button centered on 63.5), below the slats.
const QUIT_POS := Vector2(40, 116)
const QUIT_SIZE := Vector2(48, 16)

const ITEMS := [
	{"name": "VERSUS", "detail": "Fight the CPU or a friend."},
	{"name": "TRAINING", "detail": "Coming soon.", "disabled": true},
	{"name": "SETTINGS", "detail": "Tweak your settings."},
	{"name": "EXTRAS", "detail": "Coming soon.", "disabled": true},
	{"name": "QUIT", "detail": "Leave the sidewalk."},
]

var index := 0
var _slat_labels: Array[Label] = []
var _slat_lit: TextureRect
var _quit_button: TextureRect
var _quit_label: Label
var _quit_focus_bar: ColorRect
var _prompt: UiPromptLine


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var background: Node2D = STAGE_SCENE.instantiate()
	add_child(background)

	# Declutter: the stage art sits behind a #1C160D 55% overlay
	# (docs/UI_SCREENS.md review fixes).
	add_child(UiText.dim_overlay())

	var sign_rect := TextureRect.new()
	sign_rect.texture = SIGN
	sign_rect.position = SIGN_POS
	sign_rect.size = SIGN_SIZE
	sign_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sign_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(sign_rect)

	# "MENU" in the sign's empty orange header, over art: white with the
	# baked outline so it reads on the orange band.
	var menu_label := UiText.marker("MENU", MENU_LABEL_POS, Color.WHITE, true)
	menu_label.size = Vector2(MENU_LABEL_W, UiText.MARKER_LINE_HEIGHT)
	menu_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(menu_label)

	_slat_lit = TextureRect.new()
	_slat_lit.texture = SLAT_LIT
	_slat_lit.position = SIGN_POS + Vector2(6, SLAT_LIT_Y[0])
	_slat_lit.size = Vector2(66, 7)
	_slat_lit.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_slat_lit.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_slat_lit)

	for item_index in SLAT_ROWS.size():
		var label := UiText.body(ITEMS[item_index]["name"],
			SIGN_POS + Vector2(SLAT_X, SLAT_CENTER_Y[item_index] - 8.0),
			UiText.INK)
		label.size = Vector2(SLAT_W, UiText.M5X7_LINE_HEIGHT)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		add_child(label)
		_slat_labels.append(label)

	_quit_button = TextureRect.new()
	_quit_button.texture = BUTTON_TEX
	_quit_button.position = QUIT_POS
	_quit_button.size = QUIT_SIZE
	_quit_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_quit_button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_quit_button)

	_quit_focus_bar = UiText.focus_bar(QUIT_POS + Vector2.ONE,
		QUIT_SIZE - Vector2(2, 2))
	add_child(_quit_focus_bar)

	_quit_label = UiText.marker("QUIT", Vector2(QUIT_POS.x, QUIT_POS.y + 2),
		UiText.INK)
	_quit_label.size = Vector2(QUIT_SIZE.x, UiText.MARKER_LINE_HEIGHT)
	_quit_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_quit_label)

	# The description line rides the full-width prompt plate on the left;
	# the confirm/back prompt sits on its right (review fix 2026-11-22).
	_prompt = UiPromptLine.new("SELECT", "BACK", str(ITEMS[0]["detail"]))
	add_child(_prompt)
	_refresh()


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
	# Slats 0-3: the focused slat lights up and its label darkens
	# (INK_DARK on the yellow slat); greyed slats use the muted ink.
	var on_slats := index < SLAT_ROWS.size()
	_slat_lit.visible = on_slats
	if on_slats:
		_slat_lit.position = SIGN_POS + Vector2(6, SLAT_LIT_Y[index])
	for item_index in _slat_labels.size():
		var label := _slat_labels[item_index]
		var color := UiText.INK
		if ITEMS[item_index].get("disabled", false):
			color = UiText.INK_MUTED
		elif item_index == index:
			color = UiText.INK_DARK
		label.add_theme_color_override("font_color", color)

	# QUIT: the taped button gets the yellow highlight bar and dark ink
	# when focused (review fix 2026-11-22).
	_quit_button.modulate = Color.WHITE
	_quit_focus_bar.visible = index == 4
	_quit_label.add_theme_color_override("font_color",
		UiText.INK_DARK if index == 4 else UiText.INK)

	_prompt.set_left_text(str(ITEMS[index]["detail"]))
