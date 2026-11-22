# Dev tool: capture the UI Phase 3b screenshots (docs/UI_SCREENS.md) at
# 320x180 into docs/assets/ui/ — the VS bumper after the slide-in, and the
# Results screen (default REMATCH focus and STAGE SELECT focus).
#
# Usage (needs a display, or xvfb-run):
#   DISPLAY=:0 godot --path game --resolution 1280x720 \
#       --script res://tools/ui_match_capture.gd
#
# The capture is nearest-neighbour resized to 320x180 so the committed PNG
# is exactly native resolution regardless of the window scale.
extends SceneTree

const VS_SCENE := preload("res://scenes/menus/vs_screen.tscn")
const RESULTS_SCENE := preload("res://scenes/menus/results_screen.tscn")
const ROSTER := preload("res://resources/match_roster.tres")


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


func _open(scene: Node, frames: int) -> void:
	root.add_child(scene)
	for i in frames:
		await physics_frame


func _results_scene(focus_index: int) -> Control:
	var results: Control = RESULTS_SCENE.instantiate()
	results.stage = ROSTER.stages[0]
	results.winner_data = ROSTER.fighters[0]
	results.stats = {
		"wins": [2, 1],
		"winner": 0,
		"damage": [1842.0, 1503.0],
		"max_combo": [8, 6],
		"meth_used": [true, false],
		"time_left_frames": 37 * 60,
	}
	results.index = focus_index
	return results


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(_out_dir())
	await process_frame

	# 1. VS bumper after the 12-frame slide-in.
	var vs: Control = VS_SCENE.instantiate()
	vs.p1_data = ROSTER.fighters[0]
	vs.p2_data = ROSTER.fighters[1]
	await _open(vs, 14)
	await _grab("vs_screen")
	vs.free()
	await process_frame

	# 2. Results, REMATCH focused (the default).
	var results: Control = _results_scene(0)
	await _open(results, 10)
	await _grab("results")
	results.index = 2
	results._refresh()
	await _grab("results_rematch_focus")
	results.free()
	await process_frame

	quit()
