# Dev tool: capture the UI Phase 2 HUD screenshots (docs/UI_SCREENS.md)
# at 320x180 into docs/assets/ui/ by driving a real match — round start,
# FIGHT, a mid-fight exchange (combo + ghost + callout), low health with
# the hurt portrait, METH READY, a KO, and the high-contrast setting.
#
# Usage (needs a display, or xvfb-run):
#   DISPLAY=:0 godot --path game --resolution 1280x720 \
#       --script res://tools/ui_hud_capture.gd
#
# The capture is nearest-neighbour resized to 320x180 so the committed PNG
# is exactly native resolution regardless of the window scale. The
# Settings autoload is pointed at a scratch file for the high-contrast
# frame; the player's settings.cfg is never touched.
extends SceneTree

const MATCH_SCENE := preload("res://scenes/match/MatchRoot.tscn")
const ROSTER := preload("res://resources/match_roster.tres")
const SCRATCH_CONFIG := "user://settings_hud_capture.cfg"


func _initialize() -> void:
	_run.call_deferred()


func _out_dir() -> String:
	var game_dir := ProjectSettings.globalize_path("res://")
	while game_dir.ends_with("/"):
		game_dir = game_dir.substr(0, game_dir.length() - 1)
	return game_dir.get_base_dir() + "/docs/assets/ui"


func _grab(tag: String) -> void:
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	if img.get_width() != 320 or img.get_height() != 180:
		img.resize(320, 180, Image.INTERPOLATE_NEAREST)
	var path := "%s/%s.png" % [_out_dir(), tag]
	img.save_png(path)
	print("saved ", path)


func _step(frames: int) -> void:
	for _frame in frames:
		await physics_frame


func _new_match() -> Node:
	var match_root: Node = MATCH_SCENE.instantiate()
	match_root.selected_p1_data = ROSTER.fighters[0]
	match_root.selected_p2_data = ROSTER.fighters[1]
	match_root.selected_stage = ROSTER.stages[0]
	root.add_child(match_root)
	await _step(1)
	return match_root


func _place_pair(match_root: Node) -> void:
	var p1: FighterBase = match_root.p1
	var p2: FighterBase = match_root.p2
	p1.position = Vector2(120, 150)
	p2.position = Vector2(146, 150)
	p1.velocity = Vector2.ZERO
	p2.velocity = Vector2.ZERO
	p1.facing = 1
	p2.facing = -1
	p1.reset_state()
	p2.reset_state()


func _light(p1: FighterBase) -> void:
	p1._start_move(p1.data.find_move(MoveData.InputType.LIGHT, MoveData.Stance.STAND))


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(_out_dir())
	await process_frame
	var settings: Node = root.get_node_or_null("Settings")
	var original_path: String = settings.config_path if settings != null else ""
	if settings != null:
		settings.config_path = SCRATCH_CONFIG
		settings._load()

	# 1. Round start: the ROUND 1 banner stamping in.
	var match_root: Node = await _new_match()
	await _step(4)
	await _grab("hud_round_start")

	# 2. FIGHT! right after the fight starts.
	for _wait in 70:
		await physics_frame
		if match_root.hud.banner_id == "fight":
			break
	await _grab("hud_fight")

	# 3. Mid-fight: a damaged P2 with the ghost lagging, a combo counter
	# with its damage, and a callout on P1's side.
	_place_pair(match_root)
	var p1: FighterBase = match_root.p1
	var p2: FighterBase = match_root.p2
	p2.health = 420.0
	p2.health_changed.emit(p2.health, p2.max_health)
	_light(p1)
	await _step(24)
	p1.combo_tracker.record("probe_a", 120.0)
	p1.combo_tracker.record("probe_b", 80.0)
	p1.combo_changed.emit(2)
	p1.counter_hit_landed.emit()
	await _step(8)
	await _grab("hud_midfight")

	# 4. Low health: the hurt portrait and the pulse.
	p2.health = 150.0
	p2.health_changed.emit(p2.health, p2.max_health)
	await _step(4)
	await _grab("hud_low_health")

	# 5. METH READY on P1's side.
	p1.add_meter(100.0)
	await _step(4)
	await _grab("hud_meth_ready")

	# 6. KO: force the round end.
	p1.add_meter(-100.0)
	p2.health = 1.0
	p2.health_changed.emit(p2.health, p2.max_health)
	_place_pair(match_root)
	_light(p1)
	await _step(24)
	await _grab("hud_ko")
	match_root.free()
	await process_frame

	# 7. High contrast: a fresh match with the setting on.
	if settings != null:
		settings.set_value("accessibility", "high_contrast_hud", true)
	match_root = await _new_match()
	await _step(30)
	await _grab("hud_high_contrast")
	match_root.free()
	await process_frame

	if settings != null:
		settings.config_path = original_path
		settings._load()
		var scratch := ProjectSettings.globalize_path(SCRATCH_CONFIG)
		if FileAccess.file_exists(scratch):
			DirAccess.remove_absolute(scratch)
	quit()
