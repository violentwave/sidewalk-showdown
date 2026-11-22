# results_flow_test.gd — UI Phase 3b (docs/UI_SCREENS.md): the VS bumper
# and the Results screen. Pins: the VS slide-in (12 integer steps), its
# 20-frame skip guard, its 150-frame duration and hand-off; that Results
# appears at match end with the correct winner; every Results option
# routes correctly; REMATCH keeps fighters and stage through the VS
# bumper; the 30-frame Results input guard; and that neither screen
# writes match state — serialize() is identical while Results is up
# above the frozen (paused) match.
extends SceneTree

const MAIN_SCENE := preload("res://scenes/main/Main.tscn")
const VS_SCENE := preload("res://scenes/menus/vs_screen.tscn")
const ROSTER := preload("res://resources/match_roster.tres")

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
	# The select screens match the raw Backspace keycode rather than the
	# ui_back action.
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	event.device = -1
	target._unhandled_input(event)


func _step(frames: int) -> void:
	for _frame in frames:
		await physics_frame


# Boot to a live solo match through the real flow, skipping every
# hand-off guard legally (clip skip, title confirm, menu VERSUS, mode
# 1 PLAYER, difficulty NORMAL, both solo picks, first stage, VS skip).
func _boot_to_match() -> Node:
	var main: Node = MAIN_SCENE.instantiate()
	root.add_child(main)
	await process_frame
	main.content_warning._continue()
	await process_frame
	main.intro.skip_intro()
	await process_frame
	_press(main.title, "ui_confirm")
	await process_frame
	_press(main.main_menu, "p1_light")  # VERSUS
	await process_frame
	_press(main.mode_select, "p1_light")  # 1 PLAYER (solo)
	await process_frame
	_press(main.difficulty_select, "p1_light")  # NORMAL
	await process_frame
	_press(main.character_select, "p1_light")  # P1 pick
	await process_frame
	_press(main.character_select, "p1_light")  # opponent pick
	await process_frame
	_press(main.stage_select, "p1_light")
	await process_frame
	await _skip_vs(main)
	return main


func _skip_vs(main: Node) -> void:
	await _step(25)
	_press(main.vs_screen, "ui_confirm")
	await process_frame
	await process_frame


# Force the match to a quick 2-0 win for P1 with real KOs. Returns right
# after the second KO blow lands; the caller polls for the Results screen
# so it can test the screen's first 30 frames.
func _force_p1_match_win(main: Node) -> void:
	var match: Node = main.match_root
	await _step(65)  # round intro
	for round_index in 2:
		var p1: FighterBase = match.p1
		var p2: FighterBase = match.p2
		p1.position = Vector2(120, 150)
		p2.position = Vector2(146, 150)
		p1.velocity = Vector2.ZERO
		p2.velocity = Vector2.ZERO
		p1.facing = 1
		p2.facing = -1
		p2.health = 1.0
		p1.reset_state()
		p2.reset_state()
		var light: MoveData = p1.data.find_move(MoveData.InputType.LIGHT, MoveData.Stance.STAND)
		p1._start_move(light)
		if round_index == 0:
			await _step(130)  # KO + round end
			await _step(160)  # next round's intro back to FIGHT
		else:
			await _step(20)  # the KO lands; MATCH_END and the push follow


func _await_results(main: Node) -> void:
	while main.results_screen == null and is_instance_valid(main.match_root):
		await physics_frame
	await process_frame


func _run() -> void:
	await process_frame
	await _test_vs_standalone()
	var main: Node = await _boot_to_match()
	await _test_results_at_match_end(main)
	await _test_results_options(main)
	print("results_flow_test: %d checks, %d failure(s)" % [checks, failures])
	quit(1 if failures > 0 else 0)


# ---------------- VS bumper, standalone ----------------

