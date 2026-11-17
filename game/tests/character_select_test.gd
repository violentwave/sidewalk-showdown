# Headless test for the mode-select and character-select flow.
extends SceneTree

const MAIN_SCENE := preload("res://scenes/main/Main.tscn")

var main_scene: Node
var failures := 0

func _initialize() -> void:
	main_scene = MAIN_SCENE.instantiate()
	root.add_child(main_scene)
	_run.call_deferred()

func _check(label: String, condition: bool, detail: String = "") -> void:
	if condition:
		print("PASS: ", label)
	else:
		failures += 1
		print("FAIL: ", label, "  ", detail)

func _press(target: Control, action: String) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	target._unhandled_input(event)

func _press_key(target: Control, code: int) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = true
	event.device = -1
	target._unhandled_input(event)

func _step(frames: int) -> void:
	for _frame in frames:
		await physics_frame

func _new_main() -> Node:
	var instance: Node = MAIN_SCENE.instantiate()
	root.add_child(instance)
	await process_frame
	instance.intro.skip_intro()
	await process_frame
	return instance

func _choose_two_players(main: Node) -> void:
	_press(main.mode_select, "p1_right")
	_press(main.mode_select, "p1_light")
	await process_frame

func _run() -> void:
	await process_frame
	var intro_song: AudioStreamMP3 = main_scene.audio_manager.intro_music_stream
	_check("the intro song starts on The Clip and loops",
		main_scene.audio_manager.music_player.playing
			and main_scene.audio_manager.music_player.stream == intro_song
			and intro_song != null and intro_song.loop,
		"intro MP3 is not playing as a loop")
	main_scene.intro.skip_intro()
	await process_frame
	_check("the intro hands off to mode select rather than character select",
		main_scene.mode_select != null and main_scene.character_select == null,
		"mode_select=%s character_select=%s" % [
			str(main_scene.mode_select != null),
			str(main_scene.character_select != null)])
	_check("mode select defaults to 1 PLAYER",
		main_scene.mode_select != null and main_scene.mode_select.index == 0,
		"index=%d" % (main_scene.mode_select.index if main_scene.mode_select != null else -1))
	_press(main_scene.mode_select, "p1_right")
	_check("mode select can move to 2 PLAYERS",
		main_scene.mode_select.index == 1,
		"index=%d" % main_scene.mode_select.index)
	_press(main_scene.mode_select, "p1_light")
	await process_frame
	_check("confirming 2 PLAYERS reaches character select",
		main_scene.character_select != null and main_scene.mode_select == null,
		"character_select=%s mode_select=%s" % [
			str(main_scene.character_select != null),
			str(main_scene.mode_select != null)])
	var select: Control = main_scene.character_select
	_check("the intro song continues on character select",
		main_scene.audio_manager.music_player.playing
			and main_scene.audio_manager.music_player.stream == intro_song,
		"character select did not retain intro MP3")

	# Backspace backs out to mode select instead of trapping a mis-picked mode.
	_press_key(select, KEY_BACKSPACE)
	await process_frame
	_check("Backspace from character select returns to mode select",
		main_scene.mode_select != null and main_scene.character_select == null,
		"character_select=%s mode_select=%s" % [
			str(main_scene.character_select != null),
			str(main_scene.mode_select != null)])
	await _choose_two_players(main_scene)
	select = main_scene.character_select

	_check("select screen defaults to Peggy for P1 and Richard for P2",
		select.p1_choice == 0 and select.p2_choice == 1,
		"choices=%d/%d" % [select.p1_choice, select.p2_choice])

	var roster: MatchRoster = main_scene.roster
	_check("the shared roster lists both slice fighters and the Bus Stop stage",
		roster != null and roster.fighters.size() == 2 and roster.stages.size() == 1
			and roster.stages[0].display_name == "Bus Stop (Night)"
			and roster.stages[0].scene != null,
		"fighters=%d stages=%d" % [
			roster.fighters.size() if roster != null else -1,
			roster.stages.size() if roster != null else -1])
	var stage_label := ""
	for child in select.get_children():
		if child is Label and str(child.text).begins_with("STAGE:"):
			stage_label = str(child.text)
	_check("the select screen names the stage from the roster",
		stage_label == "STAGE: BUS STOP (NIGHT)", "label=%s" % stage_label)

	_press(select, "p1_right")
	_check("P1 can move the cursor with its own horizontal controls",
		select.p1_choice == 1,
		"P1 choice=%d" % select.p1_choice)
	_press(select, "p2_left")
	_check("P2 can select independently",
		select.p2_choice == 0,
		"P2 choice=%d" % select.p2_choice)
	_press(select, "p2_light")
	_check("P2 confirmation locks its pick without starting early",
		select.p2_locked and main_scene.match_root == null,
		"locked=%s match=%s" % [str(select.p2_locked), str(main_scene.match_root != null)])
	_press(select, "p2_right")
	_check("moving after confirmation unlocks P2's pick",
		select.p2_choice == 1 and not select.p2_locked,
		"P2 choice=%d locked=%s" % [select.p2_choice, str(select.p2_locked)])
	_press(select, "p2_left")
	_press(select, "p1_light")
	_check("P1 confirmation locks its pick without starting early",
		select.p1_locked and main_scene.match_root == null,
		"locked=%s match=%s" % [str(select.p1_locked), str(main_scene.match_root != null)])
	_press(select, "p2_light")
	await process_frame
	_check("the match starts after both players confirm",
		main_scene.match_root != null,
		"match root was not created")
	if main_scene.match_root != null:
		_check("selected fighter data reaches the match in P1/P2 order",
			main_scene.match_root.p1.data.display_name == "Whiskey Richard"
				and main_scene.match_root.p2.data.display_name == "Peg Leg Peggy",
			"fighters=%s / %s" % [main_scene.match_root.p1.data.display_name,
				main_scene.match_root.p2.data.display_name])
		_check("the match instantiates the roster's stage",
			main_scene.match_root.selected_stage == roster.stages[0]
				and main_scene.match_root.stage.scene_file_path
					== roster.stages[0].scene.resource_path,
			"stage=%s" % main_scene.match_root.stage.scene_file_path)
		await _step(65) # let the round intro finish
		_check("versus mode enables input for both fighters",
			main_scene.match_root.p1.input_enabled
				and main_scene.match_root.p2.input_enabled,
			"p1=%s p2=%s" % [str(main_scene.match_root.p1.input_enabled),
				str(main_scene.match_root.p2.input_enabled)])
		_check("the match switches from intro music to the existing match track",
			main_scene.audio_manager.music_player.playing,
			"match music is not playing")
		var music_stream := main_scene.audio_manager.music_player.stream as AudioStreamMP3
		_check("fight.mp3 is the looping track used only after match start",
			music_stream != null
				and music_stream == main_scene.audio_manager.fight_music_stream
				and music_stream.loop,
			"fight MP3 did not replace intro music for the match")
		main_scene.audio_manager.play_sfx("hit_light")
		_check("the audio manager can play a temporary combat effect",
			main_scene.audio_manager.has_active_sfx(),
			"no SFX player is active")
		for player in main_scene.audio_manager.sfx_players:
			player.stop()
		var light: MoveData = main_scene.match_root.p1.data.find_move(
			MoveData.InputType.LIGHT, MoveData.Stance.STAND)
		var p2: FighterBase = main_scene.match_root.p2
		main_scene.match_root._play_contact_sfx(light, p2, p2.health + 1.0)
		_check("a landed light hit plays the mapped impact cue",
			main_scene.audio_manager.has_active_sfx(),
			"hit SFX did not start")
		for player in main_scene.audio_manager.sfx_players:
			player.stop()
		p2._force_state(FighterBase.State.BLOCKSTUN)
		main_scene.match_root._play_contact_sfx(light, p2, p2.health)
		_check("a blocked hit plays the block cue",
			main_scene.audio_manager.has_active_sfx(),
			"block SFX did not start")

	main_scene.audio_manager.stop_all()
	main_scene.free()
	for _frame in 16:
		await process_frame

	# ---- solo flow: P1 picks both fighters, P2 spawns without input ----
	var solo_main: Node = await _new_main()
	_check("solo leg starts on mode select with 1 PLAYER still selected",
		solo_main.mode_select != null and solo_main.mode_select.index == 0,
		"index=%d" % (solo_main.mode_select.index if solo_main.mode_select != null else -1))
	_press(solo_main.mode_select, "p1_light")
	await process_frame
	var solo_select: Control = solo_main.character_select
	_check("confirming 1 PLAYER reaches character select in solo mode",
		solo_select != null and solo_select.solo and solo_main.mode_select == null,
		"select=%s solo=%s" % [str(solo_select != null),
			str(solo_select.solo if solo_select != null else false)])
	_check("solo mode hides the opponent cursor until P1 locks a fighter",
		solo_select._p2_marks[solo_select.p2_choice].text == "",
		"p2 mark=%s" % solo_select._p2_marks[solo_select.p2_choice].text)
	_press(solo_select, "p2_light")
	_check("P2 pad input is ignored on the solo select screen",
		not solo_select.p1_locked and not solo_select.p2_locked
			and solo_main.match_root == null,
		"p1_locked=%s p2_locked=%s" % [str(solo_select.p1_locked),
			str(solo_select.p2_locked)])
	_press(solo_select, "p1_right")
	_press(solo_select, "p1_light")
	_check("P1's first confirm locks its pick and moves to the opponent",
		solo_select.p1_locked and solo_select.active_side == 2
			and solo_main.match_root == null,
		"locked=%s side=%d" % [str(solo_select.p1_locked), solo_select.active_side])
	_check("the opponent cursor appears after P1's pick is locked",
		solo_select._p2_marks[solo_select.p2_choice].text == "P2",
		"p2 mark=%s" % solo_select._p2_marks[solo_select.p2_choice].text)
	_press_key(solo_select, KEY_BACKSPACE)
	_check("Backspace undoes the solo pick without leaving the screen",
		not solo_select.p1_locked and solo_select.active_side == 1
			and solo_main.character_select == solo_select
			and solo_main.match_root == null,
		"locked=%s side=%d" % [str(solo_select.p1_locked), solo_select.active_side])
	_press(solo_select, "p1_light")
	_press(solo_select, "p1_left")
	_press(solo_select, "p1_light")
	await process_frame
	_check("solo mode starts the match after P1 picks both fighters",
		solo_main.match_root != null,
		"match root was not created")
	if solo_main.match_root != null:
		_check("solo picks reach the match in P1/P2 order",
			solo_main.match_root.p1.data.display_name == "Whiskey Richard"
				and solo_main.match_root.p2.data.display_name == "Peg Leg Peggy",
			"fighters=%s / %s" % [solo_main.match_root.p1.data.display_name,
				solo_main.match_root.p2.data.display_name])
		_check("solo mode marks P2 as non-human",
			solo_main.match_root.p2_human == false,
			"p2_human=%s" % str(solo_main.match_root.p2_human))
		await _step(65) # let the round intro finish
		_check("solo mode enables P1 input and leaves P2 input disabled",
			solo_main.match_root.p1.input_enabled
				and not solo_main.match_root.p2.input_enabled,
			"p1=%s p2=%s" % [str(solo_main.match_root.p1.input_enabled),
				str(solo_main.match_root.p2.input_enabled)])

	solo_main.audio_manager.stop_all()
	solo_main.free()
	for _frame in 16:
		await process_frame
	print("\n%d failure(s)" % failures)
	quit(1 if failures > 0 else 0)
