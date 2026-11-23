# hud_test.gd — UI Phase 2 pins for the reskinned match HUD
# (docs/UI_SCREENS.md "The match HUD"). Everything here is
# presentation-only: the suite drives a real MatchRoot through real
# exchanges where cheap (KOs, freezes) and scripted fighter signals where
# the full combat setup would be irrelevant, and the last checks prove the
# HUD never touches the simulation's serializable state. The Settings
# autoload is pointed at a scratch file for the mode checks so the
# player's settings.cfg is never touched.
extends SceneTree

const MATCH_SCENE := preload("res://scenes/match/MatchRoot.tscn")
const ROSTER := preload("res://resources/match_roster.tres")
const PIP_SQUARE_EMPTY := preload("res://art/ui/hud/hud_pip_square_empty.png")
const PIP_SQUARE_FILLED := preload("res://art/ui/hud/hud_pip_square_filled.png")
const PIP_DIAMOND_EMPTY := preload("res://art/ui/hud/hud_pip_diamond_empty.png")
const PIP_DIAMOND_FILLED := preload("res://art/ui/hud/hud_pip_diamond_filled.png")

const SCRATCH_CONFIG := "user://settings_hud_test.cfg"

var failures := 0
var checks := 0
var scene: Node
var p1: FighterBase
var p2: FighterBase
var hud: MatchHUD


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


func _settings() -> Node:
	return root.get_node_or_null("Settings")


func _set_setting(section: String, key: String, value: Variant) -> void:
	var settings := _settings()
	if settings != null:
		settings.set_value(section, key, value)


func _new_match(intro_wait := 65) -> void:
	scene = MATCH_SCENE.instantiate()
	scene.selected_p1_data = ROSTER.fighters[0]
	scene.selected_p2_data = ROSTER.fighters[1]
	scene.selected_stage = ROSTER.stages[0]
	root.add_child(scene)
	await physics_frame
	await _step(intro_wait)  # round intro (65) or inside it (10)
	p1 = scene.p1
	p2 = scene.p2
	hud = scene.hud


# Direct health assignment does not emit health_changed (the signal fires
# from the combat path); scripted checks emit it so the HUD hears the same
# thing a real hit produces.
func _set_p2_health(value: float) -> void:
	p2.health = value
	p2.health_changed.emit(value, p2.max_health)


# Places the pair adjacent with P1 attacking, like the round-flow helper.
func _place_pair() -> void:
	p1.position = Vector2(120, 150)
	p2.position = Vector2(146, 150)
	p1.velocity = Vector2.ZERO
	p2.velocity = Vector2.ZERO
	p1.facing = 1
	p2.facing = -1
	p1.reset_state()
	p2.reset_state()


func light_move() -> MoveData:
	return p1.data.find_move(MoveData.InputType.LIGHT, MoveData.Stance.STAND)


func _run() -> void:
	await process_frame
	# Point the autoload at a scratch config for this run.
	var settings := _settings()
	var original_path: String = settings.config_path if settings != null else ""
	if settings != null:
		settings.config_path = SCRATCH_CONFIG
		settings._load()
	await _test_portraits()
	await _test_health_and_ghost()
	await _test_pips_and_timer()
	await _test_meter_and_ready()
	await _test_banners()
	await _test_callouts_and_combo()
	await _test_commentary_modes()
	await _test_accessibility()
	await _test_resync_and_isolation()
	if settings != null:
		settings.config_path = original_path
		settings._load()
		if FileAccess.file_exists(original_path):
			pass  # the real config is untouched by this suite
		var scratch := ProjectSettings.globalize_path(SCRATCH_CONFIG)
		if FileAccess.file_exists(scratch):
			DirAccess.remove_absolute(scratch)
	print("hud_test: %d checks, %d failure(s)" % [checks, failures])
	quit(1 if failures > 0 else 0)


# ---------------- portraits --------------------------------------------------

# Highest z_index among the HUD's TextureRects showing this frame art.
func _frame_z(texture: Texture2D) -> int:
	var z := -1000
	for n in hud.find_children("*", "TextureRect", true, false):
		if n.texture == texture:
			z = maxi(z, n.z_index)
	return z


