# MatchRoot — match orchestrator: rounds, timer, KO, HUD, pause.
extends Node2D

enum Phase { INTRO, FIGHT, KO, ROUND_END, MATCH_END }

# Emitted when the pause menu asks to leave the match; Main owns the flow back
# to character select.
signal return_to_select_requested
# Emitted once when the match reaches MATCH_END (UI Phase 3b): Main pauses
# the tree and pushes the Results screen above the finished match.
signal match_results_requested
# Phase 1 pause menu: Main pushes the Settings overlay over the paused
# match, exits to the main menu, or shows the quit confirm.
signal settings_requested
signal main_menu_requested
signal quit_requested

const HUD_SCENE := preload("res://scenes/match/MatchHUD.tscn")
const DEBUG_SCRIPT := preload("res://scripts/debug/debug_overlay.gd")
const FIGHTER_SCENE := preload("res://scenes/fighters/FighterBase.tscn")

const ROUND_SECONDS := 99
const SUDDEN_DEATH_SECONDS := 30
const INTRO_FRAMES := 60
const KO_FRAMES := 100
const ROUND_END_FRAMES := 90
const WINS_TO_TAKE_MATCH := 2
# PROPOSALS/GDD draw resolution: two timeout ties are draws with no pip; the
# third one starts a single sudden-death round.
const TIMEOUT_TIES_BEFORE_SUDDEN_DEATH := 2

var stage: Node2D
var hud: MatchHUD
var debug_overlay: DebugOverlay
var p1: FighterBase
var p2: FighterBase
var audio_manager
# Cast and stage come from the roster; the main flow overrides the selection,
# while a directly instantiated match (tests, tools) falls back to its defaults.
@export var roster: MatchRoster
var selected_p1_data: FighterData
var selected_p2_data: FighterData
var selected_stage: StageData
# False in solo mode: P2 still spawns and can be hit. With p2_cpu set, P2's
# input is instead fed by the deterministic CpuController (docs/CPU_OPPONENT.md).
@export var p2_human := true
# Solo AI: P2 is driven by a CPU at cpu_level. p1_cpu is the debug AI-vs-AI
# toggle (soak tests, balance capture); neither changes any combat rule — the
# controllers press the same p<index>_* actions a human would.
@export var p2_cpu := false
@export var p1_cpu := false
# 0 EASY, 1 NORMAL, 2 HARD (resources/ai/cpu_*.tres).
@export var cpu_level := 1
# 0 = derive once here from the global (non-gameplay) RNG and record it in
# serialize(); replays/rollback pin it explicitly.
@export var cpu_seed := 0
var cpu_p1: CpuController
var cpu_p2: CpuController
# Smash-style walk-through: when true, fighters do not collide at all — no
# pushbox separation on the ground or in the air, and no auto-shove when they
# overlap. Side, blocking, knockback, and throw rules come from the shared
# FighterBase.relative_side() helper instead (see docs/SIDE_SWITCHING.md).
# When false, grounded bodies separate by pushbox as before; airborne fighters
# pass through either way so a jump-over still works.
@export var fighters_can_pass_through := true
# Training mode (GDD 6.4): no timer, no rounds, no KO — the dummy is driven
# by TrainingController and health refills per its options. Versus and solo
# never set this; every branch below is training-only and default-false.
@export var training_mode := false
var training: TrainingController
# Pause menu tab while training (0 = the system options, 1 = the training
# tab). Serialized alongside pause_index like the rest of the pause state.
var pause_tab := 0
# The training tab's row list (rendered/owned by the HUD's training panel
# logic; MatchRoot only routes input and stores the selection).
const TRAINING_ROWS := ["DUMMY", "BLOCK", "TECH", "BREAKER", "SHAKE-OUT",
	"METER", "HEALTH", "POSITION", "HITBOXES"]

var phase: Phase = Phase.INTRO
var phase_frame := 0
var round_number := 1
var wins: Array[int] = [0, 0]
var timer_frames := ROUND_SECONDS * 60
var ko_loser: FighterBase
var ko_draw := false
var ko_frame := -1
var sim_frame := 0
# Draw resolution (Phase 2): each fighter's damage output this round feeds the
# sudden-death tiebreak; timeout_ties counts consecutive tied clock-outs.
var timeout_ties := 0
var sudden_death := false
var round_damage: Array[float] = [0.0, 0.0]
var pause_index := 0
var pause_menu_open := false
# True while a Phase 1 overlay (Settings / QuitConfirm) is open above the
# paused match; the pause key and menu input must not leak underneath it.
# Transient presentation state, deliberately not serialized.
var modal_open := false
var commentary_sample_shown := false
# True when _ready() could not resolve usable roster data and stopped early.
var setup_failed := false

