# Headless test for the Phase 2 “The Clip” intro and its handoff.
extends SceneTree

const MAIN_SCENE := preload("res://scenes/main/Main.tscn")
const INTRO_SCRIPT := preload("res://scripts/ui/the_clip.gd")
const PANEL_DATA_PATH := "res://data/story/the_clip.panels"

var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _check(label: String, condition: bool, detail: String = "") -> void:
	if condition:
		print("PASS: ", label)
	else:
		failures += 1
		print("FAIL: ", label, "  ", detail)

func _press_intro(intro: Control, action: String) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	intro._unhandled_input(event)

func _run() -> void:
	var file := FileAccess.open(PANEL_DATA_PATH, FileAccess.READ)
	var panel_data: Variant = JSON.parse_string(file.get_as_text()) if file else null
	var validation_errors := INTRO_SCRIPT.validate_panel_data(panel_data)
	_check("owner-editable panel data validates", validation_errors.is_empty(),
		str(validation_errors))

	var panels: Array = panel_data.get("panels", []) if typeof(panel_data) == TYPE_DICTIONARY else []
	_check("script has 15 panels in authored order",
		panels.size() == 15 and _panels_in_order(panels),
		"panel count=%d" % panels.size())
	_check("every panel has visible story text and a sane hold duration",
		_panels_have_text_and_sane_holds(panels), "panel text/duration validation failed")
	_check("authored unskipped runtime is about 45 seconds",
		is_equal_approx(_total_hold_seconds(panels), 45.0),
		"runtime=%.1fs" % _total_hold_seconds(panels))
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

	var advance_main: Node = MAIN_SCENE.instantiate()
	root.add_child(advance_main)
	await process_frame
	_check("boot starts in The Clip before character select",
		advance_main.intro != null and advance_main.character_select == null
			and advance_main.match_root == null,
		"boot did not start on intro")
	if advance_main.intro != null:
		var intro: Control = advance_main.intro
		_press_intro(intro, "ui_confirm")
		_check("Enter/UI confirm advances immediately",
			intro.current_panel_index == 1,
			"current panel=%d" % intro.current_panel_index)
		intro._process(float(intro.panels[1].hold_seconds))
		_check("authored hold duration auto-advances a panel",
			intro.current_panel_index == 2,
			"current panel=%d" % intro.current_panel_index)
		for step in 13:
			_press_intro(intro, "p1_light" if step % 2 == 0 else "p2_light")
		await process_frame
		_check("player confirm advances all panels into character select",
			advance_main.intro == null and advance_main.character_select != null,
			"intro/select state incorrect after final panel")
	else:
		_check("player confirm advances all panels into character select", false,
			"intro scene unavailable")
	advance_main.audio_manager.stop_all()
	advance_main.queue_free()
	for frame in 12:
		await process_frame

	var skip_main: Node = MAIN_SCENE.instantiate()
	root.add_child(skip_main)
	await process_frame
	if skip_main.intro != null:
		_press_intro(skip_main.intro, "p1_pause")
	await process_frame
	_check("Esc skips the intro directly to character select",
		skip_main.intro == null and skip_main.character_select != null
			and skip_main.match_root == null,
		"skip did not hand off to character select")
	skip_main.audio_manager.stop_all()
	skip_main.queue_free()
	for frame in 12:
		await process_frame

	print("\n%d failure(s)" % failures)
	quit(1 if failures > 0 else 0)

func _panels_in_order(panels: Array) -> bool:
	for index in panels.size():
		if typeof(panels[index]) != TYPE_DICTIONARY \
				or int(panels[index].get("number", -1)) != index + 1:
			return false
	return true

func _panels_have_text_and_sane_holds(panels: Array) -> bool:
	for panel in panels:
		if typeof(panel) != TYPE_DICTIONARY:
			return false
		if float(panel.get("hold_seconds", 0.0)) < 1.5 \
				or float(panel.get("hold_seconds", 0.0)) > 6.0:
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

func _total_hold_seconds(panels: Array) -> float:
	var total := 0.0
	for panel in panels:
		total += float(panel.get("hold_seconds", 0.0))
	return total

func _caption_has_fine_print_copy(panel: Dictionary) -> bool:
	for caption in panel.get("caption_text", []):
		var text := str(caption.get("text", "")).to_lower()
		if text.contains("terms apply") or text.contains("expires") or text.contains("conditions"):
			return true
	return false
