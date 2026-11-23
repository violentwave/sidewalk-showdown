# fx_events_test.gd — Phase C pins for the presentation-only FX event layer
# (docs/FX_AND_METH_DESIGN.md §1.3/§2/§4 items 5-6).
#
# Everything asserted here is data/behavior, not pixels: the right sheet per
# character and kind (precedence EX > counter > special/launcher > heavy >
# light; one primary impact per contact), mirroring by facing, sim-clock
# stepping that freezes in hitstop, startup-attached whoosh/trail, landing/
# knockdown dust, the one-shot wall contact, the FxSet data matching the
# owner manifests, and — the load-bearing check — that spawning FX changes
# no serializable gameplay state at all.
extends SceneTree

const MATCH_SCENE := preload("res://scenes/match/MatchRoot.tscn")
const ROSTER := preload("res://resources/match_roster.tres")

var failures := 0
var checks := 0
var scene: Node
var p1: FighterBase
var p2: FighterBase
var hud: MatchHUD
var fx: FxLayer


func _initialize() -> void:
	_run.call_deferred()


func _check(label: String, condition: bool, detail: String = "") -> void:
	checks += 1
	if condition:
		print("PASS: ", label)
	else:
		failures += 1
		print("FAIL: ", label, "  ", detail)


func _step(frames: int) -> void:
	for _frame in frames:
		await physics_frame


func _new_match(intro_wait := 65) -> void:
	scene = MATCH_SCENE.instantiate()
	scene.selected_p1_data = ROSTER.fighters[0]
	scene.selected_p2_data = ROSTER.fighters[1]
	scene.selected_stage = ROSTER.stages[0]
	root.add_child(scene)
	await physics_frame
	await _step(intro_wait)
	p1 = scene.p1
	p2 = scene.p2
	hud = scene.hud
	fx = scene.fx


func _place_pair(attacker: FighterBase, defender: FighterBase,
		gap := 26.0) -> void:
	var floor_y: float = scene.stage.floor_y
	attacker.position = Vector2(120.0, floor_y)
	defender.position = Vector2(120.0 + gap, floor_y)
	attacker.velocity = Vector2.ZERO
	defender.velocity = Vector2.ZERO
	attacker.facing = 1
	defender.facing = -1
	attacker.reset_state()
	defender.reset_state()
	attacker.health = attacker.max_health
	defender.health = defender.max_health


# Mirrored placement: the ATTACKER stands on the right and faces left, for
# the mirroring checks.
func _place_pair_left(attacker: FighterBase, defender: FighterBase,
		gap := 26.0) -> void:
	var floor_y: float = scene.stage.floor_y
	attacker.position = Vector2(200.0, floor_y)
	defender.position = Vector2(200.0 - gap, floor_y)
	attacker.velocity = Vector2.ZERO
	defender.velocity = Vector2.ZERO
	attacker.facing = -1
	defender.facing = 1
	attacker.reset_state()
	defender.reset_state()
	attacker.health = attacker.max_health
	defender.health = defender.max_health


func _light(f: FighterBase) -> MoveData:
	return f.data.find_move(MoveData.InputType.LIGHT, MoveData.Stance.STAND)


func _heavy(f: FighterBase) -> MoveData:
	return f.data.find_move(MoveData.InputType.HEAVY, MoveData.Stance.STAND)


func _special(f: FighterBase) -> MoveData:
	return f.data.find_move(MoveData.InputType.SPECIAL_FWD, MoveData.Stance.STAND)


func _ex(f: FighterBase) -> MoveData:
	return f.data.find_ex_move(MoveData.InputType.SPECIAL_FWD, MoveData.Stance.STAND)


func _crouch_heavy(f: FighterBase) -> MoveData:
	return f.data.find_move(MoveData.InputType.HEAVY, MoveData.Stance.CROUCH)


# Steps until a contact FX spawns (bounded), true when one did.
func _await_contact(budget := 90) -> bool:
	var before: int = fx.contact_spawn_count
	for i in budget:
		await physics_frame
		if fx.contact_spawn_count > before:
			return true
	return false


