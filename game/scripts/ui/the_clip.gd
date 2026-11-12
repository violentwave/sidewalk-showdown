# “The Clip” is an owner-editable, data-driven comic intro before character select.
extends Control

signal intro_finished

const PANEL_DATA_PATH := "res://data/story/the_clip.panels"
const PAGE_HOLD_MIN := 1.5
const PAGE_HOLD_MAX := 6.0
const CAPTION_STYLES := ["caption", "small", "screen", "banner", "flyer", "logo", "teaser_slot", "sfx"]
const DIALOGUE_STYLES := ["speech", "message", "small", "whisper", "tiny"]
const SFX_EVENTS := ["ui_confirm", "ui_move"]
const INK := Color(0.055, 0.045, 0.055)
const PAPER := Color(0.96, 0.86, 0.62)
const MUTED_PAPER := Color(0.92, 0.88, 0.76)
const CHAT_COLORS := [Color(0.48, 0.94, 0.85), Color(1.0, 0.52, 0.64)]

var panels: Array = []
var current_panel_index := 0
var audio_manager
var _elapsed := 0.0
var _finished := false
var _placeholder_art_active := true
var _panel_dynamic_nodes: Array[Control] = []

var _flat_background: ColorRect
var _art_texture: TextureRect
var _shade: ColorRect
var _placeholder_number: Label
var _page_title: Label
var _panel_counter: Label
var _caption_column: VBoxContainer
var _art_note_panel: PanelContainer
var _dialogue_layer: HBoxContainer
var _chat_panel: PanelContainer
var _chat_column: VBoxContainer

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if not _load_panel_data():
		push_error("The Clip panel data is invalid; skipping to character select.")
		call_deferred("skip_intro")
		return
	_build_ui()
	_show_panel(0)

func _process(delta: float) -> void:
	if _finished or panels.is_empty():
		return
	_elapsed += delta
	var hold_seconds := float(panels[current_panel_index].get("hold_seconds", 3.0))
	if _elapsed >= hold_seconds:
		advance_panel("ui_move")

func _unhandled_input(event: InputEvent) -> void:
	if _finished or event.is_echo():
		return
	if event.is_action_pressed("p1_pause") or event.is_action_pressed("p2_pause"):
		skip_intro()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_confirm") \
			or event.is_action_pressed("p1_light") \
			or event.is_action_pressed("p2_light"):
		advance_panel("ui_confirm")
		get_viewport().set_input_as_handled()

func _load_panel_data() -> bool:
	var file := FileAccess.open(PANEL_DATA_PATH, FileAccess.READ)
	if file == null:
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	var errors := validate_panel_data(parsed)
	if not errors.is_empty():
		for error in errors:
			push_error("The Clip panel data: " + error)
		return false
	panels = parsed.get("panels", [])
	return true

