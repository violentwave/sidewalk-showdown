# Settings — persistent user preferences (docs/UI_SCREENS.md §Settings).
# Autoload registered in project.godot as "Settings". Pure presentation:
# nothing here ever touches the 60 Hz simulation or match serialization.
#
# Storage: user://settings.cfg via ConfigFile, [meta] version = 1, one
# section per settings tab. Missing keys (old saves, new installs) are
# filled from DEFAULTS on load; loading never writes the file, changing a
# value applies it, saves, and emits `changed(section, key)`.
extends Node

signal changed(section: String, key: String)

const CONFIG_VERSION := 1
const CONFIG_PATH := "user://settings.cfg"

# Defaults double as the schema: section -> key -> value.
const DEFAULTS := {
	"video": {
		# windowed | fullscreen (borderless)
		"window_mode": "windowed",
		# 2..6
		"integer_scale": 4,
		"vsync": true,
	},
	"audio": {
		# Sliders 0-10. A bus at its default value sits at exactly 0 dB so
		# defaults never change the mix; 0 mutes the bus.
		"master": 8,
		"music": 6,
		"sfx": 8,
		"voice": 8,
		"ui": 6,
		"mute_when_unfocused": true,
	},
	"gameplay": {
		# off | p1 | both
		"input_display": "off",
		# full | minimal | off
		"commentary": "full",
		"show_combo_damage": true,
	},
	"accessibility": {
		"reduce_flashing": false,
		# off | low | full
		"screen_shake": "full",
		"high_contrast_hud": false,
		"readable_font": false,
		"hold_to_confirm_meth": false,
	},
	"stream": {
		"streamer_safe_music": false,
		"hide_tripp_text": false,
	},
}

# Overridable so tests can point at a scratch file.
var config_path := CONFIG_PATH
# Live values: a deep copy of DEFAULTS merged over the file contents.
var values := {}


func _ready() -> void:
	# Boot: load and apply before the first screen exists.
	_load()
	_apply_all()


func get_value(section: String, key: String):
	_ensure_loaded()
	if values.has(section) and values[section].has(key):
		return values[section][key]
	return DEFAULTS[section][key]


func set_value(section: String, key: String, value) -> void:
	_ensure_loaded()
	if values[section][key] == value:
		return
	values[section][key] = value
	_apply(section, key)
	save()
	changed.emit(section, key)


func set_values_silently(new_values: Dictionary) -> void:
	# Opening the settings screen uses this: control values are written
	# into the live state without applying/saving/emitting, so filling
	# sliders cannot count as the player moving them.
	for section in new_values:
		for key in new_values[section]:
			values[section][key] = new_values[section][key]


func reset_to_defaults() -> void:
	_ensure_loaded()
	# Reset, apply, then save (docs/UI_HUD_SCREENS_PLAN.md rules).
	values = _deep_copy_defaults()
	_apply_all()
	save()
	for section in values:
		for key in values[section]:
			changed.emit(section, key)


func _ensure_loaded() -> void:
	# Autoload _ready may not have run yet (headless test harnesses can
	# reach in during _initialize); values is never empty after a load.
	if values.is_empty():
		_load()


func _load() -> void:
	values = _deep_copy_defaults()
	var file := ConfigFile.new()
	if file.load(config_path) != OK:
		return  # fresh install: defaults, and opening never saves
	for section in DEFAULTS:
		for key in DEFAULTS[section]:
			if file.has_section_key(section, key):
				values[section][key] = file.get_value(section, key)
			# else: missing key keeps its default (version fill-in)


func save() -> void:
	_ensure_loaded()
	var file := ConfigFile.new()
	file.set_value("meta", "version", CONFIG_VERSION)
	for section in values:
		for key in values[section]:
			file.set_value(section, key, values[section][key])
	var err := file.save(config_path)
	if err != OK:
		push_error("Settings: cannot save %s (error %d)" % [config_path, err])


func _apply_all() -> void:
	for section in values:
		for key in values[section]:
			_apply(section, key)


func _apply(section: String, key: String) -> void:
	var value = values[section][key]
	match section:
		"audio":
			_apply_audio(key, value)
		"video":
			_apply_video(key, value)
		_:
			# gameplay / accessibility / stream keys are stored now and
			# consumed when their screens exist (Phase 2+); docs/UI_SCREENS.md
			# tracks which ones are not yet wired.
			pass


func _apply_audio(key: String, value) -> void:
	var bus_name := key.capitalize()
	if key == "mute_when_unfocused":
		# Handled live in _notification below.
		return
	if not AudioServer.get_bus_index(bus_name) >= 0:
		return
	var index := AudioServer.get_bus_index(bus_name)
	var default: int = DEFAULTS["audio"][key]
	# value/default = 1.0 at the default slider position -> 0 dB, so the
	# default settings never change the mix. 0 mutes.
	var linear: float = clampf(float(value) / float(default), 0.0, 2.0)
	AudioServer.set_bus_volume_db(index, linear_to_db(linear) if linear > 0.0 else -80.0)


func _apply_video(key: String, value) -> void:
	match key:
		"window_mode":
			var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if value == "fullscreen" \
				else DisplayServer.WINDOW_MODE_WINDOWED
			DisplayServer.window_set_mode(mode)
		"integer_scale":
			if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED:
				var scale: int = clampi(int(value), 2, 6)
				DisplayServer.window_set_size(Vector2i(320 * scale, 180 * scale))
		"vsync":
			DisplayServer.window_set_vsync_mode(
				DisplayServer.VSYNC_ENABLED if value else DisplayServer.VSYNC_DISABLED)


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and values.has("audio"):
		if values["audio"]["mute_when_unfocused"]:
			AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), true)
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN and values.has("audio"):
		AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), false)


func _deep_copy_defaults() -> Dictionary:
	var copy := {}
	for section in DEFAULTS:
		copy[section] = {}
		for key in DEFAULTS[section]:
			copy[section][key] = DEFAULTS[section][key]
	return copy