func _ready() -> void:
	process_physics_priority = 100 # run after fighters update their state
	process_mode = Node.PROCESS_MODE_ALWAYS

	if not _resolve_selections():
		# Missing/invalid roster data must not half-build a match: stop here so
		# _physics_process and the pause handler never touch null fighters.
		setup_failed = true
		set_physics_process(false)
		set_process_unhandled_input(false)
		return

	stage = selected_stage.scene.instantiate()
	add_child(stage)

	hud = HUD_SCENE.instantiate()
	if training_mode:
		# The HUD builds its training layout (pause tabs, readout panel,
		# hidden pips, infinity timer) in _ready, so the flag must land
		# before the child enters the tree.
		hud.training_mode = true
	add_child(hud)

	p1 = _spawn_fighter(1, selected_p1_data)
	p2 = _spawn_fighter(2, selected_p2_data)
	p1.opponent = p2
	p2.opponent = p1
	hud.bind(p1, p2)

	p1.ko.connect(_on_fighter_ko.bind(p1))
	p2.ko.connect(_on_fighter_ko.bind(p2))
	p1.meth_started.connect(_on_meth_started)
	p2.meth_started.connect(_on_meth_started)

	debug_overlay = DEBUG_SCRIPT.new()
	add_child(debug_overlay)
	debug_overlay.bind(p1, p2)
	if training_mode:
		# The hitbox view is a menu toggle in training (F1 still works).
		debug_overlay.show_boxes = false

	_setup_cpus()
	if training_mode:
		training = TrainingController.new()
		# Distinct priority makes the order explicit: training upkeep/random
		# first, CPU dummy second, fighters third, MatchRoot last. No node-order
		# tie between training and CpuController can affect a frame.
		training.process_physics_priority = -200
		training.process_mode = Node.PROCESS_MODE_PAUSABLE
		add_child(training)
		training.setup(self)
		hud.set_training_controller(training)
	_begin_round()

# Roster-driven setup: a caller may set any subset of the selections; anything
# unset falls back to the roster's first entries. This is the only place the
# match learns which fighters and stage exist. Returns false, without building
# anything, when the roster cannot supply a usable fighter pair and stage.
func _resolve_selections() -> bool:
	if roster == null:
		roster = MatchRoster.load_default()
	if roster != null:
		if selected_p1_data == null and not roster.fighters.is_empty():
			selected_p1_data = roster.fighters[0]
		if selected_p2_data == null:
			selected_p2_data = roster.fighters[1] \
				if roster.fighters.size() > 1 else selected_p1_data
		if selected_stage == null and not roster.stages.is_empty():
			selected_stage = roster.stages[0]
	if selected_p1_data == null or selected_p2_data == null \
			or selected_stage == null or selected_stage.scene == null:
		push_error("MatchRoot: roster has no usable fighters/stage")
		return false
	return true

func _spawn_fighter(index: int, data: FighterData) -> FighterBase:
	var f: FighterBase = FIGHTER_SCENE.instantiate()
	f.player_index = index
	f.data = data
	f.stage = stage
	# MatchRoot runs with PROCESS_MODE_ALWAYS so the pause key keeps working;
	# fighters must not inherit that or they keep simulating while paused.
	f.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(f)
	return f

# Create the CPU controllers. They tick at process_physics_priority -100, so
# they observe only the previous, completed simulation frame and issue inputs
# before the fighters poll them — the same frame a human's keypress would land.
func _setup_cpus() -> void:
	if not p2_cpu and not p1_cpu:
		return
	if cpu_seed == 0:
		# Chosen once, before gameplay, with the engine RNG — recorded via
		# serialize() so a replay can pin it.
		cpu_seed = randi()
	if p2_cpu:
		cpu_p2 = _make_cpu(p2, p1, cpu_seed)
	if p1_cpu:
		cpu_p1 = _make_cpu(p1, p2, cpu_seed ^ 0x9E3779B9)

func _make_cpu(who: FighterBase, foe: FighterBase, seed: int) -> CpuController:
	var cpu := CpuController.new()
	cpu.process_physics_priority = -100
	cpu.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(cpu)
	cpu.setup(who, foe, self, CpuDifficulty.load_level(cpu_level), seed)
	return cpu

# ---------------- training CPU dummy -----------------------------------------