func _await_oneshots_clear(budget := 60) -> void:
	for i in budget:
		await physics_frame
		if fx.active_oneshot_count() == 0:
			return


# The most recently spawned one-shot (hit bursts spawn after any startup
# streak, so the last index is the contact sheet under test).
func _last_oneshot() -> Sprite2D:
	var n := fx.active_oneshot_count()
	return null if n == 0 else fx.oneshot_sprite(n - 1)


# True when a landing_dust one-shot is anchored at `x` on the floor line.
func _has_dust_at(x: float, tolerance := 8.0) -> bool:
	for i in fx.active_oneshot_count():
		var sprite := fx.oneshot_sprite(i)
		if sprite == null:
			continue
		if str(sprite.texture.resource_path).contains("landing_dust") \
				and absf(sprite.position.x - x) <= tolerance \
				and absf(sprite.position.y - scene.stage.floor_y) <= 2.0:
			return true
	return false


# Steps (bounded) until a landing_dust one-shot exists near `x`.
func _await_dust_near(x: float, budget := 60) -> bool:
	for i in budget:
		await physics_frame
		if _has_dust_at(x):
			return true
	return false


func _run() -> void:
	await process_frame
	await _test_fx_data_and_art()
	await _test_contact_kinds()
	await _test_precedence()
	await _test_mirroring()
	await _test_startup_attached()
	await _test_landing_knockdown_wall()
	await _test_hitstop_freeze()
	await _test_no_serialization_change()
	print("fx_events_test: %d checks, %d failure(s)" % [checks, failures])
	quit(1 if failures > 0 else 0)


# ---------------- data & art ----------------

func _test_fx_data_and_art() -> void:
	await _new_match()
	_check("the FX layer is a CanvasLayer at 5 (above the world, below the HUD)",
		fx is CanvasLayer and fx.layer == 5 and hud.layer == 10,
		"fx.layer=%s hud.layer=%s" % [str(fx.layer), str(hud.layer)])
	_check("the FX layer sits above the fighters and below the HUD layer",
		fx.layer > p1.z_index and fx.layer < hud.layer,
		"fx=%d fighters z<=%d hud=%d" % [fx.layer, maxi(p1.z_index, p2.z_index), hud.layer])
	# FxSet resources: every def valid, texture real, sheet geometry exact.
	for f: FighterBase in [p1, p2]:
		var set: FxSet = f.data.fx_set
		_check("%s carries an FxSet" % f.data.id, set != null, "fx_set is null")
		if set == null:
			continue
		var defs := {
			"hit_light": set.hit_light, "hit_heavy": set.hit_heavy,
			"hit_counter": set.hit_counter, "block": set.block,
			"special_hit": set.special_hit, "ex_hit": set.ex_hit,
			"heavy_whoosh": set.heavy_whoosh,
			"special_trail": set.special_trail,
			"landing_dust": set.landing_dust,
		}
		var all_valid := true
		var all_match := true
		for kind in defs:
			var def: FxSheetDef = defs[kind]
			if def == null or not def.valid():
				all_valid = false
				continue
			var tex := load(def.texture_path) as Texture2D
			if tex == null or tex.get_width() != def.cell.x * def.frames \
					or tex.get_height() != def.cell.y:
				all_match = false
				push_error("fx def mismatch %s/%s: %s" % [f.data.id, kind, def.texture_path])
		_check("%s: all nine FxSheetDefs are valid" % f.data.id, all_valid,
			"a def is null or empty")
		_check("%s: every sheet is exactly cell*frames at native size"
			% f.data.id, all_match, "texture geometry mismatch")
	# Runtime art is byte-identical to the owner-approved sources.
	var repo_root := ProjectSettings.globalize_path("res://").trim_suffix("/").get_base_dir()
	var byte_errors := 0
	var compared := 0
	for src_dir in ["hit_fx", "meth_props"]:
		var abs_dir := repo_root.path_join("art/source/FX").path_join(src_dir)
		var dir := DirAccess.open(abs_dir)
		if dir == null:
			byte_errors += 1
			continue
		for file_name in dir.get_files():
			if not file_name.to_lower().ends_with(".png"):
				continue
			var src := FileAccess.get_file_as_bytes(abs_dir.path_join(file_name))
			var dst := FileAccess.get_file_as_bytes(
				ProjectSettings.globalize_path("res://art/fx").path_join(file_name))
			compared += 1
			if src != dst:
				byte_errors += 1
				push_error("fx art differs from source: %s" % file_name)
	_check("runtime game/art/fx sheets are byte-identical to the approved sources",
		byte_errors == 0 and compared >= 26,
		"byte errors=%d compared=%d" % [byte_errors, compared])
	scene.queue_free()
	await _step(2)


