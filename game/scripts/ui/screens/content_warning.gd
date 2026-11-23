# ContentWarning — the boot notice (shown once per launch).
# A plain, sober notice on one centered ui_panel: a short mature-content
# line and a short photosensitivity line in m5x7, a Sidewalk Marker header.
# No auto-advance (owner playtest change, 2026-11-21): the player must
# press confirm, and confirm is ignored for the first 30 frames so a key
# held at boot cannot skip the screen. UI timers count frames, never
# wall-clock. Pure presentation.
extends Control

signal warning_done

const THEME_RESOURCE := preload("res://resources/ui_theme.tres")
const GLYPH_PAD_A := preload("res://art/ui/ui/ui_glyph_pad_a.png")
const GLYPH_PAD_B := preload("res://art/ui/ui/ui_glyph_pad_b.png")
const GLYPH_PAD_X := preload("res://art/ui/ui/ui_glyph_pad_x.png")
const GLYPH_PAD_Y := preload("res://art/ui/ui/ui_glyph_pad_y.png")

const PANEL_POS := Vector2(40, 42)
const PANEL_SIZE := Vector2(240, 96)
const INPUT_GUARD_FRAMES := 30

var _frames := 0
var _done := false
var _key_label: Label
var _glyph: TextureRect
var _left_label: Label
var _right_label: Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.03, 0.04, 0.92)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)

	var panel := Panel.new()
	panel.theme = THEME_RESOURCE
	panel.position = PANEL_POS
	panel.size = PANEL_SIZE
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel)

	# Dark ink on the cardboard panel (docs/UI_SCREENS.md contrast rules).
	var header := UiText.marker("HEADS UP", Vector2(PANEL_POS.x, PANEL_POS.y + 8),
		UiText.INK)
	header.size = Vector2(PANEL_SIZE.x, UiText.MARKER_LINE_HEIGHT)
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(header)

	var line1 := UiText.body("THIS GAME CONTAINS MATURE CONTENT.",
		Vector2(PANEL_POS.x + 8, PANEL_POS.y + 26), UiText.INK)
	add_child(line1)
	var line2 := UiText.body("FLASHING LIGHTS. MIND YOUR EYES.",
		Vector2(PANEL_POS.x + 8, PANEL_POS.y + 42), UiText.INK)
	add_child(line2)

	_build_press_row(PANEL_POS.y + 70)


func _build_press_row(at_y: int) -> void:
	# "PRESS [ENTER] TO CONTINUE" as one centered row (Sidewalk Marker, dark
	# ink) inside the panel; a pad shows the A glyph instead of the bracketed
	# key name. No second prompt line below the panel.
	_left_label = UiText.marker("PRESS ", Vector2.ZERO, UiText.INK)
	_key_label = UiText.marker("[ENTER]", Vector2.ZERO, UiText.INK_MUTED)
	_right_label = UiText.marker(" TO CONTINUE", Vector2.ZERO, UiText.INK)
	_glyph = TextureRect.new()
	_glyph.texture = GLYPH_PAD_A
	_glyph.size = Vector2(9, 9)
	_glyph.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_left_label)
	add_child(_key_label)
	add_child(_glyph)
	add_child(_right_label)
	_refresh_prompt(at_y)


func _process(_delta: float) -> void:
	_refresh_prompt(PANEL_POS.y + 70)


func _refresh_prompt(at_y: int) -> void:
	var pad := ScreenRouter.last_device_was_pad()
	var player := "p2" if pad else "p1"
	var control_id := "p2_ui_confirm" if pad else "p1_ui_confirm"
	var binding := "A" if pad else "ENTER"
	var settings := get_tree().root.get_node_or_null("Settings")
	if settings != null and settings.controls != null:
		var labels: PackedStringArray = settings.controls.binding_label(
			player, control_id).split(" / ")
		if not labels.is_empty() and labels[0] != "UNBOUND":
			binding = labels[0]
	var texture := _pad_glyph(binding) if pad else null
	var show_glyph := texture != null
	var key_text := "" if show_glyph else "[%s]" % binding
	_key_label.text = key_text
	_key_label.visible = not show_glyph
	_glyph.texture = texture if show_glyph else GLYPH_PAD_A
	_glyph.visible = show_glyph
	var key_width := 9.0 if show_glyph else UiText.marker_width(key_text)
	var total := UiText.marker_width("PRESS ") + key_width \
		+ UiText.marker_width(" TO CONTINUE")
	var x := 160 - total / 2.0
	_left_label.position = Vector2(roundi(x), at_y)
	_key_label.position = Vector2(roundi(x + UiText.marker_width("PRESS ")), at_y)
	_glyph.position = Vector2(roundi(_key_label.position.x + (key_width - 9.0) / 2.0), at_y + 1)
	_right_label.position = Vector2(
		roundi(x + UiText.marker_width("PRESS ") + key_width), at_y)


func _pad_glyph(binding: String) -> Texture2D:
	match binding:
		"A": return GLYPH_PAD_A
		"B": return GLYPH_PAD_B
		"X": return GLYPH_PAD_X
		"Y": return GLYPH_PAD_Y
	return null


func _physics_process(_delta: float) -> void:
	_frames += 1


func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo():
		return
	ScreenRouter.note_input_device(event)
	if _done:
		return
	if _frames < INPUT_GUARD_FRAMES:
		# A key held down at boot must not skip the notice.
		if event.is_action_pressed("ui_confirm") or event.is_action_pressed("p1_light"):
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_confirm") or event.is_action_pressed("p1_light"):
		get_viewport().set_input_as_handled()
		_continue()


func _continue() -> void:
	if _done:
		return
	_done = true
	warning_done.emit()
