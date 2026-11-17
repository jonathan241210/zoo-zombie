extends Node
## Loads, stores and applies player settings (user://settings.cfg).
## Sections: graphics, audio, controls, gameplay. Values apply immediately on set_value().

signal setting_changed(section: String, key: String, value: Variant)

const DEFAULT_PATH := "user://settings.cfg"
const BUS_NAMES: Dictionary = {
	"master_volume": &"Master",
	"music_volume": &"Music",
	"sfx_volume": &"SFX",
	"ui_volume": &"UI",
}
const RESOLUTIONS: Array[Vector2i] = [
	Vector2i(1280, 720), Vector2i(1280, 800), Vector2i(1600, 900), Vector2i(1920, 1080),
	Vector2i(1920, 1200), Vector2i(2560, 1440), Vector2i(3840, 2160),
]
const WINDOW_MODES: Array[String] = ["windowed", "fullscreen", "borderless"]
const MAX_FPS_OPTIONS: Array[int] = [30, 60, 120, 0]
const SHADOW_QUALITIES: Array[String] = ["low", "medium", "high"]
const ANTIALIASING_OPTIONS: Array[String] = ["off", "fxaa", "msaa2x"]
const UI_SCALES: Array[float] = [1.0, 1.25, 1.5]
const LANGUAGES: Array[String] = ["es", "en"]

## Default values per section (RF-70..RF-73).
const DEFAULTS: Dictionary = {
	"graphics": {
		"window_mode": "windowed",
		"resolution": Vector2i(1920, 1080),
		"vsync": true,
		"max_fps": 60,
		"shadow_quality": "medium",
		"render_scale": 1.0,
		"antialiasing": "fxaa",
		"brightness": 1.0,
	},
	"audio": {
		"master_volume": 1.0,
		"music_volume": 0.8,
		"sfx_volume": 1.0,
		"ui_volume": 1.0,
		"mute_on_focus_loss": true,
	},
	"controls": {
		"mouse_sensitivity": 1.0,
		"stick_sensitivity": 1.0,
		"invert_y_mouse": false,
		"invert_y_stick": false,
		"fov": 80.0,
		"vibration": true,
	},
	"gameplay": {
		"show_tips": true,
		"ui_scale": 1.0,
		"camera_shake": 1.0,
		"crosshair": true,
		"language": "es",
	},
}

## Overridable so tests never touch the real user file.
var config_path: String = DEFAULT_PATH

var _values: Dictionary = {}
var _focus_muted: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_settings()
	apply_all()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		if bool(get_value("audio", "mute_on_focus_loss")):
			_focus_muted = true
			_apply_audio()
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		_focus_muted = false
		_apply_audio()


func get_value(section: String, key: String) -> Variant:
	if _values.has(section) and (_values[section] as Dictionary).has(key):
		return _values[section][key]
	return get_default(section, key)


func get_default(section: String, key: String) -> Variant:
	if DEFAULTS.has(section) and (DEFAULTS[section] as Dictionary).has(key):
		return DEFAULTS[section][key]
	return null


func set_value(section: String, key: String, value: Variant) -> void:
	if not DEFAULTS.has(section) or not (DEFAULTS[section] as Dictionary).has(key):
		push_warning("SettingsManager: unknown setting %s/%s" % [section, key])
		return
	if not _values.has(section):
		_values[section] = {}
	_values[section][key] = value
	_apply(section, key)
	setting_changed.emit(section, key, value)


## Persists current values to config_path.
func save() -> Error:
	var cfg := ConfigFile.new()
	for section: String in DEFAULTS:
		for key: String in DEFAULTS[section]:
			cfg.set_value(section, key, get_value(section, key))
	return cfg.save(config_path)


## Reads config_path. Missing file or keys fall back to defaults. Does not apply values.
func load_settings() -> Error:
	_values.clear()
	var cfg := ConfigFile.new()
	var err := cfg.load(config_path)
	for section: String in DEFAULTS:
		_values[section] = {}
		for key: String in DEFAULTS[section]:
			var default_value: Variant = DEFAULTS[section][key]
			var value: Variant = cfg.get_value(section, key, default_value) if err == OK else default_value
			_values[section][key] = _coerce(value, default_value)
	return err