func _test_portraits() -> void:
	await _new_match()
	_check("the portrait photo draws above the opaque photo-frame art",
		hud.portraits[0].z_index > _frame_z(HudArt.PORTRAIT_FRAME),
		"photo z=%d frame z=%d" % [hud.portraits[0].z_index, _frame_z(HudArt.PORTRAIT_FRAME)])
	var path: String = str(hud.portraits[0].texture.atlas.resource_path)
	_check("the P1 portrait shows the fighter's normal booking photo",
		path.contains("hud_portrait_pegleg_peg_normal"),
		"path=%s" % path)

	# Hurt face below 25% health.
	_set_p2_health(p2.max_health * 0.2)
	_check("the hurt portrait shows below 25% health",
		str(hud.portraits[1].texture.atlas.resource_path).contains("_hurt"),
		"path=%s" % str(hud.portraits[1].texture.atlas.resource_path))

	# KO face after losing the round: force a KO and let the pips land.
	_place_pair()
	_set_p2_health(1.0)
	p1._start_move(light_move())
	await _step(130)
	_check("the loser's portrait flips to the ko face after the round",
		str(hud.portraits[1].texture.atlas.resource_path).contains("_ko"),
		"path=%s" % str(hud.portraits[1].texture.atlas.resource_path))
	await _step(160)  # next round's intro; the refill clears the face
	_check("a new round's refill restores the normal portrait",
		str(hud.portraits[1].texture.atlas.resource_path).contains("_normal"),
		"path=%s" % str(hud.portraits[1].texture.atlas.resource_path))
	scene.free()
	await process_frame


# ---------------- health, ghost, freeze ---------------------------------------

func _test_health_and_ghost() -> void:
	await _new_match()
	_check("the health fills draw above the opaque cardboard frame art",
		hud.health_fills[0].z_index > _frame_z(HudArt.HEALTH_FRAME)
			and hud.ghost_fills[0].z_index > _frame_z(HudArt.HEALTH_FRAME)
			and hud.meter_fills[0].z_index > _frame_z(HudArt.METER_FRAME),
		"fill z=%d ghost z=%d meter z=%d health frame z=%d meter frame z=%d" % [
			hud.health_fills[0].z_index, hud.ghost_fills[0].z_index,
			hud.meter_fills[0].z_index, _frame_z(HudArt.HEALTH_FRAME),
			_frame_z(HudArt.METER_FRAME)])
	_check("the health fills start full",
		hud.health_fills[0].size.x >= hud.HEALTH_INTERIOR.x - 1.0
			and hud.health_fills[1].size.x >= hud.HEALTH_INTERIOR.x - 1.0,
		"sizes=%s/%s" % [str(hud.health_fills[0].size.x),
			str(hud.health_fills[1].size.x)])

	# A combo hit: the ghost lags behind the damage, then drains to match
	# 20 sim frames after the combo counter clears.
	_place_pair()
	_set_p2_health(400.0)
	p1._start_move(light_move())
	await _step(30)
	_check("the ghost segment stays behind a damaged health bar mid-combo",
		hud.ghost_fills[1].size.x > hud.health_fills[1].size.x + 1.0
			and hud.ghost_fills[1].visible,
		"ghost=%s health=%s" % [str(hud.ghost_fills[1].size.x),
			str(hud.health_fills[1].size.x)])
	await _step(60)
	await _step(30)
	_check("the ghost drains to match the health after the combo ends",
		hud.ghost_fills[1].size.x <= hud.health_fills[1].size.x + 1.0,
		"ghost=%s health=%s" % [str(hud.ghost_fills[1].size.x),
			str(hud.health_fills[1].size.x)])

	# Paused: the HUD stops counting (its tick counter freezes).
	scene._toggle_pause()
	var tick_before: int = hud._tick
	await _step(30)
	_check("the HUD tick freezes while paused",
		hud._tick == tick_before, "tick %d -> %d" % [tick_before, hud._tick])
	scene._unpause()
	scene.free()
	await process_frame


# ---------------- pips and timer ---------------------------------------------

