# MatchHUD — the street-junk match HUD, reskinned in UI Phase 2
# (docs/UI_SCREENS.md "The match HUD"). All art comes from the approved
# set in game/art/ui/hud/ and stream/; every timer counts SIM frames
# through MatchRoot's presentation-only hud.sim_tick() hook, so the HUD
# freezes with pause and hitstop and replays identically; and the stored
# HUD settings are consumed live (commentary mode, combo damage,
# reduce-flashing, high-contrast, hide-Tripp-text). The HUD only reads
# match/fighter state and signals — it never writes them, and it holds no
# state MatchRoot.serialize() needs.
#
# Public node names kept from the text HUD for the existing pins:
# `message` (text banners on the plate), `meth_banner` (the METHtality
# subtitle), `counter_flash` (the callout), `commentary_panel` /
# `commentary_label`, and the whole pause menu.
class_name MatchHUD
extends CanvasLayer

const PAUSE_OPTIONS := ["RESUME", "SETTINGS", "RESTART MATCH",
	"CHARACTER SELECT", "MAIN MENU", "QUIT TO DESKTOP"]
const UI_THEME := preload("res://resources/ui_theme.tres")

# ---- palette (docs/UI_HUD_SCREENS_PLAN.md, tightened) --------------------
const P1_HEALTH := Color("f29e26")
const P2_HEALTH := Color("e5473a")
const GHOST := Color("ff6b5a")
const METER_FILL := Color("5ac8ff")
const METH_PINK := Color("ff3d9a")
const DIRTY_YELLOW := Color("f2d13a")
const CREAM := Color("F4EEDC")
const INK_DARK := Color("1C160D")
const INK_WARM := Color("2A2418")
const COMBO_YELLOW := Color("f2d13a")
const COMBO_ORANGE := Color("f29e26")
const COMBO_RED := Color("e5473a")

# ---- layout (320x180 game pixels; P2 mirrors P1) ---------------------------
const PORTRAIT_POS := [Vector2(4, 4), Vector2(292, 4)]
const PORTRAIT_INNER := Vector2(16, 15)
# The taped photo's dark window inside the 24x24 frame, and the crop of the
# 22x22 portrait shown through it (head and shoulders). The frame art is
# opaque, so the photo draws ABOVE it (PM review of PR #92).
const PORTRAIT_WINDOW := Vector2(4, 3)
const PORTRAIT_CROP := Rect2(3, 1, 16, 15)
const HEALTH_POS := [Vector2(30, 8), Vector2(172, 8)]
# The cardboard strip between the tape caps; the strip is opaque, so fills
# draw ABOVE the frame art (PM review of PR #92).
const HEALTH_FILL_OFFSET := Vector2(10, 2)
const HEALTH_INTERIOR := Vector2(98, 6)
const NAME_Y := 19.0
const PIP_Y := 31.0
const PIP_GAP := 7.0
const TIMER_POS := Vector2(148, 3)
const TIMER_BOX_SIZE := Vector2(24, 20)
const METER_POS := [Vector2(4, 170), Vector2(210, 170)]
const METER_FILL_OFFSET := Vector2(7, 2)
const METER_INTERIOR := Vector2(90, 4)
const COMBO_POS := [Vector2(8, 64), Vector2(202, 64)]
const COMBO_DAMAGE_Y := 77.0
const COMBO_SCALE_POS := [Vector2(56, 77), Vector2(212, 77)]
const CALLOUT_Y := 80.0
const CALLOUT_X := [60.0, 200.0]  # attacker's side, outside the banner text
const BANNER_POS := Vector2(80, 74)  # 160x32 plate centered in y 70..110
const COMMENTARY_POS := Vector2(40, 44)
const COMMENTARY_SIZE := Vector2(240, 16)
const MACRO_FLASH_Y := 92.0
const JUGGLE_PIP_Y := 106.0
const JUGGLE_PIP_SIZE := 3.0
const JUGGLE_PIP_PITCH := 5.0
const STUN_LABEL_Y := 36.0
const STUN_BAR_X := [80.0, 180.0]
const STUN_BAR_Y := 40.0
const STUN_BAR_WIDTH := 62.0
const STUN_BAR_INNER_WIDTH := 60.0
const BREAKER_PIP_POS := [Vector2(4, 163), Vector2(311, 163)]
const BREAKER_LABEL_POS := [Vector2(12, 152), Vector2(273, 152)]
const BREAKER_LABEL_SIZE := Vector2(36, UiText.M5X7_LINE_HEIGHT)

# ---- timing (all SIM frames, counted in sim_tick) --------------------------
const GHOST_DRAIN_FRAMES := 20
const CALLOUT_FRAMES := 30
const COMMENTARY_FRAMES := 180
const FIGHT_BANNER_FRAMES := 30
const METH_BANNER_FRAMES := 120
const FLASH_FRAMES := 12
const PULSE_STEP := 15  # gentle low-health pulse, one shade per step
const SKULL_STEP := 15   # METH READY skull alternation
# Banner stamp-in: 6 sim frames, integer per-frame offsets from 8 px above
# down to the resting mark.
const STAMP_OFFSETS := [8, 6, 4, 2, 1, 0]

# Per-side state (index 0 = P1, 1 = P2).
var _health: Array[float] = [1000.0, 1000.0]
var _max_health: Array[float] = [1000.0, 1000.0]
var _ghost: Array[float] = [1000.0, 1000.0]
var _ghost_drain: Array[int] = [0, 0]
var _ghost_step: Array[float] = [0.0, 0.0]
# Combo state is indexed by attacker-side HUD position. The tracker itself
# belongs to the defender, so its side is inverted when rendered.
var _combo_hits_by_side: Array[int] = [0, 0]
var _combo_damage_by_side: Array[float] = [0.0, 0.0]
var _combo_active: Array[bool] = [false, false]  # defender-side health ghosts
var _flash: Array[int] = [0, 0]
var _round_lost: Array[bool] = [false, false]
var _last_wins: Array[int] = [0, 0]

# Sim-tick state.
var _tick := 0
var _last_sim_frame := -1
var banner_id := ""
var _banner_stamp := 0
var _banner_auto := -1  # frames until auto-remove; -1 = persist (today's
# round/KO banner behavior: they sit until the next banner replaces them)
var _callout_frames := 0
var _callout_side := -1
var _macro_flash_frames := 0
var _macro_flash_side := -1
var _commentary_frames := 0
var _settings_cache: Node
var _match_root: Node

