# “The Clip” is an owner-editable, data-driven comic intro before character select.
extends Control

signal intro_finished

const PANEL_DATA_PATH := "res://data/story/the_clip.panels"
const BANGERS := preload("res://assets/fonts/Bangers-Regular.ttf")
const COMIC_NEUE := preload("res://assets/fonts/ComicNeue-Regular.ttf")
const COMIC_NEUE_BOLD := preload("res://assets/fonts/ComicNeue-Bold.ttf")
const SHARE_TECH_MONO := preload("res://assets/fonts/ShareTechMono-Regular.ttf")
const CAPTION_STYLES := ["caption", "small", "screen", "banner", "flyer", "logo", "teaser_slot", "sfx"]
const DIALOGUE_STYLES := ["speech", "message", "small", "whisper", "tiny"]
const SFX_EVENTS := ["ui_confirm", "ui_move"]
const INK := Color("#17131a")
const PAPER := Color("#f4e7bd")
const GUTTER := Color("#fffdf7")
const CAPTION_YELLOW := Color("#ffdf4f")
const CHAT_COLORS := [Color("#9cf6e5"), Color("#ff9aad")]
const PANEL_SIZE := Vector2(290, 128)
const CAPTION_OPACITY := 0.78
const BUBBLE_FILL := Color(1.0, 0.996, 0.98, 0.78)

var panels: Array = []
var current_panel_index := 0
var current_panel_step := 0
var audio_manager
var _finished := false
var _hint_clock := 0.0
var _transition_tween: Tween
var _placeholder_art_active := true

var _page_canvas: Control
var _page_border: Panel
var _comic_frame: Panel
var _panel_content: Control
var _art_backdrop: ColorRect
var _art_texture: TextureRect
var _halftone_overlay: ColorRect
var _dynamic_layer: Control
var _page_title: Label
var _panel_counter: Label
var _advance_hint: Label
var _comic_shader: Shader
var _content_top_y := 5.0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if not _load_panel_data():
		push_error("The Clip panel data is invalid; skipping to character select.")
		call_deferred("skip_intro")
		return
	_build_ui()
	_render_panel(0)

func _process(delta: float) -> void:
	if _finished or _advance_hint == null:
		return
	if current_panel_index == 0:
		_hint_clock += delta
		_advance_hint.modulate.a = 0.48 + 0.34 * (0.5 + 0.5 * sin(_hint_clock * TAU * 0.72))
	else:
		_advance_hint.modulate.a = 0.68

func _unhandled_input(event: InputEvent) -> void:
	if _finished or event.is_echo():
		return
	if _is_escape_press(event) or event.is_action_pressed("p1_pause") \
			or event.is_action_pressed("p2_pause"):
		skip_intro()
		get_viewport().set_input_as_handled()
	elif _is_space_press(event):
		advance_panel()
		get_viewport().set_input_as_handled()

static func _is_space_press(event: InputEvent) -> bool:
	if event is InputEventKey:
		return event.pressed and (event.keycode == KEY_SPACE or event.physical_keycode == KEY_SPACE)
	return false

static func _is_escape_press(event: InputEvent) -> bool:
	if event is InputEventKey:
		return event.pressed and (event.keycode == KEY_ESCAPE or event.physical_keycode == KEY_ESCAPE)
	return false

func _load_panel_data() -> bool:
	var file := FileAccess.open(PANEL_DATA_PATH, FileAccess.READ)
	if file == null:
		return false
	var parsed: Variant = parse_panel_data_text(file.get_as_text())
	var errors := validate_panel_data(parsed)
	if not errors.is_empty():
		for error in errors:
			push_error("The Clip panel data: " + error)
		return false
	panels = parsed.get("panels", [])
	return true

static func parse_panel_data_text(source: String) -> Variant:
	var json_lines := PackedStringArray()
	for line in source.split("\n"):
		if line.strip_edges().begins_with("#"):
			continue
		json_lines.append(line)
	return JSON.parse_string("\n".join(json_lines))

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
		var hold: Variant = panel.get("hold_seconds", null)
		if typeof(hold) not in [TYPE_INT, TYPE_FLOAT]:
			errors.append("panel %d deprecated hold_seconds field must remain numeric" % (index + 1))
		var sfx_event: Variant = panel.get("sfx_event", null)
		if sfx_event != null and str(sfx_event) not in SFX_EVENTS:
			errors.append("panel %d sfx_event must reuse ui_confirm or ui_move" % (index + 1))
	return errors

