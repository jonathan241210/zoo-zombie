extends SceneTree
## Idempotent project setup: input map (keyboard/mouse + gamepad), autoloads,
## physics layer names and editor plugins. Re-run after changing defaults:
##   godot --headless --path . -s tools/setup_project.gd

const DEADZONE := 0.2
const LOOK_DEADZONE := 0.15
## Matches every keyboard/mouse/gamepad (InputEvent.device -1).
const ALL_DEVICES := -1

## Order matters: SettingsManager loads first so window/audio start with saved settings.
const AUTOLOADS: Array[Array] = [
	["SettingsManager", "res://scripts/autoload/settings_manager.gd"],
	["EventBus", "res://scripts/autoload/event_bus.gd"],
	["GameManager", "res://scripts/autoload/game_manager.gd"],
	["InputGlyphs", "res://scripts/autoload/input_glyphs.gd"],
	["SceneLoader", "res://scripts/autoload/scene_loader.gd"],
]

const UI_THEME := "res://scenes/ui/theme/ui_theme.tres"
const BUS_LAYOUT := "res://default_bus_layout.tres"
const TRANSLATIONS := [
	"res://localization/strings.es.translation",
	"res://localization/strings.en.translation",
]

const PHYSICS_LAYERS := {
	1: "world",
	2: "player",
	3: "zombies",
	4: "animals",
	5: "interactables",
	6: "pickups",
	7: "hurtboxes",
	8: "enclosures",
}


func _init() -> void:
	_setup_input()
	_setup_autoloads()
	_setup_layers()
	ProjectSettings.set_setting("gui/theme/custom", UI_THEME)
	ProjectSettings.set_setting("audio/buses/default_bus_layout", BUS_LAYOUT)
	ProjectSettings.set_setting("internationalization/locale/fallback", "es")
	ProjectSettings.set_setting("internationalization/locale/translations", PackedStringArray(TRANSLATIONS))
	ProjectSettings.set_setting("application/run/main_scene", "res://scenes/main/game.tscn")
	ProjectSettings.set_setting("editor_plugins/enabled", PackedStringArray(["res://addons/gut/plugin.cfg"]))
	var err := ProjectSettings.save()
	print("[setup_project] saved project.godot: ", error_string(err))
	quit(0 if err == OK else 1)


func _setup_input() -> void:
	_action("move_forward", DEADZONE, [_key(KEY_W), _axis(JOY_AXIS_LEFT_Y, -1.0)])
	_action("move_back", DEADZONE, [_key(KEY_S), _axis(JOY_AXIS_LEFT_Y, 1.0)])
	_action("move_left", DEADZONE, [_key(KEY_A), _axis(JOY_AXIS_LEFT_X, -1.0)])
	_action("move_right", DEADZONE, [_key(KEY_D), _axis(JOY_AXIS_LEFT_X, 1.0)])
	_action("look_up", LOOK_DEADZONE, [_axis(JOY_AXIS_RIGHT_Y, -1.0)])
	_action("look_down", LOOK_DEADZONE, [_axis(JOY_AXIS_RIGHT_Y, 1.0)])
	_action("look_left", LOOK_DEADZONE, [_axis(JOY_AXIS_RIGHT_X, -1.0)])
	_action("look_right", LOOK_DEADZONE, [_axis(JOY_AXIS_RIGHT_X, 1.0)])
	_action("sprint", DEADZONE, [_key(KEY_SHIFT), _button(JOY_BUTTON_LEFT_STICK)])
	_action("fire", DEADZONE, [_mouse(MOUSE_BUTTON_LEFT), _axis(JOY_AXIS_TRIGGER_RIGHT, 1.0)])
	_action("reload", DEADZONE, [_key(KEY_R), _button(JOY_BUTTON_X)])
	_action("interact", DEADZONE, [_key(KEY_E), _button(JOY_BUTTON_A)])
	_action("switch_weapon", DEADZONE, [
		_key(KEY_Q), _mouse(MOUSE_BUTTON_WHEEL_UP), _mouse(MOUSE_BUTTON_WHEEL_DOWN), _button(JOY_BUTTON_Y)])
	_action("weapon_1", DEADZONE, [_key(KEY_1)])
	_action("weapon_2", DEADZONE, [_key(KEY_2)])
	_action("pause", DEADZONE, [_key(KEY_ESCAPE), _button(JOY_BUTTON_START)])
	_action("ui_tab_prev", DEADZONE, [_key(KEY_Q), _button(JOY_BUTTON_LEFT_SHOULDER)])
	_action("ui_tab_next", DEADZONE, [_key(KEY_E), _button(JOY_BUTTON_RIGHT_SHOULDER)])


func _setup_autoloads() -> void:
	# Clear first so re-runs keep the declared order.
	for prop: Dictionary in ProjectSettings.get_property_list():
		var prop_name: String = prop["name"]
		if prop_name.begins_with("autoload/"):
			ProjectSettings.set_setting(prop_name, null)
	for entry: Array in AUTOLOADS:
		# Leading "*" registers the autoload as a singleton (global name).
		ProjectSettings.set_setting("autoload/" + String(entry[0]), "*" + String(entry[1]))


func _setup_layers() -> void:
	for layer: int in PHYSICS_LAYERS:
		ProjectSettings.set_setting("layer_names/3d_physics/layer_%d" % layer, PHYSICS_LAYERS[layer])


func _action(action_name: String, deadzone: float, events: Array) -> void:
	ProjectSettings.set_setting("input/" + action_name, {"deadzone": deadzone, "events": events})


func _key(keycode: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.device = ALL_DEVICES
	event.physical_keycode = keycode
	return event


func _mouse(button: MouseButton) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.device = ALL_DEVICES
	event.button_index = button
	return event


func _button(button: JoyButton) -> InputEventJoypadButton:
	var event := InputEventJoypadButton.new()
	event.device = ALL_DEVICES
	event.button_index = button
	return event


func _axis(axis: JoyAxis, value: float) -> InputEventJoypadMotion:
	var event := InputEventJoypadMotion.new()
	event.device = ALL_DEVICES
	event.axis = axis
	event.axis_value = value
	return event
