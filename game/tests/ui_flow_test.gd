# ui_flow_test.gd — Phase 1 front-end routing (docs/UI_SCREENS.md):
# router push/pop/replace semantics, every forward and back path of the
# boot flow, the confirm-leak guard across hand-offs, the pause menu's new
# SETTINGS / MAIN MENU / QUIT entries, greyed main-menu items refusing
# confirm, and QuitConfirm defaulting to NO.
extends SceneTree

const MAIN_SCENE := preload("res://scenes/main/Main.tscn")
const QUIT_CONFIRM_SCENE := preload("res://scenes/menus/quit_confirm.tscn")
const TITLE_SCENE := preload("res://scenes/menus/title.tscn")

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
	# The legacy select screens match the raw Backspace keycode rather than
	# the ui_back action.
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	event.device = -1
	target._unhandled_input(event)


func _step(frames: int) -> void:
	for _frame in frames:
		await physics_frame


func _new_main() -> Node:
	var main: Node = MAIN_SCENE.instantiate()
	root.add_child(main)
	await process_frame
	return main


func _run() -> void:
	await process_frame
	await _test_router_semantics()
	await _test_boot_flow()
	await _test_quit_confirm_defaults()
	await _test_title_pulse()
	print("ui_flow_test: %d checks, %d failure(s)" % [checks, failures])
	quit(1 if failures > 0 else 0)


# ---------------- router semantics (direct) ----------------

func _test_router_semantics() -> void:
	var router := ScreenRouter.new()
	root.add_child(router)
	await process_frame

	var below := Control.new()
	router.push(below)
	_check("push defers the add until the end of the frame",
		not below.is_inside_tree(), "screen joined the tree in the same frame")
	await process_frame
	_check("the deferred push lands in the tree and on the stack",
		below.is_inside_tree() and router.top() == below and router.stack.size() == 1,
		"stack=%d inside=%s" % [router.stack.size(), str(below.is_inside_tree())])

	var above := Control.new()
	router.push(above)
	await process_frame
	_check("overlays push without freeing the screen below",
		router.stack.size() == 2 and below.is_inside_tree() and above.is_inside_tree(),
		"stack=%d below=%s above=%s" % [router.stack.size(),
			str(below.is_inside_tree()), str(above.is_inside_tree())])

	router.pop()
	await process_frame
	_check("pop frees only the top screen",
		router.stack.size() == 1 and not is_instance_valid(above)
			and below.is_inside_tree(),
		"stack=%d above_alive=%s" % [router.stack.size(), str(is_instance_valid(above))])

	var replacement := Control.new()
	router.replace(replacement)
	await process_frame
	_check("replace frees the old top and pushes the new screen",
		router.stack.size() == 1 and not is_instance_valid(below)
			and replacement.is_inside_tree(),
		"stack=%d below_alive=%s" % [router.stack.size(), str(is_instance_valid(below))])

	router.clear_and_push(Control.new())
	await process_frame
	_check("clear_and_push empties the stack before its push",
		not is_instance_valid(replacement) and router.stack.size() == 1,
		"replacement alive after clear")
	router.free()
	await process_frame


# ---------------- the boot flow, forward and back ----------------

