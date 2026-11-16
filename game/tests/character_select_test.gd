# Headless test for the Phase 2 local two-player character-select mockup.
extends SceneTree

var main_scene: Node
var failures := 0

func _initialize() -> void:
	main_scene = load("res://scenes/main/Main.tscn").instantiate()
	root.add_child(main_scene)
	_run.call_deferred()

func _check(label: String, condition: bool, detail: String = "") -> void:
	if condition:
		print("PASS: ", label)
	else:
		failures += 1
		print("FAIL: ", label, "  ", detail)

func _press(action: String) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	main_scene.character_select._unhandled_input(event)

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
	var select: Control = main_scene.character_select
	_check("the intro song continues on character select",
		main_scene.audio_manager.music_player.playing
			and main_scene.audio_manager.music_player.stream == intro_song,
		"character select did not retain intro MP3")
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

	_press("p1_right")
	_check("P1 can move the cursor with its own horizontal controls",
		select.p1_choice == 1,
		"P1 choice=%d" % select.p1_choice)
	_press("p2_left")
	_check("P2 can select independently",
		select.p2_choice == 0,
		"P2 choice=%d" % select.p2_choice)
	_press("p2_light")
	_check("P2 confirmation locks its pick without starting early",
		select.p2_locked and main_scene.match_root == null,
		"locked=%s match=%s" % [str(select.p2_locked), str(main_scene.match_root != null)])
	_press("p2_right")
	_check("moving after confirmation unlocks P2's pick",
		select.p2_choice == 1 and not select.p2_locked,
		"P2 choice=%d locked=%s" % [select.p2_choice, str(select.p2_locked)])
	_press("p2_left")
	_press("p1_light")
	_check("P1 confirmation locks its pick without starting early",
		select.p1_locked and main_scene.match_root == null,
		"locked=%s match=%s" % [str(select.p1_locked), str(main_scene.match_root != null)])
	_press("p2_light")
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
	for frame in 16:
		await process_frame
	print("\n%d failure(s)" % failures)
	quit(1 if failures > 0 else 0)
