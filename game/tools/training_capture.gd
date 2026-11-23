# Dev tool: capture the training-mode README screenshot (docs/UI_SCREENS.md
# "Training") at 320x180 into docs/assets/ui/ — a real training match with
# the readout plate populated (a landed light's damage and frame advantage,
# the dummy's juggle budget), the infinity clock, and the debug boxes off.
#
# Usage (needs a display, or xvfb-run):
#   DISPLAY=:0 godot --path game --resolution 1280x720 \
#       --script res://tools/training_capture.gd
extends SceneTree

const MATCH_SCENE := preload("res://scenes/match/MatchRoot.tscn")
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


func _step(frames: int) -> void:
	for _frame in frames:
		await physics_frame


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(_out_dir())
	await process_frame
	var mroot: Node = MATCH_SCENE.instantiate()
	mroot.selected_p1_data = ROSTER.fighters[0]
	mroot.selected_p2_data = ROSTER.fighters[1]
	mroot.selected_stage = ROSTER.stages[0]
	mroot.training_mode = true
	root.add_child(mroot)
	# The shipped HUD, not the F1 boxes (training starts with them off, but
	# pin it so a future default change cannot leak into the capture).
	if mroot.debug_overlay != null:
		mroot.debug_overlay.show_boxes = false
	await _step(4)

	# Populate the readout: land Peggy's standing light on the dummy.
	var p1: FighterBase = mroot.p1
	var p2: FighterBase = mroot.p2
	p1.position = Vector2(120, mroot.stage.floor_y)
	p2.position = Vector2(146, mroot.stage.floor_y)
	p1.velocity = Vector2.ZERO
	p2.velocity = Vector2.ZERO
	p1.facing = 1
	p2.facing = -1
	p1.reset_state()
	p2.reset_state()
	var light: MoveData = p1.data.find_move(
		MoveData.InputType.LIGHT, MoveData.Stance.STAND)
	p1._start_move(light)
	await _step(18)
	# Second hit keeps the existing #96 combo counter visible so the
	# training capture shows both the extra panel and the reused readout.
	p1._start_move(light)
	await _step(8)
	await _grab("training")
	mroot.free()
	await process_frame
	quit()