# Nodes.
var portraits: Array[TextureRect] = []
var health_fills: Array[ColorRect] = []
var ghost_fills: Array[ColorRect] = []
var pips: Array = []  # per side: Array[TextureRect]
var meter_fills: Array[ColorRect] = []
var meter_ready: Array[Label] = []
var meter_skulls: Array[TextureRect] = []
var p1_name: Label
var p2_name: Label
var timer_digits: Array[TextureRect] = []
var timer_box_art: TextureRect
var p1_combo: Label
var p2_combo: Label
var combo_damages: Array[Label] = []
var combo_scales: Array[Label] = []
var macro_flash_labels: Array[Label] = []
var juggle_pip_outlines: Array = [[], []]
var juggle_pip_fills: Array = [[], []]
var stun_labels: Array[Label] = []
var stun_bar_borders: Array[ColorRect] = []
var stun_bar_backgrounds: Array[ColorRect] = []
var stun_bar_fills: Array[ColorRect] = []
var breaker_pip_borders: Array[ColorRect] = []
var breaker_pip_centers: Array[ColorRect] = []
var breaker_pip_states: Array[String] = ["unavailable", "unavailable"]
var commentary_panel: TextureRect
var commentary_label: Label
var message: Label
var meth_banner: Label
var counter_flash: Label
var banner_plate: TextureRect
var banner_word: TextureRect
var hud_root: Control
var readout_root: Control
var pause_root: Control
var pause_options: Array[Label] = []
var pause_bars: Array[ColorRect] = []
var high_contrast_plates: Array[ColorRect] = []


func _ready() -> void:
	_build()
	_apply_accessibility_settings()
	var settings := _settings()
	if settings != null and settings.has_signal("changed"):
		settings.changed.connect(_on_settings_changed)


func _on_settings_changed(_section: String, _key: String) -> void:
	_apply_accessibility_settings()
	for side in 2:
		_update_combo_visibility(side)


func _apply_accessibility_settings() -> void:
	apply_high_contrast(
		bool(_setting("accessibility", "high_contrast_hud", false)))


# ---------------- construction ----------------------------------------------

func _build() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	hud_root = root

	# Solid plates for the high-contrast setting, hidden by default.
	for plate_rect in [Rect2(28, 6, 122, 26), Rect2(170, 6, 122, 26),
			Rect2(146, 1, 28, 24)]:
		var plate := _rect(root, plate_rect.position, plate_rect.size, INK_DARK)
		plate.visible = false
		high_contrast_plates.append(plate)

	# Portraits: taped-photo frames, the 22x22 booking photo inside.
	for side in 2:
		var frame := _art(root, HudArt.PORTRAIT_FRAME,
			PORTRAIT_POS[side], Vector2(24, 24))
		frame.z_index = 2
		var photo := _art(root, null,
			PORTRAIT_POS[side] + PORTRAIT_WINDOW, PORTRAIT_INNER)
		photo.z_index = 3
		portraits.append(photo)

	# Health: frame art over a code-drawn fill, ghost segment behind it
	# draining toward the timer (P2 mirrors).
	for side in 2:
		var frame := _art(root, HudArt.HEALTH_FRAME,
			HEALTH_POS[side], Vector2(118, 10))
		frame.z_index = 3
		var ghost := _rect(root, HEALTH_POS[side] + HEALTH_FILL_OFFSET,
			Vector2(0, HEALTH_INTERIOR.y), GHOST)
		ghost.z_index = 4
		ghost_fills.append(ghost)
		var fill := _rect(root, HEALTH_POS[side] + HEALTH_FILL_OFFSET,
			Vector2(HEALTH_INTERIOR.x, HEALTH_INTERIOR.y),
			P1_HEALTH if side == 0 else P2_HEALTH)
		fill.z_index = 5
		health_fills.append(fill)

	# Names in outlined Marker cream under each bar.
	p1_name = UiText.marker("", Vector2(30, NAME_Y), CREAM, true)
	p1_name.size = Vector2(140, UiText.MARKER_LINE_HEIGHT)
	root.add_child(p1_name)
	p2_name = UiText.marker("", Vector2(150, NAME_Y), CREAM, true)
	p2_name.size = Vector2(140, UiText.MARKER_LINE_HEIGHT)
	p2_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	root.add_child(p2_name)

	# Round pips: P1 squares from the bar's outer (left) end, P2 diamonds
	# from the right end. TODO(docs/UI_SCREENS.md): win-type letters
	# (K/T/M/D) need a per-round win-type history MatchRoot does not keep.
	pips = [[], []]
	for side in 2:
		for i in 2:
			_append_pip(root, side, i)

	# Timer: box art with two 8x12 digit cells centered inside.
	timer_box_art = _art(root, HudArt.TIMER_BOX, TIMER_POS, TIMER_BOX_SIZE)
	for i in 2:
		var digit := _art(root, HudArt.digit_texture(9),
			TIMER_POS + Vector2(4 + i * 8.0, 4), Vector2(8, 12))
		timer_digits.append(digit)

	# Meter: frame art over a code-drawn fill with 25/50 tick marks; at
	# full the fill turns METH pink, METH READY rides beside the bar and
	# the two skull frames alternate.
	for side in 2:
		var frame := _art(root, HudArt.METER_FRAME,
			METER_POS[side], Vector2(106, 8))
		frame.z_index = 3
		var fill := _rect(root, METER_POS[side] + METER_FILL_OFFSET,
			Vector2(0, METER_INTERIOR.y), METER_FILL)
		fill.z_index = 5
		meter_fills.append(fill)
		# Tick marks at 25 (Clip Cancel) and 50 (EX) of 100.
		for fraction in [roundi(METER_INTERIOR.x * 0.25), roundi(METER_INTERIOR.x * 0.5)]:
			var mark_x: float = METER_POS[side].x + METER_FILL_OFFSET.x
			if side == 1:
				mark_x += METER_INTERIOR.x - fraction
			else:
				mark_x += fraction - 1.0
			var mark := _rect(root, Vector2(mark_x, METER_POS[side].y + METER_FILL_OFFSET.y),
				Vector2(1, METER_INTERIOR.y), INK_DARK)
			mark.z_index = 6
		var ready := UiText.marker("METH READY",
			Vector2(114 if side == 0 else 128, 168), METH_PINK, true)
		if side == 1:
			ready.size = Vector2(78, UiText.MARKER_LINE_HEIGHT)
			ready.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		else:
			ready.size = Vector2(78, UiText.MARKER_LINE_HEIGHT)
		ready.visible = false
		root.add_child(ready)
		meter_ready.append(ready)
		var skull := _art(root, HudArt.SKULL_F1,
			Vector2(0, 170.0), Vector2(8, 8))
		skull.visible = false
		meter_skulls.append(skull)

	# Combo counter (today's position and logic), restyled: "<n> HITS" in
	# outlined Marker yellow, combo damage under it in m5x7 cream only
	# while the setting is on.
	p1_combo = UiText.marker("", Vector2(COMBO_POS[0].x, 64), COMBO_YELLOW, true)
	p1_combo.size = Vector2(110, UiText.MARKER_LINE_HEIGHT)
	root.add_child(p1_combo)
	p2_combo = UiText.marker("", Vector2(COMBO_POS[1].x, 64), COMBO_YELLOW, true)
	p2_combo.size = Vector2(110, UiText.MARKER_LINE_HEIGHT)
	p2_combo.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	root.add_child(p2_combo)
	var p1_damage := UiText.body("", Vector2(8, COMBO_DAMAGE_Y), CREAM)
	p1_damage.size = Vector2(48, UiText.M5X7_LINE_HEIGHT)
	root.add_child(p1_damage)
	combo_damages.append(p1_damage)
	var p2_damage := UiText.body("", Vector2(264, COMBO_DAMAGE_Y), CREAM)
	p2_damage.size = Vector2(48, UiText.M5X7_LINE_HEIGHT)
	p2_damage.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	root.add_child(p2_damage)
	combo_damages.append(p2_damage)

	# Tripp commentary: the stream tape with dark-ink m5x7 text on it.
	commentary_panel = _art(root, HudArt.COMMENTARY_BOX,
		COMMENTARY_POS, COMMENTARY_SIZE)
	commentary_panel.visible = false
	commentary_label = UiText.body("", Vector2(46, 46), UiText.INK)
	commentary_label.size = Vector2(228, 13)
	root.add_child(commentary_label)

	# Callouts: one at a time, on the attacker's side. Kept under the
	# historical member name for the existing pins.
	counter_flash = UiText.marker("COUNTER HIT",
		Vector2(CALLOUT_X[0], CALLOUT_Y), CREAM, true)
	counter_flash.size = Vector2(120, UiText.MARKER_LINE_HEIGHT)
	counter_flash.visible = false
	root.add_child(counter_flash)

	# Banner: the 160x32 plate with a word sprite (or Marker cream text
	# when the message has no sprite) stamping in over 6 sim frames. The
	# word/text/subtitle are plate children, so the stamp moves the plate
	# alone.
	banner_plate = _art(root, HudArt.BANNER_PLATE, BANNER_POS, Vector2(160, 32))
	banner_plate.visible = false
	banner_word = _art(banner_plate, null, Vector2(0, 0), Vector2(1, 1))
	banner_word.visible = false
	message = UiText.marker("", Vector2(0, 5), CREAM, true)
	message.size = Vector2(160, 22)
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.visible = false
	banner_plate.add_child(message)
	meth_banner = UiText.marker("", Vector2(0, 19), CREAM, true)
	meth_banner.size = Vector2(160, 12)
	meth_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	meth_banner.visible = false
	banner_plate.add_child(meth_banner)

	_build_combo_readouts(root)
	_build_pause_menu(root)


