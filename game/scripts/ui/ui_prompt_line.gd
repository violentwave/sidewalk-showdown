# UiPromptLine — the confirm/back glyph prompt shared by every screen
# (docs/UI_SCREENS.md "Typography rules"): ONE row at the bottom,
# right-aligned, baseline y 172, glyph + m5x7 label pairs with 8 px between
# pairs, 8 px screen margin on the right. Keyboard or pad glyphs match the
# last device used (ScreenRouter's device flag). Pure presentation.
class_name UiPromptLine
extends Control

const GLYPH_KEY := preload("res://art/ui/ui/ui_glyph_key_blank.png")
const GLYPH_PAD_A := preload("res://art/ui/ui/ui_glyph_pad_a.png")
const GLYPH_PAD_B := preload("res://art/ui/ui/ui_glyph_pad_b.png")
const GLYPH_SIZE := Vector2(9, 9)

# Baseline y 172: the 9 px glyph's bottom edge sits on it; the label rect
# is vertically centered on the same optical band.
const BASELINE_Y := 172
const GLYPH_Y := BASELINE_Y - 9  # 163
const LABEL_RECT_Y := 160
const RIGHT_MARGIN := 8
const PAIR_GAP := 8
const LABEL_TO_GLYPH_GAP := 4

var _confirm_glyph: TextureRect
var _confirm_label: Label
var _back_glyph: TextureRect
var _back_label: Label


func _init(confirm_text: String, back_text: String) -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var right_x := 320 - RIGHT_MARGIN
	_confirm_glyph = _make_glyph(GLYPH_KEY, Vector2(right_x - 9, GLYPH_Y))
	add_child(_confirm_glyph)

	_confirm_label = UiText.body(confirm_text, Vector2.ZERO, UiText.YELLOW)
	_confirm_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(_confirm_label)

	_back_glyph = _make_glyph(GLYPH_KEY, Vector2.ZERO)
	add_child(_back_glyph)

	_back_label = UiText.body(back_text, Vector2.ZERO, UiText.MUTED)
	_back_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	add_child(_back_label)

	_layout(confirm_text, back_text)
	_refresh_device()


func _layout(confirm_text: String, back_text: String) -> void:
	var right_x := 320 - RIGHT_MARGIN
	# Confirm pair (primary, rightmost): label right-aligned, then glyph.
	_confirm_glyph.position = Vector2(right_x - 9, GLYPH_Y)
	var confirm_edge := right_x - 9 - LABEL_TO_GLYPH_GAP
	_confirm_label.size = Vector2(UiText.body_width(confirm_text), UiText.M5X7_LINE_HEIGHT)
	_confirm_label.position = Vector2(confirm_edge - _confirm_label.size.x, LABEL_RECT_Y)
	_confirm_label.visible = not confirm_text.is_empty()
	_confirm_glyph.visible = not confirm_text.is_empty()

	# Back pair sits 8 px to the left of the confirm pair's label.
	var back_edge := confirm_edge - _confirm_label.size.x - PAIR_GAP
	if confirm_text.is_empty():
		back_edge = right_x - 9 - LABEL_TO_GLYPH_GAP
	_back_glyph.position = Vector2(back_edge - 9, GLYPH_Y)
	_back_label.size = Vector2(UiText.body_width(back_text), UiText.M5X7_LINE_HEIGHT)
	_back_label.position = Vector2(back_edge - 9 - LABEL_TO_GLYPH_GAP - _back_label.size.x, LABEL_RECT_Y)
	_back_label.visible = not back_text.is_empty()
	_back_glyph.visible = not back_text.is_empty()


func _process(_delta: float) -> void:
	_refresh_device()


func _refresh_device() -> void:
	var pad := ScreenRouter.last_device_was_pad()
	_confirm_glyph.texture = GLYPH_PAD_A if pad else GLYPH_KEY
	_back_glyph.texture = GLYPH_PAD_B if pad else GLYPH_KEY


func _make_glyph(texture: Texture2D, at: Vector2) -> TextureRect:
	var rect := TextureRect.new()
	rect.texture = texture
	rect.position = at
	rect.size = GLYPH_SIZE
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return rect
