# UiText — the Phase 1 typography rules as code (docs/UI_SCREENS.md).
#
# Two fonts only:
#   - Sidewalk Marker (BMFont, native size 10) for headers, menu items,
#     button labels and short labels. The _outline variant goes where text
#     sits directly over art; the baked dark outline stays dark, the fill
#     recolors with font_color.
#   - m5x7 (native size 16) for body text and descriptions.
# Bangers lives only inside the logo art. Pixel fonts are never given a
# Godot theme outline or shadow: contrast comes from the _outline font or
# a plate behind the text. Integer positions only, no scaling on text
# nodes, no extra letter tracking (the font's own spacing is the spacing).
#
# Spacing conventions: 8 px screen margins, a 4 px grid, line height 12
# for Sidewalk Marker and 16 for m5x7, body text left-aligned, at most
# about 36 characters per m5x7 line.
class_name UiText

const MARKER := preload("res://assets/fonts/sidewalk_marker.fnt")
const MARKER_OUTLINE := preload("res://assets/fonts/sidewalk_marker_outline.fnt")
const M5X7 := preload("res://assets/fonts/m5x7.ttf")

const MARKER_SIZE := 10
const M5X7_SIZE := 16
const MARKER_LINE_HEIGHT := 12
const M5X7_LINE_HEIGHT := 16

# Shared palette (docs/UI_HUD_SCREENS_PLAN.md, tightened for the screens).
const YELLOW := Color("F2D13A")        # focus / prompt accents
const CREAM_TEXT := Color("F4EEDC")    # default text on dark plates
const MUTED := Color("9C8F70")         # greyed items, inactive tabs
const INK := Color("2A2418")           # dark ink on the cream slats
const INK_DARK := Color("1C160D")      # focused ink + baked outline color


static func marker(text: String, at: Vector2, color: Color = CREAM_TEXT,
		use_outline: bool = false) -> Label:
	return _make_label(text, MARKER_OUTLINE if use_outline else MARKER,
		MARKER_SIZE, at, color)


static func body(text: String, at: Vector2, color: Color = CREAM_TEXT) -> Label:
	return _make_label(text, M5X7, M5X7_SIZE, at, color)


static func marker_width(text: String) -> float:
	return _text_width(MARKER, MARKER_SIZE, text)


static func body_width(text: String) -> float:
	return _text_width(M5X7, M5X7_SIZE, text)


static func _text_width(font: Font, size: int, text: String) -> float:
	return ceili(font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT,
		-1, size).x)


static func _make_label(text: String, font: Font, size: int, at: Vector2,
		color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.position = Vector2(roundi(at.x), roundi(at.y))
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Typography rule: no Godot outline or shadow on a pixel font. These
	# overrides pin the default to 0 so a stray theme can never add one.
	label.add_theme_constant_override("outline_size", 0)
	label.add_theme_constant_override("shadow_size_x", 0)
	label.add_theme_constant_override("shadow_size_y", 0)
	return label


static func center_on(rect: Control, center_x: float) -> void:
	# Integer horizontal centering of a sized control (4 px grid friendly).
	rect.position = Vector2(roundi(center_x - rect.size.x / 2.0), rect.position.y)