# TrainingController calls these when the DUMMY stance asks for a CPU. The
# dummy CPU reuses the solo opponent's whole machinery (seed, difficulty
# data, serialization through the cpu_p2 slot) — only training ever drives
# it this way, so versus/solo behavior is untouched.
func ensure_training_cpu(level: int, seed: int) -> void:
	if cpu_p2 != null:
		cpu_p2.difficulty = CpuDifficulty.load_level(level)
		return
	cpu_seed = seed if seed != 0 else 1
	cpu_p2 = _make_cpu(p2, p1, cpu_seed)
	cpu_p2.difficulty = CpuDifficulty.load_level(level)


func clear_training_cpu() -> void:
	if cpu_p2 == null:
		return
	cpu_p2._release_all()
	cpu_p2.queue_free()
	cpu_p2 = null

# ---------------- Round flow ----------------
func _begin_round() -> void:
	p1.begin_round(Vector2(stage.spawn_p1_x, stage.floor_y), stage.spawn_p2_x)
	p2.begin_round(Vector2(stage.spawn_p2_x, stage.floor_y), stage.spawn_p1_x)
	# Deterministic base draw order for the new round (rule I): P1 under P2
	# until an attacker in active/recovery frames claims the top slot.
	p1.z_index = 0
	p2.z_index = 0
	if training_mode:
		# Training skips the round intro entirely: straight to FIGHT with
		# both fighters live, no banner, no clock. begin_round() already
		# restored health/meter/state above.
		p1.input_enabled = true
		p2.input_enabled = true
		timer_frames = 0
		phase = Phase.FIGHT
		phase_frame = 0
		ko_loser = null
		ko_draw = false
		ko_frame = -1
		round_damage = [0.0, 0.0]
		hud.set_timer_infinite()
		return
	p1.input_enabled = false
	p2.input_enabled = false
	timer_frames = (SUDDEN_DEATH_SECONDS if sudden_death else ROUND_SECONDS) * 60
	phase = Phase.INTRO
	phase_frame = 0
	ko_loser = null
	ko_draw = false
	ko_frame = -1
	round_damage = [0.0, 0.0]
	hud.set_timer(float(timer_frames) / 60.0)
	hud.set_pips(wins[0], wins[1])
	if sudden_death:
		hud.show_banner_text("SUDDEN DEATH")
	elif wins[0] >= WINS_TO_TAKE_MATCH and wins[1] >= WINS_TO_TAKE_MATCH:
		hud.show_banner("decisive")
	else:
		# Rounds can pass 5 through double-KO draws; the approved word
		# sprites stop at ROUND 5, so later rounds fall back to text on
		# the plate.
		if round_number >= 1 and round_number <= 5:
			hud.show_banner("round_%d" % round_number)
		else:
			hud.show_banner_text("ROUND %d" % round_number)

func _start_fight() -> void:
	phase = Phase.FIGHT
	phase_frame = 0
	p1.input_enabled = true
	p2.input_enabled = p2_human or p2_cpu
	hud.show_banner("fight")
	if not commentary_sample_shown:
		hud.show_commentary("TRIPP: The crowd is going insane!")
		commentary_sample_shown = true
	if audio_manager != null:
		audio_manager.play_sfx("round_start")

func _on_meth_started(meth_name: String) -> void:
	hud.show_banner("methtality", meth_name.to_upper())
	if audio_manager != null:
		audio_manager.play_sfx("meth")

func _on_fighter_ko(loser: FighterBase) -> void:
	if training_mode:
		# The training health floor makes this unreachable; keep the guard
		# so a future rule change can never push training into round flow.
		return
	if phase == Phase.KO:
		# A second KO inside the same simulation frame means both fighters died
		# on the trade: make it a draw round instead of crediting the first signal.
		if ko_frame == sim_frame and p1.health <= 0.0 and p2.health <= 0.0:
			ko_draw = true
			ko_loser = null
			for f: FighterBase in [p1, p2]:
				if f.health <= 0.0 and f.state != FighterBase.State.KO:
					f._force_state(FighterBase.State.KO)
			hud.show_banner("double_ko")
		return
	if phase != Phase.FIGHT:
		return
	ko_loser = loser
	ko_frame = sim_frame
	ko_draw = false
	phase = Phase.KO
	phase_frame = 0
	p1.input_enabled = false
	p2.input_enabled = false
	if audio_manager != null:
		audio_manager.play_sfx("ko")
	var winner := p2 if loser == p1 else p1
	winner._force_state(FighterBase.State.WIN)
	hud.show_banner("ko")

