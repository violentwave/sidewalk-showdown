# Main flow, Phases 1 + 3b (docs/UI_SCREENS.md): boot -> content warning ->
# The Clip -> Title -> Main Menu -> VERSUS -> Mode Select (1P/2P) ->
# [solo] Difficulty -> Character Select -> Stage Select -> VS -> Match ->
# Results -> { Rematch -> VS -> Match | Character Select | Stage Select |
# Main Menu }. The ScreenRouter owns the screen stack with deferred
# transitions (the confirm-leak guard); FlowState owns the flow context.
# Everything here is front-end presentation: nothing enters the 60 Hz sim
# or MatchRoot's serialize()/load().
extends Node

const CONTENT_WARNING_SCENE := preload("res://scenes/menus/content_warning.tscn")
const MODE_SELECT_SCENE := preload("res://scenes/menus/ModeSelect.tscn")
const DIFFICULTY_SELECT_SCENE := preload("res://scenes/menus/DifficultySelect.tscn")
const CHARACTER_SELECT_SCENE := preload("res://scenes/menus/CharacterSelect.tscn")
const STAGE_SELECT_SCENE := preload("res://scenes/menus/StageSelect.tscn")
const THE_CLIP_SCENE := preload("res://scenes/menus/TheClip.tscn")
const TITLE_SCENE := preload("res://scenes/menus/title.tscn")
const MAIN_MENU_SCENE := preload("res://scenes/menus/main_menu.tscn")
const QUIT_CONFIRM_SCENE := preload("res://scenes/menus/quit_confirm.tscn")
const SETTINGS_SCENE := preload("res://scenes/menus/settings_overlay.tscn")
const VS_SCENE := preload("res://scenes/menus/vs_screen.tscn")
const RESULTS_SCENE := preload("res://scenes/menus/results_screen.tscn")
const MATCH_SCENE := preload("res://scenes/match/MatchRoot.tscn")
const AUDIO_MANAGER_SCRIPT := preload("res://scripts/audio/audio_manager.gd")
const ROSTER_PATH := "res://resources/match_roster.tres"

# Screen instances. Kept as named fields (not router lookup) so the flow
# tests can keep using main.intro / main.mode_select / ... directly.
var intro: Control
var content_warning: Control
var title: Control
var main_menu: Control
var quit_confirm: Control
var settings_overlay: Control
var mode_select: Control
# Physics frames between MATCH_END and the Results screen (PM review, PR #91).
const RESULTS_DELAY_FRAMES := 90
var _results_pending := false
var difficulty_select: Control
var character_select: Control
var stage_select: Control
var vs_screen: Control
var results_screen: Control
var match_root: Node
var stats_tracker: MatchStatsTracker
var audio_manager
var router: ScreenRouter
var flow := FlowState.new()
var roster: MatchRoster

# Flow context lives on FlowState; these aliases keep the historical
# property names working for tests and screens.
var solo_mode: bool:
	get:
		return flow.solo_mode
	set(value):
		flow.solo_mode = value
var cpu_level: int:
	get:
		return flow.cpu_level
	set(value):
		flow.cpu_level = value
var last_p1_choice: int:
	get:
		return flow.last_p1_choice
	set(value):
		flow.last_p1_choice = value
var last_p2_choice: int:
	get:
		return flow.last_p2_choice
	set(value):
		flow.last_p2_choice = value
var last_stage_id: String:
	get:
		return flow.last_stage_id
	set(value):
		flow.last_stage_id = value


func _ready() -> void:
	roster = load(ROSTER_PATH) as MatchRoster
	router = ScreenRouter.new()
	add_child(router)
	audio_manager = AUDIO_MANAGER_SCRIPT.new()
	add_child(audio_manager)
	_show_content_warning()


func _show_content_warning() -> void:
	# Shown once per launch: this is the single boot entry point.
	audio_manager.start_intro_music()
	content_warning = CONTENT_WARNING_SCENE.instantiate()
	content_warning.warning_done.connect(_on_warning_done)
	router.push(content_warning)


func _on_warning_done() -> void:
	if content_warning != null:
		content_warning = null
	_show_intro()


func _show_intro() -> void:
	intro = THE_CLIP_SCENE.instantiate()
	intro.audio_manager = audio_manager
	intro.intro_finished.connect(_on_intro_finished)
	router.replace(intro)


func _on_intro_finished() -> void:
	if intro != null:
		intro = null
	_show_title()


func _show_title() -> void:
	title = TITLE_SCENE.instantiate()
	title.start_pressed.connect(_on_start_pressed)
	title.back_requested.connect(_on_title_back)
	router.replace(title)


func _on_start_pressed() -> void:
	if title != null:
		title = null
	_show_main_menu()