func _append_pip(root: Control, side: int, index: int) -> TextureRect:
	var pip := TextureRect.new()
	pip.texture = HudArt.PIP_SQUARE_EMPTY if side == 0 else HudArt.PIP_DIAMOND_EMPTY
	var x: float = HEALTH_POS[side].x + index * PIP_GAP
	if side == 1:
		x = HEALTH_POS[side].x + 118.0 - 5.0 - index * PIP_GAP
	pip.position = Vector2(x, PIP_Y)
	pip.size = Vector2(5, 5)
	pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pip.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	root.add_child(pip)
	pips[side].append(pip)
	return pip


func _build_combo_readouts(root: Control) -> void:
	# One presentation-only layer keeps every new readout above the opaque HUD
	# art it may touch. The pause root is added after this layer and stays above
	# it.
	readout_root = Control.new()
	readout_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	readout_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	readout_root.z_index = 4
	root.add_child(readout_root)

	for side in 2:
		var scale_label := UiText.body("", COMBO_SCALE_POS[side], CREAM)
		scale_label.size = Vector2(52, UiText.M5X7_LINE_HEIGHT)
		if side == 1:
			scale_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		scale_label.visible = false
		readout_root.add_child(scale_label)
		combo_scales.append(scale_label)

		var macro_label := UiText.marker("", Vector2(COMBO_POS[side].x,
			MACRO_FLASH_Y), CREAM, true)
		macro_label.size = Vector2(110, UiText.MARKER_LINE_HEIGHT)
		if side == 1:
			macro_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		macro_label.visible = false
		readout_root.add_child(macro_label)
		macro_flash_labels.append(macro_label)

		# The actual text ink lands at y38-46; the bar is beside it on the same
		# row, just clear of the commentary tape's ink band.
		var stun_label := UiText.marker("STUNNED",
			Vector2(30 if side == 0 else 240, STUN_LABEL_Y),
			METH_PINK, true)
		stun_label.size = Vector2(50, UiText.MARKER_LINE_HEIGHT)
		if side == 1:
			stun_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		stun_label.visible = false
		readout_root.add_child(stun_label)
		stun_labels.append(stun_label)

		var bar_x: float = STUN_BAR_X[side]
		var bar_border := _rect(readout_root,
			Vector2(bar_x, STUN_BAR_Y), Vector2(STUN_BAR_WIDTH, 4), INK_DARK)
		bar_border.visible = false
		stun_bar_borders.append(bar_border)
		var bar_background := _rect(readout_root,
			Vector2(bar_x + 1, STUN_BAR_Y + 1),
			Vector2(STUN_BAR_INNER_WIDTH, 2), INK_WARM)
		bar_background.visible = false
		stun_bar_backgrounds.append(bar_background)
		var bar_fill := _rect(readout_root,
			Vector2(bar_x + 1, STUN_BAR_Y + 1),
			Vector2(STUN_BAR_INNER_WIDTH, 2), METH_PINK)
		bar_fill.visible = false
		stun_bar_fills.append(bar_fill)

		var breaker_border := _rect(readout_root,
			BREAKER_PIP_POS[side], Vector2(5, 5), INK_DARK)
		breaker_pip_borders.append(breaker_border)
		var breaker_center := _rect(readout_root,
			BREAKER_PIP_POS[side] + Vector2.ONE, Vector2(3, 3), Color.TRANSPARENT)
		breaker_pip_centers.append(breaker_center)

		var breaker_label := UiText.body("BRK", BREAKER_LABEL_POS[side], CREAM)
		breaker_label.size = BREAKER_LABEL_SIZE
		if side == 1:
			breaker_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		readout_root.add_child(breaker_label)