func _finish_round(winner_index: int, double_ko := false) -> void:
	var tiebreak_note := ""
	# Sudden death always terminates: a tie (clock-out or double KO) is resolved
	# by the documented tiebreak below instead of starting another round.
	if sudden_death and (double_ko or winner_index < 0):
		winner_index = _sudden_death_tiebreak()
		tiebreak_note = "\nWON ON TIEBREAK"
	if double_ko and not sudden_death:
		# Street Fighter convention: both fighters take the round.
		wins[0] += 1
		wins[1] += 1
	elif winner_index >= 0:
		wins[winner_index] += 1
	hud.set_pips(wins[0], wins[1])
	phase_frame = 0
	if sudden_death:
		_end_match(winner_index, tiebreak_note)
		return
	if _match_has_winner():
		_end_match(0 if wins[0] > wins[1] else 1)
		return
	phase = Phase.ROUND_END
	if winner_index < 0:
		hud.show_banner_text("DOUBLE K.O.\nBOTH TAKE THE ROUND" if double_ko else "DRAW")
	else:
		var winner := p1 if winner_index == 0 else p2
		hud.show_banner_text("%s\nTAKES THE ROUND" % winner.data.display_name.to_upper())

# A match is won by the first fighter to reach WINS_TO_TAKE_MATCH *and* lead the
# other. A 2-2 scoreline (two double KOs, or a double KO levelling the set) does
# not end the match: decisive rounds continue until one fighter wins outright.
func _match_has_winner() -> bool:
	if wins[0] == wins[1]:
		return false
	return maxi(wins[0], wins[1]) >= WINS_TO_TAKE_MATCH

func _end_match(winner_index: int, note := "") -> void:
	phase = Phase.MATCH_END
	var champion := p1 if winner_index == 0 else p2
	hud.show_banner_text("%s WINS THE MATCH%s" % [champion.data.display_name.to_upper(), note])
	# UI Phase 3b: Main owns the match-end hand-off now (the Results screen
	# replaces the old "ENTER TO RESTART" prompt). Emitted exactly once; the
	# sim is untouched and the paused match stays frozen underneath.
	match_results_requested.emit()

# Sudden death must end without a coin flip. Deterministic order:
#   1. remaining health,
#   2. damage dealt this round (chip included),
#   3. hype meter,
#   4. player index (P1) as the documented last resort.
func _sudden_death_tiebreak() -> int:
	if p1.health > p2.health + 0.1:
		return 0
	if p2.health > p1.health + 0.1:
		return 1
	if round_damage[0] > round_damage[1] + 0.1:
		return 0
	if round_damage[1] > round_damage[0] + 0.1:
		return 1
	if p1.meter > p2.meter + 0.1:
		return 0
	if p2.meter > p1.meter + 0.1:
		return 1
	return 0

func _timeout_round() -> void:
	p1.input_enabled = false
	p2.input_enabled = false
	var winner := -1
	if p1.health > p2.health + 0.1:
		winner = 0
	elif p2.health > p1.health + 0.1:
		winner = 1
	var trigger_sudden_death := false
	if winner < 0 and not sudden_death:
		timeout_ties += 1
		# Third tie: this round is still a draw (no pip), the next round is the
		# final sudden-death round with a 30-second clock. Flag it after the
		# round resolves, so this tie is not itself tiebroken.
		trigger_sudden_death = timeout_ties > TIMEOUT_TIES_BEFORE_SUDDEN_DEATH
	_finish_round(winner)
	if trigger_sudden_death:
		sudden_death = true

func _reset_match() -> void:
	wins = [0, 0]
	round_number = 1
	timeout_ties = 0
	sudden_death = false
	commentary_sample_shown = false
	_begin_round()

# Debug frame-step: advance exactly one simulation frame while the tree stays
# paused. Fighters tick first, then the match, mirroring process_physics_priority.
func step_simulation_frame() -> void:
	if p1 == null or p2 == null:
		return
	var tree := get_tree()
	var was_paused := tree.paused
	var dt := 1.0 / float(Engine.physics_ticks_per_second)
	tree.paused = false
	p1._physics_process(dt)
	p2._physics_process(dt)
	_physics_process(dt)
	tree.paused = was_paused

