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
const GLYPH_PAD_X := preload("res://art/ui/ui/ui_glyph_pad_x.png")
const GLYPH_PAD_Y := preload("res://art/ui/ui/ui_glyph_pad_y.png")
const GLYPH_SIZE := Vector2(9, 9)

# The plate: full width, 12 px tall, flush with the screen bottom.
const PLATE_Y := 168
const PLATE_SIZE := Vector2(320, 12)
# Optical band inside the plate: Godot's m5x7 Label minimum is 13 px high,
# so start its rect one pixel above the 12 px plate. The font's ink still
# lands inside the plate, and the label's bottom stays on the 180 px frame.
const LABEL_Y := 167
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
var _last_confirm_binding := ""
var _last_back_binding := ""


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

	# Confirm pair (rightmost): the live confirm binding or its pad glyph.
	_confirm_label = UiText.body(confirm_text, Vector2.ZERO, UiText.YELLOW)
	add_child(_confirm_label)
	_confirm_key = UiText.body("", Vector2.ZERO, UiText.CREAM_TEXT)
	add_child(_confirm_key)
	_confirm_glyph = _make_glyph(GLYPH_PAD_A, Vector2.ZERO)
	add_child(_confirm_glyph)

	# Back pair to its left: the live back binding or its pad glyph.
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
	_layout_key(_confirm_key, _confirm_glyph,
		_current_binding("ui_confirm", "[ENTER]"),
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
	_layout_key(_back_key, _back_glyph,
		_current_binding("ui_back", "[BKSP]"),
		_back_label.position.x - KEY_TO_LABEL_GAP, back_text.is_empty())

	# The left description gets only the room left of the back pair, so a
	# long description can never run under the key prompts.
	if _left_label != null:
		var back_left: float = _back_glyph.position.x if _laid_out_for_pad else _back_key.position.x
		_left_label.clip_text = true
		_left_label.size = Vector2(maxf(0.0, back_left - PAIR_GAP - LEFT_X), 12.0)


func _layout_key(key: Label, glyph: TextureRect, key_name: String,
		right_edge: float, hidden: bool) -> void:
	# Keyboard and non-face pad inputs use text. Standard face buttons keep
	# their glyphs, selected from the current action binding.
	var binding_name := key_name
	var pad_texture: Texture2D
	if _laid_out_for_pad:
		pad_texture = _pad_glyph(binding_name)
		if pad_texture != null:
			binding_name = ""
		else:
			binding_name = "[%s]" % binding_name
	elif not binding_name.begins_with("["):
		binding_name = "[%s]" % binding_name
	key.text = binding_name
	key.size = Vector2(UiText.body_width(binding_name), 12.0)
	key.position = Vector2(roundi(right_edge - key.size.x), LABEL_Y)
	glyph.position = Vector2(roundi(right_edge - 9.0), GLYPH_Y)
	key.visible = not hidden
	glyph.texture = pad_texture
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
	var device_changed := pad != _laid_out_for_pad
	_laid_out_for_pad = pad
	var confirm_binding := _current_binding("ui_confirm", "[ENTER]")
	var back_binding := _current_binding("ui_back", "[BKSP]")
	if device_changed or confirm_binding != _last_confirm_binding \
			or back_binding != _last_back_binding:
		# The pad glyph (9 px) is narrower than "[ENTER]", so re-lay the
		# pairs whenever the last-used device changes.
		_layout(_confirm_text, _back_text)
		_last_confirm_binding = confirm_binding
		_last_back_binding = back_binding
	_confirm_key.visible = (not pad or _confirm_glyph.texture == null) \
		and _confirm_label.visible
	_back_key.visible = (not pad or _back_glyph.texture == null) \
		and _back_label.visible
	_confirm_glyph.visible = pad and _confirm_glyph.texture != null \
		and _confirm_label.visible
	_back_glyph.visible = pad and _back_glyph.texture != null \
		and _back_label.visible


func _current_binding(action: String, fallback: String) -> String:
	var player := "p2" if _laid_out_for_pad else "p1"
	var control_id := "p1_ui_confirm" if action == "ui_confirm" \
		else "p1_ui_back"
	if player == "p2":
		control_id = "p2_ui_confirm" if action == "ui_confirm" \
			else "p2_ui_back"
	var scene_tree := Engine.get_main_loop() as SceneTree
	if scene_tree == null:
		return fallback.trim_prefix("[").trim_suffix("]")
	var settings := scene_tree.root.get_node_or_null("Settings")
	if settings != null and settings.controls != null:
		var labels: PackedStringArray = settings.controls.binding_label(
			player, control_id).split(" / ")
		if not labels.is_empty() and labels[0] != "UNBOUND":
			return labels[0]
	return fallback.trim_prefix("[").trim_suffix("]")


func _pad_glyph(binding: String) -> Texture2D:
	match binding:
		"A": return GLYPH_PAD_A
		"B": return GLYPH_PAD_B
		"X": return GLYPH_PAD_X
		"Y": return GLYPH_PAD_Y
	return null


func _make_glyph(texture: Texture2D, at: Vector2) -> TextureRect:
	var rect := TextureRect.new()
	rect.texture = texture
	rect.position = at
	rect.size = GLYPH_SIZE
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return rect
