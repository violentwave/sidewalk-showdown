# ui_assets_test.gd — every file prepare_ui.gd expects exists in
# game/art/ui/ at its exact native size. The size table is not duplicated
# here: the test compiles art/tools/prepare_ui.gd (the same source the
# shim loads) and runs it in verify-only mode, so the manifest and the
# test can never drift apart.
extends SceneTree

var failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _check(label: String, condition: bool, detail: String = "") -> void:
	if condition:
		print("PASS: ", label)
	else:
		failures += 1
		print("FAIL: ", label, "  ", detail)


func _run() -> void:
	await process_frame
	var checks := 0

	# 1. The tool source loads and compiles.
	var repo_root := ProjectSettings.globalize_path("res://").trim_suffix("/").get_base_dir()
	var tool_path := repo_root.path_join("art/tools/prepare_ui.gd")
	var source := FileAccess.get_file_as_string(tool_path)
	_check("prepare_ui.gd exists in the repo", not source.is_empty(),
		"missing %s" % tool_path)
	if source.is_empty():
		_finish()
		return
	var script := GDScript.new()
	script.source_code = source
	var compiled: bool = script.reload() == OK
	_check("prepare_ui.gd compiles", compiled, "parse error in the tool")
	checks += 2
	if not compiled:
		_finish()
		return

	# 2. Every manifest entry exists in game/art/ui at the exact size.
	#    The tool prints the per-file detail; a clean run is all-or-nothing.
	var tool: RefCounted = script.new()
	var errors: int = tool.run(false)
	_check("every approved UI asset is in game/art/ui at its manifest size",
		errors == 0, "%d mismatching/missing file(s) — see the lines above" % errors)
	checks += 1

	# 3. The runtime copies are byte-identical to the approved sources.
	var runtime_root := ProjectSettings.globalize_path("res://art/ui")
	var approved_root := repo_root.path_join("art/source/UI/approved")
	var byte_errors := 0
	var compared := 0
	var groups := DirAccess.open(approved_root)
	if groups != null:
		for group in groups.get_directories():
			var group_dir := DirAccess.open(approved_root.path_join(group))
			if group_dir == null:
				continue
			for file_name in group_dir.get_files():
				if not file_name.to_lower().ends_with(".png"):
					continue
				var rel := "%s/%s" % [group, file_name]
				var approved_bytes := FileAccess.get_file_as_bytes(
					approved_root.path_join(rel))
				var runtime_bytes := FileAccess.get_file_as_bytes(
					runtime_root.path_join(rel))
				if approved_bytes != runtime_bytes:
					byte_errors += 1
					push_error("ui_assets: %s differs from its approved source" % rel)
				compared += 1
	_check("runtime UI art is byte-identical to the approved sources",
		byte_errors == 0 and compared > 0,
		"byte errors=%d compared=%d" % [byte_errors, compared])
	checks += 1

	print("ui_assets_test: %d checks, %d failure(s)" % [checks, failures])
	_finish()


func _finish() -> void:
	quit(1 if failures > 0 else 0)
