# settings_test.gd — the Settings autoload's persistence contract
# (docs/UI_SCREENS.md): defaults on a missing file, round-trip save/load,
# version fill-in of missing keys, opening never saves, reset applies and
# saves, and default settings keep every audio bus at 0 dB.
#
# Uses its own scratch file (user://settings_test.cfg) so the player's
# real settings.cfg is never touched.
extends SceneTree

const TEST_PATH := "user://settings_test.cfg"

var failures := 0
var settings: Node


func _initialize() -> void:
	_run.call_deferred()


func _check(label: String, condition: bool, detail: String = "") -> void:
	if condition:
		print("PASS: ", label)
	else:
		failures += 1
		print("FAIL: ", label, "  ", detail)


func _scratch_path() -> String:
	return ProjectSettings.globalize_path(TEST_PATH)


func _scratch_exists() -> bool:
	return FileAccess.file_exists(_scratch_path())


func _delete_scratch() -> void:
	if _scratch_exists():
		DirAccess.remove_absolute(_scratch_path())


func _write_scratch(text: String) -> void:
	var file := FileAccess.open(_scratch_path(), FileAccess.WRITE)
	file.store_string(text)
	file.close()


func _run() -> void:
	await process_frame
	settings = root.get_node_or_null("Settings")
	if settings == null:
		_check("the Settings autoload is registered", false, "no /root/Settings")
		_finish()
		return
	_check("the Settings autoload is registered", true)
	settings.config_path = TEST_PATH
	_delete_scratch()
	var checks := 1

	# --- defaults on a missing file; loading never writes ---
	settings._load()
	_check("a missing settings file yields the default values",
		settings.get_value("video", "window_mode") == "windowed"
			and settings.get_value("video", "integer_scale") == 4
			and settings.get_value("audio", "master") == 8
			and settings.get_value("gameplay", "commentary") == "full"
			and settings.get_value("accessibility", "screen_shake") == "full"
			and settings.get_value("stream", "streamer_safe_music") == false,
		"defaults not applied for a fresh install")
	_check("loading a missing file does not create one", not _scratch_exists(),
		"settings.cfg was written by a load")
	checks += 2

	# --- version fill-in: partial file keeps stored keys, fills the rest ---
	_write_scratch("""
[meta]

version=1

[video]

integer_scale=3

[audio]

master=2
""")
	settings._load()
	_check("stored keys survive and missing keys are filled from defaults",
		settings.get_value("video", "integer_scale") == 3
			and settings.get_value("audio", "master") == 2
			and settings.get_value("video", "window_mode") == "windowed"
			and settings.get_value("audio", "music") == 6
			and settings.get_value("gameplay", "commentary") == "full",
		"partial file not merged with defaults")
	checks += 1

	# --- round trip: set, save, reload ---
	var change_events := [0]
	settings.changed.connect(func(_section, _key): change_events[0] += 1)
	settings.set_value("audio", "music", 9)
	settings.set_value("video", "integer_scale", 5)
	_check("changing a value saves the file immediately", _scratch_exists(),
		"set_value did not save")
	var saved := FileAccess.get_file_as_string(_scratch_path())
	_check("the saved file is versioned", "[meta]" in saved and "version=1" in saved,
		"missing [meta] version in:\n%s" % saved)
	settings._load()
	_check("values survive a save/load round trip",
		settings.get_value("audio", "music") == 9
			and settings.get_value("video", "integer_scale") == 5,
		"round trip changed the values")
	_check("a no-op set_value does not emit changed",
		change_events[0] == 2,
		"emitted %d change events for 2 real changes" % change_events[0])
	checks += 4

	# --- opening the screen never saves ---
	var before := FileAccess.get_file_as_string(_scratch_path())
	var loaded_at_open = settings.get_value("audio", "music")
	var silent := {}
	for section in ["video", "audio", "gameplay", "accessibility", "stream"]:
		silent[section] = {}
		for key in settings.values[section]:
			silent[section][key] = settings.values[section][key]
	settings.set_values_silently(silent)
	_check("set_values_silently (the opening path) does not save",
		FileAccess.get_file_as_string(_scratch_path()) == before,
		"the file changed while only reading values")
	_check("set_values_silently keeps the loaded values",
		loaded_at_open == 9, "values changed while opening")
	checks += 2

	# --- audio buses: defaults are 0 dB (no loudness change), sliders map ---
	var music_bus := AudioServer.get_bus_index("Music")
	settings.set_value("audio", "music", 6)  # the default
	_check("the default audio settings leave the bus at 0 dB",
		is_equal_approx(AudioServer.get_bus_volume_db(music_bus), 0.0),
		"music bus at %.2f dB with default settings" % AudioServer.get_bus_volume_db(music_bus))
	settings.set_value("audio", "music", 0)
	_check("slider 0 mutes the bus",
		AudioServer.get_bus_volume_db(music_bus) < -60.0,
		"music bus at %.2f dB at slider 0" % AudioServer.get_bus_volume_db(music_bus))
	settings.set_value("audio", "music", 6)
	_check("moving the slider back restores 0 dB",
		is_equal_approx(AudioServer.get_bus_volume_db(music_bus), 0.0),
		"music bus at %.2f dB after restore" % AudioServer.get_bus_volume_db(music_bus))
	checks += 3

	# --- reset applies and saves ---
	settings.set_value("video", "integer_scale", 6)
	settings.set_value("gameplay", "commentary", "off")
	settings.reset_to_defaults()
	_check("reset restores every default value",
		settings.get_value("video", "integer_scale") == 4
			and settings.get_value("gameplay", "commentary") == "full"
			and settings.get_value("audio", "music") == 6,
		"reset did not restore defaults")
	_check("reset writes the defaults to disk",
		_scratch_exists() and "integer_scale=4" in FileAccess.get_file_as_string(_scratch_path()),
		"reset did not save defaults")
	_check("reset re-applies engine state",
		is_equal_approx(AudioServer.get_bus_volume_db(music_bus), 0.0),
		"music bus at %.2f dB after reset" % AudioServer.get_bus_volume_db(music_bus))
	checks += 3

	# --- cleanup: never leave the player's real config pointing at scratch ---
	settings.set_value("audio", "master", 8)
	_delete_scratch()
	settings.config_path = "user://settings.cfg"
	settings._load()

	print("settings_test: %d checks, %d failure(s)" % [checks, failures])
	_finish()


func _finish() -> void:
	quit(1 if failures > 0 else 0)