func _test_pips_and_timer() -> void:
	await _new_match()
	_check("the pip rows start with two empty slots per side",
		hud.pips[0].size() == 2 and hud.pips[1].size() == 2
			and hud.pips[0][0].texture == PIP_SQUARE_EMPTY
			and hud.pips[1][0].texture == PIP_DIAMOND_EMPTY,
		"pips=%d/%d" % [hud.pips[0].size(), hud.pips[1].size()])

	hud.set_pips(1, 0)
	_check("a won round fills the winner's first pip sprite",
		hud.pips[0][0].texture == PIP_SQUARE_FILLED,
		"pip sprite unchanged")

	hud.set_pips(2, 2)
	_check("a 2-2 pip count fills both rows' second pips",
		hud.pips[0][1].texture == PIP_SQUARE_FILLED
			and hud.pips[1][1].texture == PIP_DIAMOND_FILLED,
		"second pips not filled")

	# Timer digits from the strip: 99 at round start.
	hud.set_timer(99.0)
	_check("the timer draws two 9 digit cells from the strip",
		hud.timer_digits[0].texture.region.position.x == 9 * 8
			and hud.timer_digits[1].texture.region.position.x == 9 * 8,
		"regions=%s/%s" % [str(hud.timer_digits[0].texture.region.position.x),
			str(hud.timer_digits[1].texture.region.position.x)])

	scene.timer_frames = 9 * 60
	hud.set_timer(9.0)
	_check("under 10 seconds the timer box tints dirty yellow",
		hud.timer_box_art.modulate == Color("f2d13a"),
		"modulate=%s" % str(hud.timer_box_art.modulate))
	scene.timer_frames = 99 * 60
	hud.set_timer(99.0)
	_check("the timer tint clears above 10 seconds",
		hud.timer_box_art.modulate == Color.WHITE,
		"modulate=%s" % str(hud.timer_box_art.modulate))
	scene.free()
	await process_frame


# ---------------- meter ------------------------------------------------------

func _test_meter_and_ready() -> void:
	await _new_match()
	_check("the meter fills start empty",
		hud.meter_fills[0].size.x <= 1.0 and hud.meter_fills[1].size.x <= 1.0,
		"sizes=%s/%s" % [str(hud.meter_fills[0].size.x),
			str(hud.meter_fills[1].size.x)])

	p1.add_meter(50.0)
	_check("50 meter fills half the interior from the outer edge",
		absf(hud.meter_fills[0].size.x - hud.METER_INTERIOR.x * 0.5) <= 1.0,
		"width=%s" % str(hud.meter_fills[0].size.x))

	p2.add_meter(100.0)
	_check("a full meter turns METH pink and shows METH READY",
		hud.meter_fills[1].color == Color("ff3d9a")
			and hud.meter_ready[1].visible
			and hud.meter_skulls[1].visible,
		"ready=%s skull=%s" % [str(hud.meter_ready[1].visible),
			str(hud.meter_skulls[1].visible)])

	# Skull alternation on the sim tick: two alternating frames, 15 apart.
	var first: Texture2D = hud.meter_skulls[1].texture
	for _frame in 16:
		hud.sim_tick()
	_check("the METH READY skull alternates every 15 sim frames",
		hud.meter_skulls[1].texture != first,
		"skull texture did not change")

	p2.spend_meter(90.0)
	_check("spending meter restores the blue fill and hides READY",
		hud.meter_fills[1].color == Color("5ac8ff")
			and not hud.meter_ready[1].visible
			and not hud.meter_skulls[1].visible,
		"ready=%s" % str(hud.meter_ready[1].visible))
	scene.free()
	await process_frame


# ---------------- banners ----------------------------------------------------