func _test_boot_flow() -> void:
	var main: Node = await _new_main()
	var audio = main.audio_manager

	_check("boot opens on the content warning",
		main.content_warning != null and main.intro == null,
		"warning=%s intro=%s" % [str(main.content_warning != null), str(main.intro != null)])

	# Forward: warning -> clip (auto-continue on the frame counter).
	main.content_warning._continue()
	await process_frame
	_check("the warning hands off to The Clip", main.intro != null,
		"intro=%s" % str(main.intro != null))

	main.intro.skip_intro()
	await process_frame
	_check("The Clip hands off to the title screen",
		main.title != null and main.intro == null,
		"title=%s" % str(main.title != null))

	_press(main.title, "ui_confirm")
	await process_frame
	_check("confirm on the title opens the main menu",
		main.main_menu != null and main.title == null,
		"menu=%s" % str(main.main_menu != null))

	# Owner playtest change: the chat strip is gone entirely.
	var chat_art := 0
	for node in main.main_menu.get_children():
		if node is TextureRect:
			var path := str((node as TextureRect).texture.resource_path)
			if "chat" in path or "live" in path:
				chat_art += 1
	_check("the main menu has no chat panel, LIVE tag or chat lines",
		chat_art == 0, "%d chat texture(s) found" % chat_art)

	# Navigation wraps across all five items and reaches QUIT.
	var seen_order: Array[int] = [main.main_menu.index]
	for step in 5:
		_press(main.main_menu, "p1_down")
		seen_order.append(main.main_menu.index)
	var wrapped := seen_order[0] == 0 and seen_order[5] == 0 and seen_order[4] == 4
	_check("menu navigation wraps VERSUS..QUIT -> VERSUS",
		wrapped, "order=%s" % str(seen_order))

	# Back: main menu -> title -> quit confirm -> NO -> title.
	_press(main.main_menu, "ui_back")
	await process_frame
	_check("back from the main menu returns to the title",
		main.title != null and main.main_menu == null,
		"title=%s" % str(main.title != null))
	_press(main.title, "ui_back")
	await process_frame
	_check("back on the title opens the quit confirm",
		main.quit_confirm != null and main.title != null,
		"quit_confirm=%s" % str(main.quit_confirm != null))
	_check("the quit confirm defaults to NO", main.quit_confirm.index == 1,
		"index=%d" % main.quit_confirm.index)
	_press(main.quit_confirm, "p1_light")  # NO selected
	await process_frame
	_check("NO dismisses the quit confirm back to the title",
		main.quit_confirm == null and main.title != null,
		"quit=%s title=%s" % [str(main.quit_confirm != null), str(main.title != null)])

	# Forward again to the main menu.
	_press(main.title, "ui_confirm")
	await process_frame

	# Training is live; only EXTRAS remains greyed.
	_check("TRAINING is an enabled main-menu slat",
		not main.main_menu.ITEMS[1].get("disabled", false),
		"training item is still disabled")
	for greyed_index in [3]:
		while main.main_menu.index != greyed_index:
			_press(main.main_menu, "p1_down")
		var chosen := [0]
		main.main_menu.versus_chosen.connect(func(): chosen[0] += 1)
		main.main_menu.settings_requested.connect(func(): chosen[0] += 10)
		main.main_menu.quit_requested.connect(func(): chosen[0] += 100)
		_press(main.main_menu, "p1_light")
		await process_frame
		_check("the greyed EXTRAS slat cannot be confirmed",
			chosen[0] == 0 and main.main_menu != null,
			"emitted signal=%d menu=%s" % [chosen[0], str(main.main_menu != null)])

	# SETTINGS overlay over the menu.
	while main.main_menu.index != 2:
		_press(main.main_menu, "p1_down")
	_press(main.main_menu, "p1_light")
	await process_frame
	_check("SETTINGS opens as an overlay above the menu",
		main.settings_overlay != null and main.main_menu != null,
		"overlay=%s menu=%s" % [str(main.settings_overlay != null),
			str(main.main_menu != null)])
	_press(main.settings_overlay, "ui_back")
	await process_frame
	_check("closing settings returns to the intact menu below",
		main.settings_overlay == null and main.main_menu != null,
		"overlay=%s menu=%s" % [str(main.settings_overlay != null),
			str(main.main_menu != null)])

	# QUIT from the menu goes through the confirm, and NO returns.
	while main.main_menu.index != 4:
		_press(main.main_menu, "p1_down")
	_press(main.main_menu, "p1_light")
	await process_frame
	_check("QUIT opens the quit confirm over the menu",
		main.quit_confirm != null and main.main_menu != null,
		"quit=%s" % str(main.quit_confirm != null))
	_press(main.quit_confirm, "p1_light")
	await process_frame
	_check("NO returns from the quit confirm to the menu",
		main.quit_confirm == null and main.main_menu != null,
		"quit=%s menu=%s" % [str(main.quit_confirm != null),
			str(main.main_menu != null)])

	# VERSUS -> mode select; back returns to the menu.
	while main.main_menu.index != 0:
		_press(main.main_menu, "p1_up")
	_press(main.main_menu, "p1_light")
	await process_frame
	_check("VERSUS opens the mode select", main.mode_select != null,
		"mode=%s" % str(main.mode_select != null))
	_press(main.mode_select, "ui_back")
	await process_frame
	_check("back from mode select returns to the main menu",
		main.main_menu != null and main.mode_select == null,
		"menu=%s mode=%s" % [str(main.main_menu != null), str(main.mode_select != null)])

	# Solo: VERSUS -> 1 PLAYER -> difficulty; back returns to mode select.
	_press(main.main_menu, "p1_light")
	await process_frame
	_check("mode select still defaults to 1 PLAYER",
		main.mode_select.index == 0, "index=%d" % main.mode_select.index)
	_press(main.mode_select, "p1_light")
	await process_frame
	_check("1 PLAYER opens the difficulty screen",
		main.difficulty_select != null, "difficulty=%s" % str(main.difficulty_select != null))
	_press_key(main.difficulty_select, KEY_BACKSPACE)
	await process_frame
	_check("back from difficulty returns to mode select",
		main.mode_select != null and main.difficulty_select == null,
		"mode=%s" % str(main.mode_select != null))

	# Solo picks both fighters; stage select appears with no confirm leak.
	_press(main.mode_select, "p1_light")
	await process_frame
	_check("re-entering 1 PLAYER opens the difficulty screen again",
		main.difficulty_select != null,
		"difficulty=%s" % str(main.difficulty_select != null))
	_press(main.difficulty_select, "p1_light")
	await process_frame
	_check("difficulty confirm reaches character select",
		main.character_select != null, "select=%s" % str(main.character_select != null))
	_press(main.character_select, "p1_light")
	await process_frame
	_press(main.character_select, "p1_light")
	_check("the hand-off guard keeps the next screen out of this frame's input",
		main.stage_select != null and not main.stage_select.is_inside_tree(),
		"stage joined the tree in the confirming frame")
	await process_frame
	_check("stage select lands after the guarded frame",
		main.stage_select.is_inside_tree() and main.character_select == null,
		"stage=%s" % str(main.stage_select.is_inside_tree()))

	# Back: stage -> character select.
	_press_key(main.stage_select, KEY_BACKSPACE)
	await process_frame
	_check("back from stage select returns to character select",
		main.character_select != null and main.stage_select == null,
		"select=%s stage=%s" % [str(main.character_select != null),
			str(main.stage_select != null)])

	# Forward again into a match.
	_press(main.character_select, "p1_light")
	await process_frame
	_press(main.character_select, "p1_light")
	await process_frame
	# Forward again into a match — through the Phase 3b VS bumper.
	_press(main.stage_select, "p1_light")
	await process_frame
	await process_frame
	_check("confirming a stage opens the VS bumper",
		main.vs_screen != null and main.stage_select == null
			and main.match_root == null,
		"vs=%s match=%s" % [str(main.vs_screen != null),
			str(main.match_root != null)])
	await _step(25)
	_press(main.vs_screen, "ui_confirm")  # past the 20-frame guard: skip
	await process_frame
	await process_frame
	_check("skipping the VS bumper starts the match",
		main.match_root != null and main.vs_screen == null,
		"match=%s vs=%s" % [str(main.match_root != null),
			str(main.vs_screen != null)])

	# Pause: SETTINGS overlay above the paused match, back to the pause menu.
	var paused_match: Node = main.match_root
	paused_match._toggle_pause()
	_press(paused_match, "p1_down")  # SETTINGS
	_check("the pause menu offers SETTINGS at index 1",
		paused_match.pause_index == 1, "index=%d" % paused_match.pause_index)
	_press(paused_match, "p1_light")
	await process_frame
	_check("pause SETTINGS opens the overlay above the paused match",
		main.settings_overlay != null and paused_match.pause_menu_open
			and paused_match.modal_open and paused,
		"overlay=%s open=%s modal=%s paused=%s" % [str(main.settings_overlay != null),
			str(paused_match.pause_menu_open), str(paused_match.modal_open), str(paused)])
	# The pause key must not unpause underneath the overlay.
	_press(paused_match, "p1_pause")
	_check("the pause key is ignored while the overlay is open",
		paused_match.pause_menu_open and paused,
		"the overlay leaked the pause key")
	_press(main.settings_overlay, "ui_back")
	await process_frame
	_check("closing settings returns to the still-open pause menu",
		main.settings_overlay == null and paused_match.pause_menu_open
			and not paused_match.modal_open and paused,
		"overlay=%s open=%s" % [str(main.settings_overlay != null),
			str(paused_match.pause_menu_open)])

	# QUIT TO DESKTOP through the confirm, NO returns to the pause menu.
	_press(paused_match, "p1_down")  # RESTART
	_press(paused_match, "p1_down")  # BACK TO SELECT
	_press(paused_match, "p1_down")  # MAIN MENU
	_press(paused_match, "p1_down")  # QUIT TO DESKTOP
	_check("the pause menu offers QUIT TO DESKTOP at index 5",
		paused_match.pause_index == 5, "index=%d" % paused_match.pause_index)
	_press(paused_match, "p1_light")
	await process_frame
	_check("QUIT TO DESKTOP opens the quit confirm over the paused match",
		main.quit_confirm != null and paused and paused_match.modal_open,
		"quit=%s paused=%s" % [str(main.quit_confirm != null), str(paused)])
	_press(main.quit_confirm, "p1_light")  # NO
	await process_frame
	_check("NO returns from the quit confirm to the pause menu",
		main.quit_confirm == null and paused_match.pause_menu_open
			and not paused_match.modal_open and paused,
		"quit=%s open=%s" % [str(main.quit_confirm != null), str(paused_match.pause_menu_open)])

	# MAIN MENU from pause leaves the match entirely.
	_press(paused_match, "p1_down")  # wraps to RESUME? no: 5 -> down wraps to 0
	_press(paused_match, "p1_down")  # 1 SETTINGS
	_press(paused_match, "p1_down")  # 2 RESTART
	_press(paused_match, "p1_down")  # 3 BACK TO SELECT
	_press(paused_match, "p1_down")  # 4 MAIN MENU
	_check("the pause menu offers MAIN MENU at index 4",
		paused_match.pause_index == 4, "index=%d" % paused_match.pause_index)
	_press(paused_match, "p1_light")
	await process_frame
	await process_frame
	_check("MAIN MENU from pause frees the match and unpauses",
		main.match_root == null and main.main_menu != null and not paused,
		"match=%s menu=%s paused=%s" % [str(main.match_root != null),
			str(main.main_menu != null), str(paused)])

	audio.stop_all()
	main.free()
	for _frame in 8:
		await process_frame