func _ensure_juggle_pips(attacker_side: int, count: int) -> void:
	var pip_list: Array = juggle_pip_outlines[attacker_side]
	var fill_list: Array = juggle_pip_fills[attacker_side]
	var total_width := count * int(JUGGLE_PIP_PITCH) - 2
	var start_x: float = COMBO_POS[0].x if attacker_side == 0 \
		else COMBO_POS[1].x + 110.0 - total_width
	while pip_list.size() < count:
		var index := pip_list.size()
		var at := Vector2(start_x + index * JUGGLE_PIP_PITCH, JUGGLE_PIP_Y)
		var outline := _rect(readout_root, at,
			Vector2(JUGGLE_PIP_SIZE, JUGGLE_PIP_SIZE), INK_DARK)
		var fill := _rect(readout_root, at + Vector2.ONE, Vector2.ONE, CREAM)
		outline.visible = false
		fill.visible = false
		pip_list.append(outline)
		fill_list.append(fill)


func _juggle_points_start(fighter: FighterBase) -> int:
	if fighter == null or fighter.data == null \
			or fighter.data.combo_tuning == null:
		return 5
	return fighter.data.combo_tuning.juggle_points_start


func _refresh_live_readouts() -> void:
	if _match_root == null or not is_instance_valid(_match_root):
		return
	for defender_side in 2:
		_update_juggle_readout(defender_side)
		_update_stun_readout(defender_side)
		_update_breaker_pip(defender_side)


func _update_juggle_readout(defender_side: int) -> void:
	var defender: FighterBase = _match_root.p1 if defender_side == 0 else _match_root.p2
	if defender == null:
		return
	var attacker_side := 1 - defender_side
	var count := _juggle_points_start(defender)
	_ensure_juggle_pips(attacker_side, count)
	var active := defender.juggle_points >= 0
	for i in juggle_pip_outlines[attacker_side].size():
		var outline: ColorRect = juggle_pip_outlines[attacker_side][i]
		var fill: ColorRect = juggle_pip_fills[attacker_side][i]
		outline.visible = active
		fill.visible = active and i < defender.juggle_points


func _on_stun_started(defender_side: int) -> void:
	var defender: FighterBase = _match_root.p1 if defender_side == 0 else _match_root.p2
	if defender != null:
		# A stun seeds the existing tracker at ladder step 3 without emitting
		# ComboTracker.changed; resample it here for the attacker's readout.
		_on_combo_changed(defender_side, defender.combo_tracker.hits,
			defender.combo_tracker.total_damage)
	_update_stun_readout(defender_side)


func _update_stun_readout(side: int) -> void:
	if _match_root == null:
		return
	var fighter: FighterBase = _match_root.p1 if side == 0 else _match_root.p2
	if fighter == null:
		return
	var active := fighter.stun_active() and fighter.stun_frames_remaining > 0
	stun_labels[side].visible = active
	stun_bar_borders[side].visible = active
	stun_bar_backgrounds[side].visible = active
	stun_bar_fills[side].visible = active
	if not active:
		return
	var total := maxi(fighter.stun_window_applied,
		fighter.stun_frames_remaining)
	var fraction := clampf(float(fighter.stun_frames_remaining) / float(maxi(1, total)),
		0.0, 1.0)
	var width := roundf(STUN_BAR_INNER_WIDTH * fraction)
	var fill := stun_bar_fills[side]
	fill.size.x = width
	if side == 1:
		fill.position.x = STUN_BAR_X[side] + 1.0 \
			+ STUN_BAR_INNER_WIDTH - width


func _update_breaker_pip(side: int) -> void:
	if side < 0 or side >= breaker_pip_borders.size() or _match_root == null:
		return
	var fighter: FighterBase = _match_root.p1 if side == 0 else _match_root.p2
	if fighter == null or fighter.data == null:
		breaker_pip_states[side] = "unavailable"
	else:
		var unlocked := fighter.breaker_cooldown_frames <= 0 \
			and not fighter.breaker_used_this_combo
		if unlocked and fighter.breaker_free_uses_left > 0:
			breaker_pip_states[side] = "free"
		elif unlocked and fighter.meter + 0.001 >= fighter.data.breaker_meter_cost:
			breaker_pip_states[side] = "paid"
		else:
			breaker_pip_states[side] = "unavailable"

	match breaker_pip_states[side]:
		"free":
			breaker_pip_borders[side].color = INK_DARK
			breaker_pip_centers[side].color = DIRTY_YELLOW
		"paid":
			breaker_pip_borders[side].color = DIRTY_YELLOW
			breaker_pip_centers[side].color = Color.TRANSPARENT
		_:
			breaker_pip_borders[side].color = INK_WARM
			breaker_pip_centers[side].color = INK_WARM


func _on_macro_step(side: int, macro_name: String, step_index: int) -> void:
	if step_index != 0:
		return
	for label in macro_flash_labels:
		label.visible = false
	macro_flash_labels[side].text = macro_name.to_upper()
	macro_flash_labels[side].visible = true
	_macro_flash_side = side
	_macro_flash_frames = 45


func _clear_macro_flash() -> void:
	_macro_flash_frames = 0
	_macro_flash_side = -1
	for label in macro_flash_labels:
		label.visible = false


# ---------------- settings (read live; never written) -----------------------

func _settings() -> Node:
	if _settings_cache == null:
		_settings_cache = get_tree().root.get_node_or_null("Settings")
	return _settings_cache


