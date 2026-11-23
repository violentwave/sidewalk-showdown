# ui_layout_test.gd — owner playtest fix batch (2026-11-23): numeric layout
# assertions at the 320x180 game resolution. No image reading: every check
# measures node rects and ink extents directly.
#
# Covered, across versus, solo, and training, both stages, and both
# character orders (WHISKEY RICHARD on each side):
#   - name ink vs health frames vs the timer box (never overlapping)
#   - the BREAK readout joined to its pip in the meter band, clear of the
#     meter frames and the stun labels
#   - the METHtality word art vs its subtitle line
#   - the training readout panel vs the timer and the jump-apex band
#   - Results banner vs stats panel vs prompt plate, label contrast,
#     and the TOTAL DMG label
#   - UI z-order: router screens above the HUD, HUD above stage ambient
#
# Run: godot --headless --path game --script res://tests/ui_layout_test.gd
extends SceneTree

const MATCH_SCENE := preload("res://scenes/match/MatchRoot.tscn")
const RESULTS_SCENE := preload("res://scenes/menus/results_screen.tscn")
const ROUTER_SCRIPT := preload("res://scripts/ui/screen_router.gd")
const ROSTER := preload("res://resources/match_roster.tres")

# HUD frame geometry (mirrors match_hud.gd; sizes are the art's native px).
const HEALTH_FRAME_SIZE := Vector2(118, 10)
const METER_FRAME_SIZE := Vector2(106, 8)
const TIMER_BOX_RECT := Rect2(148, 3, 24, 20)
# The meter band the BREAK readout lives in: from the label top to the
# meter frame bottom.
const METER_BAND := Rect2(0, 157, 320, 21)
# Richard on Gas-N-Go: floor 158 - body 60 - jump apex 45.125 => the
# highest a NORMAL jump's head reaches; nothing may cover this band's top.
const WORST_JUMP_TOP := 52.875
# Widest art half-extent measured across all enabled art cels, mirrored for
# facing (Richard ko_air f2): 40.78 px.
const WIDEST_ART_HALF := 40.78
# The Meth banner plate's resting rect.
const BANNER_RECT := Rect2(80, 74, 160, 32)
const RESULTS_WINNER_RECT := Rect2(115, 10, 90, 20)
const RESULTS_PANEL_RECT := Rect2(168, 34, 140, 78)
const PROMPT_PLATE_RECT := Rect2(0, 168, 320, 12)

var failures := 0
var checks := 0
var _top_band_checked := false


func _initialize() -> void:
	_run.call_deferred()


func _check(label: String, condition: bool, detail: String = "") -> void:
	checks += 1
	if condition:
		print("PASS: ", label)
	else:
		failures += 1
		print("FAIL: ", label, "  ", detail)


func _ink(label: Label, align_right := false) -> Rect2:
	# The m5x7 16 px line box centers ~8 px of ink at y + 4.
	var width := UiText.body_width(label.text)
	var x := label.position.x
	if align_right:
		x = label.position.x + label.size.x - width
	return Rect2(x, label.position.y + 4.0, width, 8.0)


func _build_match(stage_index: int, p1_index: int, p2_index: int,
		training: bool, solo: bool) -> Node:
	var mroot: Node = MATCH_SCENE.instantiate()
	mroot.selected_p1_data = ROSTER.fighters[p1_index]
	mroot.selected_p2_data = ROSTER.fighters[p2_index]
	mroot.selected_stage = ROSTER.stages[stage_index]
	mroot.training_mode = training
	if solo:
		mroot.p2_cpu = true
	root.add_child(mroot)
	await process_frame
	await physics_frame
	return mroot


func _free_match(mroot: Node) -> void:
	mroot.free()
	await process_frame