func _on_title_back() -> void:
	# Esc on the title asks before quitting, like every other exit.
	_push_quit_confirm()


func _show_main_menu() -> void:
	main_menu = MAIN_MENU_SCENE.instantiate()
	main_menu.versus_chosen.connect(_on_versus_chosen)
	main_menu.settings_requested.connect(_on_menu_settings)
	main_menu.quit_requested.connect(_on_menu_quit)
	main_menu.back_requested.connect(_on_main_menu_back)
	main_menu.selection_moved.connect(audio_manager.play_ui_move)
	main_menu.selection_confirmed.connect(audio_manager.play_ui_confirm)
	router.replace(main_menu)


func _on_main_menu_back() -> void:
	if main_menu != null:
		main_menu = null
	_show_title()


func _on_versus_chosen() -> void:
	if main_menu != null:
		main_menu = null
	_show_mode_select()


func _on_menu_settings() -> void:
	_push_settings()


func _on_menu_quit() -> void:
	_push_quit_confirm()


# ---------------- existing versus flow (unchanged behavior) ----------------

func _show_mode_select() -> void:
	mode_select = MODE_SELECT_SCENE.instantiate()
	mode_select.mode_chosen.connect(_on_mode_chosen)
	mode_select.back_requested.connect(_on_mode_select_back)
	mode_select.selection_moved.connect(audio_manager.play_ui_move)
	mode_select.selection_confirmed.connect(audio_manager.play_ui_confirm)
	router.replace(mode_select)


func _on_mode_select_back() -> void:
	# Back from Mode Select returns to the main menu (Phase 1 flow).
	if mode_select != null:
		mode_select = null
	_show_main_menu()


func _on_mode_chosen(solo: bool) -> void:
	solo_mode = solo
	if mode_select != null:
		mode_select = null
	# Solo picks the CPU level right after the mode; versus goes straight
	# to character select as before.
	if solo_mode:
		_show_difficulty_select()
	else:
		_show_character_select()


func _show_difficulty_select() -> void:
	difficulty_select = DIFFICULTY_SELECT_SCENE.instantiate()
	difficulty_select.difficulty_chosen.connect(_on_difficulty_chosen)
	difficulty_select.back_requested.connect(_on_difficulty_back)
	difficulty_select.selection_moved.connect(audio_manager.play_ui_move)
	difficulty_select.selection_confirmed.connect(audio_manager.play_ui_confirm)
	router.replace(difficulty_select)


func _on_difficulty_chosen(level: int) -> void:
	cpu_level = level
	if difficulty_select != null:
		difficulty_select = null
	_show_character_select()


func _on_difficulty_back() -> void:
	if difficulty_select != null:
		difficulty_select = null
	_show_mode_select()


func _show_character_select() -> void:
	# On first entry this is already playing (no-op); after leaving a match it
	# switches back from the fight track.
	audio_manager.start_intro_music()
	character_select = CHARACTER_SELECT_SCENE.instantiate()
	character_select.roster = roster
	character_select.solo = solo_mode
	character_select.initial_p1_choice = last_p1_choice
	character_select.initial_p2_choice = last_p2_choice
	character_select.match_requested.connect(_on_match_requested)
	character_select.back_requested.connect(_on_select_back)
	character_select.selection_moved.connect(audio_manager.play_ui_move)
	character_select.selection_confirmed.connect(audio_manager.play_ui_confirm)
	router.replace(character_select)


func _on_select_back() -> void:
	if character_select != null:
		character_select = null
	# Leaving select to change modes drops the restored matchup context.
	last_p1_choice = -1
	last_p2_choice = -1
	last_stage_id = ""
	_show_mode_select()


# Both fighters are locked in. Keep their picks for a possible return from
# the match, then hand off to the shared stage choice. The router creates
# the stage screen deferred so the confirm keypress that closed character
# select cannot also confirm the stage that appears in the same input event.
func _on_match_requested(p1_data: FighterData, p2_data: FighterData) -> void:
	if match_root != null or stage_select != null:
		return
	flow.pending_p1_data = p1_data
	flow.pending_p2_data = p2_data
	last_p1_choice = roster.fighters.find(p1_data)
	last_p2_choice = roster.fighters.find(p2_data)
	if character_select != null:
		character_select = null
		router.pop()
	var stage: Control = STAGE_SELECT_SCENE.instantiate()
	stage.roster = roster
	stage.initial_stage_id = last_stage_id
	stage.stage_chosen.connect(_on_stage_chosen)
	stage.back_requested.connect(_on_stage_back)
	stage.selection_moved.connect(audio_manager.play_ui_move)
	stage.selection_confirmed.connect(audio_manager.play_ui_confirm)
	router.push(stage)
	stage_select = stage


