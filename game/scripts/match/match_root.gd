# MatchRoot — match orchestrator: rounds, timer, KO, HUD, pause.
extends Node2D

enum Phase { INTRO, FIGHT, KO, ROUND_END, MATCH_END }

# Emitted when the pause menu asks to leave the match; Main owns the flow back
# to character select.
signal return_to_select_requested

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
# False in solo mode: P2 still spawns and can be hit, but never reads input.
@export var p2_human := true
# Smash-style walk-through: when true, grounded fighters are not separated by
# their pushboxes. Airborne fighters always pass through, so a jump-over works
# in either mode; when this is false, grounded bodies still block each other.
@export var fighters_can_pass_through := false

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

# ---------------- Round flow ----------------
func _begin_round() -> void:
	p1.begin_round(Vector2(stage.spawn_p1_x, stage.floor_y), stage.spawn_p2_x)
	p2.begin_round(Vector2(stage.spawn_p2_x, stage.floor_y), stage.spawn_p1_x)
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
		hud.show_message("SUDDEN DEATH")
	elif wins[0] >= WINS_TO_TAKE_MATCH and wins[1] >= WINS_TO_TAKE_MATCH:
		hud.show_message("DECISIVE ROUND")
	else:
		hud.show_message("ROUND %d" % round_number)

func _start_fight() -> void:
	phase = Phase.FIGHT
	phase_frame = 0
	p1.input_enabled = true
	p2.input_enabled = p2_human
	hud.clear_message()
	if not commentary_sample_shown:
		hud.show_commentary("TRIPP: The crowd is going insane!")
		commentary_sample_shown = true
	if audio_manager != null:
		audio_manager.play_sfx("round_start")

func _on_meth_started(meth_name: String) -> void:
	hud.show_meth_message("METHtality\n%s" % meth_name.to_upper())
	if audio_manager != null:
		audio_manager.play_sfx("meth")

func _on_fighter_ko(loser: FighterBase) -> void:
	if phase == Phase.KO:
		# A second KO inside the same simulation frame means both fighters died
		# on the trade: make it a draw round instead of crediting the first signal.
		if ko_frame == sim_frame and p1.health <= 0.0 and p2.health <= 0.0:
			ko_draw = true
			ko_loser = null
			for f: FighterBase in [p1, p2]:
				if f.health <= 0.0 and f.state != FighterBase.State.KO:
					f._force_state(FighterBase.State.KO)
			hud.show_message("DOUBLE K.O.")
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
	hud.show_message("K.O.")

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
		hud.show_message("DOUBLE K.O.\nBOTH TAKE THE ROUND" if double_ko else "DRAW")
	else:
		var winner := p1 if winner_index == 0 else p2
		hud.show_message("%s\nTAKES THE ROUND" % winner.data.display_name.to_upper())

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
	hud.show_message("%s WINS THE MATCH%s\nENTER TO RESTART"
		% [champion.data.display_name.to_upper(), note])

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
			if phase != Phase.FIGHT:
				return
			# Hitstop freezes the whole exchange, so it must not burn the clock.
			if p1.hitstop_frames > 0 or p2.hitstop_frames > 0:
				return
			timer_frames -= 1
			hud.set_timer(float(timer_frames) / 60.0)
			if timer_frames <= 0:
				_timeout_round()
		Phase.KO:
			_separate_pushboxes()
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
			if Input.is_action_just_pressed("ui_confirm"):
				_reset_match()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo():
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
		pause_index = 0
	if audio_manager != null:
		audio_manager.play_ui_confirm()
	hud.set_paused(paused)

func _unpause() -> void:
	get_tree().paused = false
	pause_menu_open = false
	hud.set_paused(false)

# Debug frame-step asks before stepping: the sim must never advance underneath
# the pause menu.
func is_pause_menu_open() -> bool:
	return pause_menu_open

func _move_pause_selection(dir: int) -> void:
	var count := hud.pause_option_count()
	if count <= 0:
		return
	pause_index = wrapi(pause_index + dir, 0, count)
	hud.set_pause_selection(pause_index)
	if audio_manager != null:
		audio_manager.play_ui_move()

func _confirm_pause_selection() -> void:
	if audio_manager != null:
		audio_manager.play_ui_confirm()
	match pause_index:
		1:
			# Start the new match unpaused so its intro frames actually run.
			_unpause()
			_reset_match()
		2:
			# Leave the match to Main: it frees this node and restores character
			# select. Unpause first so the menu screen is not left paused.
			_unpause()
			return_to_select_requested.emit()
		3:
			_unpause()
			get_tree().quit()
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

# ---------------- Save/Load (replays, rollback, training reset) ----------------

# Serialize the full match state. Non-serializable internals (scene nodes,
# audio_manager, resource references) are intentionally excluded.
func serialize() -> Dictionary:
	var data := {
		"phase": phase,
		"phase_frame": phase_frame,
		"round_number": round_number,
		"wins": wins,
		"timer_frames": timer_frames,
		"ko_loser": ko_loser,
		"ko_draw": ko_draw,
		"ko_frame": ko_frame,
		"sim_frame": sim_frame,
		"timeout_ties": timeout_ties,
		"sudden_death": sudden_death,
		"round_damage": round_damage,
		"pause_index": pause_index,
		"pause_menu_open": pause_menu_open,
		"commentary_sample_shown": commentary_sample_shown,
		"p2_human": p2_human,
		"fighters_can_pass_through": fighters_can_pass_through,
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
	fighters_can_pass_through = data.get(
		"fighters_can_pass_through", fighters_can_pass_through)
	p1.load(data["p1"])
	p2.load(data["p2"])

# ---------------- Simulation ----------------