# ---------------- contact kinds ----------------

func _test_contact_kinds() -> void:
	await _new_match()
	# Peggy light: the per-character light sheet at the overlap center.
	_place_pair(p1, p2)
	p1._start_move(_light(p1))
	var landed := await _await_contact()
	_check("peggy light contact spawns the peggy light sheet",
		landed and fx.last_spawn["sheet"].contains("peggy_hit_light"),
		"last=%s" % str(fx.last_spawn))
	var spawn_pos: Vector2 = fx.last_spawn["position"]
	_check("the light FX anchors between the pair at strike height",
		spawn_pos.x > p1.position.x and spawn_pos.x < p2.position.x + 8.0
			and spawn_pos.y < scene.stage.floor_y - 8.0,
		"spawn=%s" % str(spawn_pos))
	_check("one primary impact per resolved contact",
		fx.contact_spawn_count == 1, "count=%d" % fx.contact_spawn_count)
	await _await_oneshots_clear()

	# Peggy heavy.
	_place_pair(p1, p2)
	p1._start_move(_heavy(p1))
	landed = await _await_contact()
	_check("peggy heavy contact spawns the peggy heavy sheet",
		landed and fx.last_spawn["sheet"].contains("peggy_hit_heavy"),
		"last=%s" % str(fx.last_spawn))
	await _await_oneshots_clear()

	# Peggy forward special (the launcher row) uses the special sheet.
	_place_pair(p1, p2)
	p1._start_move(_special(p1))
	landed = await _await_contact()
	_check("peggy special (launcher) contact spawns the peggy special sheet",
		landed and fx.last_spawn["sheet"].contains("peggy_special_hit"),
		"last=%s" % str(fx.last_spawn))
	await _await_oneshots_clear()

	# Peggy forward EX with meter for it.
	_place_pair(p1, p2)
	p1.add_meter(60.0)
	p1._start_move(_ex(p1))
	landed = await _await_contact()
	_check("peggy EX contact spawns the peggy EX sheet",
		landed and fx.last_spawn["sheet"].contains("peggy_ex_hit"),
		"last=%s" % str(fx.last_spawn))
	await _await_oneshots_clear()

	# Block: the defender holds away (right, away from the left-side
	# attacker); the subdued block sheet spawns, chip only, no hit kind.
	_place_pair(p1, p2)
	Input.action_press("p2_right")
	p1._start_move(_light(p1))
	landed = await _await_contact()
	_check("a blocked contact spawns the block sheet",
		landed and fx.last_spawn["sheet"].contains("peggy_block")
			and fx.last_spawn["blocked"] == true,
		"last=%s" % str(fx.last_spawn))
	_check("the blocked contact dealt chip damage only (health floored at 1)",
		p2.health >= p2.max_health - 8.0 and p2.health < p2.max_health,
		"p2 health=%f" % p2.health)
	Input.action_release("p2_right")
	await _await_oneshots_clear()

	# Richard as attacker: his own sheets, never a Peggy recolor.
	_place_pair(p2, p1)
	p2._start_move(_light(p2))
	landed = await _await_contact()
	_check("richard light contact spawns the richard light sheet",
		landed and fx.last_spawn["sheet"].contains("richard_hit_light"),
		"last=%s" % str(fx.last_spawn))
	await _await_oneshots_clear()

	_place_pair(p2, p1)
	p2._start_move(_heavy(p2))
	landed = await _await_contact()
	_check("richard heavy contact spawns the richard heavy sheet",
		landed and fx.last_spawn["sheet"].contains("richard_hit_heavy"),
		"last=%s" % str(fx.last_spawn))
	scene.queue_free()
	await _step(2)