static func validate_panel_data(data: Variant) -> Array[String]:
	var errors: Array[String] = []
	if typeof(data) != TYPE_DICTIONARY:
		errors.append("root must be a JSON object")
		return errors
	var panel_list: Variant = data.get("panels", null)
	if typeof(panel_list) != TYPE_ARRAY or panel_list.size() != 15:
		errors.append("panels must be an ordered array of exactly 15 entries")
		return errors
	if int(data.get("schema_version", 0)) != 1:
		errors.append("schema_version must be 1")
	for index in panel_list.size():
		var panel: Variant = panel_list[index]
		if typeof(panel) != TYPE_DICTIONARY:
			errors.append("panel %d must be an object" % (index + 1))
			continue
		if int(panel.get("number", -1)) != index + 1:
			errors.append("panel %d has an out-of-order number" % (index + 1))
		if str(panel.get("image_slot", "")).is_empty():
			errors.append("panel %d has no image slot" % (index + 1))
		if str(panel.get("page_title", "")).strip_edges().is_empty():
			errors.append("panel %d has no page title" % (index + 1))
		if str(panel.get("art_note", "")).strip_edges().is_empty():
			errors.append("panel %d has no art-direction note" % (index + 1))
		var has_text := false
		var captions: Variant = panel.get("caption_text", [])
		if typeof(captions) != TYPE_ARRAY:
			errors.append("panel %d caption_text must be an array" % (index + 1))
		else:
			for caption in captions:
				if typeof(caption) != TYPE_DICTIONARY:
					errors.append("panel %d has a non-object caption" % (index + 1))
					continue
				if str(caption.get("style", "")) not in CAPTION_STYLES:
					errors.append("panel %d has an unknown caption style" % (index + 1))
				if str(caption.get("text", "")).strip_edges().is_empty():
					errors.append("panel %d has an empty caption" % (index + 1))
				else:
					has_text = true
		var dialogue: Variant = panel.get("dialogue", [])
		if typeof(dialogue) != TYPE_ARRAY:
			errors.append("panel %d dialogue must be an array" % (index + 1))
		else:
			for line in dialogue:
				if typeof(line) != TYPE_DICTIONARY:
					errors.append("panel %d has a non-object dialogue entry" % (index + 1))
					continue
				if str(line.get("speaker", "")).strip_edges().is_empty() \
						or str(line.get("text", "")).strip_edges().is_empty():
					errors.append("panel %d has incomplete dialogue" % (index + 1))
				else:
					has_text = true
				if str(line.get("style", "speech")) not in DIALOGUE_STYLES:
					errors.append("panel %d has an unknown dialogue style" % (index + 1))
		var comments: Variant = panel.get("chat_comments", [])
		if typeof(comments) != TYPE_ARRAY:
			errors.append("panel %d chat_comments must be an array" % (index + 1))
		else:
			for comment in comments:
				if not str(comment).strip_edges().is_empty():
					has_text = true
		if not has_text:
			errors.append("panel %d has no caption, dialogue, or chat text" % (index + 1))
		var hold := float(panel.get("hold_seconds", 0.0))
		if hold < PAGE_HOLD_MIN or hold > PAGE_HOLD_MAX:
			errors.append("panel %d hold_seconds must be between %.1f and %.1f" % [
				index + 1, PAGE_HOLD_MIN, PAGE_HOLD_MAX])
		var sfx_event: Variant = panel.get("sfx_event", null)
		if sfx_event != null and str(sfx_event) not in SFX_EVENTS:
			errors.append("panel %d sfx_event must reuse ui_confirm or ui_move" % (index + 1))
	return errors

func advance_panel(transition_sfx := "ui_confirm") -> void:
	if _finished:
		return
	if current_panel_index + 1 >= panels.size():
		_finish_intro()
		return
	current_panel_index += 1
	_elapsed = 0.0
	_show_panel(current_panel_index, transition_sfx)

func skip_intro() -> void:
	if _finished:
		return
	_play_sfx_event("ui_confirm")
	_finish_intro()

func _finish_intro() -> void:
	if _finished:
		return
	_finished = true
	intro_finished.emit()

