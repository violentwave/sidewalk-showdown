# UiPromptLine — the confirm/back prompt shared by every screen
# (docs/UI_SCREENS.md "Contrast and prompts"): ONE full-width dark plate
# (#1C160D at 80% alpha, 12 px tall) across the bottom of the 320x180
# frame, so the prompt never collides with stage art. Keyboard prompts
# show bracketed key names in m5x7 ("[ENTER] SELECT", "[BKSP] BACK");
# pad prompts keep the A/B glyph sprites. An optional left_text (used by
# the main menu's description line) rides the same plate on the left.
# Pure presentation.
class_name UiPromptLine
extends Control

const GLYPH_PAD_A := preload("res://art/ui/ui/ui_glyph_pad_a.png")
const GLYPH_PAD_B := preload("res://art/ui/ui/ui_glyph_pad_b.png")
const GLYPH_SIZE := Vector2(9, 9)

# The plate: full width, 12 px tall, flush with the screen bottom.
const PLATE_Y := 168
const PLATE_SIZE := Vector2(320, 12)
# Optical band inside the plate: the m5x7 label rect (16 px tall) centers
# on the plate; the 9 px glyph centers on the same band.
const LABEL_Y := 168
const GLYPH_Y := 169
const LEFT_X := 8
const RIGHT_MARGIN := 8
const PAIR_GAP := 8
const KEY_TO_LABEL_GAP := 4
const GLYPH_TO_LABEL_GAP := 4

var _plate: ColorRect
var _left_label: Label
var _confirm_key: Label
var _confirm_glyph: TextureRect
var _confirm_label: Label
var _back_key: Label
var _back_glyph: TextureRect
var _back_label: Label
var _confirm_text: String
var _back_text: String
var _laid_out_for_pad := false


func _init(confirm_text: String, back_text: String, left_text: String = "") -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)

	_plate = ColorRect.new()
	_plate.color = UiText.PROMPT_PLATE
	_plate.position = Vector2(0, PLATE_Y)
	_plate.size = PLATE_SIZE
	_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_plate)

	if not left_text.is_empty():
		_left_label = UiText.body(left_text, Vector2(LEFT_X, LABEL_Y), UiText.CREAM_TEXT)
		add_child(_left_label)

	# Confirm pair (rightmost): "[ENTER] SELECT" or [pad A] SELECT.
	_confirm_label = UiText.body(confirm_text, Vector2.ZERO, UiText.YELLOW)
	add_child(_confirm_label)
	_confirm_key = UiText.body("", Vector2.ZERO, UiText.CREAM_TEXT)
	add_child(_confirm_key)
	_confirm_glyph = _make_glyph(GLYPH_PAD_A, Vector2.ZERO)
	add_child(_confirm_glyph)

	# Back pair to its left: "[BKSP] BACK" or [pad B] BACK.
	_back_label = UiText.body(back_text, Vector2.ZERO, UiText.MUTED)
	add_child(_back_label)
	_back_key = UiText.body("", Vector2.ZERO, UiText.CREAM_TEXT)
	add_child(_back_key)
	_back_glyph = _make_glyph(GLYPH_PAD_B, Vector2.ZERO)
	add_child(_back_glyph)

	_confirm_text = confirm_text
	_back_text = back_text
	_laid_out_for_pad = ScreenRouter.last_device_was_pad()
	_layout(confirm_text, back_text)
	_refresh_device()


func _layout(confirm_text: String, back_text: String) -> void:
	var right_x := 320 - RIGHT_MARGIN
	# Confirm pair: label, then 4 px gap, then the key name / glyph.
	_confirm_label.size = Vector2(UiText.body_width(confirm_text), 12.0)
	_confirm_label.position = Vector2(
		right_x - _confirm_label.size.x, LABEL_Y)
	_confirm_label.visible = not confirm_text.is_empty()
	_layout_key(_confirm_key, _confirm_glyph, "[ENTER]",
		_confirm_label.position.x - KEY_TO_LABEL_GAP, confirm_text.is_empty())

	# Back pair sits PAIR_GAP px to the left of the confirm KEY (or pad
	# glyph), not the confirm label: the key is drawn left of its label.
	var back_edge: float = _confirm_key.position.x
	if _laid_out_for_pad:
		back_edge = _confirm_glyph.position.x
	if confirm_text.is_empty():
		back_edge = right_x
	_back_label.size = Vector2(UiText.body_width(back_text), 12.0)
	_back_label.position = Vector2(
		back_edge - PAIR_GAP - _back_label.size.x, LABEL_Y)
	_back_label.visible = not back_text.is_empty()
	_layout_key(_back_key, _back_glyph, "[BKSP]",
		_back_label.position.x - KEY_TO_LABEL_GAP, back_text.is_empty())

	# The left description gets only the room left of the back pair, so a
	# long description can never run under the key prompts.
	if _left_label != null:
		var back_left: float = _back_glyph.position.x if _laid_out_for_pad else _back_key.position.x
		_left_label.clip_text = true
		_left_label.size = Vector2(maxf(0.0, back_left - PAIR_GAP - LEFT_X), 12.0)


func _layout_key(key: Label, glyph: TextureRect, key_name: String,
		right_edge: float, hidden: bool) -> void:
	# Keyboard: the bracketed key name as text. Pad: the A/B sprite.
	key.text = key_name
	key.size = Vector2(UiText.body_width(key_name), 12.0)
	key.position = Vector2(roundi(right_edge - key.size.x), LABEL_Y)
	glyph.position = Vector2(roundi(right_edge - 9.0), GLYPH_Y)
	key.visible = not hidden
	glyph.visible = false  # _refresh_device() flips this for pad input


func set_left_text(text: String) -> void:
	# The main menu's description line rides the prompt plate on the left
	# and updates as the selection moves.
	if _left_label != null:
		_left_label.text = text


func _process(_delta: float) -> void:
	_refresh_device()


func _refresh_device() -> void:
	var pad := ScreenRouter.last_device_was_pad()
	if pad != _laid_out_for_pad:
		# The pad glyph (9 px) is narrower than "[ENTER]", so re-lay the
		# pairs whenever the last-used device changes.
		_laid_out_for_pad = pad
		_layout(_confirm_text, _back_text)
	_confirm_key.visible = not pad and _confirm_label.visible
	_back_key.visible = not pad and _back_label.visible
	_confirm_glyph.visible = pad and _confirm_label.visible
	_back_glyph.visible = pad and _back_label.visible


func _make_glyph(texture: Texture2D, at: Vector2) -> TextureRect:
	var rect := TextureRect.new()
	rect.texture = texture
	rect.position = at
	rect.size = GLYPH_SIZE
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return rect