static func manual_steps_for_panel(panel_index: int) -> int:
	match panel_index:
		1: return 3 # Phone-screen line, explanation, landlord aside.
		2: return 5 # Split Tripp's long opening line, chat, reply, undercut.
		3: return 4 # Two exchanges, the final line, then the caption.
		4: return 2 # Main caption then its aside.
		5: return 3 # SFX, shout, undercut caption.
		6: return 2 # Viral caption then commenter aside.
		7: return 3 # Email, main caption, undercut.
		8: return 4 # Split announcement, then main caption and undercut.
		9: return 2 # Flyer caption and fine-print aside.
		10: return 3 # Signup captions, undercut, background shout.
		11: return 3 # Split long speech, then mirror aside.
		12: return 3 # Bracket captions, undercut, Tripp's small line.
		13: return 3 # Slot joke, denial, contract aside.
		14: return 4 # Split long caption, undercut, tiny sign-off.
	return 1

func advance_panel() -> void:
	if _finished:
		return
	if current_panel_step + 1 < manual_steps_for_panel(current_panel_index):
		current_panel_step += 1
		_play_sfx_event("ui_confirm")
		_transition_within_panel()
		return
	if current_panel_index >= panels.size() - 1:
		_play_sfx_event("ui_confirm")
		_finish_intro()
		return
	var next_index := current_panel_index + 1
	var next_event := str(panels[next_index].get("sfx_event", "ui_confirm"))
	_play_sfx_event(next_event)
	current_panel_step = 0
	_transition_to_panel(next_index)

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

func _transition_to_panel(next_index: int) -> void:
	if _transition_tween and _transition_tween.is_running():
		_transition_tween.kill()
	_page_canvas.scale.x = 1.0
	_page_canvas.position.x = 0.0
	_page_canvas.modulate.a = 1.0
	var page_changed := floori(float(next_index) / 4.0) != floori(float(current_panel_index) / 4.0)
	current_panel_index = next_index
	if page_changed:
		_page_canvas.scale.x = 1.0
		_transition_tween = create_tween()
		_transition_tween.tween_property(_page_canvas, "scale:x", 0.025, 0.075) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		_transition_tween.tween_callback(_render_panel.bind(next_index))
		_transition_tween.tween_property(_page_canvas, "scale:x", 1.0, 0.115) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	else:
		_render_panel(next_index)
		_page_canvas.position.x = 9.0
		_page_canvas.modulate.a = 0.55
		_transition_tween = create_tween()
		_transition_tween.set_parallel(true)
		_transition_tween.tween_property(_page_canvas, "position:x", 0.0, 0.12) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_transition_tween.tween_property(_page_canvas, "modulate:a", 1.0, 0.12)

func _transition_within_panel() -> void:
	if _transition_tween and _transition_tween.is_running():
		_transition_tween.kill()
	_page_canvas.scale.x = 1.0
	_page_canvas.position.x = 0.0
	_page_canvas.modulate.a = 1.0
	_render_panel(current_panel_index)
	_page_canvas.position.x = 7.0
	_page_canvas.modulate.a = 0.6
	_transition_tween = create_tween()
	_transition_tween.set_parallel(true)
	_transition_tween.tween_property(_page_canvas, "position:x", 0.0, 0.1) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_transition_tween.tween_property(_page_canvas, "modulate:a", 1.0, 0.1)

