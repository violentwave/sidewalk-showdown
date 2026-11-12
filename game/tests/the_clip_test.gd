# Headless tests for manual progression and the comic intro rendering setup.
extends SceneTree

const MAIN_SCENE := preload("res://scenes/main/Main.tscn")
const INTRO_SCRIPT := preload("res://scripts/ui/the_clip_comic.gd")
const PANEL_DATA_PATH := "res://data/story/the_clip.panels"
const EXPECTED_HOLDS := [3.5, 2.5, 3.5, 2.5, 2.5, 2.0, 2.5, 2.5, 3.5, 4.5, 2.5, 3.5, 2.5, 2.5, 4.5]

var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _check(label: String, condition: bool, detail: String = "") -> void:
	if condition:
		print("PASS: ", label)
	else:
		failures += 1
		print("FAIL: ", label, "  ", detail)

func _press_space(intro: Control) -> void:
	var event := InputEventKey.new()
	event.keycode = KEY_SPACE
	event.physical_keycode = KEY_SPACE
	event.pressed = true
	intro._unhandled_input(event)

func _press_escape(intro: Control) -> void:
	var event := InputEventKey.new()
	event.keycode = KEY_ESCAPE
	event.physical_keycode = KEY_ESCAPE
	event.pressed = true
	intro._unhandled_input(event)

func _start_main() -> Node:
	var main: Node = MAIN_SCENE.instantiate()
	root.add_child(main)
	await process_frame
	if main.intro != null:
		main.intro.audio_manager = null
		main.audio_manager.stop_all()
	return main

func _dispose_main(main: Node) -> void:
	if main.audio_manager != null:
		main.audio_manager.stop_all()
	main.free()
	for _frame in 16:
		await process_frame

func _run() -> void:
	var file := FileAccess.open(PANEL_DATA_PATH, FileAccess.READ)
	var source := file.get_as_text() if file else ""
	var panel_data: Variant = INTRO_SCRIPT.parse_panel_data_text(source)
	var validation_errors := INTRO_SCRIPT.validate_panel_data(panel_data)
	_check("hold_seconds is marked deprecated in the panel-file header",
		source.begins_with("# DEPRECATED FIELD: hold_seconds"), "deprecation header missing")
	_check("owner-editable panel data validates", validation_errors.is_empty(),
		str(validation_errors))

	var panels: Array = panel_data.get("panels", []) if typeof(panel_data) == TYPE_DICTIONARY else []
	_check("script has 15 panels in authored order",
		panels.size() == 15 and _panels_in_order(panels),
		"panel count=%d" % panels.size())
	_check("all 15 panel art slots are installed",
		_panel_art_slots_exist(), "one or more image slots are missing")
	_check("panel copy and deprecated hold values remain present",
		_panels_have_text_and_expected_holds(panels), "copy/hold values changed or missing")
	_check("bracket tease is 15 fighters plus intro-only question slot",
		panels.size() == 15 and panels[12].get("bracket_slots", 0) == 15
			and panels[13].get("teaser_slot", "") == "?",
		"bracket data does not match canon")
	_check("flyer fine print is only an illegible art gag",
		panels.size() == 15
			and panels[9].get("fine_print_render", "") == "illegible_squiggle"
			and str(panels[9].get("art_note", "")).contains("illegible smudge")
			and not _caption_has_fine_print_copy(panels[9]),
		"panel 10 contains legible fine-print copy")
	_check("panel 04 Peggy line matches the owner script",
		panels.size() == 15 and _panel_has_dialogue(panels[3], "PEGGY",
			"You were asleep in a dumpster ten minutes ago."),
		"panel 4 Peggy line mismatch")
	_check("dumpster lid hat is not referenced anywhere in panel data",
		not source.to_lower().contains("dumpster lid"), "stale dumpster lid hat text found")
	_check("stale panel 14 'Terms apply' copy is gone",
		not source.contains("Terms apply"), "stale 'Terms apply' line found")
	_check("panel 14 keeps both halves of the joke",
		panels.size() == 15
			and str(panels[13].get("teaser_slot", "")) == "?"
			and _panel_has_dialogue(panels[13], "TRIPP",
				"That's because there isn't one."),
		"panel 14 teaser slot or denial line missing")
	var split_probe: Control = INTRO_SCRIPT.new()
	_check("split visual beats reconstruct the authored text exactly",
		_split_script_text_is_lossless(split_probe, panels),
		"a split visual beat changed or dropped script text")
	split_probe.free()

	var advance_main: Node = await _start_main()
	_check("boot starts in The Clip before character select",
		advance_main.intro != null and advance_main.character_select == null
			and advance_main.match_root == null,
		"boot did not start on intro")
	if advance_main.intro != null:
		var intro: Control = advance_main.intro
		var enter_event := InputEventKey.new()
		enter_event.keycode = KEY_ENTER
		enter_event.pressed = true
		intro._unhandled_input(enter_event)
		_check("non-Space confirm does not advance a panel",
			intro.current_panel_index == 0, "Enter unexpectedly advanced the intro")
		_press_space(intro)
		_check("one Space press advances exactly one panel",
			intro.current_panel_index == 1, "current panel=%d" % intro.current_panel_index)
		for _step in 80:
			if advance_main.intro == null:
				break
			_press_space(intro)
		await process_frame
		_check("Space on the final panel reaches character select",
			advance_main.intro == null and advance_main.character_select != null
				and advance_main.match_root == null,
			"15 Space presses did not hand off to select")
	else:
		_check("non-Space confirm does not advance a panel", false,
			"intro scene unavailable")
		_check("one Space press advances exactly one panel", false, "intro scene unavailable")
		_check("Space on the final panel reaches character select", false, "intro scene unavailable")
	await _dispose_main(advance_main)

	for panel_index in [0, 7, 14]:
		var skip_main: Node = await _start_main()
		if skip_main.intro != null:
			var skip_intro: Control = skip_main.intro
			var guard := 0
			while skip_intro.current_panel_index < panel_index and guard < 80:
				_press_space(skip_intro)
				guard += 1
			_press_escape(skip_intro)
		await process_frame
		_check("Esc from panel %02d reaches character select" % (panel_index + 1),
			skip_main.intro == null and skip_main.character_select != null
				and skip_main.match_root == null,
			"Esc did not skip from panel %d" % (panel_index + 1))
		await _dispose_main(skip_main)

	var font_main: Node = await _start_main()
	if font_main.intro != null:
		var font_intro: Control = font_main.intro
		_check("all intro labels use bundled fonts with fallback disabled",
			_all_labels_have_sourced_fonts(font_intro),
			"a label has no bundled font override or has system fallback enabled")
		for _step in 10:
			if font_main.intro == null \
					or (font_intro.current_panel_index == 2
						and font_intro.current_panel_step == 2):
				break
			_press_space(font_intro)
		await process_frame
		_check("chat strip appears on panel 03 at its second beat",
			font_main.intro != null and font_intro.current_panel_index == 2
				and font_intro.current_panel_step == 2,
			"panel=%d step=%d" % [font_intro.current_panel_index,
				font_intro.current_panel_step])
		_check("livestream chat uses the bundled monospaced font",
			_chat_uses_share_tech_mono(font_intro), "chat label is not Share Tech Mono")
		font_intro._render_panel(9)
		_check("panel 10 flyer keeps its artwork in nearest-neighbor aspect-fit mode",
			font_intro._art_texture.visible
				and font_intro._art_texture.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				and font_intro._art_texture.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST,
			"flyer overlay hid or cropped the panel art")
	else:
		_check("all intro labels use bundled fonts with fallback disabled", false,
			"intro scene unavailable")
		_check("livestream chat uses the bundled monospaced font", false,
			"intro scene unavailable")
	await _dispose_main(font_main)

	print("\n%d failure(s)" % failures)
	quit(1 if failures > 0 else 0)