# ---------------- QuitConfirm + ContentWarning standalone ----------------

func _test_quit_confirm_defaults() -> void:
	var confirm: Control = QUIT_CONFIRM_SCENE.instantiate()
	root.add_child(confirm)
	await process_frame
	_check("quit confirm defaults to NO", confirm.index == 1,
		"index=%d" % confirm.index)
	var quit_events := [0]
	var dismiss_events := [0]
	confirm.quit_confirmed.connect(func(): quit_events[0] += 1)
	confirm.dismissed.connect(func(): dismiss_events[0] += 1)
	# NO is selected: confirm dismisses, does not quit.
	_press(confirm, "p1_light")
	_check("confirming the default NO dismisses without quitting",
		dismiss_events[0] == 1 and quit_events[0] == 0,
		"quit=%d dismiss=%d" % [quit_events[0], dismiss_events[0]])
	confirm.free()
	await process_frame

	# YES path: up to YES, confirm emits quit_confirmed.
	confirm = QUIT_CONFIRM_SCENE.instantiate()
	root.add_child(confirm)
	await process_frame
	quit_events[0] = 0
	dismiss_events[0] = 0
	confirm.quit_confirmed.connect(func(): quit_events[0] += 1)
	confirm.dismissed.connect(func(): dismiss_events[0] += 0)
	_press(confirm, "p1_up")
	_check("up moves to YES", confirm.index == 0, "index=%d" % confirm.index)
	_press(confirm, "p1_light")
	_check("confirming YES requests the quit",
		quit_events[0] == 1, "quit=%d" % quit_events[0])
	confirm.free()
	await process_frame

	# Content warning waits for a key press (owner playtest change,
	# 2026-11-21): no auto-advance, a 30-frame input guard at boot,
	# then confirm continues.
	const WARNING_SCENE := preload("res://scenes/menus/content_warning.tscn")
	var warning: Control = WARNING_SCENE.instantiate()
	root.add_child(warning)
	await process_frame
	var done := [0]
	warning.warning_done.connect(func(): done[0] += 1)
	await _step(600)
	_check("the content warning never advances on its own (600 frames)",
		done[0] == 0, "warning_done emitted %d time(s)" % done[0])
	warning.free()
	await process_frame

	var guard_warning: Control = WARNING_SCENE.instantiate()
	root.add_child(guard_warning)
	var guard_done := [0]
	guard_warning.warning_done.connect(func(): guard_done[0] += 1)
	_press(guard_warning, "ui_confirm")
	_check("a key held at boot cannot skip the warning (30-frame guard)",
		guard_done[0] == 0, "warning_done emitted %d time(s)" % guard_done[0])
	guard_warning.free()
	await process_frame

	var ready_warning: Control = WARNING_SCENE.instantiate()
	root.add_child(ready_warning)
	var ready_done := [0]
	ready_warning.warning_done.connect(func(): ready_done[0] += 1)
	await _step(35)
	_press(ready_warning, "ui_confirm")
	_check("confirm after the 30-frame guard continues the warning",
		ready_done[0] == 1, "warning_done emitted %d time(s)" % ready_done[0])
	ready_warning.free()
	await process_frame


# ---------------- Title pulse ----------------

func _test_title_pulse() -> void:
	var title: Control = TITLE_SCENE.instantiate()
	root.add_child(title)
	await process_frame
	_check("PRESS START starts visible", title._press_start.visible,
		"visible=%s" % str(title._press_start.visible))
	await _step(61)
	_check("PRESS START hides inside its 1-second pulse",
		not title._press_start.visible,
		"still visible after 61 frames")
	await _step(60)
	_check("PRESS START comes back on the next pulse cycle",
		title._press_start.visible,
		"did not return after a full cycle")
	title.free()
	await process_frame