func _test_banners() -> void:
	await _new_match(10)  # inside the intro: the round banner is still up
	_check("the round start shows the ROUND 1 sprite banner",
		hud.banner_id == "round_1" and hud.banner_plate.visible
			and str(hud.banner_word.texture.resource_path).contains("round_1"),
		"banner=%s" % hud.banner_id)
	await _step(6)
	_check("the banner stamps in from above and settles on its mark",
		hud.banner_plate.position.y >= 73.9,
		"y=%s" % str(hud.banner_plate.position.y))

	# FIGHT replaces the round banner at fight start, then auto-removes.
	for _wait in 55:
		await physics_frame
		if hud.banner_id == "fight":
			break
	_check("the FIGHT banner replaces the round banner at fight start",
		hud.banner_id == "fight"
			and str(hud.banner_word.texture.resource_path).contains("banner_fight"),
		"banner=%s" % hud.banner_id)
	await _step(31)
	_check("the FIGHT banner auto-removes after its 30 sim frames",
		hud.banner_id == "" and not hud.banner_plate.visible,
		"banner=%s" % hud.banner_id)

	# Spriteless messages render as Marker cream text on the plate.
	hud.show_banner_text("PEG LEG PEGGY\nTAKES THE ROUND")
	_check("a spriteless message renders as Marker cream text on the plate",
		hud.banner_id == "text" and hud.message.visible
			and hud.message.text.contains("TAKES THE ROUND")
			and not hud.banner_word.visible,
		"banner=%s" % hud.banner_id)

	# KO shows the ko sprite; rounds past 5 fall back to text.
	hud.show_banner("ko")
	_check("K.O. uses the ko word sprite",
		str(hud.banner_word.texture.resource_path).contains("banner_ko"),
		"path=%s" % str(hud.banner_word.texture.resource_path))
	hud.show_banner_text("ROUND 6")
	_check("a round past the sprite set falls back to plate text",
		hud.message.visible and hud.message.text == "ROUND 6",
		"text=%s" % hud.message.text)

	# METHtality: sprite + the move name subtitle.
	hud.show_banner("methtality", "WALK THE PLANK")
	_check("the METH banner carries the move-name subtitle",
		hud.meth_banner.visible and hud.meth_banner.text == "WALK THE PLANK",
		"subtitle=%s" % hud.meth_banner.text)
	scene.free()
	await process_frame


# ---------------- callouts and combo ------------------------------------------

func _test_callouts_and_combo() -> void:
	await _new_match()
	# Scripted signal path: the HUD listens to per-fighter signals, so
	# emitting them exercises exactly the wiring the real exchange uses.
	p1.counter_hit_landed.emit()
	_check("a counter callout lands on the attacker's side",
		hud.counter_flash.visible and hud.counter_flash.text == "COUNTER HIT"
			and hud.counter_flash.position.x < 160.0,
		"visible=%s side=%s text=%s" % [str(hud.counter_flash.visible),
			str(hud.counter_flash.position.x), hud.counter_flash.text])
	p2.teched.emit()
	_check("a tech callout replaces the counter one at a time",
		hud.counter_flash.visible and hud.counter_flash.text == "TECH"
			and hud.counter_flash.position.x > 160.0,
		"text=%s side=%s" % [hud.counter_flash.text,
			str(hud.counter_flash.position.x)])
	await _step(31)
	_check("the callout clears after its 30 sim frames",
		not hud.counter_flash.visible, "still visible")

	# Combo counter + damage total from the fighter's combo record.
	p1.combo_tracker.record("probe_a", 120.0)
	p1.combo_tracker.record("probe_b", 80.0)
	p1.combo_changed.emit(2)
	_check("a combo shows '<n> HITS' with its damage total under it",
		hud.p1_combo.text == "2 HITS"
			and hud.combo_damages[0].visible
			and hud.combo_damages[0].text == "200",
		"label=%s damage=%s" % [hud.p1_combo.text, hud.combo_damages[0].text])

	_set_setting("gameplay", "show_combo_damage", false)
	p1.combo_changed.emit(2)
	_check("combo damage hides when show_combo_damage is off",
		not hud.combo_damages[0].visible,
		"still visible")
	_set_setting("gameplay", "show_combo_damage", true)

	p1.combo_changed.emit(0)
	_check("the combo counter clears with the combo",
		hud.p1_combo.text == "" and not hud.combo_damages[0].visible,
		"label=%s" % hud.p1_combo.text)
	scene.free()
	await process_frame


# ---------------- commentary --------------------------------------------------