func _setting(section: String, key: String, default: Variant) -> Variant:
	var settings := _settings()
	if settings == null:
		return default
	return settings.get_value(section, key)


# ---------------- the sim tick (presentation-only) --------------------------

func sim_tick() -> void:
	if _match_root == null or not is_instance_valid(_match_root):
		return
	# A sim_frame discontinuity is a serialize()/load() restore (or a debug
	# frame-step): resync everything from the current state.
	var sim_frame: int = _match_root.sim_frame
	if _last_sim_frame >= 0 and sim_frame != _last_sim_frame + 1:
		_resync()
	_last_sim_frame = sim_frame
	# Hitstop holds the exchange and the clock; the HUD holds with it.
	var p1: FighterBase = _match_root.p1
	var p2: FighterBase = _match_root.p2
	if p1 == null or p2 == null:
		return
	if p1.hitstop_frames > 0 or p2.hitstop_frames > 0:
		return

	_tick += 1
	# Banner stamp-in and auto-remove.
	if banner_plate.visible:
		if _banner_stamp < STAMP_OFFSETS.size():
			var offset: int = STAMP_OFFSETS[_banner_stamp]
			_stamp_banner_y(offset)
			_banner_stamp += 1
		if _banner_auto > 0:
			_banner_auto -= 1
			if _banner_auto == 0:
				_hide_banner()
	# Callout, one at a time, 30 sim frames.
	if _callout_frames > 0:
		_callout_frames -= 1
		if _callout_frames == 0:
			counter_flash.visible = false
			_callout_side = -1
			for side in 2:
				_update_combo_visibility(side)
	# Macro names are presentation-only flashes. Like callouts, they use the
	# HUD sim tick, so they freeze during pause and hitstop.
	if _macro_flash_frames > 0:
		_macro_flash_frames -= 1
		if _macro_flash_frames == 0:
			for label in macro_flash_labels:
				label.visible = false
			_macro_flash_side = -1
	# Commentary tape.
	if _commentary_frames > 0:
		_commentary_frames -= 1
		if _commentary_frames == 0:
			commentary_panel.visible = false
			commentary_label.visible = false
	# Ghost drain: a linear 20-sim-frame descent from the damage point to
	# the current health, starting when the combo counter clears.
	for side in 2:
		if _ghost_drain[side] > 0:
			_ghost_drain[side] -= 1
			var target: float = _health[side]
			_ghost[side] = maxf(target, _ghost[side] - _ghost_step[side])
			_layout_ghost(side)
		# One flash per hit (a single fade, never strobing).
		if _flash[side] > 0:
			_flash[side] -= 1
			_layout_health_fill(side)
	# Gentle low-health pulse: one shade per 15 sim frames, no strobing.
	if _tick % PULSE_STEP == 0:
		for side in 2:
			if _health[side] < 0.2 * _max_health[side] and _health[side] > 0.0:
				_layout_health_fill(side)
	# METH READY skull alternation, every 15 sim frames.
	if _tick % SKULL_STEP == 0:
		for side in 2:
			if meter_skulls[side].visible:
				var frame_index := int(_tick / SKULL_STEP) % 2
				meter_skulls[side].texture = (
					HudArt.SKULL_F2 if frame_index == 1 else HudArt.SKULL_F1)
	# Under-10s timer digits tick (one shade per 15 sim frames).
	if _tick % PULSE_STEP == 0:
		_refresh_timer_tint()
	_refresh_live_readouts()


func _resync() -> void:
	# A restore just rewrote the match: snap the presentation to it.
	for side in 2:
		var fighter: FighterBase = _match_root.p1 if side == 0 else _match_root.p2
		if fighter == null:
			continue
		_health[side] = fighter.health
		_max_health[side] = fighter.max_health
		_ghost[side] = fighter.health
		_ghost_drain[side] = 0
		_combo_active[side] = fighter.combo_tracker.hits > 0
		_flash[side] = 0
		_layout_health_fill(side)
		_layout_ghost(side)
		_on_meter(side, fighter.meter, fighter.max_meter)
		_on_combo_changed(side, fighter.combo_tracker.hits,
			fighter.combo_tracker.total_damage)
		_update_stun_readout(side)
		_update_juggle_readout(side)
		_update_breaker_pip(side)
		_refresh_portrait(side)
	_hide_banner()
	counter_flash.visible = false
	_callout_frames = 0
	_callout_side = -1
	_clear_macro_flash()
	commentary_panel.visible = false
	commentary_label.visible = false
	_commentary_frames = 0
	for side in 2:
		_update_combo_visibility(side)


# ---------------- bind -------------------------------------------------------

func bind(p1: FighterBase, p2: FighterBase) -> void:
	_match_root = p1.get_parent()
	p1_name.text = p1.data.display_name.to_upper()
	p2_name.text = p2.data.display_name.to_upper()
	p1.health_changed.connect(_on_p1_health)
	p2.health_changed.connect(_on_p2_health)
	p1.meter_changed.connect(_on_p1_meter)
	p2.meter_changed.connect(_on_p2_meter)
	p1.combo_tracker.changed.connect(
		func(hits: int, total_damage: float):
			_on_combo_changed(0, hits, total_damage))
	p2.combo_tracker.changed.connect(
		func(hits: int, total_damage: float):
			_on_combo_changed(1, hits, total_damage))
	p1.macro_step_replayed.connect(
		func(name: String, index: int): _on_macro_step(0, name, index))
	p2.macro_step_replayed.connect(
		func(name: String, index: int): _on_macro_step(1, name, index))
	p1.stun_started.connect(
		func(_id: StringName, _frames: int): _on_stun_started(0))
	p2.stun_started.connect(
		func(_id: StringName, _frames: int): _on_stun_started(1))
	p1.stun_ended.connect(func(): _update_stun_readout(0))
	p2.stun_ended.connect(func(): _update_stun_readout(1))
	p1.breaker_used.connect(func(_was_free: bool): _on_breaker_used(0))
	p2.breaker_used.connect(func(_was_free: bool): _on_breaker_used(1))
	p1.clip_cancelled.connect(func(): _show_callout(0, "CLIP CANCEL"))
	p2.clip_cancelled.connect(func(): _show_callout(1, "CLIP CANCEL"))
	# Attacker-side callouts need the side, so each fighter connects its
	# own teched / counter signal.
	p1.teched.connect(func(): _on_teched(0))
	p2.teched.connect(func(): _on_teched(1))
	p1.counter_hit_landed.connect(func(): _on_counter_hit(0))
	p2.counter_hit_landed.connect(func(): _on_counter_hit(1))
	_last_wins = [0, 0]
	_on_p1_health(p1.health, p1.max_health)
	_on_p2_health(p2.health, p2.max_health)
	_on_p1_meter(p1.meter, p1.max_meter)
	_on_p2_meter(p2.meter, p2.max_meter)
	_ensure_juggle_pips(1, _juggle_points_start(p2))
	_ensure_juggle_pips(0, _juggle_points_start(p1))
	_on_combo_changed(0, p1.combo_tracker.hits, p1.combo_tracker.total_damage)
	_on_combo_changed(1, p2.combo_tracker.hits, p2.combo_tracker.total_damage)
	_refresh_live_readouts()
	# Meter-ready geometry (static): P1 text at x 114, P2 right edge 206,
	# the skull beside it.
	var skull_1_x: float = 114.0 + UiText.marker_width("METH READY") + 2.0
	meter_skulls[0].position = Vector2(skull_1_x, 170.0)
	meter_ready[1].position = Vector2(206.0 - meter_ready[1].size.x, 168.0)
	meter_skulls[1].position = Vector2(
		206.0 - meter_ready[1].size.x - 10.0, 170.0)