# ---------------- precedence ----------------

func _test_precedence() -> void:
	await _new_match()
	# Counter: the defender was in its own startup; the counter sheet
	# REPLACES the ordinary heavy burst.
	_place_pair(p1, p2)
	p2._start_move(_heavy(p2))  # startup 9 > peggy heavy startup 7
	p1._start_move(_heavy(p1))
	var landed := await _await_contact()
	_check("a counter-hit spawns the counter sheet, not the heavy sheet",
		landed and fx.last_spawn["sheet"].contains("peggy_hit_counter"),
		"last=%s" % str(fx.last_spawn))
	await _await_oneshots_clear()

	# EX beats counter (design §2 precedence): the defender's late light is
	# still in startup when the EX connects, and its active window never
	# opens (the hit interrupts it), so no trade can mask the counter.
	_place_pair(p1, p2)
	p1.add_meter(60.0)
	p1._start_move(_ex(p1))  # startup 9, active 9-12
	await _step(7)
	p2._start_move(_light(p2))  # p2 state_frame 2 when the EX connects
	landed = await _await_contact()
	_check("an EX counter-hit spawns the EX sheet (EX > counter)",
		landed and fx.last_spawn["sheet"].contains("peggy_ex_hit"),
		"last=%s" % str(fx.last_spawn))
	await _await_oneshots_clear()

	# A stun-authored special (Peg-Lock) still uses the normal special
	# sheet — no separate stun art (design §1.3).
	_place_pair(p1, p2)
	p1._start_move(p1.data.find_move(MoveData.InputType.SPECIAL_NEUTRAL,
		MoveData.Stance.STAND))
	landed = await _await_contact()
	_check("the stun special uses the ordinary special sheet (no stun aura)",
		landed and fx.last_spawn["sheet"].contains("peggy_special_hit"),
		"last=%s" % str(fx.last_spawn))
	scene.queue_free()
	await _step(2)


# ---------------- mirroring ----------------

func _test_mirroring() -> void:
	await _new_match()
	# Facing right: directional sheets unflipped.
	_place_pair(p1, p2)
	p1._start_move(_special(p1))
	var landed := await _await_contact()
	_check("a right-facing special hit is not mirrored",
		landed and _last_oneshot() != null and not _last_oneshot().flip_h,
		"flip_h should be false")
	await _await_oneshots_clear()

	# Facing left: the special sheet mirrors.
	_place_pair_left(p2, p1)  # p2 stands right, facing left
	p2._start_move(_special(p2))
	landed = await _await_contact()
	_check("a left-facing special hit mirrors with the attacker's facing",
		landed and _last_oneshot() != null and _last_oneshot().flip_h,
		"flip_h should be true")
	await _await_oneshots_clear()

	# Radial bursts never mirror (design §1.5).
	_place_pair_left(p2, p1)
	p2._start_move(_light(p2))
	landed = await _await_contact()
	_check("a left-facing light hit (radial) is never mirrored",
		landed and _last_oneshot() != null and not _last_oneshot().flip_h,
		"flip_h should be false")
	scene.queue_free()
	await _step(2)


# ---------------- startup-attached streaks ----------------