# ---------------- Simulation ----------------
func _physics_process(_delta: float) -> void:
	if get_tree().paused:
		return

	sim_frame += 1
	phase_frame += 1
	# UI Phase 2: the presentation-only per-sim-tick hook. The HUD counts
	# its timers through this call (frozen here by the paused check above,
	# and by hitstop inside the HUD), and it never writes anything back —
	# nothing in the match reads from the HUD.
	if hud != null:
		hud.sim_tick()
	match phase:
		Phase.INTRO:
			if phase_frame >= INTRO_FRAMES:
				_start_fight()
		Phase.FIGHT:
			_separate_pushboxes()
			# Both attackers' hits are polled before either is applied, so a
			# same-frame trade lands both hits (double-ko), and the hits resolve
			# before the clock so a hit on the timer's final frame still counts
			# and a KO there beats the timeout (timer-hitstop).
			_resolve_hits()
			_update_draw_order()
			if phase != Phase.FIGHT:
				return
			# Hitstop freezes the whole exchange, so it must not burn the clock.
			if p1.hitstop_frames > 0 or p2.hitstop_frames > 0:
				return
			if training_mode:
				# No clock in training; the HUD shows the infinity digits.
				return
			timer_frames -= 1
			hud.set_timer(float(timer_frames) / 60.0)
			if timer_frames <= 0:
				_timeout_round()
		Phase.KO:
			_separate_pushboxes()
			_update_draw_order()
			if phase_frame >= KO_FRAMES:
				if ko_draw:
					_finish_round(-1, true)
				else:
					var winner_index := 0 if ko_loser == p2 else 1
					_finish_round(winner_index)
		Phase.ROUND_END:
			if phase_frame >= ROUND_END_FRAMES:
				round_number += 1
				_begin_round()
		Phase.MATCH_END:
			# UI Phase 3b: the Results screen (pushed by Main on
			# match_results_requested) owns everything from here; the
			# finished match just idles, frozen, underneath it.
			pass

func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo():
		return
	if modal_open:
		# An overlay above the paused match owns all input right now.
		return
	# Training match keys (never while paused: the sim is frozen underneath
	# the menu and the trainer should not stack resets on a frozen frame).
	if training_mode and not get_tree().paused:
		if event.is_action_pressed("training_reset"):
			if training != null:
				training.reset_positions()
			return
		if event.is_action_pressed("training_record"):
			if training != null:
				training.toggle_recording()
			return
		if event.is_action_pressed("training_playback"):
			if training != null:
				training.toggle_playback()
			return
	if event.is_action_pressed("p1_pause") or (p2_human and event.is_action_pressed("p2_pause")):
		_toggle_pause()
		return
	if not get_tree().paused:
		return
	# Menu navigation uses the players' own actions rather than ui_up/ui_down,
	# which also match the arrow keys and would step the selection twice.
	if event.is_action_pressed("p1_up") or (p2_human and event.is_action_pressed("p2_up")):
		_move_pause_selection(-1)
	elif event.is_action_pressed("p1_down") or (p2_human and event.is_action_pressed("p2_down")):
		_move_pause_selection(1)
	elif training_mode and pause_tab == 1 \
			and (event.is_action_pressed("p1_left") or event.is_action_pressed("p1_right")):
		# The training tab adjusts the focused row's value in place; the tab
		# row itself switches tabs.
		_adjust_training_row(1 if event.is_action_pressed("p1_right") else -1)
	elif training_mode and pause_tab == 0 \
			and (event.is_action_pressed("p1_left") or event.is_action_pressed("p1_right")):
		# On the system tab the tab row sits above the options: left/right
		# switches tabs, everywhere else it is inert.
		if pause_index < 0:
			_switch_pause_tab(1)
	elif (event.is_action_pressed("p1_light")
			or (p2_human and event.is_action_pressed("p2_light"))
			or event.is_action_pressed("ui_confirm")):
		_confirm_pause_selection()

# ---------------- Pause menu ----------------
func _toggle_pause() -> void:
	var paused := not pause_menu_open
	get_tree().paused = paused
	pause_menu_open = paused
	if paused:
		pause_index = -1 if training_mode else 0
		pause_tab = 1 if training_mode else 0
	if audio_manager != null:
		audio_manager.play_ui_confirm()
	hud.set_paused(paused)
	if paused and training_mode:
		hud.set_training_pause(pause_tab, pause_index)

func _unpause() -> void:
	get_tree().paused = false
	pause_menu_open = false
	hud.set_paused(false)

# Debug frame-step asks before stepping: the sim must never advance underneath
# the pause menu.
func is_pause_menu_open() -> bool:
	return pause_menu_open

# Rows visible on the current pause tab: the six system options, or the nine
# training rows. The tab row itself is pause_index == -1.
func _pause_row_count() -> int:
	if training_mode and pause_tab == 1:
		return TRAINING_ROWS.size()
	return hud.pause_option_count()

func _switch_pause_tab(tab: int) -> void:
	pause_tab = tab
	pause_index = -1
	hud.set_training_pause(pause_tab, pause_index)
	if audio_manager != null:
		audio_manager.play_ui_move()

