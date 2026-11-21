# Game-side entry point for art/tools/prepare_ui.gd (docs/UI_ASSETS.md §2).
# Godot only executes scripts under res://, so this shim compiles and runs
# the canonical tool that lives outside the game project:
#
#   godot --headless --path game --script res://tools/prepare_ui.gd
#
# Copies art/source/UI/approved/<group>/*.png to game/art/ui/<group>/
# unchanged and verifies each size. Exits 1 on any mismatch or gap.
extends SceneTree

func _initialize() -> void:
	var repo_root := ProjectSettings.globalize_path("res://").trim_suffix("/").get_base_dir()
	var tool_path := repo_root.path_join("art/tools/prepare_ui.gd")
	var source := FileAccess.get_file_as_string(tool_path)
	if source.is_empty():
		push_error("prepare_ui: cannot read %s" % tool_path)
		quit(1)
		return
	var script := GDScript.new()
	script.source_code = source
	if script.reload() != OK:
		push_error("prepare_ui: cannot compile %s" % tool_path)
		quit(1)
		return
	var tool: RefCounted = script.new()
	var errors: int = tool.run()
	quit(1 if errors > 0 else 0)