## Restores one section to defaults (applies and emits per key). Does not save.
func restore_defaults(section: String) -> void:
	if not DEFAULTS.has(section):
		return
	for key: String in DEFAULTS[section]:
		set_value(section, key, DEFAULTS[section][key])


func apply_all() -> void:
	for section: String in DEFAULTS:
		for key: String in DEFAULTS[section]:
			_apply(section, key)


## Keeps loaded values type-safe: a wrongly typed value in the file reverts to the default.
func _coerce(value: Variant, default_value: Variant) -> Variant:
	if typeof(value) == typeof(default_value):
		return value
	if typeof(default_value) == TYPE_FLOAT and typeof(value) == TYPE_INT:
		return float(value)
	return default_value


func _apply(section: String, key: String) -> void:
	match section:
		"graphics":
			_apply_graphics(key)
		"audio":
			_apply_audio()
		"gameplay":
			if key == "language":
				TranslationServer.set_locale(str(get_value("gameplay", "language")))
		# controls and brightness are read by gameplay code / levels via get_value + setting_changed.


func _apply_graphics(key: String) -> void:
	var root: Window = get_tree().root if is_inside_tree() else null
	match key:
		"window_mode", "resolution":
			_apply_window()
		"vsync":
			DisplayServer.window_set_vsync_mode(
				DisplayServer.VSYNC_ENABLED if bool(get_value("graphics", "vsync")) else DisplayServer.VSYNC_DISABLED)
		"max_fps":
			Engine.max_fps = int(get_value("graphics", "max_fps"))
		"shadow_quality":
			var quality: int = clampi(SHADOW_QUALITIES.find(str(get_value("graphics", "shadow_quality"))), 0, 2)
			var sizes: Array[int] = [1024, 2048, 4096]
			var filters: Array[RenderingServer.ShadowQuality] = [
				RenderingServer.SHADOW_QUALITY_SOFT_LOW,
				RenderingServer.SHADOW_QUALITY_SOFT_MEDIUM,
				RenderingServer.SHADOW_QUALITY_SOFT_HIGH,
			]
			RenderingServer.directional_shadow_atlas_set_size(sizes[quality], true)
			RenderingServer.directional_soft_shadow_filter_set_quality(filters[quality])
			RenderingServer.positional_soft_shadow_filter_set_quality(filters[quality])
		"render_scale":
			if root:
				root.scaling_3d_scale = clampf(float(get_value("graphics", "render_scale")), 0.5, 1.0)
		"antialiasing":
			if root:
				var mode: String = str(get_value("graphics", "antialiasing"))
				root.screen_space_aa = (
					Viewport.SCREEN_SPACE_AA_FXAA if mode == "fxaa" else Viewport.SCREEN_SPACE_AA_DISABLED)
				root.msaa_3d = Viewport.MSAA_2X if mode == "msaa2x" else Viewport.MSAA_DISABLED
		# "brightness": exposed via get_value + setting_changed; levels apply it to their Environment.


func _apply_window() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var mode: String = str(get_value("graphics", "window_mode"))
	var resolution: Vector2i = get_value("graphics", "resolution")
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, mode == "borderless")
	match mode:
		"fullscreen":
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
		"borderless":
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_size(DisplayServer.screen_get_size())
			DisplayServer.window_set_position(DisplayServer.screen_get_position())
		_:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_size(resolution)


func _apply_audio() -> void:
	for key: String in BUS_NAMES:
		var bus: int = AudioServer.get_bus_index(BUS_NAMES[key])
		if bus < 0:
			continue
		var volume: float = clampf(float(get_value("audio", key)), 0.0, 1.0)
		AudioServer.set_bus_volume_db(bus, linear_to_db(volume))
		AudioServer.set_bus_mute(bus, _focus_muted or volume <= 0.0)