func _panels_in_order(panels: Array) -> bool:
	for index in panels.size():
		if typeof(panels[index]) != TYPE_DICTIONARY \
				or int(panels[index].get("number", -1)) != index + 1:
			return false
	return true

func _panel_art_slots_exist() -> bool:
	for panel_index in 15:
		var path := "res://art/story/the_clip/panel_%02d.png" % (panel_index + 1)
		if not ResourceLoader.exists(path):
			return false
	return true

func _split_script_text_is_lossless(intro: Control, panels: Array) -> bool:
	if intro == null or panels.size() != 15:
		return false
	var dialogue_targets := [[2, 0], [8, 0], [11, 0]]
	for target in dialogue_targets:
		var text := str(panels[target[0]].get("dialogue", [])[target[1]].get("text", ""))
		if intro._text_part(text, 0) + " " + intro._text_part(text, 1) != text:
			return false
	var final_caption := ""
	for caption in panels[14].get("caption_text", []):
		if str(caption.get("style", "")) == "caption":
			final_caption = str(caption.get("text", ""))
	return not final_caption.is_empty() \
		and intro._text_part(final_caption, 0) + " " + intro._text_part(final_caption, 1) == final_caption

func _panels_have_text_and_expected_holds(panels: Array) -> bool:
	if panels.size() != EXPECTED_HOLDS.size():
		return false
	for index in panels.size():
		var panel: Variant = panels[index]
		if typeof(panel) != TYPE_DICTIONARY \
				or not is_equal_approx(float(panel.get("hold_seconds", -1)), EXPECTED_HOLDS[index]):
			return false
		var has_text := false
		for caption in panel.get("caption_text", []):
			if not str(caption.get("text", "")).strip_edges().is_empty():
				has_text = true
		for line in panel.get("dialogue", []):
			if not str(line.get("text", "")).strip_edges().is_empty():
				has_text = true
		for comment in panel.get("chat_comments", []):
			if not str(comment).strip_edges().is_empty():
				has_text = true
		if not has_text:
			return false
	return true

func _panel_has_dialogue(panel: Dictionary, speaker: String, text: String) -> bool:
	for line in panel.get("dialogue", []):
		if str(line.get("speaker", "")) == speaker \
				and str(line.get("text", "")) == text:
			return true
	return false

func _all_labels_have_sourced_fonts(node: Node) -> bool:
	if node is Label:
		var font: Font = node.get_theme_font("font")
		if font == null or not font.resource_path.begins_with("res://assets/fonts/"):
			return false
		if font is FontFile and font.allow_system_fallback:
			return false
	for child in node.get_children():
		if not _all_labels_have_sourced_fonts(child):
			return false
	return true

func _chat_uses_share_tech_mono(node: Node) -> bool:
	if node is Label and node.text == "WHO":
		var font: Font = node.get_theme_font("font")
		return font != null and font.resource_path.ends_with("ShareTechMono-Regular.ttf")
	for child in node.get_children():
		if _chat_uses_share_tech_mono(child):
			return true
	return false

func _caption_has_fine_print_copy(panel: Dictionary) -> bool:
	for caption in panel.get("caption_text", []):
		var text := str(caption.get("text", "")).to_lower()
		if text.contains("terms apply") or text.contains("expires") or text.contains("conditions"):
			return true
	return false
