# Dev tool: capture the Phase 1 polish screenshots (docs/UI_SCREENS.md) at
# 320x180 into docs/assets/ui/ by driving the REAL scenes — content
# warning, title, main menu (default and QUIT focus), settings (Video and
# Audio tabs), pause menu, quit confirm.
#
# Usage (needs a display):
#   DISPLAY=:0 godot --path game --resolution 1280x720 \
#       --script res://tools/ui_polish_capture.gd
#
# The capture is nearest-neighbour resized to 320x180 so the committed PNG
# is exactly native resolution regardless of the window scale.
extends SceneTree

const WARNING_SCENE := preload("res://scenes/menus/content_warning.tscn")
const TITLE_SCENE := preload("res://scenes/menus/title.tscn")
const MENU_SCENE := preload("res://scenes/menus/main_menu.tscn")
const SETTINGS_SCENE := preload("res://scenes/menus/settings_overlay.tscn")
const QUIT_SCENE := preload("res://scenes/menus/quit_confirm.tscn")
const MATCH_SCENE := preload("res://scenes/match/MatchRoot.tscn")


func _initialize() -> void:
	_run.call_deferred()


func _out_dir() -> String:
	# res:// globalizes to <repo>/game (with a trailing slash); the docs
	# folder is a sibling of the game dir.
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

	# 1. Content warning (past the 30-frame guard, waiting for the press).
	var warning := WARNING_SCENE.instantiate()
	await _open(warning, 40)
	await _grab("content_warning")
	warning.free()
	await process_frame

	# 2. Title (PRESS START is visible during the first pulse second).
	var title := TITLE_SCENE.instantiate()
	await _open(title, 30)
	await _grab("title")
	title.free()
	await process_frame

	# 3. Main menu, VERSUS focused.
	var menu := MENU_SCENE.instantiate()
	await _open(menu, 10)
	await _grab("main_menu")

	# 3b. Main menu with SETTINGS focused (yellow bar on the third slat).
	menu.index = 2
	menu._refresh()
	await _grab("main_menu_settings")

	# 4. Main menu with QUIT focused (the taped pole button).
	menu.index = 4
	menu._refresh()
	await _grab("main_menu_quit")
	menu.free()
	await process_frame

	# 5-7. Settings overlay: Video, Audio, then Gameplay tabs.
	var settings := SETTINGS_SCENE.instantiate()
	await _open(settings, 10)
	await _grab("settings_video")
	settings.tab_index = 1
	settings._refresh()
	await _grab("settings_audio")
	settings.tab_index = 2
	settings._refresh()
	await _grab("settings_gameplay")
	settings.free()
	await process_frame

	# 7. Pause menu over a live match.
	var match_root := MATCH_SCENE.instantiate()
	await _open(match_root, 120)
	match_root._toggle_pause()
	await _grab("pause")
	match_root._unpause()
	match_root.free()
	await process_frame

	# 8. Quit confirm (defaults to NO).
	var quit := QUIT_SCENE.instantiate()
	await _open(quit, 10)
	await _grab("quit_confirm")
	quit.free()
	await process_frame

	quit()