func _on_stage_chosen(stage: StageData, stage_id: String) -> void:
	if match_root != null or stage_select == null:
		return
	# RANDOM has already been resolved by the selector, so this is always the
	# concrete stage id the match will use.
	last_stage_id = stage_id
	flow.pending_stage = stage
	# Phase 3b: the VS bumper plays between stage select and the match
	# (rematch goes through it too).
	_show_vs(flow.pending_p1_data, flow.pending_p2_data)


func _show_vs(p1_data: FighterData, p2_data: FighterData) -> void:
	if stage_select != null:
		router.pop()
		stage_select = null
	var vs: Control = VS_SCENE.instantiate()
	vs.p1_data = p1_data
	vs.p2_data = p2_data
	vs.vs_done.connect(_on_vs_done)
	router.push(vs)
	vs_screen = vs


func _on_vs_done() -> void:
	if vs_screen != null:
		router.pop()
		vs_screen = null
	if match_root != null:
		return
	_start_match(flow.pending_p1_data, flow.pending_p2_data, flow.pending_stage)


func _on_stage_back() -> void:
	if stage_select != null:
		router.pop()
		stage_select = null
	# The router's push is deferred for the same reason as the forward
	# hand-off.
	var select := _build_character_select()
	router.push(select)
	character_select = select


func _build_character_select() -> Control:
	# On first entry the intro track is already playing (no-op); after
	# leaving a match this switches back from the fight track.
	audio_manager.start_intro_music()
	var select: Control = CHARACTER_SELECT_SCENE.instantiate()
	select.roster = roster
	select.solo = solo_mode
	select.initial_p1_choice = last_p1_choice
	select.initial_p2_choice = last_p2_choice
	select.match_requested.connect(_on_match_requested)
	select.back_requested.connect(_on_select_back)
	select.selection_moved.connect(audio_manager.play_ui_move)
	select.selection_confirmed.connect(audio_manager.play_ui_confirm)
	return select


func _start_match(p1_data: FighterData, p2_data: FighterData,
		stage: StageData) -> void:
	if match_root != null:
		return
	if stage_select != null:
		router.pop()
		stage_select = null
	audio_manager.start_music()
	match_root = MATCH_SCENE.instantiate()
	match_root.roster = roster
	match_root.selected_p1_data = p1_data
	match_root.selected_p2_data = p2_data
	match_root.selected_stage = stage
	match_root.p2_human = not solo_mode
	match_root.p2_cpu = solo_mode
	match_root.cpu_level = cpu_level
	match_root.audio_manager = audio_manager
	match_root.return_to_select_requested.connect(_on_return_to_select)
	match_root.settings_requested.connect(_on_match_settings_requested)
	match_root.main_menu_requested.connect(_on_match_main_menu_requested)
	match_root.quit_requested.connect(_on_match_quit_requested)
	match_root.match_results_requested.connect(_on_match_results_requested)
	# Phase 3b: the presentation-only stats tracker reads the match for the
	# Results screen; it never writes simulation state.
	stats_tracker = MatchStatsTracker.new()
	add_child(stats_tracker)
	stats_tracker.attach(match_root)
	router.push(match_root)


# Match end (Phase 3b): pause the finished match and push the Results
# screen above it. The match stays frozen underneath — serialize() is
# byte-identical before and after the screen appears, and every Results
# option unpauses and routes.
func _on_match_results_requested() -> void:
	if match_root == null or results_screen != null or _results_pending:
		return
	# Give the KO and the "X WINS THE MATCH" banner a beat before Results
	# covers them. Counted in physics frames (deterministic); presentation only.
	_results_pending = true
	for _frame in RESULTS_DELAY_FRAMES:
		await get_tree().physics_frame
	_results_pending = false
	if match_root == null or results_screen != null:
		return
	var snapshot: Dictionary = stats_tracker.snapshot()
	var winner_index: int = snapshot["winner"]
	var winner_data: FighterData = match_root.p1.data if winner_index == 0 \
		else match_root.p2.data
	var stage: StageData = match_root.selected_stage
	match_root.modal_open = true
	get_tree().paused = true
	var results: Control = RESULTS_SCENE.instantiate()
	results.stats = snapshot
	results.winner_data = winner_data
	results.stage = stage
	results.rematch_requested.connect(_on_results_rematch)
	results.character_select_requested.connect(_on_results_character_select)
	results.stage_select_requested.connect(_on_results_stage_select)
	results.main_menu_requested.connect(_on_results_main_menu)
	router.push(results)
	results_screen = results
	# Kept for the rematch path: the same fighters and stage go through the
	# VS bumper again.
	flow.pending_p1_data = match_root.p1.data
	flow.pending_p2_data = match_root.p2.data
	flow.pending_stage = stage