func _hud_checks(mroot: Node, tag: String) -> void:
	var hud: MatchHUD = mroot.hud
	if not _top_band_checked:
		_top_band_checked = true
		var top_band_rect := Rect2(hud.top_band.position, hud.top_band.size)
		_check("the opaque HUD top band masks the foreground canopy strip",
			hud.top_band.visible and is_equal_approx(hud.top_band.color.a, 1.0)
				and top_band_rect.encloses(TIMER_BOX_RECT)
				and top_band_rect.has_point(Vector2(175, 7))
				and top_band_rect.has_point(Vector2(250, 7)),
			str(top_band_rect))
	var stage: Node = mroot.stage
	_check("%s: bounds keep the widest authored pose fully on screen" % tag,
		stage.left_bound >= WIDEST_ART_HALF + 3.0
			and stage.right_bound <= 320.0 - WIDEST_ART_HALF - 3.0,
		"bounds=%s..%s widest=%s" % [stage.left_bound,
			stage.right_bound, WIDEST_ART_HALF])
	var health: Array[Rect2] = [
		Rect2(hud.HEALTH_POS[0], HEALTH_FRAME_SIZE),
		Rect2(hud.HEALTH_POS[1], HEALTH_FRAME_SIZE),
	]
	# 1. Name ink: inside the screen, below the bars, never on the timer.
	for side in 2:
		var name_label: Label = hud.p1_name if side == 0 else hud.p2_name
		var ink := _ink(name_label, side == 1)
		_check("%s: side %d name ink stays on screen" % [tag, side],
			ink.position.x >= 0.0 and ink.end.x <= 320.0
				and ink.position.y >= 0.0 and ink.end.y <= 180.0,
			str(ink))
		_check("%s: side %d name ink never overlaps its health bar" % [tag, side],
			not ink.intersects(health[side]), str(ink))
		_check("%s: side %d name ink never overlaps the timer box" % [tag, side],
			not ink.intersects(TIMER_BOX_RECT), str(ink))
		_check("%s: side %d name label rect never overlaps the timer box"
				% [tag, side],
			not Rect2(name_label.position, name_label.size).intersects(
				TIMER_BOX_RECT),
			str(Rect2(name_label.position, name_label.size)))
		# The dark backing plate hugs the ink and stays inside the band
		# between the bar (bottom y 18) and the pip row (top y 31).
		var plate: ColorRect = hud.name_plates[side]
		var plate_rect := Rect2(plate.position, plate.size)
		_check("%s: side %d name plate covers the ink and clears bar and pips"
				% [tag, side],
			plate.visible and plate_rect.encloses(ink)
				and plate_rect.position.y >= 18.0
				and plate_rect.end.y <= 31.0,
			str(plate_rect))
	# 2. BREAK: renamed, joined to its pip, inside the meter band.
	_check("%s: the breaker readout is spelled BREAK" % tag,
		hud.BREAKER_TEXT == "BREAK", hud.BREAKER_TEXT)
	for side in 2:
		var breaker: Label = hud.breaker_labels[side]
		var b_ink := _ink(breaker)
		var pip_rect := Rect2(hud.BREAKER_PIP_POS[side], Vector2(5, 5))
		var meter_rect := Rect2(hud.METER_POS[side], METER_FRAME_SIZE)
		_check("%s: side %d BREAK ink sits inside the meter band" % [tag, side],
			METER_BAND.encloses(b_ink), str(b_ink))
		_check("%s: side %d BREAK ink never overlaps the meter frame" % [tag, side],
			not b_ink.intersects(meter_rect), str(b_ink))
		_check("%s: side %d BREAK shares its row with the pip" % [tag, side],
			b_ink.position.y <= pip_rect.position.y + 5.0
				and b_ink.end.y >= pip_rect.position.y,
			"ink=%s pip=%s" % [str(b_ink), str(pip_rect)])
		# Clear of the stun label on its own side.
		var stun: Label = hud.stun_labels[side]
		var stun_ink := Rect2(stun.position.x, stun.position.y + 2.0,
			UiText.marker_width("STUNNED"), 8.0)
		_check("%s: side %d BREAK never overlaps the STUNNED label" % [tag, side],
			not b_ink.intersects(stun_ink),
			"ink=%s stun=%s" % [str(b_ink), str(stun_ink)])
	# 3. The METHtality banner: title and subtitle on separate lines.
	for subtitle in ["WALK THE PLANK", "FLAMING BELCH"]:
		hud.show_banner("methtality", subtitle)
		var word_rect := Rect2(
			BANNER_RECT.position + hud.banner_word.position,
			hud.banner_word.size)
		var sub_ink := Rect2(
			BANNER_RECT.position.x + 0.0,
			BANNER_RECT.position.y + hud.meth_banner.position.y + 2.0,
			UiText.marker_width(subtitle), 8.0)
		_check("%s: the METHTALITY art never overlaps its subtitle" % tag,
			not word_rect.intersects(sub_ink),
			"word=%s sub=%s" % [str(word_rect), str(sub_ink)])
		_check("%s: the %s subtitle fits its plate" % [tag, subtitle],
			BANNER_RECT.encloses(word_rect) and BANNER_RECT.encloses(sub_ink),
			"word=%s sub=%s" % [str(word_rect), str(sub_ink)])
		hud._hide_banner()