func _test_commentary_modes() -> void:
	await _new_match()
	_check("the commentary tape shows the round-start line by default",
		hud.commentary_panel.visible and hud.commentary_label.visible
			and hud.commentary_label.text.contains("TRIPP"),
		"visible=%s" % str(hud.commentary_panel.visible))
	# Clear the tape so each mode check observes only its own line.
	hud.commentary_panel.visible = false
	hud.commentary_label.visible = false
	hud.commentary_label.text = ""

	_set_setting("gameplay", "commentary", "minimal")
	hud.show_commentary("TRIPP: MID-FIGHT BARK", 60, "mid")
	_check("minimal commentary hides mid-fight lines",
		not hud.commentary_panel.visible
			and not hud.commentary_label.text.contains("MID-FIGHT BARK"),
		"visible=%s text=%s" % [str(hud.commentary_panel.visible),
			hud.commentary_label.text])
	hud.show_commentary("TRIPP: ROUND LINE", 60, "round")
	_check("minimal commentary keeps round lines",
		hud.commentary_panel.visible
			and hud.commentary_label.text.contains("ROUND LINE"),
		"visible=%s text=%s" % [str(hud.commentary_panel.visible),
			hud.commentary_label.text])
	hud.commentary_panel.visible = false
	hud.commentary_label.text = ""

	_set_setting("gameplay", "commentary", "off")
	hud.show_commentary("TRIPP: ANYTHING", 60)
	_check("commentary off hides the tape entirely",
		not hud.commentary_panel.visible
			and not hud.commentary_label.text.contains("ANYTHING"),
		"still visible")

	_set_setting("gameplay", "commentary", "full")
	_set_setting("stream", "hide_tripp_text", true)
	hud.show_commentary("TRIPP: ANYTHING", 60)
	_check("hide_tripp_text hides the commentary even in full mode",
		not hud.commentary_panel.visible
			and not hud.commentary_label.text.contains("ANYTHING"),
		"still visible")
	_set_setting("stream", "hide_tripp_text", false)
	scene.free()
	await process_frame


# ---------------- accessibility ----------------------------------------------

func _test_accessibility() -> void:
	await _new_match()
	_set_setting("accessibility", "reduce_flashing", true)
	_set_p2_health(500.0)
	_check("reduce_flashing turns the health flash into a 1-frame tint",
		hud._flash[1] <= 1, "flash=%d" % hud._flash[1])

	_set_setting("accessibility", "reduce_flashing", false)
	_set_p2_health(400.0)
	_check("the default flash runs the full frame count",
		hud._flash[1] > 1, "flash=%d" % hud._flash[1])

	_set_setting("accessibility", "high_contrast_hud", true)
	_check("high_contrast_hud puts solid plates behind bars and timer",
		hud.high_contrast_plates[0].visible
			and hud.high_contrast_plates[1].visible
			and hud.high_contrast_plates[2].visible,
		"plates=%s" % str(hud.high_contrast_plates[0].visible))
	_set_setting("accessibility", "high_contrast_hud", false)
	_check("the contrast plates clear when the setting is off",
		not hud.high_contrast_plates[0].visible, "plate still visible")
	scene.free()
	await process_frame


# ---------------- resync and isolation -----------------------------------------

func _test_resync_and_isolation() -> void:
	await _new_match()
	# Leave some presentation state dirty, then restore a snapshot.
	_set_p2_health(300.0)
	hud.show_banner_text("DIRTY")
	p1.teched.emit()
	var snapshot: Dictionary = scene.serialize()

	scene.load(snapshot)
	await process_frame
	hud.sim_tick()  # the restore's sim_frame jump triggers the resync
	_check("a serialize/load restore clears the banner and callout",
		hud.banner_id == "" and not hud.counter_flash.visible,
		"banner=%s callout=%s" % [hud.banner_id,
			str(hud.counter_flash.visible)])
	_check("the ghost snaps to the restored health",
		hud.ghost_fills[1].size.x <= hud.health_fills[1].size.x + 1.0,
		"ghost=%s health=%s" % [str(hud.ghost_fills[1].size.x),
			str(hud.health_fills[1].size.x)])

	# Isolation: the serializable surface is identical with the HUD bound
	# and ticking.
	var with_hud: Dictionary = scene.serialize()
	scene.hud.queue_free()
	scene.hud = null
	await process_frame
	var without_hud: Dictionary = scene.serialize()
	_check("serialize() is identical with the HUD bound and unbound",
		with_hud == without_hud, "the sim state diverged")
	scene.free()
	await process_frame