# ---------------- health, ghost, portraits ----------------------------------

func _on_p1_health(value: float, max_value: float) -> void:
	_on_health(0, value, max_value)


func _on_p2_health(value: float, max_value: float) -> void:
	_on_health(1, value, max_value)


func _on_health(side: int, value: float, max_value: float) -> void:
	var previous: float = _health[side]
	_health[side] = value
	_max_health[side] = max_value
	if value > previous:
		# A refill is a new round: the ko face and ghost clear.
		_round_lost[side] = false
		_ghost[side] = value
		_ghost_drain[side] = 0
	elif value < previous:
		# One flash per hit; reduce_flashing makes it a 1-frame tint.
		_flash[side] = 1 if _reduce_flashing() else FLASH_FRAMES
		if _combo_active[side]:
			# The ghost remembers the combo's highest health.
			_ghost[side] = maxf(_ghost[side], previous)
		else:
			_ghost[side] = value
	_layout_health_fill(side)
	_layout_ghost(side)
	_refresh_portrait(side)


func _layout_health_fill(side: int) -> void:
	var fraction: float = clampf(_health[side] / _max_health[side], 0.0, 1.0)
	var width: float = roundf(HEALTH_INTERIOR.x * fraction)
	var fill := health_fills[side]
	var base := P1_HEALTH if side == 0 else P2_HEALTH
	# The flash fade and the gentle low-health pulse live on the fill's
	# color; both are single shades per step, never strobes.
	var color := base
	if _flash[side] > 0:
		color = base.lerp(Color.WHITE, 0.35)
	elif fraction <= 0.2 and fraction > 0.0 and _tick % (PULSE_STEP * 2) >= PULSE_STEP:
		color = base.darkened(0.25)
	fill.color = color
	fill.size = Vector2(width, HEALTH_INTERIOR.y)
	if side == 1:
		fill.position.x = HEALTH_POS[1].x + HEALTH_FILL_OFFSET.x + (HEALTH_INTERIOR.x - width)


func _layout_ghost(side: int) -> void:
	var fraction: float = clampf(_ghost[side] / _max_health[side], 0.0, 1.0)
	var width: float = roundf(HEALTH_INTERIOR.x * fraction)
	var ghost := ghost_fills[side]
	ghost.size = Vector2(width, HEALTH_INTERIOR.y)
	if side == 1:
		ghost.position.x = HEALTH_POS[1].x + HEALTH_FILL_OFFSET.x + (HEALTH_INTERIOR.x - width)
	ghost.visible = _ghost[side] > _health[side] + 0.5


func _refresh_portrait(side: int) -> void:
	var path := ""
	if _round_lost[side] or _health[side] <= 0.5:
		path = HudArt.portrait_path(_fighter_id(side), "ko")
	elif _health[side] < 0.25 * _max_health[side]:
		path = HudArt.portrait_path(_fighter_id(side), "hurt")
	if path.is_empty():
		path = HudArt.portrait_path(_fighter_id(side), "normal")
	if path.is_empty():
		portraits[side].texture = null  # the empty frame, never a crash
	else:
		var crop := AtlasTexture.new()
		crop.atlas = load(path)
		crop.region = PORTRAIT_CROP
		portraits[side].texture = crop


func _fighter_id(side: int) -> String:
	if _match_root == null:
		return ""
	var fighter: FighterBase = _match_root.p1 if side == 0 else _match_root.p2
	return fighter.data.id if fighter != null else ""


# ---------------- meter -----------------------------------------------------

func _on_p1_meter(value: float, max_value: float) -> void:
	_on_meter(0, value, max_value)


func _on_p2_meter(value: float, max_value: float) -> void:
	_on_meter(1, value, max_value)


func _on_meter(side: int, value: float, max_value: float) -> void:
	var fraction: float = clampf(value / max_value, 0.0, 1.0)
	var width: float = roundf(METER_INTERIOR.x * fraction)
	var fill := meter_fills[side]
	fill.size = Vector2(width, METER_INTERIOR.y)
	if side == 1:
		fill.position.x = METER_POS[1].x + METER_FILL_OFFSET.x + (METER_INTERIOR.x - width)
	else:
		fill.position.x = METER_POS[0].x + METER_FILL_OFFSET.x
	var full := fraction >= 0.999
	fill.color = METH_PINK if full else METER_FILL
	meter_ready[side].visible = full
	meter_skulls[side].visible = full
	if not full:
		meter_skulls[side].texture = HudArt.SKULL_F1
	_update_breaker_pip(side)


# ---------------- combo ------------------------------------------------------