func _build_ui() -> void:
	_comic_shader = Shader.new()
	_comic_shader.code = """
	shader_type canvas_item;
	uniform vec4 base_color : source_color = vec4(0.96, 0.91, 0.78, 1.0);
	uniform vec4 dot_color : source_color = vec4(0.08, 0.06, 0.07, 1.0);
	uniform float dot_alpha : hint_range(0.0, 0.5) = 0.09;
	uniform vec2 dot_grid = vec2(42.0, 24.0);
	void fragment() {
		vec2 cell = fract(UV * dot_grid) - vec2(0.5);
		float radius = length(cell);
		float dot_mask = 1.0 - smoothstep(0.105, 0.155, radius);
		COLOR = vec4(mix(base_color.rgb, dot_color.rgb, dot_mask * dot_alpha), base_color.a);
	}
	"""

	var paper := ColorRect.new()
	paper.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	paper.material = _halftone_material(PAPER, 0.12, Vector2(42, 24))
	add_child(paper)

	_page_canvas = Control.new()
	_page_canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_page_canvas.pivot_offset = Vector2(160, 90)
	_page_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_page_canvas)

	_page_border = _surface(Rect2(5, 4, 310, 172), PAPER, INK, 2)
	_page_canvas.add_child(_page_border)
	_page_title = _make_label("", Rect2(12, 6, 236, 13), 8, BANGERS, INK,
		HORIZONTAL_ALIGNMENT_LEFT)
	_page_canvas.add_child(_page_title)
	_panel_counter = _make_label("", Rect2(250, 6, 56, 13), 7, BANGERS, Color("#51463a"),
		HORIZONTAL_ALIGNMENT_RIGHT)
	_page_canvas.add_child(_panel_counter)

	_comic_frame = _surface(Rect2(10, 20, 300, 138), GUTTER, INK, 4)
	_page_canvas.add_child(_comic_frame)
	_panel_content = Control.new()
	_panel_content.position = Vector2(5, 5)
	_panel_content.size = PANEL_SIZE
	_panel_content.clip_contents = true
	_panel_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_comic_frame.add_child(_panel_content)

	_art_backdrop = ColorRect.new()
	_art_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_art_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel_content.add_child(_art_backdrop)
	_art_texture = TextureRect.new()
	_art_texture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_art_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_art_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_art_texture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_art_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel_content.add_child(_art_texture)
	_halftone_overlay = ColorRect.new()
	_halftone_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_halftone_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_halftone_overlay.material = _halftone_overlay_material(0.14)
	_panel_content.add_child(_halftone_overlay)
	_dynamic_layer = Control.new()
	_dynamic_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dynamic_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel_content.add_child(_dynamic_layer)

	_advance_hint = _make_label("SPACE — next   ESC — skip", Rect2(177, 162, 131, 11),
		6, COMIC_NEUE_BOLD, Color("#746b56"), HORIZONTAL_ALIGNMENT_RIGHT)
	_advance_hint.modulate.a = 0.68
	_page_canvas.add_child(_advance_hint)

func _halftone_material(base: Color, alpha: float, grid: Vector2) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = _comic_shader
	material.set_shader_parameter("base_color", base)
	material.set_shader_parameter("dot_color", Color("#322a30"))
	material.set_shader_parameter("dot_alpha", alpha)
	material.set_shader_parameter("dot_grid", grid)
	return material

