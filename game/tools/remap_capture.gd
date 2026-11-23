# Capture the real Settings → CONTROLS overlay at native resolution.
#
# Usage (needs a display):
#   DISPLAY=:0 godot --path game --resolution 1280x720 \
#       --script res://tools/remap_capture.gd
extends SceneTree

const MENU_SCENE := preload("res://scenes/menus/main_menu.tscn")
const SETTINGS_SCENE := preload("res://scenes/menus/settings_overlay.tscn")


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await process_frame
	var settings_autoload := root.get_node_or_null("Settings")
	if settings_autoload != null and settings_autoload.controls != null:
		# The documentation capture is the shipped layout, regardless of
		# per-machine overrides. This changes only this capture process.
		settings_autoload.controls.bindings = \
			settings_autoload.controls.defaults.duplicate(true)
		settings_autoload.controls._apply_bindings()

	var menu := MENU_SCENE.instantiate()
	root.add_child(menu)
	await process_frame
	var overlay := SETTINGS_SCENE.instantiate()
	root.add_child(overlay)
	await process_frame
	overlay.tab_index = 5
	overlay.row_index = 0
	overlay._refresh()
	await process_frame
	await RenderingServer.frame_post_draw

	var image := root.get_texture().get_image()
	if image.get_width() != 320 or image.get_height() != 180:
		image.resize(320, 180, Image.INTERPOLATE_NEAREST)
	var output := ProjectSettings.globalize_path(
		"res://../docs/assets/ui/settings_controls.png")
	DirAccess.make_dir_recursive_absolute(output.get_base_dir())
	var error := image.save_png(output)
	if error != OK:
		push_error("Could not save Controls capture: %s" % output)
	else:
		print("saved ", output)
	quit(1 if error != OK else 0)