func _move_pause_selection(dir: int) -> void:
	if training_mode:
		# Domain -1 (tab row) .. count-1, wrapping through the tab row.
		var count := _pause_row_count()
		pause_index = wrapi(pause_index + dir, -1, count)
		hud.set_training_pause(pause_tab, pause_index)
		if audio_manager != null:
			audio_manager.play_ui_move()
		return
	var count := hud.pause_option_count()
	if count <= 0:
		return
	pause_index = wrapi(pause_index + dir, 0, count)
	hud.set_pause_selection(pause_index)
	if audio_manager != null:
		audio_manager.play_ui_move()

# Left/right on a training row cycles that row's value (the POSITION and
# HITBOXES rows apply immediately through the controller).
func _adjust_training_row(dir: int) -> void:
	if training == null or pause_index < 0:
		_switch_pause_tab(0 if pause_tab == 1 else 1)
		return
	var row := pause_index
	var value: int = wrapi(training.option_value(row) + dir, 0,
		training.option_value_count(row))
	training.set_option_value(row, value)
	hud.set_training_pause(pause_tab, pause_index)
	if audio_manager != null:
		audio_manager.play_ui_move()

func _confirm_pause_selection() -> void:
	if audio_manager != null:
		audio_manager.play_ui_confirm()
	if training_mode:
		# The tab row enters its tab; the training tab's POSITION and
		# HITBOXES rows also act on confirm.
		if pause_index < 0:
			pause_index = 0
			hud.set_training_pause(pause_tab, pause_index)
			return
		if pause_tab == 1:
			match pause_index:
				7:
					if training != null:
						training.reset_positions()
				8:
					if training != null:
						training.set_option_value(8,
							1 - training.option_value(8))
						hud.set_training_pause(pause_tab, pause_index)
			return
	match pause_index:
		2:
			# Start the new match unpaused so its intro frames actually run.
			_unpause()
			_reset_match()
		3:
			# Leave the match to Main: it frees this node and restores character
			# select. Unpause first so the menu screen is not left paused.
			_unpause()
			return_to_select_requested.emit()
		4:
			# Leave the match to Main: it frees this node and shows the main
			# menu (Phase 1 hub). Unpause first so the menu is not left paused.
			_unpause()
			main_menu_requested.emit()
		5:
			# QUIT goes through the quit-confirm overlay; Main pushes it above
			# the still-paused match so NO can cancel back into the pause menu.
			quit_requested.emit()
		1:
			# SETTINGS opens the overlay above the paused match; Main clears
			# modal_open when the overlay closes.
			settings_requested.emit()
		_:
			_unpause()

# Poll both fighters before applying either hit, so a same-frame trade lands
# both hits. Resolving them in sequence let the first KO interrupt the second
# attacker (state leaves ATTACK) and silently win every exchange.
func _resolve_hits() -> void:
	var move_a := _poll_hit(p1, p2)
	var move_b := _poll_hit(p2, p1)
	# GDD §5.6 counter hit: the defender is still in its own startup, and the
	# exchange is not a trade (a same-frame reply from the defender cancels it).
	if move_a != null:
		var p2_before := p2.health
		var counter_a := move_b == null and p2.is_in_attack_startup()
		var hit_a := p2.receive_hit(p1, move_a, counter_a)
		p1.on_attack_connected(hit_a)
		_play_contact_sfx(move_a, p2, p2_before)
		round_damage[0] += maxf(0.0, p2_before - p2.health)
	if move_b != null:
		var p1_before := p1.health
		var counter_b := move_a == null and p1.is_in_attack_startup()
		var hit_b := p1.receive_hit(p2, move_b, counter_b)
		p2.on_attack_connected(hit_b)
		_play_contact_sfx(move_b, p1, p1_before)
		round_damage[1] += maxf(0.0, p1_before - p1.health)
	# B10 repair: when the first hit of a trade KOs and _on_fighter_ko() moves
	# the match into Phase.KO, the second hit was already polled, so the
	# not-yet-KO fighter can take a nonlethal reply that would otherwise leave
	# the round winner stuck in HITSTUN for the KO phase. Force the winner back
	# to WIN, keeping its nonlethal reply damage, unless the exchange is a true
	# double KO (the second hit killed: _on_fighter_ko() set ko_draw and forced
	# both fighters to KO).
	if phase == Phase.KO and not ko_draw:
		var ko_winner: FighterBase = p2 if ko_loser == p1 else p1
		if ko_winner.state != FighterBase.State.WIN:
			ko_winner._force_state(FighterBase.State.WIN)