func _on_combo_changed(defender_side: int, count: int, total_damage: float) -> void:
	var attacker_side := 1 - defender_side
	_combo_hits_by_side[attacker_side] = count
	_combo_damage_by_side[attacker_side] = total_damage
	# Health ghost ownership stays with the defender; the combo readout itself
	# is deliberately shown on the opposite (attacker's) side.
	if count >= 1:
		_combo_active[defender_side] = true
		_ghost_drain[defender_side] = 0
	else:
		_combo_active[defender_side] = false
		if _ghost[defender_side] > _health[defender_side] + 0.5:
			_ghost_drain[defender_side] = GHOST_DRAIN_FRAMES
			_ghost_step[defender_side] = (
				_ghost[defender_side] - _health[defender_side]
			) / float(GHOST_DRAIN_FRAMES)
	_render_combo_readout(attacker_side)


func _render_combo_readout(attacker_side: int) -> void:
	var count := _combo_hits_by_side[attacker_side]
	var damage := _combo_damage_by_side[attacker_side]
	var combo_label := p1_combo if attacker_side == 0 else p2_combo
	combo_label.text = "%d HITS" % count if count >= 2 else ""
	var defender_side := 1 - attacker_side
	var scale := _base_combo_scale(defender_side, count)
	combo_label.add_theme_color_override("font_color", _combo_color(scale))
	combo_damages[attacker_side].text = (
		"%d" % int(roundi(damage)) if count >= 2 else "")
	combo_scales[attacker_side].text = (
		"x%.2f" % scale if count >= 2 else "")
	_update_combo_visibility(attacker_side)


func _base_combo_scale(defender_side: int, hits: int) -> float:
	if hits <= 0:
		return 1.0
	var fighter: FighterBase = _match_root.p1 if defender_side == 0 else _match_root.p2
	if fighter == null or fighter.data == null \
			or fighter.data.combo_tuning == null:
		return 1.0
	# This intentionally reports the base ladder tier for the most recent hit.
	# Repeat-move penalties and variety bonuses are move-specific and are not
	# represented as one current HUD multiplier.
	return fighter.data.combo_tuning.ladder_for(hits)


func _combo_color(scale: float) -> Color:
	if scale >= 0.95:
		return COMBO_YELLOW
	if scale >= 0.775:
		return COMBO_ORANGE
	if scale >= 0.625:
		return COMBO_RED
	return METH_PINK


func _update_combo_visibility(side: int) -> void:
	var has_combo := _combo_hits_by_side[side] >= 2
	var show_damage := has_combo and _show_combo_damage()
	var callout_collision := _callout_frames > 0 and _callout_side == side
	# Keep the damage/scale line clear of the shared callout row and keep the
	# scale tag off the opaque central banner. Both return after the transient.
	combo_damages[side].visible = show_damage and not callout_collision
	combo_scales[side].visible = show_damage and not callout_collision \
		and not banner_plate.visible


# ---------------- callouts ---------------------------------------------------

func _on_teched(side: int) -> void:
	_show_callout(side, "TECH")


func _on_counter_hit(side: int) -> void:
	_show_callout(side, "COUNTER HIT")


func _on_breaker_used(side: int) -> void:
	_update_breaker_pip(side)
	_show_callout(side, "BREAK!")


func _show_callout(side: int, text: String) -> void:
	counter_flash.text = text
	counter_flash.position = Vector2(
		CALLOUT_X[0] if side == 0 else CALLOUT_X[1], CALLOUT_Y)
	counter_flash.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if side == 0 \
		else HORIZONTAL_ALIGNMENT_RIGHT
	counter_flash.visible = true
	_callout_frames = CALLOUT_FRAMES
	_callout_side = side
	for combo_side in 2:
		_update_combo_visibility(combo_side)


# ---------------- banners ----------------------------------------------------

func show_banner(id: String, subtitle := "") -> void:
	banner_id = id
	_banner_stamp = 0
	banner_plate.visible = true
	_stamp_banner_y(STAMP_OFFSETS[0])
	var texture := HudArt.banner_texture(id)
	if texture != null:
		banner_word.texture = texture
		banner_word.size = texture.get_size()
		banner_word.position = Vector2(
			(160.0 - texture.get_size().x) / 2.0,
			(32.0 - texture.get_size().y) / 2.0)
		banner_word.visible = true
		message.visible = false
		message.text = ""
	else:
		banner_word.visible = false
	_show_banner_subtitle(subtitle)
	_banner_auto = FIGHT_BANNER_FRAMES if id == "fight" else (
		METH_BANNER_FRAMES if id == "methtality" else -1)
	for side in 2:
		_update_combo_visibility(side)


func show_banner_text(text: String) -> void:
	banner_id = "text"
	_banner_stamp = 0
	banner_plate.visible = true
	_stamp_banner_y(STAMP_OFFSETS[0])
	banner_word.visible = false
	message.text = text
	message.visible = true
	_show_banner_subtitle("")
	_banner_auto = -1
	for side in 2:
		_update_combo_visibility(side)


func _show_banner_subtitle(subtitle: String) -> void:
	if subtitle.is_empty():
		meth_banner.visible = false
		meth_banner.text = ""
	else:
		meth_banner.text = subtitle
		meth_banner.visible = true


func _stamp_banner_y(offset: int) -> void:
	# The word/text/subtitle are plate children; only the plate moves.
	banner_plate.position.y = BANNER_POS.y - offset


func _hide_banner() -> void:
	banner_plate.visible = false
	banner_word.visible = false
	message.visible = false
	meth_banner.visible = false
	banner_id = ""
	_banner_auto = -1
	for side in 2:
		_update_combo_visibility(side)


# Backward-compatible aliases for the pre-Phase-2 call sites.
func show_message(text: String) -> void:
	show_banner_text(text)


func show_meth_message(text: String) -> void:
	# Old callers passed "METHtality\n<name>"; the banner art carries the
	# word, the subtitle label carries the name.
	var parts := text.split("\n")
	show_banner("methtality", parts[parts.size() - 1])


func clear_message() -> void:
	_hide_banner()


# ---------------- timer -----------------------------------------------------

func set_timer(seconds: float) -> void:
	var value := int(ceilf(seconds))
	for i in 2:
		var digit := value % 10 if i == 0 else (value / 10) % 10
		timer_digits[i].texture = HudArt.digit_texture(digit)
	_refresh_timer_tint()