func _build_ui() -> void:
	_flat_background = ColorRect.new()
	_flat_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_flat_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_flat_background)

	_art_texture = TextureRect.new()
	_art_texture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_art_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_art_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_art_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_art_texture)

	_shade = ColorRect.new()
	_shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_shade.color = Color(0.02, 0.015, 0.02, 0.28)
	_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_shade)

	_placeholder_number = _add_label("", Vector2(58, 53), Vector2(204, 66), 42,
		Color(1.0, 0.95, 0.83, 0.14), HORIZONTAL_ALIGNMENT_CENTER)
	_page_title = _add_label("", Vector2(8, 2), Vector2(230, 12), 7,
		Color(1.0, 0.88, 0.61), HORIZONTAL_ALIGNMENT_LEFT)
	_panel_counter = _add_label("", Vector2(240, 2), Vector2(72, 12), 7,
		Color(1.0, 0.88, 0.61), HORIZONTAL_ALIGNMENT_RIGHT)

	_caption_column = VBoxContainer.new()
	_caption_column.position = Vector2(8, 18)
	_caption_column.size = Vector2(176, 76)
	_caption_column.add_theme_constant_override("separation", 2)
	_caption_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_caption_column)

	_art_note_panel = _panel(Vector2(192, 18), Vector2(120, 76),
		Color(0.05, 0.045, 0.055, 0.88), Color(0.98, 0.72, 0.28))
	add_child(_art_note_panel)

	_dialogue_layer = HBoxContainer.new()
	_dialogue_layer.position = Vector2(8, 104)
	_dialogue_layer.size = Vector2(304, 44)
	_dialogue_layer.add_theme_constant_override("separation", 4)
	_dialogue_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_dialogue_layer)

	_chat_panel = _panel(Vector2(194, 96), Vector2(118, 52),
		Color(0.035, 0.04, 0.075, 0.94), Color(0.37, 0.82, 0.94))
	_chat_column = VBoxContainer.new()
	_chat_column.add_theme_constant_override("separation", 1)
	_chat_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_chat_panel.add_child(_chat_column)
	_chat_panel.visible = false
	add_child(_chat_panel)

	_add_label("ENTER / PLAYER CONFIRM: NEXT     ESC: SKIP", Vector2(8, 160),
		Vector2(304, 12), 6, Color(0.96, 0.88, 0.72), HORIZONTAL_ALIGNMENT_CENTER)

func _show_panel(index: int, transition_sfx := "") -> void:
	var panel: Dictionary = panels[index]
	var art_slot := str(panel.get("image_slot", ""))
	var texture: Texture2D
	if art_slot != "" and ResourceLoader.exists(art_slot):
		texture = load(art_slot) as Texture2D
	var art_exists := texture != null
	if texture == null:
		var fallback_path := str(panel.get("fallback_image", ""))
		if fallback_path != "" and ResourceLoader.exists(fallback_path):
			texture = load(fallback_path) as Texture2D
	_art_texture.texture = texture
	_art_texture.visible = texture != null
	_placeholder_art_active = not art_exists
	_flat_background.color = Color.from_string(str(panel.get("placeholder_color", "#33303a")),
		Color(0.2, 0.18, 0.22))
	_placeholder_number.visible = not art_exists
	_placeholder_number.text = "PANEL %02d" % int(panel.get("number", index + 1))
	_page_title.text = str(panel.get("page_title", ""))
	_panel_counter.text = "PANEL %02d / %02d" % [int(panel.get("number", index + 1)), panels.size()]
	_art_note_panel.visible = not art_exists
	_clear_children(_art_note_panel)
	if not art_exists:
		var art_label := _new_label(str(panel.get("art_note", "")), Vector2(5, 3),
			Vector2(110, 68), 5, Color(0.98, 0.9, 0.73), HORIZONTAL_ALIGNMENT_LEFT)
		art_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_art_note_panel.add_child(art_label)
	_render_captions(panel.get("caption_text", []))
	_render_dialogue(panel.get("dialogue", []), not panel.get("chat_comments", []).is_empty())
	_render_chat(panel.get("chat_comments", []))
	var event_name := str(panel.get("sfx_event", transition_sfx))
	_play_sfx_event(event_name)

func _render_captions(items: Array) -> void:
	_clear_children(_caption_column)
	for dynamic_node in _panel_dynamic_nodes:
		dynamic_node.free()
	_panel_dynamic_nodes.clear()
	for item in items:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var text := str(item.get("text", ""))
		var style := str(item.get("style", "caption"))
		if style in ["banner", "flyer", "logo", "teaser_slot", "sfx"]:
			_render_special_text(text, style)
		else:
			_caption_column.add_child(_caption_box(text, style))