func _test_vs_standalone() -> void:
	var roster: MatchRoster = ROSTER
	var vs: Control = VS_SCENE.instantiate()
	vs.p1_data = roster.fighters[0]
	vs.p2_data = roster.fighters[1]
	root.add_child(vs)
	await process_frame

	var done_events := [0]
	vs.vs_done.connect(func(): done_events[0] += 1)

	await _step(5)
	_check("the VS busts slide in from off-screen (mid-slide at frame 5)",
		vs._p1_bust.position.x < 12 and vs._p1_bust.position.x > -96
			and vs._p2_bust.position.x > 212 and vs._p2_bust.position.x < 320,
		"p1=%s p2=%s" % [str(vs._p1_bust.position.x), str(vs._p2_bust.position.x)])

	await _step(7)  # frame 12: slide complete
	_check("the VS busts land at their marks in 12 integer steps",
		vs._p1_bust.position == Vector2(12, 40) and vs._p2_bust.position == Vector2(212, 40)
			and vs._p2_bust.flip_h,
		"p1=%s p2=%s" % [str(vs._p1_bust.position), str(vs._p2_bust.position)])

	# 20-frame skip guard.
	await _step(3)  # frame ~15
	_press(vs, "ui_confirm")
	_check("confirm inside the 20-frame guard does not skip the VS bumper",
		done_events[0] == 0, "skipped early")
	await _step(8)  # frame ~23: past the guard
	_press(vs, "ui_confirm")
	_check("confirm past the guard skips the VS bumper",
		done_events[0] == 1, "events=%d" % done_events[0])
	vs.free()
	await process_frame

	# Full duration: 150 frames, no input.
	vs = VS_SCENE.instantiate()
	vs.p1_data = roster.fighters[0]
	vs.p2_data = roster.fighters[1]
	root.add_child(vs)
	await process_frame
	var timed_events := [0]
	vs.vs_done.connect(func(): timed_events[0] += 1)
	await _step(149)
	_check("the VS bumper plays its full 150 frames",
		timed_events[0] == 0, "ended at 149 frames")
	await _step(2)
	_check("the VS bumper ends on its own after 150 frames",
		timed_events[0] == 1, "events=%d" % timed_events[0])
	vs.free()
	await process_frame


# ---------------- Results at match end ----------------

func _test_results_at_match_end(main: Node) -> void:
	var match: Node = main.match_root
	_check("the booted flow reached a live match",
		match != null and match.p1 != null and match.p2 != null,
		"match=%s" % str(match != null))

	await _force_p1_match_win(main)
	await _await_results(main)
	_check("the match end pushes the Results screen above the frozen match",
		main.results_screen != null and main.match_root != null,
		"results=%s match=%s" % [str(main.results_screen != null),
			str(main.match_root != null)])
	var frames_at_appearance: int = main.results_screen._frames
	_check("the finished match is paused under the Results screen",
		paused and main.match_root.modal_open,
		"paused=%s" % str(paused))
	_check("the Results screen shows the real winner (P1)",
		main.results_screen.stats["winner"] == 0
			and main.results_screen.winner_data == main.match_root.p1.data,
		"winner=%s" % str(main.results_screen.stats["winner"]))
	_check("the Results stats carry the rounds tally",
		main.results_screen.stats["wins"][0] == 2
			and main.results_screen.stats["wins"][1] == 0,
		"wins=%s" % str(main.results_screen.stats["wins"]))

	# 30-frame input guard: an early confirm must not route anywhere.
	# Checked FIRST, while the Results screen is young.
	_check("the Results guard is testable (screen still in its guard)",
		frames_at_appearance < 25,
		"frames_at_appearance=%d" % frames_at_appearance)
	_press(main.results_screen, "ui_confirm")
	await _step(3)
	_check("the Results menu ignores input for its first 30 frames",
		main.results_screen != null and main.match_root != null,
		"routed early at %d frames" % frames_at_appearance)

	# Neither screen writes match state: while Results is up, the frozen
	# match's serializable surface never changes.
	var before: Dictionary = main.match_root.serialize()
	await _step(60)
	var after: Dictionary = main.match_root.serialize()
	_check("serialize() is identical while the Results screen is up",
		before == after, "the frozen match's state changed")


# ---------------- Results menu routing ----------------