func _test_startup_attached() -> void:
	await _new_match()
	# Heavy startup: the whoosh is attached and follows the attacker.
	_place_pair(p1, p2)
	var before: int = fx.active_oneshot_count()
	p1._start_move(_heavy(p1))
	await physics_frame
	await physics_frame
	_check("a heavy startup spawns the attached whoosh sheet",
		fx.active_oneshot_count() == before + 1
			and fx.oneshot_sprite(before) != null
			and str(fx.oneshot_sprite(before).texture.resource_path).contains("peggy_heavy_whoosh"),
		"count=%d" % fx.active_oneshot_count())
	var whoosh_pos: Vector2 = fx.oneshot_sprite(before).position
	p1.position.x += 10.0
	await physics_frame
	var followed: Vector2 = fx.oneshot_sprite(before).position
	_check("the whoosh follows its attacker",
		absf(followed.x - (whoosh_pos.x + 10.0)) < 0.01,
		"was=%s now=%s" % [str(whoosh_pos), str(followed)])
	await _await_oneshots_clear()

	# Special startup: the trail; light startup: nothing.
	_place_pair(p1, p2)
	before = fx.active_oneshot_count()
	p1._start_move(_special(p1))
	await physics_frame
	await physics_frame
	_check("a special startup spawns the attached trail sheet",
		fx.active_oneshot_count() == before + 1
			and str(fx.oneshot_sprite(before).texture.resource_path).contains("peggy_special_trail"),
		"count=%d" % fx.active_oneshot_count())
	await _await_oneshots_clear()

	_place_pair(p1, p2)
	before = fx.active_oneshot_count()
	p1._start_move(_light(p1))
	await physics_frame
	await physics_frame
	_check("a light startup spawns no streak",
		fx.active_oneshot_count() == before, "count=%d" % fx.active_oneshot_count())

	# The METH move itself spawns nothing (the cinematic owns it).
	_place_pair(p1, p2)
	before = fx.active_oneshot_count()
	p1.add_meter(p1.max_meter)
	p1._start_move(p1.data.meth_move)
	await _step(6)
	_check("a METH startup spawns no whoosh/trail",
		fx.active_oneshot_count() == before, "count=%d" % fx.active_oneshot_count())
	scene.queue_free()
	await _step(2)


# ---------------- landing / knockdown / wall ----------------

func _test_landing_knockdown_wall() -> void:
	await _new_match()
	# Landing from a jump: one dust at the feet.
	_place_pair(p1, p2)
	p1._force_state(FighterBase.State.JUMP_FALL)
	p1.grounded = false
	p1.position.y = scene.stage.floor_y - 30.0
	var landed_dust := false
	for i in 40:
		await physics_frame
		if p1.grounded and _has_dust_at(p1.position.x):
			landed_dust = true
			break
	_check("a landing transition spawns the shared dust at the feet",
		landed_dust, "no landing dust")
	await _await_oneshots_clear()

	# Grounded knockdown: one dust at the slam (the FX poll sees the state
	# transition one tick after the resolver).
	_place_pair(p1, p2)
	p1._start_move(_crouch_heavy(p1))
	var landed := await _await_contact()
	var knockdown_dust := await _await_dust_near(p2.position.x, 20)
	_check("a grounded knockdown connects into KNOCKDOWN with floor dust",
		landed and p2.state == FighterBase.State.KNOCKDOWN and knockdown_dust,
		"state=%s" % str(p2.state))
	await _await_oneshots_clear()

	# Airborne knockdown: dust waits for floor contact.
	_place_pair(p1, p2)
	p2.grounded = false
	p2.position.y = scene.stage.floor_y - 24.0
	p2._force_state(FighterBase.State.JUMP_FALL)
	p1._start_move(_crouch_heavy(p1))
	landed = await _await_contact()
	_check("an airborne knockdown connects and lands into KNOCKDOWN",
		landed and p2.state == FighterBase.State.KNOCKDOWN,
		"state=%s" % str(p2.state))
	var dust_at_floor := false
	for i in 80:
		await physics_frame
		if p2.grounded and _has_dust_at(p2.position.x):
			dust_at_floor = true
			break
	_check("the airborne knockdown dust fires once the feet reach the floor",
		dust_at_floor, "no dust on knockdown landing")
	await _await_oneshots_clear()

	# Wall contact: exactly one event per clamp contact, not per pinned frame.
	# The attacker stands just left of the defender so the heavy actually
	# reaches, and the defender is a knockback's length from the wall.
	_place_pair(p1, p2, 26.0)
	p1.position.x = scene.stage.right_bound - 30.0
	p2.position.x = scene.stage.right_bound - 4.0
	p1._start_move(_heavy(p1))
	var landed_wall := await _await_contact()
	var wall_dust := await _await_dust_near(scene.stage.right_bound)
	_check("a knockback into the wall spawns dust at the wall",
		landed_wall and wall_dust, "no wall dust")
	var wall_dust_events := 0
	var last_dust_seen := -1
	for i in 40:
		await physics_frame
		if p2.position.x >= scene.stage.right_bound and _has_dust_at(scene.stage.right_bound):
			if last_dust_seen < 0 or i - last_dust_seen > 20:
				wall_dust_events += 1
			last_dust_seen = i
	_check("a wall-pinned fighter does not re-spawn wall dust every frame",
		wall_dust_events <= 1, "wall dust events=%d" % wall_dust_events)
	scene.queue_free()
	await _step(2)


