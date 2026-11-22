# select_screens_test.gd — pins for the PR A street-junk reskins of the
# four select screens (docs/UI_SCREENS.md): the Mode and Difficulty choices
# are unchanged (names, order, defaults, emits, back paths), the rap sheet
# shows the focused fighter's booking details, cursors are per-player
# scribbles, the focused stage ticket lifts 2 px with a yellow frame, and
# the RANDOM scratch-off reveals over 18 frames before the same hand-off
# the old logic performed. Presentation only — nothing here touches the
# simulation.
extends SceneTree

const MODE_SCENE := preload("res://scenes/menus/ModeSelect.tscn")
const DIFFICULTY_SCENE := preload("res://scenes/menus/DifficultySelect.tscn")
const CHARACTER_SCENE := preload("res://scenes/menus/CharacterSelect.tscn")
const STAGE_SCENE := preload("res://scenes/menus/StageSelect.tscn")

var failures := 0
var checks := 0


func _initialize() -> void:
	_run.call_deferred()


func _check(label: String, condition: bool, detail: String = "") -> void:
	checks += 1
	if condition:
		print("PASS: ", label)
	else:
		failures += 1
		print("FAIL: ", label, "  ", detail)


func _press(target: Node, action: String) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	target._unhandled_input(event)


func _press_key(target: Node, code: int) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	event.device = -1
	target._unhandled_input(event)


func _open(scene: Node) -> void:
	root.add_child(scene)
	await process_frame


func _step(frames: int) -> void:
	for _frame in frames:
		await physics_frame


func _run() -> void:
	await process_frame
	await _test_mode_select()
	await _test_difficulty_select()
	await _test_character_select()
	await _test_stage_select()
	print("select_screens_test: %d checks, %d failure(s)" % [checks, failures])
	quit(1 if failures > 0 else 0)


# ---------------- Mode select ----------------

func _test_mode_select() -> void:
	var mode: Control = MODE_SCENE.instantiate()
	await _open(mode)
	_check("mode select still defaults to 1 PLAYER",
		mode.index == 0 and mode.MODES[0]["name"] == "1 PLAYER"
			and mode.MODES[1]["name"] == "2 PLAYERS",
		"index=%d" % mode.index)

	var solo_events: Array = []
	mode.mode_chosen.connect(func(solo: bool): solo_events.append(solo))
	_press(mode, "p1_light")
	_check("confirming from 1 PLAYER still chooses solo",
		solo_events == [true], "events=%s" % str(solo_events))
	mode.free()
	await process_frame

	mode = MODE_SCENE.instantiate()
	await _open(mode)
	var versus_events: Array = []
	mode.mode_chosen.connect(func(solo: bool): versus_events.append(solo))
	_press(mode, "p1_right")
	_press(mode, "p1_light")
	_check("moving right and confirming still chooses versus",
		versus_events == [false], "events=%s" % str(versus_events))
	mode.free()
	await process_frame

	mode = MODE_SCENE.instantiate()
	await _open(mode)
	var back_events := [0]
	mode.back_requested.connect(func(): back_events[0] += 1)
	_press(mode, "ui_back")
	_check("ui_back on mode select still requests the flow back",
		back_events[0] == 1, "backs=%d" % back_events[0])
	mode.free()
	await process_frame


# ---------------- Difficulty select ----------------

func _test_difficulty_select() -> void:
	var difficulty: Control = DIFFICULTY_SCENE.instantiate()
	await _open(difficulty)
	_check("difficulty select keeps EASY/NORMAL/HARD in order and defaults to NORMAL",
		difficulty.index == 1
			and difficulty.LEVELS[0]["name"] == "EASY"
			and difficulty.LEVELS[1]["name"] == "NORMAL"
			and difficulty.LEVELS[2]["name"] == "HARD",
		"index=%d" % difficulty.index)

	_check("the difficulty rows draw 1/2/3 tally marks",
		difficulty._tallies[0].size() == 1
			and difficulty._tallies[1].size() == 2
			and difficulty._tallies[2].size() == 3,
		"tallies=%d/%d/%d" % [difficulty._tallies[0].size(),
			difficulty._tallies[1].size(), difficulty._tallies[2].size()])

	var level_events: Array = []
	difficulty.difficulty_chosen.connect(func(level: int): level_events.append(level))
	_press(difficulty, "p1_light")
	_check("confirming from NORMAL still emits level 1",
		level_events == [1], "events=%s" % str(level_events))
	difficulty.free()
	await process_frame

	difficulty = DIFFICULTY_SCENE.instantiate()
	await _open(difficulty)
	var back_events := [0]
	difficulty.back_requested.connect(func(): back_events[0] += 1)
	_press_key(difficulty, KEY_BACKSPACE)
	_check("Backspace on difficulty still requests the flow back",
		back_events[0] == 1, "backs=%d" % back_events[0])
	difficulty.free()
	await process_frame


# ---------------- Character select ----------------