func _play_contact_sfx(move: MoveData, defender: FighterBase, health_before: float) -> void:
	if audio_manager == null:
		return
	if defender.state == FighterBase.State.BLOCKSTUN:
		audio_manager.play_sfx("block")
	elif defender.health < health_before:
		if move.input == MoveData.InputType.LIGHT:
			audio_manager.play_sfx("hit_light")
		else:
			audio_manager.play_sfx("hit_heavy")

func _poll_hit(attacker: FighterBase, defender: FighterBase) -> MoveData:
	if attacker.state != FighterBase.State.ATTACK:
		return null
	if attacker.current_move == null or attacker.move_already_hit:
		return null
	var hb := attacker.get_hitbox_rect()
	if hb.size == Vector2.ZERO:
		return null
	if not hb.intersects(defender.hurtbox_rect()):
		return null
	# An invulnerable defender (wake-up window, or a reversal's authored invuln
	# frames) is skipped before the move is returned, for the same reason as the
	# throw guard below: _resolve_hits() only calls on_attack_connected() for a
	# non-null move, so the brush costs the attacker nothing and the first frame
	# the defender is vulnerable is the frame that connects. Folding this into
	# receive_hit() instead would burn the whole active window on the brush and
	# make a meaty impossible.
	if defender.is_invulnerable_to(attacker.current_move):
		return null
	# A grounded throw cannot grab a defender who has left the ground. This is
	# rejected before the move is returned on purpose: _resolve_hits() only calls
	# on_attack_connected() for a non-null move, so the brush does not consume the
	# throw's active window and the grab still lands on a later active frame if the
	# defender touches down inside it.
	if attacker.current_move.level == MoveData.Level.THROW and not defender.grounded:
		return null
	# Rule F: a throw connects only in front of the thrower, equal x counting
	# as in front (FighterBase.is_in_front_of). Rejected here rather than in
	# receive_hit() for the same reason as the invuln/airborne guards above:
	# the brush does not consume the throw's active window.
	if attacker.current_move.level == MoveData.Level.THROW \
			and not FighterBase.is_in_front_of(attacker, defender):
		return null
	return attacker.current_move

func _separate_pushboxes() -> void:
	if p1.state == FighterBase.State.KO or p2.state == FighterBase.State.KO:
		return
	# Airborne bodies may cross over the opponent's pushbox; grounded bodies
	# still separate on landing (unless walk-through mode is enabled).
	if fighters_can_pass_through:
		return
	if not p1.grounded or not p2.grounded:
		return
	var r1 := p1.pushbox_rect()
	var r2 := p2.pushbox_rect()
	if not r1.intersects(r2):
		return
	var overlap := minf(r1.end.x, r2.end.x) - maxf(r1.position.x, r2.position.x)
	if overlap <= 0.0:
		return
	# Separate by center order, initially sharing the correction evenly. If one
	# fighter is pinned at a stage bound, transfer that fighter's unapplied share
	# to the other fighter rather than leaving residual pushbox overlap. At
	# exactly equal x the lower player slot is fixed as the left body, so the
	# result never depends on node order.
	var left_fighter: FighterBase
	if p1.position.x == p2.position.x:
		left_fighter = p1 if p1.player_index <= p2.player_index else p2
	else:
		left_fighter = p1 if p1.position.x < p2.position.x else p2
	var right_fighter: FighterBase = p2 if left_fighter == p1 else p1
	var left_room := maxf(0.0, left_fighter.position.x - left_fighter.stage.left_bound)
	var right_room := maxf(0.0, right_fighter.stage.right_bound - right_fighter.position.x)
	var left_move := minf(overlap * 0.5, left_room)
	var right_move := minf(overlap * 0.5, right_room)
	var remaining := overlap - left_move - right_move
	if remaining > 0.0:
		var extra_left := minf(remaining, maxf(0.0, left_room - left_move))
		left_move += extra_left
		remaining -= extra_left
	if remaining > 0.0:
		var extra_right := minf(remaining, maxf(0.0, right_room - right_move))
		right_move += extra_right
		remaining -= extra_right
	left_fighter.position.x -= left_move
	right_fighter.position.x += right_move
	p1.clamp_to_stage()
	p2.clamp_to_stage()

# Rule I: overlap draw order. An attacker in active/recovery frames draws
# above the other fighter; otherwise the fixed P1-under-P2 slot order stands.
# Recomputed from state alone every frame, so overlapping fighters can't
# flicker. Both attacking (a trade frame) falls back to the slot order.
func _update_draw_order() -> void:
	var p1_on_top := _is_active_or_recovery(p1) and not _is_active_or_recovery(p2)
	var p2_on_top := _is_active_or_recovery(p2) and not _is_active_or_recovery(p1)
	p1.z_index = 1 if p1_on_top else 0
	p2.z_index = 1 if p2_on_top else 0