func _test_results_options(main: Node) -> void:
	var stage_id: String = main.match_root.selected_stage.id
	var p1_name: String = main.match_root.p1.data.display_name
	var p2_name: String = main.match_root.p2.data.display_name

	# REMATCH (default focus): same fighters and stage, through the VS.
	await _step(30)  # past the input guard
	_press(main.results_screen, "ui_confirm")
	await process_frame
	await process_frame
	_check("REMATCH routes through the VS bumper with the same fighters",
		main.results_screen == null and main.vs_screen != null
			and main.vs_screen.p1_data.display_name == p1_name
			and main.vs_screen.p2_data.display_name == p2_name,
		"vs=%s p1=%s" % [str(main.vs_screen != null),
			str(main.vs_screen.p1_data.display_name if main.vs_screen != null else "?")])
	await _skip_vs(main)
	await process_frame
	_check("the rematch keeps the fighters and the stage",
		main.match_root != null and main.vs_screen == null
			and main.match_root.p1.data.display_name == p1_name
			and main.match_root.p2.data.display_name == p2_name
			and main.match_root.selected_stage.id == stage_id,
		"stage=%s" % str(main.match_root.selected_stage.id
			if main.match_root != null else "?"))

	# End the rematch the same way, then walk the other three options.
	await _force_p1_match_win(main)
	await _await_results(main)
	await _step(30)  # past the new Results screen's input guard

	# CHARACTER SELECT.
	_press(main.results_screen, "p1_down")
	_press(main.results_screen, "ui_confirm")
	await process_frame
	await process_frame
	_check("CHARACTER SELECT restores the select screen unpaused",
		main.character_select != null and main.match_root == null
			and main.results_screen == null and not paused,
		"select=%s paused=%s" % [str(main.character_select != null),
			str(paused)])

	# Back out to the main menu and run one more match for STAGE SELECT /
	# MAIN MENU. The select screens back out on the raw Backspace key.
	_press_key(main.character_select, KEY_BACKSPACE)
	await process_frame
	_press(main.mode_select, "ui_back")
	await process_frame
	_press(main.main_menu, "p1_light")  # VERSUS
	await process_frame
	_press(main.mode_select, "p1_light")
	await process_frame
	_press(main.difficulty_select, "p1_light")
	await process_frame
	_press(main.character_select, "p1_light")
	await process_frame
	_press(main.character_select, "p1_light")
	await process_frame
	_press(main.stage_select, "p1_light")
	await process_frame
	await _skip_vs(main)
	await _force_p1_match_win(main)
	await _await_results(main)
	await _step(30)

	# STAGE SELECT.
	_press(main.results_screen, "p1_down")
	_press(main.results_screen, "p1_down")
	_press(main.results_screen, "ui_confirm")
	await process_frame
	await process_frame
	_check("STAGE SELECT restores the stage choice with the last stage",
		main.stage_select != null and main.match_root == null
			and main.stage_select.initial_stage_id == stage_id
			and not paused,
		"stage_select=%s id=%s" % [str(main.stage_select != null),
			str(main.stage_select.initial_stage_id if main.stage_select != null else "?")])

	# MAIN MENU.
	_press_key(main.stage_select, KEY_BACKSPACE)
	await process_frame
	# Stage back rebuilt character select; back again reaches mode select,
	# and mode-select back reaches the main menu (the hub).
	_press_key(main.character_select, KEY_BACKSPACE)
	await process_frame
	_press(main.mode_select, "ui_back")
	await process_frame
	_check("mode-select back returns to the main menu hub",
		main.main_menu != null and main.mode_select == null,
		"menu=%s" % str(main.main_menu != null))
	# One more match through the hub, then the MAIN MENU option.
	_press(main.main_menu, "p1_light")
	await process_frame
	_press(main.mode_select, "p1_light")
	await process_frame
	_press(main.difficulty_select, "p1_light")
	await process_frame
	_press(main.character_select, "p1_light")
	await process_frame
	_press(main.character_select, "p1_light")
	await process_frame
	_press(main.stage_select, "p1_light")
	await process_frame
	await _skip_vs(main)
	await _force_p1_match_win(main)
	await _await_results(main)
	await _step(30)
	_press(main.results_screen, "p1_down")
	_press(main.results_screen, "p1_down")
	_press(main.results_screen, "p1_down")
	_press(main.results_screen, "ui_confirm")
	await process_frame
	await process_frame
	_check("MAIN MENU returns to the hub unpaused",
		main.main_menu != null and main.match_root == null
			and main.results_screen == null and not paused,
		"menu=%s paused=%s" % [str(main.main_menu != null), str(paused)])

	main.audio_manager.stop_all()
	main.free()
	await process_frame