func _test_character_select() -> void:
	var select: Control = CHARACTER_SCENE.instantiate()
	select.solo = false
	await _open(select)

	var sheet_name := " ".join(select._sheet_name_lines.map(
		func(line: Label): return line.text)).strip_edges()
	_check("the rap sheet shows the focused fighter's roster name",
		sheet_name == "PEG LEG PEGGY",
		"name=%s" % sheet_name)
	var sheet_details: Array[String] = []
	for line in select._sheet_detail_lines:
		if not line.text.is_empty():
			sheet_details.append(line.text)
	_check("the rap sheet carries archetype, tagline and tally details",
		sheet_details.size() >= 2
			and select._sheet_tally[0].visible
			and select._sheet_tally[1].visible
			and not select._sheet_tally[2].visible,
		"details=%s" % str(sheet_details))
	_check("the clipboard carries the focused fighter's booking photo",
		select._sheet_portrait.texture != null
			and select._sheet_portrait.texture.get_size() == Vector2(22, 22),
		"photo=%s" % str(select._sheet_portrait.texture))

	# P2 moving its own cursor moves the rap sheet to P2's fighter.
	_press(select, "p2_left")
	_check("P2's pad moves its own cursor and the rap sheet follows",
		select.p2_choice == 0 and select._p2_scribble.visible
			and " ".join(select._sheet_name_lines.map(
				func(line: Label): return line.text)).strip_edges() == "PEG LEG PEGGY"
			and select._p1_scribble.position.x == 44.0,
		"p2_choice=%d" % select.p2_choice)
	_press(select, "p2_right")
	var p2_name := " ".join(select._sheet_name_lines.map(
		func(line: Label): return line.text)).strip_edges()
	_check("the rap sheet shows the P2-focused fighter after a P2 move",
		p2_name == "WHISKEY RICHARD",
		"name=%s" % p2_name)
	_check("the P2 fighter's tally marks replace the P1 fighter's",
		select._sheet_tally[0].visible
			and select._sheet_tally[1].visible
			and select._sheet_tally[2].visible,
		"tallies visible=%s/%s/%s" % [str(select._sheet_tally[0].visible),
			str(select._sheet_tally[1].visible),
			str(select._sheet_tally[2].visible)])

	_check("the cursors are per-player scribbles in the side accents",
		select._p1_scribble.kind == 0
			and select._p1_scribble.accent == Color("f29e26")
			and select._p2_scribble.kind == 1
			and select._p2_scribble.accent == Color("e5473a"),
		"kinds=%d/%d" % [select._p1_scribble.kind, select._p2_scribble.kind])
	select.free()
	await process_frame

	# Solo: P2's scribble stays hidden until P1 locks a pick.
	var solo_select: Control = CHARACTER_SCENE.instantiate()
	solo_select.solo = true
	await _open(solo_select)
	_check("solo keeps the P2 scribble hidden until P1 locks",
		not solo_select._p2_scribble.visible, "p2 scribble visible")
	_press(solo_select, "p1_light")
	_check("P1's lock reveals the P2 opponent scribble",
		solo_select._p2_scribble.visible, "p2 scribble hidden after lock")
	solo_select.free()
	await process_frame


# ---------------- Stage select ----------------

func _test_stage_select() -> void:
	var roster: MatchRoster = MatchRoster.load_default()
	var select: Control = STAGE_SCENE.instantiate()
	select.roster = roster
	await _open(select)

	_check("RANDOM starts covered with no thumbnail",
		select._thumbnails[select.random_index()].texture == null,
		"RANDOM thumbnail is set")

	# Focus: the focused ticket lifts 2 px with a 1 px yellow frame.
	_press(select, "p1_right")
	_check("the focused ticket lifts 2 px with a yellow frame",
		select.index == 1
			and select._tickets[1].position.y == 46.0 - 2.0
			and select._frames[1].visible
			and select._tickets[0].position.y == 46.0,
		"index=%d lift=%s frame=%s" % [select.index,
			str(select._tickets[1].position.y),
			str(select._frames[1].visible)])

	# Concrete stages hand off immediately (unchanged timing).
	var chosen: Array = []
	select.stage_chosen.connect(func(stage: StageData, stage_id: String):
		chosen.append(stage_id))
	_press(select, "p1_light")
	await process_frame
	_check("a concrete stage still hands off immediately",
		chosen == ["bus_stop_night"]
			and select.resolved_stage_id == "bus_stop_night",
		"chosen=%s" % str(chosen))
	select.free()
	await process_frame

	# RANDOM: 18-frame scratch-off, then the same hand-off.
	select = STAGE_SCENE.instantiate()
	select.roster = roster
	await _open(select)
	var reveal_chosen: Array = []
	select.stage_chosen.connect(func(stage: StageData, stage_id: String):
		reveal_chosen.append(stage_id))
	select.index = select.random_index()
	select.rng.seed = 11
	_press(select, "p1_light")
	await _step(17)
	_check("the scratch-off holds the hand-off for its full 18 frames",
		reveal_chosen.is_empty(),
		"handed off early: %s" % str(reveal_chosen))
	await _step(3)
	_check("the scratch-off hands off the stage the RNG picked after 18 frames",
		reveal_chosen.size() == 1
			and reveal_chosen[0] == select.resolved_stage_id
			and roster.stages.any(func(stage: StageData):
				return stage.id == reveal_chosen[0]),
		"chosen=%s resolved=%s" % [str(reveal_chosen), select.resolved_stage_id])
	var revealed: Texture2D = select._thumbnails[select.random_index()].texture
	var source: Texture2D = revealed if revealed is not AtlasTexture \
		else (revealed as AtlasTexture).atlas
	var drawn: StageData = null
	for stage in roster.stages:
		if stage.id == select.resolved_stage_id:
			drawn = stage
	_check("the revealed thumbnail is the drawn stage's art",
		drawn != null and source == drawn.thumbnail,
		"revealed source=%s" % (source.resource_path if source != null else "null"))

	# Back still leaves (and never during the reveal).
	var backs := [0]
	select.back_requested.connect(func(): backs[0] += 1)
	_press_key(select, KEY_BACKSPACE)
	_check("Backspace still leaves the stage select after the reveal",
		backs[0] == 1, "backs=%d" % backs[0])
	select.free()
	await process_frame