func _refresh_timer_tint() -> void:
	var low: bool = _health.size() == 2 and _match_root != null \
		and _match_root.timer_frames < 10 * 60
	if low:
		timer_box_art.modulate = DIRTY_YELLOW
		# The digits tick: one shade per 15 sim frames, never a strobe.
		var dim: bool = _tick % (PULSE_STEP * 2) >= PULSE_STEP
		for digit in timer_digits:
			digit.modulate = Color(0.55, 0.5, 0.3) if dim else Color.WHITE
	else:
		timer_box_art.modulate = Color.WHITE
		for digit in timer_digits:
			digit.modulate = Color.WHITE


# ---------------- pips -------------------------------------------------------

func set_pips(p1_wins: int, p2_wins: int) -> void:
	# Round-loss detection for the ko portrait: a side whose opponent's
	# pip count grew while its own did not lost the round (a double KO
	# grows both, so nobody's face flips).
	if p2_wins > _last_wins[1] and p1_wins == _last_wins[0]:
		_round_lost[0] = true
	if p1_wins > _last_wins[0] and p2_wins == _last_wins[1]:
		_round_lost[1] = true
	_last_wins = [p1_wins, p2_wins]
	# Double KOs award both fighters a pip, so a score can pass 2-2; grow
	# the rows instead of hiding wins.
	var count := maxi(2, maxi(p1_wins, p2_wins))
	for side in 2:
		while pips[side].size() < count:
			_append_pip(hud_root, side, pips[side].size())
	var wins := [p1_wins, p2_wins]
	for side in 2:
		for i in pips[side].size():
			var pip: TextureRect = pips[side][i]
			pip.visible = i < count
			if i < wins[side]:
				pip.texture = HudArt.PIP_SQUARE_FILLED if side == 0 \
					else HudArt.PIP_DIAMOND_FILLED
			else:
				pip.texture = HudArt.PIP_SQUARE_EMPTY if side == 0 \
					else HudArt.PIP_DIAMOND_EMPTY
	# A round just resolved; the loser's face flips after the pips.
	if _round_lost[0]:
		_refresh_portrait(0)
	if _round_lost[1]:
		_refresh_portrait(1)


# ---------------- commentary -------------------------------------------------

func show_commentary(text: String, duration_frames := 180,
		kind := "round") -> void:
	var mode := str(_setting("gameplay", "commentary", "full"))
	var hide_tripp := bool(_setting("stream", "hide_tripp_text", false))
	if mode == "off" or hide_tripp:
		return
	if mode == "minimal" and kind != "round":
		return
	commentary_label.text = text
	commentary_panel.visible = true
	commentary_label.visible = true
	_commentary_frames = duration_frames


# ---------------- accessibility ----------------------------------------------

func _reduce_flashing() -> bool:
	return bool(_setting("accessibility", "reduce_flashing", false))


func _show_combo_damage() -> bool:
	return bool(_setting("gameplay", "show_combo_damage", true))


func apply_high_contrast(enabled: bool) -> void:
	for plate in high_contrast_plates:
		plate.visible = enabled


# ---------------- pause menu (unchanged from the Phase 1 polish) ------------

func set_paused(paused: bool) -> void:
	pause_root.visible = paused
	if paused:
		set_pause_selection(0)


func pause_option_count() -> int:
	return PAUSE_OPTIONS.size()


func _build_pause_menu(root: Control) -> void:
	pause_root = Control.new()
	pause_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_root.visible = false
	pause_root.theme = UI_THEME
	pause_root.z_index = 5
	root.add_child(pause_root)
	# The same #1C160D 55% declutter overlay the title and main menu use
	# (docs/UI_SCREENS.md review fixes).
	pause_root.add_child(UiText.dim_overlay())
	# Phase 1 polish: one small centered ui_panel sized to its longest item
	# plus 8 px padding on each side; items in Sidewalk Marker dark ink; the
	# focused item rides a full-width yellow bar with the darkest ink
	# (contrast rules). No per-item buttons, no Godot outline on the font.
	var longest := 0.0
	for option in PAUSE_OPTIONS:
		longest = maxf(longest, UiText.marker_width(option))
	var panel_w := int(longest) + 16
	var panel_x := 160 - panel_w / 2
	var pause_panel := Panel.new()
	pause_panel.position = Vector2(panel_x, 24)
	pause_panel.size = Vector2(panel_w, 116)
	pause_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pause_root.add_child(pause_panel)
	var header := UiText.marker("PAUSED", Vector2(panel_x, 30), UiText.INK)
	header.size = Vector2(panel_w, UiText.MARKER_LINE_HEIGHT)
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_root.add_child(header)
	for i in PAUSE_OPTIONS.size():
		var row_y := 47 + i * 14
		var bar := UiText.focus_bar(Vector2(panel_x + 8, row_y - 1),
			Vector2(panel_w - 16, 12))
		pause_root.add_child(bar)
		pause_bars.append(bar)
		var option := _pause_option_label(PAUSE_OPTIONS[i],
			Vector2(panel_x + 8, row_y), panel_w - 16)
		pause_root.add_child(option)
		pause_options.append(option)
	pause_root.add_child(UiPromptLine.new("SELECT", ""))
	set_pause_selection(0)


# One pause-menu row: a plain Sidewalk Marker label in dark ink, centered
# on its row; input stays in match_root's hands.
func _pause_option_label(text: String, at: Vector2, width: float) -> Label:
	var option := UiText.marker(text, at, UiText.INK)
	option.size = Vector2(width, UiText.MARKER_LINE_HEIGHT)
	option.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return option


func set_pause_selection(index: int) -> void:
	# The focused item rides the full-width yellow bar with the darkest
	# ink; the rest stay dark ink on the cardboard. match_root owns the
	# selection index.
	for i in pause_options.size():
		var selected := i == index
		pause_bars[i].visible = selected
		pause_options[i].text = PAUSE_OPTIONS[i]
		pause_options[i].add_theme_color_override("font_color",
			UiText.INK_DARK if selected else UiText.INK)


# ---------------- small builders --------------------------------------------

func _rect(parent: Control, pos: Vector2, size: Vector2, color: Color) -> ColorRect:
	var r := ColorRect.new()
	r.position = pos
	r.size = size
	r.color = color
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(r)
	return r


func _art(parent: Control, texture: Texture2D, pos: Vector2,
		size: Vector2) -> TextureRect:
	var rect := TextureRect.new()
	rect.texture = texture
	rect.position = pos
	rect.size = size
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	parent.add_child(rect)
	return rect