func _leave_match_to_results(action: Callable) -> void:
	if match_root == null:
		return
	var leaving := match_root
	match_root = null
	router.pop()
	get_tree().paused = false
	if is_instance_valid(leaving):
		leaving.modal_open = false
	if stats_tracker != null:
		stats_tracker.queue_free()
		stats_tracker = null
	if results_screen != null:
		router.pop()
		results_screen = null
	action.call()


func _on_results_rematch() -> void:
	# Same fighters, same stage, through the VS bumper again.
	_leave_match_to_results(func() -> void: _show_vs(flow.pending_p1_data, flow.pending_p2_data))


func _on_results_character_select() -> void:
	_leave_match_to_results(_push_results_character_select)


func _push_results_character_select() -> void:
	var select := _build_character_select()
	router.push(select)
	character_select = select


func _on_results_stage_select() -> void:
	_leave_match_to_results(_push_results_stage_select)


func _push_results_stage_select() -> void:
	var stage: Control = STAGE_SELECT_SCENE.instantiate()
	stage.roster = roster
	stage.initial_stage_id = last_stage_id
	stage.stage_chosen.connect(_on_stage_chosen)
	stage.back_requested.connect(_on_stage_back)
	stage.selection_moved.connect(audio_manager.play_ui_move)
	stage.selection_confirmed.connect(audio_manager.play_ui_confirm)
	router.push(stage)
	stage_select = stage


func _on_results_main_menu() -> void:
	_leave_match_to_results(_push_results_main_menu)


func _push_results_main_menu() -> void:
	main_menu = MAIN_MENU_SCENE.instantiate()
	main_menu.versus_chosen.connect(_on_versus_chosen)
	main_menu.settings_requested.connect(_on_menu_settings)
	main_menu.quit_requested.connect(_on_menu_quit)
	main_menu.back_requested.connect(_on_main_menu_back)
	main_menu.selection_moved.connect(audio_manager.play_ui_move)
	main_menu.selection_confirmed.connect(audio_manager.play_ui_confirm)
	router.push(main_menu)


# Pause menu -> BACK TO CHARACTER SELECT. Deferred by the router so the
# confirming keypress does not reach the select screen created in the same
# input event.
func _on_return_to_select() -> void:
	if match_root == null:
		return
	var leaving := match_root
	match_root = null
	router.pop()
	get_tree().paused = false
	var select := _build_character_select()
	router.push(select)
	character_select = select


# Pause menu -> SETTINGS: the overlay rides on top of the paused match;
# closing it returns to the still-open pause menu.
func _on_match_settings_requested() -> void:
	_push_settings()
	if match_root != null:
		match_root.modal_open = true


# Pause menu -> MAIN MENU: leave the match entirely.
func _on_match_main_menu_requested() -> void:
	if match_root == null:
		return
	match_root = null
	router.pop()
	get_tree().paused = false
	main_menu = MAIN_MENU_SCENE.instantiate()
	main_menu.versus_chosen.connect(_on_versus_chosen)
	main_menu.settings_requested.connect(_on_menu_settings)
	main_menu.quit_requested.connect(_on_menu_quit)
	main_menu.back_requested.connect(_on_main_menu_back)
	main_menu.selection_moved.connect(audio_manager.play_ui_move)
	main_menu.selection_confirmed.connect(audio_manager.play_ui_confirm)
	router.push(main_menu)


# Pause menu -> QUIT TO DESKTOP: through the quit confirm, above the
# still-paused match.
func _on_match_quit_requested() -> void:
	_push_quit_confirm()
	if match_root != null:
		match_root.modal_open = true


# ---------------- overlays ----------------

func _push_settings() -> void:
	if settings_overlay != null:
		return
	settings_overlay = SETTINGS_SCENE.instantiate()
	settings_overlay.closed.connect(_on_settings_closed)
	settings_overlay.selection_moved.connect(audio_manager.play_ui_move)
	settings_overlay.selection_confirmed.connect(audio_manager.play_ui_confirm)
	router.push(settings_overlay)


func _on_settings_closed() -> void:
	if settings_overlay == null:
		return
	router.pop()
	settings_overlay = null
	if match_root != null:
		# Back to the pause menu over the paused match.
		match_root.modal_open = false


func _push_quit_confirm() -> void:
	if quit_confirm != null:
		return
	quit_confirm = QUIT_CONFIRM_SCENE.instantiate()
	quit_confirm.quit_confirmed.connect(_on_quit_confirmed)
	quit_confirm.dismissed.connect(_on_quit_dismissed)
	router.push(quit_confirm)


func _on_quit_confirmed() -> void:
	get_tree().quit()


func _on_quit_dismissed() -> void:
	if quit_confirm == null:
		return
	router.pop()
	quit_confirm = null
	if match_root != null:
		match_root.modal_open = false