func _caption_box(text: String, style: String) -> PanelContainer:
	var background := PAPER
	var color := INK
	var font_size := 7
	if style == "small":
		background = MUTED_PAPER
		font_size = 6
	elif style == "screen":
		background = Color(0.025, 0.055, 0.045, 0.98)
		color = Color(0.54, 1.0, 0.69)
		font_size = 6
	var panel := _panel(Vector2.ZERO, Vector2(176, 0), background, INK)
	var label := _new_label(text, Vector2.ZERO, Vector2.ZERO, font_size, color,
		HORIZONTAL_ALIGNMENT_LEFT)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.custom_minimum_size.x = 160
	label.add_theme_constant_override("outline_size", 1)
	label.add_theme_color_override("font_outline_color", INK)
	panel.add_child(label)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	panel.custom_minimum_size.x = 176
	return panel

func _render_special_text(text: String, style: String) -> void:
	var position := Vector2(60, 58)
	var size := Vector2(200, 32)
	var font_size := 14
	var color := Color(1.0, 0.91, 0.56)
	var background := Color(0.12, 0.035, 0.03, 0.96)
	var border := Color(0.02, 0.02, 0.025)
	match style:
		"banner":
			position = Vector2(8, 68)
			size = Vector2(176, 24)
			font_size = 10
			background = Color(0.84, 0.32, 0.08, 0.96)
			color = Color(1.0, 0.95, 0.72)
		"flyer":
			position = Vector2(8, 94)
			size = Vector2(304, 50)
			background = PAPER
			color = INK
			font_size = 11
		"logo":
			position = Vector2(8, 76)
			size = Vector2(176, 24)
			font_size = 10
			background = Color(0.82, 0.29, 0.08, 0.96)
		"teaser_slot":
			position = Vector2(128, 54)
			size = Vector2(64, 58)
			font_size = 32
			background = Color(0.07, 0.055, 0.08, 0.96)
		"sfx":
			position = Vector2(8, 68)
			size = Vector2(176, 38)
			font_size = 16
			background = Color(0.72, 0.12, 0.11, 0.96)
			color = Color(1.0, 1.0, 0.92)
	var panel := _panel(position, size, background, border)
	var label := _new_label(text, Vector2(4, 2), size - Vector2(8, 4), font_size,
		color, HORIZONTAL_ALIGNMENT_CENTER)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_constant_override("outline_size", 1)
	label.add_theme_color_override("font_outline_color", INK)
	panel.add_child(label)
	if style == "flyer" and _placeholder_art_active:
		var squiggle := Line2D.new()
		squiggle.position = Vector2(38, 38)
		squiggle.points = PackedVector2Array([
			Vector2(0, 3), Vector2(7, 0), Vector2(13, 2), Vector2(20, 0),
			Vector2(27, 3), Vector2(34, 1), Vector2(42, 2), Vector2(48, 0),
			Vector2(56, 3), Vector2(63, 1), Vector2(70, 2), Vector2(77, 0),
			Vector2(84, 2), Vector2(91, 0), Vector2(98, 3), Vector2(105, 1),
			Vector2(112, 2), Vector2(119, 0), Vector2(126, 2), Vector2(133, 0),
			Vector2(140, 3), Vector2(147, 1), Vector2(154, 2), Vector2(161, 0),
			Vector2(168, 2), Vector2(175, 0), Vector2(182, 3), Vector2(189, 1),
			Vector2(196, 2), Vector2(203, 0), Vector2(210, 2), Vector2(217, 0)
		])
		squiggle.width = 2.0
		squiggle.default_color = Color(0.26, 0.2, 0.14)
		panel.add_child(squiggle)
	add_child(panel)
	_panel_dynamic_nodes.append(panel)

