# Capture the owner playtest fixes as one side-by-side composite. Each half
# is a real 320x180 scene capture: versus HUD (full meters + METHtality
# banner) and Results (winner banner, TOTAL DMG stats, prompt).
#
# Usage (needs a display):
#   DISPLAY=:0 godot --path game --resolution 1280x720 \
#       --script res://tools/ui_playtest_capture.gd
extends SceneTree

const MATCH_SCENE := preload("res://scenes/match/MatchRoot.tscn")
const RESULTS_SCENE := preload("res://scenes/menus/results_screen.tscn")
const ROSTER := preload("res://resources/match_roster.tres")


func _initialize() -> void:
	_run.call_deferred()


func _capture_frame() -> Image:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image.get_width() != 320 or image.get_height() != 180:
		image.resize(320, 180, Image.INTERPOLATE_NEAREST)
	image.convert(Image.FORMAT_RGBA8)
	return image


func _run() -> void:
	await process_frame

	# Left half: live versus HUD, full meters, and the longest authored
	# METHtality title/subtitle combination.
	var match_root: Node = MATCH_SCENE.instantiate()
	match_root.selected_p1_data = ROSTER.fighters[0]
	match_root.selected_p2_data = ROSTER.fighters[1]
	match_root.selected_stage = ROSTER.stages[0]
	root.add_child(match_root)
	for _frame in 140:
		await physics_frame
	match_root.p1.add_meter(100.0)
	match_root.p2.add_meter(100.0)
	match_root.hud.show_banner("methtality", "WALK THE PLANK")
	for _frame in 8:
		match_root.hud.sim_tick()
	var hud_frame := await _capture_frame()
	match_root.free()
	await process_frame

	# Right half: Results with long match-total damage and all stat rows.
	var results: Control = RESULTS_SCENE.instantiate()
	results.stats = {
		"wins": [2, 1],
		"winner": 0,
		"damage": [2000.0, 717.0],
		"max_combo": [7, 3],
		"meth_used": [true, false],
		"time_left_frames": 1234,
	}
	results.winner_data = ROSTER.fighters[1]
	results.stage = ROSTER.stages[0]
	root.add_child(results)
	await process_frame
	await process_frame
	var results_frame := await _capture_frame()
	results.free()
	await process_frame

	var composite := Image.create(640, 180, false, Image.FORMAT_RGBA8)
	composite.blit_rect(hud_frame, Rect2i(0, 0, 320, 180), Vector2i(0, 0))
	composite.blit_rect(results_frame, Rect2i(0, 0, 320, 180), Vector2i(320, 0))
	var output := ProjectSettings.globalize_path(
		"res://../docs/assets/ui/uifix_playtest.png")
	DirAccess.make_dir_recursive_absolute(output.get_base_dir())
	var error := composite.save_png(output)
	if error != OK:
		push_error("Could not save UI playtest composite: %s" % output)
	else:
		print("saved ", output, " ", composite.get_width(), "x",
			composite.get_height())
	quit(1 if error != OK else 0)