func _halftone_overlay_material(alpha: float) -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
	shader_type canvas_item;
	uniform vec4 ink_color : source_color = vec4(0.04, 0.03, 0.04, 1.0);
	uniform float dot_alpha : hint_range(0.0, 0.5) = 0.14;
	void fragment() {
		vec2 cell = fract(UV * vec2(42.0, 24.0)) - vec2(0.5);
		float mask = 1.0 - smoothstep(0.105, 0.155, length(cell));
		COLOR = vec4(ink_color.rgb, mask * dot_alpha);
	}
	"""
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("dot_alpha", alpha)
	return material

func _render_panel(index: int) -> void:
	var panel: Dictionary = panels[index]
	var texture: Texture2D
	var slot := str(panel.get("image_slot", ""))
	if slot != "" and ResourceLoader.exists(slot):
		texture = load(slot) as Texture2D
	_placeholder_art_active = texture == null
	if texture == null:
		var fallback := str(panel.get("fallback_image", ""))
		if fallback != "" and ResourceLoader.exists(fallback):
			texture = load(fallback) as Texture2D
	_art_texture.texture = texture
	_art_texture.visible = texture != null
	_art_backdrop.visible = texture == null
	_art_backdrop.color = Color.from_string(str(panel.get("placeholder_color", "#d2b878")), PAPER)
	_art_backdrop.material = _halftone_material(_art_backdrop.color, 0.25, Vector2(38, 24))
	_halftone_overlay.visible = _placeholder_art_active
	_page_title.text = str(panel.get("page_title", "")).to_upper()
	_panel_counter.text = "PANEL %02d / %02d" % [int(panel.get("number", index + 1)), panels.size()]
	_clear_children(_dynamic_layer)
	var captions: Array = panel.get("caption_text", [])
	var displayed_captions := _captions_for_step(index, captions, current_panel_step)
	var dialogue: Array = panel.get("dialogue", [])
	var displayed_dialogue := _dialogue_for_step(index, dialogue, current_panel_step)
	var displayed_chat: Array = panel.get("chat_comments", []) \
		if index != 2 or current_panel_step == 2 else []
	var caption_start_y := 5.0
	if _placeholder_art_active:
		caption_start_y = _render_placeholder(panel, _has_caption_style(captions, ["banner", "logo"]))
	var has_banner := _has_caption_style(captions, ["banner", "logo"])
	if has_banner:
		_render_banner(captions)
		var dual_brand_row := _has_caption_style(captions, ["logo"]) \
			and _has_caption_style(captions, ["banner"])
		caption_start_y = maxf(caption_start_y,
			60.0 if dual_brand_row and _placeholder_art_active else 30.0 if _placeholder_art_active else 29.0)
	_content_top_y = caption_start_y
	if _has_caption_style(captions, ["sfx"]) and current_panel_step == 0:
		_render_sfx()
	elif _has_caption_style(captions, ["flyer"]):
		_render_flyer(panel, captions, displayed_captions)
	else:
		var caption_y := caption_start_y
		if index == 2 and current_panel_step == 4:
			caption_y = 98.0
		elif index == 3 and current_panel_step == 3:
			caption_y = 94.0
		_render_caption_boxes(displayed_captions, caption_y)
		if _has_caption_style(captions, ["teaser_slot"]):
			_render_teaser_slot()
	_render_dialogue(displayed_dialogue, not displayed_chat.is_empty(), index)
	_render_chat(displayed_chat)

func _captions_for_step(panel_index: int, captions: Array, step: int) -> Array:
	if panel_index == 1:
		if step == 0:
			return _captions_with_style(captions, "screen")
		if step == 1:
			return _captions_with_style(captions, "caption")
		return _captions_with_style(captions, "small") if step == 2 else []
	if panel_index == 2:
		return _captions_with_style(captions, "small") if step == 4 else []
	if panel_index == 3:
		return _captions_with_style(captions, "caption") if step == 3 else []
	if panel_index == 4:
		return _captions_with_style(captions, "caption") if step == 0 else \
			(_captions_with_style(captions, "small") if step == 1 else [])
	if panel_index == 5:
		return _captions_with_style(captions, "small") if step == 2 else []
	if panel_index == 6:
		return _captions_with_style(captions, "caption") if step == 0 else \
			(_captions_with_style(captions, "small") if step == 1 else [])
	if panel_index == 7:
		return _captions_with_style(captions, "caption") if step == 1 else \
			(_captions_with_style(captions, "small") if step == 2 else [])
	if panel_index == 8:
		return _captions_with_style(captions, "caption") if step == 2 else \
			(_captions_with_style(captions, "small") if step == 3 else [])
	if panel_index == 9:
		return _captions_with_style(captions, "caption") if step == 0 else \
			(_captions_with_style(captions, "small") if step == 1 else [])
	if panel_index == 10:
		return _captions_with_style(captions, "caption") if step == 0 else \
			(_captions_with_style(captions, "small") if step == 1 else [])
	if panel_index == 11:
		return _captions_with_style(captions, "small") if step == 2 else []
	if panel_index == 12:
		return _captions_with_style(captions, "caption") if step == 0 else \
			(_captions_with_style(captions, "small") if step == 1 else [])
	if panel_index == 13:
		return _captions_with_style(captions, "caption") if step == 0 else \
			(_captions_with_style(captions, "small") if step == 2 else [])
	if panel_index == 14:
		if step in [0, 1]:
			return [_caption_part(_captions_with_style(captions, "caption")[0], step)]
		return _captions_with_style(captions, "small") if step == 2 else []
	return captions

func _dialogue_for_step(panel_index: int, dialogue: Array, step: int) -> Array:
	if panel_index == 2:
		if step in [0, 1]:
			return [_dialogue_part(dialogue[0], step)]
		return [dialogue[1]] if step == 3 else []
	if panel_index == 3:
		if step == 0:
			return [dialogue[0], dialogue[1]]
		if step == 1:
			return [dialogue[2], dialogue[3]]
		return [dialogue[4]] if step == 2 else []
	if panel_index == 5:
		return [dialogue[0]] if step == 1 else []
	if panel_index == 7:
		return [dialogue[0]] if step == 0 else []
	if panel_index == 8:
		return [_dialogue_part(dialogue[0], step)] if step in [0, 1] else []
	if panel_index == 10:
		return [dialogue[0]] if step == 2 else []
	if panel_index == 11:
		return [_dialogue_part(dialogue[0], step)] if step in [0, 1] else []
	if panel_index == 12:
		return [dialogue[0]] if step == 2 else []
	if panel_index == 13:
		return [dialogue[0]] if step == 1 else []
	if panel_index == 14:
		return [dialogue[0]] if step == 3 else []
	return dialogue

func _dialogue_part(entry: Dictionary, part: int) -> Dictionary:
	var result := entry.duplicate()
	result["text"] = _text_part(str(entry.get("text", "")), part)
	return result

func _caption_part(entry: Dictionary, part: int) -> Dictionary:
	var result: Dictionary = entry.duplicate()
	result["text"] = _text_part(str(entry.get("text", "")), part)
	return result

func _text_part(text: String, part: int) -> String:
	var midpoint := int(text.length() / 2)
	var split_at := text.rfind(" ", midpoint)
	if split_at <= 0:
		split_at = text.find(" ", midpoint)
	if split_at <= 0:
		return text
	return text.substr(0, split_at) if part == 0 else text.substr(split_at + 1)

func _captions_with_style(captions: Array, wanted_style: String) -> Array:
	var result: Array = []
	for caption in captions:
		if typeof(caption) == TYPE_DICTIONARY and str(caption.get("style", "")) == wanted_style:
			result.append(caption)
	return result

func _render_placeholder(panel: Dictionary, has_banner: bool) -> float:
	var note_width := 150.0 if has_banner else 232.0
	var note_size := 5 if has_banner else 6
	var note := _make_text_panel(str(panel.get("art_note", "")), Vector2(6, 4), note_width,
		BANGERS, note_size, CAPTION_YELLOW, INK, 3, HORIZONTAL_ALIGNMENT_LEFT,
		30.0 if has_banner else 0.0)
	note.z_index = 4
	_dynamic_layer.add_child(note)
	var badge := _surface(Rect2(247, 4, 36, 20), Color("#fffdf7"), INK, 2)
	badge.z_index = 5
	_dynamic_layer.add_child(badge)
	var number_label := _make_label("%02d" % int(panel.get("number", 1)),
		Rect2(249, 4, 32, 19), 11, BANGERS, INK, HORIZONTAL_ALIGNMENT_CENTER)
	number_label.z_index = 6
	_dynamic_layer.add_child(number_label)
	return note.position.y + note.size.y + 4.0

func _render_caption_boxes(captions: Array, start_y: float) -> void:
	var y := start_y
	for caption in captions:
		if typeof(caption) != TYPE_DICTIONARY:
			continue
		var style := str(caption.get("style", "caption"))
		if style in ["banner", "logo", "flyer", "sfx", "teaser_slot"]:
			continue
		var text := str(caption.get("text", ""))
		var font := BANGERS
		var size := 6
		var fill := CAPTION_YELLOW
		var text_color := INK
		var width := 230.0
		var padding := 3
		if style == "small":
			size = 5
			width = 194.0
			fill = Color("#ffe989")
		elif style == "screen":
			font = SHARE_TECH_MONO
			size = 5
			width = 268.0
			fill = Color(0.025, 0.055, 0.045, 0.84)
			text_color = Color("#a8ffc0")
		fill.a *= CAPTION_OPACITY
		var box := _make_text_panel(text, Vector2(6, y), width, font, size, fill,
			INK, padding, HORIZONTAL_ALIGNMENT_LEFT, 0,
			text_color)
		_dynamic_layer.add_child(box)
		y += box.size.y + 3.0

func _render_banner(captions: Array) -> void:
	var has_logo := _has_caption_style(captions, ["logo"])
	var has_banner := _has_caption_style(captions, ["banner"])
	for caption in captions:
		var style := str(caption.get("style", ""))
		if style not in ["banner", "logo"]:
			continue
		var is_logo := style == "logo"
		var dual_brand_row := has_logo and has_banner and _placeholder_art_active
		var width := 124.0 if _placeholder_art_active else (256.0 if is_logo else 200.0)
		var font_size := 8 if _placeholder_art_active else (10 if is_logo else 8)
		var x := 160.0 if _placeholder_art_active else (PANEL_SIZE.x - width) * 0.5
		var y := 4.0 if _placeholder_art_active else 5.0
		var height := 22.0
		if dual_brand_row and not is_logo:
			x = 6.0
			width = 278.0
			y = 34.0
			font_size = 9
		var fill := Color("#e83d24") if is_logo else Color("#f7a91f")
		if not _placeholder_art_active:
			fill.a = 0.9
		var banner := _make_text_panel(str(caption.get("text", "")), Vector2(x, y),
			width, BANGERS, font_size, fill, INK, 3,
			HORIZONTAL_ALIGNMENT_CENTER, height, Color("#fff5d5"))
		banner.z_index = 12
		_dynamic_layer.add_child(banner)

func _render_teaser_slot() -> void:
	var box := _surface(Rect2(253, 96, 30, 25), Color(1.0, 0.996, 0.97, 0.86), INK, 2)
	box.z_index = 10
	_dynamic_layer.add_child(box)
	var mark := _make_label("?", Rect2(254, 94, 28, 26), 18, BANGERS,
		Color("#d52e26"), HORIZONTAL_ALIGNMENT_CENTER)
	mark.add_theme_constant_override("outline_size", 2)
	mark.add_theme_color_override("font_outline_color", INK)
	mark.z_index = 11
	_dynamic_layer.add_child(mark)

func _render_sfx() -> void:
	var points := PackedVector2Array()
	for index in 24:
		var angle := TAU * float(index) / 24.0
		var radius := 50.0 if index % 2 == 0 else 43.0
		points.append(Vector2(145, 76) + Vector2(cos(angle), sin(angle)) * radius)
	var burst := Polygon2D.new()
	burst.polygon = points
	burst.color = Color("#f33b27")
	burst.z_index = 10
	_dynamic_layer.add_child(burst)
	var outline := Line2D.new()
	var closed_points := points.duplicate()
	closed_points.append(points[0])
	outline.points = closed_points
	outline.width = 3.0
	outline.default_color = INK
	outline.z_index = 11
	_dynamic_layer.add_child(outline)
	var shadow := _make_label("ZOOM", Rect2(67, 55, 160, 42), 32, BANGERS,
		Color("#39212a"), HORIZONTAL_ALIGNMENT_CENTER)
	shadow.rotation_degrees = -7
	shadow.position += Vector2(3, 4)
	shadow.z_index = 12
	_dynamic_layer.add_child(shadow)
	var lettering := _make_label("ZOOM", Rect2(67, 55, 160, 42), 32, BANGERS,
		Color("#fff34d"), HORIZONTAL_ALIGNMENT_CENTER)
	lettering.rotation_degrees = -7
	lettering.add_theme_constant_override("outline_size", 4)
	lettering.add_theme_color_override("font_outline_color", INK)
	lettering.z_index = 13
	_dynamic_layer.add_child(lettering)

func _render_flyer(panel: Dictionary, captions: Array, displayed_captions: Array) -> void:
	if _placeholder_art_active:
		_art_backdrop.visible = true
		_art_backdrop.color = Color("#ffe04e")
		_art_backdrop.material = _halftone_material(_art_backdrop.color, 0.10, Vector2(42, 24))
		_art_texture.visible = false
	for caption in captions:
		var style := str(caption.get("style", ""))
		var text := str(caption.get("text", ""))
		if style == "flyer":
			var display_text := text.to_upper().replace(" $100,000 AND ", "\n$100,000 AND ")
			var headline := _surface(Rect2(6, 5, 278, 35),
				Color(1.0, 0.91, 0.55, 0.84), INK, 2)
			headline.z_index = 11
			_dynamic_layer.add_child(headline)
			var prize := _make_label(display_text,
				Rect2(10, 6, 270, 33), 12, BANGERS, INK, HORIZONTAL_ALIGNMENT_CENTER)
			prize.autowrap_mode = TextServer.AUTOWRAP_OFF
			prize.z_index = 12
			_dynamic_layer.add_child(prize)
	for caption in displayed_captions:
		var style := str(caption.get("style", ""))
		if style in ["caption", "small"]:
			var fill := Color(CAPTION_YELLOW.r, CAPTION_YELLOW.g, CAPTION_YELLOW.b,
				CAPTION_OPACITY)
			var caption_box := _make_text_panel(str(caption.get("text", "")),
				Vector2(6, 101), 212, BANGERS, 5, fill, INK, 3,
				HORIZONTAL_ALIGNMENT_LEFT, 25)
			caption_box.z_index = 15
			_dynamic_layer.add_child(caption_box)
	if str(panel.get("fine_print_render", "")) == "illegible_squiggle":
		_draw_fine_print_squiggle(Vector2(224, 114), 54)

func _draw_fine_print_squiggle(at: Vector2, width: float) -> void:
	var points := PackedVector2Array()
	for index in 17:
		var x := width * float(index) / 16.0
		var y := 2.0 + float((index * 7) % 5)
		points.append(at + Vector2(x, y))
	var squiggle := Line2D.new()
	squiggle.points = points
	squiggle.width = 2.0
	squiggle.default_color = Color("#3d3325")
	squiggle.z_index = 20
	_dynamic_layer.add_child(squiggle)

func _render_dialogue(entries: Array, has_chat: bool, panel_index: int) -> void:
	var valid_entries: Array = []
	for entry in entries:
		if typeof(entry) == TYPE_DICTIONARY:
			valid_entries.append(entry)
	if valid_entries.is_empty():
		return
	if str(valid_entries[0].get("speaker", "")) == "EMAIL":
		_render_email_card(valid_entries[0])
		return
	var bubbles: Array[Panel] = []
	var width := 218.0
	if valid_entries.size() > 1:
		width = 230.0
	elif has_chat:
		width = 178.0
	else:
		var style := str(valid_entries[0].get("style", "speech"))
		if style == "small":
			width = 202.0
		elif style in ["whisper", "tiny"]:
			width = 138.0 if style == "whisper" else 126.0
	for entry_index in valid_entries.size():
		var entry: Dictionary = valid_entries[entry_index]
		var style := str(entry.get("style", "speech"))
		var body_size_override := 5 if panel_index == 3 else -1
		var tail_left := str(entry.get("speaker", "")) == "RICHARD" \
			or (panel_index == 2 and entry_index == 0)
		var bubble := _make_speech_bubble(entry, Vector2.ZERO, width, style,
			tail_left, body_size_override)
		bubbles.append(bubble)
	var total_height := 0.0
	for bubble in bubbles:
		total_height += bubble.size.y + 2.0
	var top := maxf(_content_top_y, PANEL_SIZE.y - total_height - 5.0)
	for bubble in bubbles:
		bubble.position = Vector2((PANEL_SIZE.x - width) * 0.5, top)
		_dynamic_layer.add_child(bubble)
		top += bubble.size.y + 2.0

func _make_speech_bubble(entry: Dictionary, at: Vector2, width: float,
		style: String, tail_left: bool, body_size_override: int = -1) -> Panel:
	var body_size := body_size_override if body_size_override > 0 \
		else 5
	var body_font := COMIC_NEUE if style in ["tiny", "whisper"] else COMIC_NEUE_BOLD
	var body_text := str(entry.get("text", "")).to_upper()
	var body_lines := _wrapped_line_count(body_text, body_font, body_size, width - 16.0)
	var body_height := body_lines * (maxf(body_font.get_height(body_size), body_size + 2) + 2)
	var height := maxf(30.0, body_height + 22.0)
	if style in ["tiny", "whisper"]:
		height = maxf(28.0, body_height + 19.0)
	var bubble := _surface(Rect2(at.x, at.y, width, height), BUBBLE_FILL, INK, 2)
	bubble.z_index = 14
	var stylebox := bubble.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	stylebox.set_content_margin_all(4)
	bubble.add_theme_stylebox_override("panel", stylebox)
	var tail_x := 17.0 if tail_left else width - 25.0
	var tail := Polygon2D.new()
	tail.position = Vector2(tail_x, height - 2.0)
	tail.polygon = PackedVector2Array([Vector2(0, 0), Vector2(14, 0), Vector2(3, 9)])
	tail.color = BUBBLE_FILL
	bubble.add_child(tail)
	var tail_line := Line2D.new()
	tail_line.position = tail.position
	tail_line.points = PackedVector2Array([Vector2(0, 0), Vector2(3, 9), Vector2(14, 0)])
	tail_line.width = 2.0
	tail_line.default_color = INK
	bubble.add_child(tail_line)
	var stack := VBoxContainer.new()
	stack.position = Vector2(5, 4)
	stack.size = Vector2(width - 10, height - 8)
	stack.add_theme_constant_override("separation", 0)
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bubble.add_child(stack)
	var speaker := _make_label(str(entry.get("speaker", "")).to_upper(),
		Rect2(0, 0, width - 12.0, 7), 5, BANGERS,
		_speaker_color(str(entry.get("speaker", ""))),
		HORIZONTAL_ALIGNMENT_CENTER)
	speaker.custom_minimum_size.y = 7
	stack.add_child(speaker)
	var body := _make_label(body_text, Rect2(0, 0, width - 14.0, body_height),
		body_size, body_font, INK, HORIZONTAL_ALIGNMENT_CENTER)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size = Vector2(width - 14.0, body_height)
	stack.add_child(body)
	return bubble

func _render_email_card(entry: Dictionary) -> void:
	var card := _surface(Rect2(25, 51, 240, 72), Color("#fffef7"), INK, 3)
	card.z_index = 14
	_dynamic_layer.add_child(card)
	var header := _surface(Rect2(4, 4, 232, 17), Color("#f52c43"), INK, 2)
	card.add_child(header)
	var bolt := Polygon2D.new()
	bolt.position = Vector2(10, 4)
	bolt.polygon = PackedVector2Array([
		Vector2(8, 0), Vector2(1, 9), Vector2(7, 9), Vector2(4, 17),
		Vector2(15, 6), Vector2(9, 6),
	])
	bolt.color = Color("#fff53d")
	header.add_child(bolt)
	var logo := _make_label("EMAIL", Rect2(25, 2, 196, 14), 9, BANGERS,
		Color("#fff4d8"), HORIZONTAL_ALIGNMENT_CENTER)
	header.add_child(logo)
	var message := _make_label(str(entry.get("text", "")).to_upper(),
		Rect2(9, 25, 222, 42), 8, COMIC_NEUE, INK, HORIZONTAL_ALIGNMENT_CENTER)
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.custom_minimum_size = Vector2(222, 38)
	card.add_child(message)

func _render_chat(comments: Array) -> void:
	if comments.is_empty():
		return
	var width := 72.0
	var content_width := width - 10.0
	var line_count := 0
	for comment in comments:
		line_count += _wrapped_line_count(str(comment).to_upper(), SHARE_TECH_MONO, 6, content_width)
	var height := minf(61.0, line_count * 7.0 + 9.0)
	var chat := _surface(Rect2(PANEL_SIZE.x - width - 4.0, PANEL_SIZE.y - height - 4.0,
		width, height), Color(0.025, 0.035, 0.06, 0.88), Color("#83d7df"), 2)
	chat.z_index = 22
	var stack := VBoxContainer.new()
	stack.position = Vector2(5, 4)
	stack.size = Vector2(width - 10, height - 8)
	stack.add_theme_constant_override("separation", 0)
	chat.add_child(stack)
	for index in comments.size():
		var label := _make_label(str(comments[index]).to_upper(),
			Rect2(0, 0, content_width, 7.0 * _wrapped_line_count(
				str(comments[index]).to_upper(), SHARE_TECH_MONO, 5, content_width)),
			5, SHARE_TECH_MONO, CHAT_COLORS[index % CHAT_COLORS.size()],
			HORIZONTAL_ALIGNMENT_LEFT)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.custom_minimum_size = Vector2(content_width, 7.0 * _wrapped_line_count(
			str(comments[index]).to_upper(), SHARE_TECH_MONO, 5, content_width))
		stack.add_child(label)
	_dynamic_layer.add_child(chat)

func _make_text_panel(text: String, at: Vector2, width: float, font: Font,
		font_size: int, fill: Color, border: Color, padding: int,
		alignment: HorizontalAlignment, fixed_height: float = 0.0,
		text_color: Color = INK) -> Panel:
	var display_text := text.to_upper()
	var inner_width := width - float(padding * 2 + 2)
	var lines := _wrapped_line_count(display_text, font, font_size, inner_width)
	var line_height := maxf(font.get_height(font_size) + 2.0, font_size + 4.0) + 4.0
	var height := fixed_height if fixed_height > 0.0 else lines * line_height + padding * 2 + 2
	var box := _surface(Rect2(at.x, at.y, width, height), fill, border, 2)
	var stylebox := box.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	stylebox.set_content_margin_all(padding)
	box.add_theme_stylebox_override("panel", stylebox)
	var label := _make_label(display_text,
		Rect2(padding, padding, inner_width, maxf(0.0, height - padding * 2 - 2)),
		font_size, font, text_color, alignment)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(label)
	return box

func _wrapped_line_count(text: String, font: Font, font_size: int, width: float) -> int:
	var lines := 1
	var current_width := 0.0
	var space_width := font.get_string_size(" ", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	for word in text.split(" ", false):
		var word_width := font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		if current_width > 0.0 and current_width + space_width + word_width > width:
			lines += 1
			current_width = word_width
		else:
			current_width += (space_width if current_width > 0.0 else 0.0) + word_width
	return maxi(lines, 1)

func _make_label(text: String, rect: Rect2, font_size: int,
		font: Font, color: Color, alignment: HorizontalAlignment) -> Label:
	var label := Label.new()
	label.position = rect.position
	label.size = rect.size
	label.text = text
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func _surface(rect: Rect2, fill: Color, border: Color, border_width: int) -> Panel:
	var panel := Panel.new()
	panel.position = rect.position
	panel.size = rect.size
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(0)
	panel.add_theme_stylebox_override("panel", style)
	return panel

func _speaker_color(speaker: String) -> Color:
	match speaker:
		"PEGGY":
			return Color("#b14d10")
		"RICHARD":
			return Color("#9c3036")
		"TRIPP":
			return Color("#235c91")
		_:
			return INK

func _has_caption_style(captions: Array, styles: Array) -> bool:
	for caption in captions:
		if typeof(caption) == TYPE_DICTIONARY and str(caption.get("style", "")) in styles:
			return true
	return false

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