# ---------------- sim-clock stepping ----------------

func _test_hitstop_freeze() -> void:
	await _new_match()
	_place_pair(p1, p2)
	p1._start_move(_heavy(p1))  # authored hitstop 6
	var hitstop := -1
	for i in 90:
		await physics_frame
		if fx.contact_spawn_count > 0:
			hitstop = maxi(p1.hitstop_frames, p2.hitstop_frames)
			break
	_check("the scripted heavy contact landed with its authored hitstop",
		hitstop >= 1, "hitstop=%d" % hitstop)
	var frozen_ok := true
	var samples := 0
	while (p1.hitstop_frames > 0 or p2.hitstop_frames > 0) and samples < 20:
		var burst := _last_oneshot()
		if burst != null and burst.frame != 0 and samples > 0:
			frozen_ok = false
		await physics_frame
		samples += 1
	_check("the hit FX frame freezes while hitstop holds the exchange",
		frozen_ok, "advanced during hitstop")
	var advanced := false
	for i in 8:
		await physics_frame
		var burst := _last_oneshot()
		if burst != null and burst.frame > 0:
			advanced = true
			break
	_check("the hit FX resumes stepping after hitstop",
		advanced, "frame never advanced past 0")
	await _await_oneshots_clear()
	scene.queue_free()
	await _step(2)


# ---------------- the load-bearing check: no serializable change ----------------

func _scripted_exchange() -> Dictionary:
	# Deterministic scripted sequence with three serialize checkpoints. The
	# tick counts are FIXED so the FX-on and FX-off runs sample the exact
	# same sim frames (the light's contact lands on tick 3-4 every time).
	_place_pair(p1, p2)
	var t0: Dictionary = scene.serialize()
	p1._start_move(_light(p1))
	await _step(12)
	var t1: Dictionary = scene.serialize()
	await _step(30)
	var t2: Dictionary = scene.serialize()
	return {"t0": t0, "t1": t1, "t2": t2,
		"spawned": fx.contact_spawn_count > 0}


func _test_no_serialization_change() -> void:
	# Two identical scripted runs: FX spawning enabled vs disabled. The
	# serializable state must be byte-identical at every checkpoint.
	await _new_match()
	fx.spawning_enabled = false
	var off: Dictionary = await _scripted_exchange()
	_check("control run: FX disabled, no contact spawned",
		not off["spawned"], "unexpected spawn")
	scene.queue_free()
	await _step(4)

	await _new_match()
	fx.spawning_enabled = true
	var on: Dictionary = await _scripted_exchange()
	_check("experimental run: FX enabled, the contact spawned",
		on["spawned"], "no spawn")
	_check("serialize() before the hit is identical with FX on vs off",
		off["t0"] == on["t0"], "t0 differs")
	_check("serialize() at the hit is identical with FX on vs off",
		off["t1"] == on["t1"], "t1 differs")
	_check("serialize() after the FX expired is identical with FX on vs off",
		off["t2"] == on["t2"], "t2 differs")
	_check("the FX layer never adds itself to the serializable surface",
		not on["t2"].has("fx") and on["t2"]["meth_cinematic"] == null,
		"unexpected fx serialization")
	_check("the FX spawn counts differ between the runs (control sanity)",
		fx.contact_spawn_count > 0, "no spawns recorded")
	scene.queue_free()
	await _step(2)