func _render_dialogue(entries: Array, has_chat: bool) -> void:
	_clear_children(_dialogue_layer)
	var width := 178.0 if has_chat else (150.0 if entries.size() > 1 else 304.0)
	for entry in entries:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var speaker := str(entry.get("speaker", ""))
		var style := str(entry.get("style", "speech"))
		var color := Color(0.96, 0.91, 0.79)
		if speaker == "PEGGY":
			color = Color(1.0, 0.82, 0.56)
		elif speaker == "RICHARD":
			color = Color(1.0, 0.7, 0.67)
		elif speaker == "TRIPP":
			color = Color(0.7, 0.92, 1.0)
		elif speaker == "EMAIL":
			color = Color(0.76, 1.0, 0.76)
		var bubble_color := Color(0.96, 0.94, 0.83, 0.97)
		var bubble := _panel(Vector2.ZERO, Vector2(width, 40), bubble_color, INK)
		bubble.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN \
			if has_chat or entries.size() > 1 else Control.SIZE_EXPAND_FILL
		bubble.custom_minimum_size.x = width
		var stack := VBoxContainer.new()
		stack.add_theme_constant_override("separation", 0)
		stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var speaker_label := _new_label(speaker, Vector2.ZERO, Vector2.ZERO, 6, color,
			HORIZONTAL_ALIGNMENT_LEFT)
		var dialogue_label := _new_label(str(entry.get("text", "")), Vector2.ZERO,
			Vector2.ZERO, 7 if style in ["small", "tiny", "whisper"] else 8,
			INK, HORIZONTAL_ALIGNMENT_LEFT)
		dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		dialogue_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		stack.add_child(speaker_label)
		stack.add_child(dialogue_label)
		bubble.add_child(stack)
		var tail := Polygon2D.new()
		tail.position = Vector2(14, 35)
		tail.polygon = PackedVector2Array([
			Vector2(0, 0), Vector2(14, 0), Vector2(3, 10),
		])
		tail.color = bubble_color
		bubble.add_child(tail)
		var tail_outline := Line2D.new()
		tail_outline.position = tail.position
		tail_outline.points = PackedVector2Array([
			Vector2(0, 0), Vector2(3, 10), Vector2(14, 0),
		])
		tail_outline.width = 2.0
		tail_outline.default_color = INK
		bubble.add_child(tail_outline)
		_dialogue_layer.add_child(bubble)

func _render_chat(comments: Array) -> void:
	_clear_children(_chat_column)
	_chat_panel.visible = not comments.is_empty()
	for index in comments.size():
		var comment := _new_label(str(comments[index]), Vector2.ZERO, Vector2(108, 9), 6,
			CHAT_COLORS[index % CHAT_COLORS.size()],
			HORIZONTAL_ALIGNMENT_LEFT)
		comment.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_chat_column.add_child(comment)

func _panel(at: Vector2, dimensions: Vector2, fill: Color, border: Color) -> PanelContainer:
	var result := PanelContainer.new()
	result.position = at
	result.size = dimensions
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(2)
	result.add_theme_stylebox_override("panel", style)
	return result

func _new_label(text: String, at: Vector2, dimensions: Vector2, font_size: int,
		color: Color, alignment: HorizontalAlignment) -> Label:
	var result := Label.new()
	result.position = at
	result.size = dimensions
	result.text = text
	result.horizontal_alignment = alignment
	result.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	result.add_theme_font_size_override("font_size", font_size)
	result.add_theme_color_override("font_color", color)
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return result

func _add_label(text: String, at: Vector2, dimensions: Vector2, font_size: int,
		color: Color, alignment: HorizontalAlignment) -> Label:
	var result := _new_label(text, at, dimensions, font_size, color, alignment)
	add_child(result)
	return result

func _play_sfx_event(event_name: String) -> void:
	if audio_manager == null:
		return
	match event_name:
		"ui_confirm":
			audio_manager.play_ui_confirm()
		"ui_move":
			audio_manager.play_ui_move()

func _clear_children(parent: Node) -> void:
	for child in parent.get_children():
		child.free()