func _is_active_or_recovery(f: FighterBase) -> bool:
	return f.state == FighterBase.State.ATTACK and f.current_move != null \
		and f.state_frame >= f.current_move.startup

# ---------------- Save/Load (replays, rollback, training reset) ----------------

# Serialize the full match state. Non-serializable internals (scene nodes,
# audio_manager, resource references) are intentionally excluded.
func serialize() -> Dictionary:
	var data := {
		"phase": phase,
		"phase_frame": phase_frame,
		"round_number": round_number,
		"wins": wins.duplicate(),
		"timer_frames": timer_frames,
		"ko_loser": ko_loser,
		"ko_draw": ko_draw,
		"ko_frame": ko_frame,
		"sim_frame": sim_frame,
		"timeout_ties": timeout_ties,
		"sudden_death": sudden_death,
		"round_damage": round_damage.duplicate(),
		"pause_index": pause_index,
		"pause_menu_open": pause_menu_open,
		"commentary_sample_shown": commentary_sample_shown,
		"p2_human": p2_human,
		"p2_cpu": p2_cpu,
		"p1_cpu": p1_cpu,
		"cpu_level": cpu_level,
		"cpu_seed": cpu_seed,
		"cpu_p1": cpu_p1.serialize() if cpu_p1 != null else null,
		"cpu_p2": cpu_p2.serialize() if cpu_p2 != null else null,
		"fighters_can_pass_through": fighters_can_pass_through,
		"training_mode": training_mode,
		"pause_tab": pause_tab,
		"training": training.serialize() if training != null else null,
		"p1": p1.serialize(),
		"p2": p2.serialize(),
	}
	return data

# Load the full match state from a dictionary produced by serialize().
func load(data: Dictionary) -> void:
	phase = data["phase"]
	phase_frame = data["phase_frame"]
	round_number = data["round_number"]
	wins = data["wins"]
	timer_frames = data["timer_frames"]
	ko_loser = data["ko_loser"]
	ko_draw = data["ko_draw"]
	ko_frame = data["ko_frame"]
	sim_frame = data["sim_frame"]
	timeout_ties = data["timeout_ties"]
	sudden_death = data["sudden_death"]
	round_damage = data["round_damage"]
	pause_index = data["pause_index"]
	pause_menu_open = data["pause_menu_open"]
	commentary_sample_shown = data["commentary_sample_shown"]
	p2_human = data["p2_human"]
	p2_cpu = data.get("p2_cpu", p2_cpu)
	p1_cpu = data.get("p1_cpu", p1_cpu)
	cpu_level = data.get("cpu_level", cpu_level)
	cpu_seed = data.get("cpu_seed", cpu_seed)
	fighters_can_pass_through = data.get(
		"fighters_can_pass_through", fighters_can_pass_through)
	training_mode = bool(data.get("training_mode", false))
	pause_tab = int(data.get("pause_tab", 0))
	if training_mode and training != null:
		# Fighter state first: TrainingController's load re-snapshots the
		# prior-frame edge detectors from the restored fighters. It may
		# create/remove the training CPU based on the restored dummy option.
		p1.load(data["p1"])
		p2.load(data["p2"])
		if typeof(data.get("training")) == TYPE_DICTIONARY:
			training.load_state(data["training"])
		if cpu_p1 != null and typeof(data.get("cpu_p1")) == TYPE_DICTIONARY:
			cpu_p1.load_state(data["cpu_p1"])
		if cpu_p2 != null and typeof(data.get("cpu_p2")) == TYPE_DICTIONARY:
			cpu_p2.load_state(data["cpu_p2"])
	else:
		# Keep the pre-training CPU -> fighter load order byte-for-byte for
		# versus and solo. Non-training fighters carry the zero health floor.
		if cpu_p1 != null and typeof(data.get("cpu_p1")) == TYPE_DICTIONARY:
			cpu_p1.load_state(data["cpu_p1"])
		if cpu_p2 != null and typeof(data.get("cpu_p2")) == TYPE_DICTIONARY:
			cpu_p2.load_state(data["cpu_p2"])
		p1.load(data["p1"])
		p2.load(data["p2"])
		p1.training_min_health = 0.0
		p2.training_min_health = 0.0
	if training_mode and pause_menu_open:
		hud.set_training_pause(pause_tab, pause_index)

# ---------------- Simulation ----------------