func _training_checks(mroot: Node, tag: String) -> void:
	var hud: MatchHUD = mroot.hud
	var panel := hud.training_panel
	var plate_rect := Rect2(panel.PLATE_POS, panel.PLATE_SIZE)
	_check("%s: the training panel never overlaps the timer box" % tag,
		not plate_rect.intersects(TIMER_BOX_RECT), str(plate_rect))
	_check("%s: the training panel clears the highest normal jump" % tag,
		plate_rect.end.y <= WORST_JUMP_TOP,
		"bottom=%.1f worst jump top=%.3f" % [plate_rect.end.y, WORST_JUMP_TOP])
	for side in 2:
		var name_label: Label = hud.p1_name if side == 0 else hud.p2_name
		var name_ink := _ink(name_label, side == 1)
		_check("%s: the training panel never covers name ink %d" % [tag, side],
			not plate_rect.intersects(name_ink),
			"plate=%s name=%s" % [str(plate_rect), str(name_ink)])
		var stun: Label = hud.stun_labels[side]
		var stun_ink := Rect2(stun.position.x, stun.position.y + 2.0,
			UiText.marker_width("STUNNED"), 8.0)
		_check("%s: the training panel never overlaps STUNNED %d" % [tag, side],
			not plate_rect.intersects(stun_ink),
			"plate=%s stun=%s" % [str(plate_rect), str(stun_ink)])
	# Simulate a launched P2 body passing through the reserved band. The
	# readout disappears only for the intersecting sim frames and returns
	# when both fighters clear the plate.
	var p2_position: Vector2 = mroot.p2.position
	mroot.p2.position = Vector2(160.0,
		plate_rect.position.y + mroot.p2.body_height * 0.5)
	panel.sim_tick()
	_check("%s: the training readout hides while a fighter overlaps it" % tag,
		not panel.visible,
		"fighter=%s panel=%s" % [str(mroot.p2.hurtbox_rect()), str(plate_rect)])
	mroot.p2.position = p2_position
	panel.sim_tick()
	_check("%s: the training readout returns after the fighter clears" % tag,
		panel.visible)
	# Readout text: DMG prefix and no raw -1 sentinel.
	var tc: TrainingController = mroot.training
	tc.last_kind = "DMG"
	tc.last_hit_damage = 35.0
	tc.last_advantage = 4
	tc.last_startup = 3
	tc.last_move_id = "probe"
	mroot.p2.juggle_points = -1
	panel.sim_tick()
	_check("%s: the readout shows DMG for last-hit damage" % tag,
		panel.row1.text.begins_with("DMG 35"), panel.row1.text)
	_check("%s: the readout hides the juggle sentinel" % tag,
		panel.row2.text.contains("JUG -") and not panel.row2.text.contains("-1"),
		panel.row2.text)
	mroot.p2.juggle_points = 3
	panel.sim_tick()
	_check("%s: an active juggle budget still shows its points" % tag,
		panel.row2.text.contains("JUG 3"), panel.row2.text)


func _zorder_checks() -> void:
	var hud_scene: CanvasLayer = preload(
		"res://scenes/match/MatchHUD.tscn").instantiate()
	root.add_child(hud_scene)
	_check("the match HUD draws on a canvas layer above the world",
		hud_scene.layer == 10, "layer=%d" % hud_scene.layer)
	hud_scene.free()
	var router: Node = ROUTER_SCRIPT.new()
	root.add_child(router)
	await process_frame
	var ui_layer: CanvasLayer = null
	for child in router.get_children():
		if child is CanvasLayer:
			ui_layer = child
	_check("router screens draw above the match HUD",
		ui_layer != null and ui_layer.layer > 10
			and ui_layer.layer == router.UI_LAYER,
		"layer=%s" % str(ui_layer.layer if ui_layer != null else -1))
	_check("router screens draw above every world z_index sprite",
		ui_layer != null and ui_layer.layer > 10,
		"mosquitoes z=10 vs layer=%s"
			% str(ui_layer.layer if ui_layer != null else -1))
	router.free()
	await process_frame


func _debug_box_mode_checks() -> void:
	# Versus and solo each construct a fresh overlay with F1 still working.
	var versus: Node = await _build_match(0, 0, 1, false, false)
	_check("versus hitbox boxes start OFF", not versus.debug_overlay.show_boxes)
	var overlay: DebugOverlay = versus.debug_overlay
	var was_headless := overlay._headless
	overlay._headless = false
	var f1 := InputEventKey.new()
	f1.keycode = KEY_F1
	f1.physical_keycode = KEY_F1
	f1.pressed = true
	overlay._unhandled_input(f1)
	_check("F1 still toggles hitbox boxes ON", overlay.show_boxes)
	overlay._unhandled_input(f1)
	_check("F1 still toggles hitbox boxes OFF", not overlay.show_boxes)
	overlay._headless = was_headless
	await _free_match(versus)

	# Training's option is match-local, serialized with that training match,
	# and is not a Settings or FlowState global preference.
	var training: Node = await _build_match(0, 0, 1, true, false)
	training.training.set_option_value(8, 1)
	_check("the training HITBOXES option controls training F1 boxes",
		training.debug_overlay.show_boxes
			and training.training.hitboxes == training.training.Toggle.ON)
	await _free_match(training)

	var solo: Node = await _build_match(0, 1, 0, false, true)
	_check("solo hitbox boxes start OFF after a training match",
		not solo.debug_overlay.show_boxes)
	await _free_match(solo)

	var settings: Node = root.get_node("Settings")
	var persisted := false
	for section in settings.values:
		for key in settings.values[section]:
			if str(key).to_lower().contains("hitbox"):
				persisted = true
	var flow := FlowState.new()
	var flow_has_hitboxes := false
	for property in flow.get_property_list():
		if str(property["name"]).to_lower().contains("hitbox"):
			flow_has_hitboxes = true
	_check("training hitboxes are not persisted in Settings or FlowState",
		not persisted and not flow_has_hitboxes)


