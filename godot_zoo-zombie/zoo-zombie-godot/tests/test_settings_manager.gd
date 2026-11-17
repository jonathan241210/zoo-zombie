extends GutTest
## SettingsManager: defaults, set/get, persistence, signals and restore. Uses a temp file.

const TEST_PATH := "user://test_settings.cfg"
const SettingsScript := preload("res://scripts/autoload/settings_manager.gd")

var _settings: Node


func before_each() -> void:
	_settings = SettingsScript.new()
	_settings.config_path = TEST_PATH
	add_child_autofree(_settings)


func after_each() -> void:
	DirAccess.remove_absolute(TEST_PATH)
	TranslationServer.set_locale("es")


func test_defaults() -> void:
	assert_eq(_settings.get_value("graphics", "max_fps"), 60)
	assert_eq(_settings.get_value("graphics", "render_scale"), 1.0)
	assert_eq(_settings.get_value("controls", "fov"), 80.0)
	assert_eq(_settings.get_value("gameplay", "language"), "es")
	assert_true(_settings.get_value("audio", "mute_on_focus_loss"))
	assert_eq(_settings.get_value("gameplay", "ui_scale"), 1.0)


func test_set_and_get() -> void:
	_settings.set_value("controls", "mouse_sensitivity", 1.75)
	assert_eq(_settings.get_value("controls", "mouse_sensitivity"), 1.75)


func test_unknown_key_is_ignored() -> void:
	_settings.set_value("controls", "nope", 1)
	assert_null(_settings.get_value("controls", "nope"))
	assert_push_warning_count(1)


func test_signal_emitted() -> void:
	watch_signals(_settings)
	_settings.set_value("audio", "sfx_volume", 0.3)
	assert_signal_emitted_with_parameters(_settings, "setting_changed", ["audio", "sfx_volume", 0.3])


func test_save_load_roundtrip() -> void:
	_settings.set_value("graphics", "resolution", Vector2i(1280, 720))
	_settings.set_value("gameplay", "language", "en")
	_settings.set_value("controls", "invert_y_stick", true)
	assert_eq(_settings.save(), OK)
	_settings.restore_defaults("graphics")
	_settings.restore_defaults("gameplay")
	_settings.restore_defaults("controls")
	assert_eq(_settings.load_settings(), OK)
	assert_eq(_settings.get_value("graphics", "resolution"), Vector2i(1280, 720))
	assert_eq(_settings.get_value("gameplay", "language"), "en")
	assert_true(_settings.get_value("controls", "invert_y_stick"))


func test_restore_defaults_only_affects_section() -> void:
	_settings.set_value("audio", "music_volume", 0.1)
	_settings.set_value("controls", "fov", 95.0)
	_settings.restore_defaults("audio")
	assert_eq(_settings.get_value("audio", "music_volume"), 0.8)
	assert_eq(_settings.get_value("controls", "fov"), 95.0)


func test_wrong_type_in_file_falls_back_to_default() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("controls", "fov", "wide")
	cfg.save(TEST_PATH)
	_settings.load_settings()
	assert_eq(_settings.get_value("controls", "fov"), 80.0)


func test_language_applies_to_translation_server() -> void:
	_settings.set_value("gameplay", "language", "en")
	assert_eq(TranslationServer.get_locale(), "en")


func test_audio_buses_exist() -> void:
	for bus_name in ["Master", "Music", "SFX", "UI"]:
		assert_gt(AudioServer.get_bus_index(bus_name), -1, bus_name)
