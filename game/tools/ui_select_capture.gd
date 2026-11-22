# Dev tool: capture the PR A select-screen screenshots (docs/UI_SCREENS.md)
# at 320x180 into docs/assets/ui/ by driving the REAL scenes — mode select,
# difficulty, character select (solo P1 and versus both cursors), and
# stage select (first stage and RANDOM focused).
#
# Usage (needs a display, or xvfb-run):
#   DISPLAY=:0 godot --path game --resolution 1280x720 \
#       --script res://tools/ui_select_capture.gd
#
# The capture is nearest-neighbour resized to 320x180 so the committed PNG
# is exactly native resolution regardless of the window scale.
extends SceneTree

const MODE_SCENE := preload("res://scenes/menus/ModeSelect.tscn")
const DIFFICULTY_SCENE := preload("res://scenes/menus/DifficultySelect.tscn")
const CHARACTER_SCENE := preload("res://scenes/menus/CharacterSelect.tscn")
const STAGE_SCENE := preload("res://scenes/menus/StageSelect.tscn")


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


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(_out_dir())
	await process_frame

	var mode := MODE_SCENE.instantiate()
	await _open(mode, 10)
	await _grab("mode_select")
	mode.free()
	await process_frame

	var difficulty := DIFFICULTY_SCENE.instantiate()
	await _open(difficulty, 10)
	await _grab("difficulty")
	difficulty.free()
	await process_frame

	var solo: Control = CHARACTER_SCENE.instantiate()
	solo.solo = true
	await _open(solo, 10)
	await _grab("character_select_p1")
	solo.free()
	await process_frame

	var both: Control = CHARACTER_SCENE.instantiate()
	both.solo = false
	await _open(both, 10)
	await _grab("character_select_both")
	both.free()
	await process_frame

	var stages := STAGE_SCENE.instantiate()
	await _open(stages, 10)
	await _grab("stage_select")

	stages.index = stages.random_index()
	stages._refresh()
	await _grab("stage_select_random")
	stages.free()
	await process_frame

	quit()