func _results_checks() -> void:
	var results: Control = RESULTS_SCENE.instantiate()
	results.stats = {
		"wins": [2, 0], "winner": 0,
		"damage": [2000.0, 717.0], "max_combo": [7, 3],
		"meth_used": [true, false], "time_left_frames": 1234,
	}
	results.winner_data = ROSTER.fighters[0]
	results.stage = ROSTER.stages[0]
	root.add_child(results)
	await process_frame
	_check("the Results winner banner never overlaps the stats panel",
		not RESULTS_WINNER_RECT.intersects(RESULTS_PANEL_RECT))
	_check("the Results winner banner never overlaps the prompt plate",
		not RESULTS_WINNER_RECT.intersects(PROMPT_PLATE_RECT))
	_check("the Results stats panel never overlaps the prompt plate",
		not RESULTS_PANEL_RECT.intersects(PROMPT_PLATE_RECT))
	var saw_total_dmg := false
	var labels := results.find_children("*", "Label", true, false)
	for label in labels:
		if label.text == "TOTAL DMG":
			saw_total_dmg = true
	_check("the Results rows label the match-total damage",
		saw_total_dmg, "no TOTAL DMG label")
	var stat_rows: Array = results._stat_rows()
	_check("TOTAL DMG displays both accumulated match totals",
		stat_rows[1][0] == "TOTAL DMG" and stat_rows[1][1] == "2000 / 717",
		str(stat_rows[1]))
	for row in results._row_labels:
		_check("the Results stat label %s uses the readable ink" % row.text,
			row.get_theme_color("font_color").is_equal_approx(UiText.INK),
			row.text)
	var prompt := results.find_children("*", "UiPromptLine", true, false)
	_check("the Results prompt plate stays fully on screen",
		not prompt.is_empty() and PROMPT_PLATE_RECT.end.y <= 180.0)
	var prompt_labels_in_frame := not prompt.is_empty()
	var prompt_label_rects: Array[String] = []
	if not prompt.is_empty():
		for node in prompt[0].find_children("*", "Label", true, false):
			var label := node as Label
			if label.visible and not label.text.is_empty():
				var rect := Rect2(label.global_position, label.size)
				prompt_label_rects.append("%s %s" % [label.text, str(rect)])
				if rect.position.x < 0.0 or rect.position.y < 0.0 \
						or rect.end.x > 320.0 or rect.end.y > 180.0:
					prompt_labels_in_frame = false
	_check("every Results prompt label fits on the 320x180 frame",
		prompt_labels_in_frame, str(prompt_label_rects))
	results.free()
	await process_frame


func _run() -> void:
	await process_frame
	var orders := [[0, 1], [1, 0]]  # [P1 index, P2 index]: Richard each side.
	for stage in 2:
		for order in orders:
			var mroot: Node = await _build_match(stage, order[0], order[1],
				false, false)
			_hud_checks(mroot, "versus stage %d order %s" % [stage, str(order)])
			await _free_match(mroot)
	# Solo (CPU P2): cross both stages and both character orders too.
	for stage in 2:
		for order in orders:
			var solo: Node = await _build_match(stage, order[0], order[1],
				false, true)
			_hud_checks(solo, "solo stage %d order %s" % [stage, str(order)])
			await _free_match(solo)
	# Training: both stages, both orders.
	for stage in 2:
		for order in orders:
			var troot: Node = await _build_match(stage, order[0], order[1],
				true, false)
			_hud_checks(troot, "training stage %d order %s" % [stage, str(order)])
			_training_checks(troot, "training stage %d order %s"
				% [stage, str(order)])
			await _free_match(troot)
	await _zorder_checks()
	await _results_checks()
	await _debug_box_mode_checks()
	print("ui_layout_test: %d checks, %d failure(s)" % [checks, failures])
	quit(1 if failures > 0 else 0)
