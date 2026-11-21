# UiPromptLine — the confirm/back glyph prompt shared by every screen
# (docs/UI_HUD_SCREENS_PLAN.md: keyboard or pad glyphs matching the last
# device used). Built in code, polls ScreenRouter's device flag each frame;
# pure presentation, no input handling of its own.
class_name UiPromptLine
extends Control

const THEME_RESOURCE := preload("res://resources/ui_theme.tres")
const GLYPH_KEY := preload("res://art/ui/ui/ui_glyph_key_blank.png")
const GLYPH_PAD_A := preload("res://art/ui/ui/ui_glyph_pad_a.png")
const GLYPH_PAD_B := preload("res://art/ui/ui/ui_glyph_pad_b.png")
const GLYPH_SIZE := Vector2(9, 9)
const WARM_YELLOW := Color(0.949, 0.82, 0.227)
const MUTED := Color(0.75, 0.72, 0.68)

var _confirm_glyph: TextureRect
var _confirm_label: Label
var _back_glyph: TextureRect
var _back_label: Label


func _init(confirm_text: String, back_text: String) -> void:
	theme = THEME_RESOURCE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)

	_back_glyph = _make_glyph(GLYPH_KEY, Vector2(12, 166))
	add_child(_back_glyph)
	_back_label = _make_label(back_text, Vector2(24, 164), MUTED)
	_back_label.size = Vector2(120, 16)
	add_child(_back_label)

	_confirm_label = _make_label(confirm_text, Vector2(160, 164), WARM_YELLOW)
	_confirm_label.size = Vector2(136, 16)
	_confirm_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(_confirm_label)
	_confirm_glyph = _make_glyph(GLYPH_KEY, Vector2(300, 166))
	add_child(_confirm_glyph)

	_refresh_device()


func _process(_delta: float) -> void:
	_refresh_device()


func _refresh_device() -> void:
	var pad := ScreenRouter.last_device_was_pad()
	# Confirm = pad A / any key; back = pad B / any key.
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


func _make_label(text: String, at: Vector2, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.position = at
	label.size = Vector2(296, 16)
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label
