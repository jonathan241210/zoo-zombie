extends Node
## Tracks the last used input device and resolves input icons / text labels per action.
## Reads the CURRENT InputMap, so remapped actions update automatically.
## Icons: Kenney "Input Prompts" (CC0) under res://assets/ui/glyphs/{keyboard,xbox,playstation}/.
## Missing PNGs are not an error: get_glyph() returns null and get_label() gives text.

signal device_changed(device: StringName)

const DEVICE_KEYBOARD_MOUSE := &"keyboard_mouse"
const DEVICE_XBOX := &"xbox"
const DEVICE_PLAYSTATION := &"playstation"
const GLYPH_DIR := "res://assets/ui/glyphs/"
const PLAYSTATION_NAME_HINTS: Array[String] = ["ps", "dualsense", "dualshock", "playstation"]
const STICK_AXIS_DEADZONE := 0.5

const KEY_STEMS: Dictionary = {
	KEY_ESCAPE: "escape", KEY_ENTER: "enter", KEY_KP_ENTER: "enter", KEY_SHIFT: "shift", KEY_SPACE: "space",
	KEY_UP: "arrow_up", KEY_DOWN: "arrow_down", KEY_LEFT: "arrow_left", KEY_RIGHT: "arrow_right",
}
const MOUSE_STEMS: Dictionary = {
	MOUSE_BUTTON_LEFT: "mouse_left", MOUSE_BUTTON_RIGHT: "mouse_right",
	MOUSE_BUTTON_WHEEL_UP: "mouse_scroll", MOUSE_BUTTON_WHEEL_DOWN: "mouse_scroll",
}
## Joypad button -> [xbox stem, playstation stem, text label xbox, text label playstation].
const JOY_BUTTONS: Dictionary = {
	JOY_BUTTON_A: ["button_a", "button_cross", "A", "Cross"],
	JOY_BUTTON_B: ["button_b", "button_circle", "B", "Circle"],
	JOY_BUTTON_X: ["button_x", "button_square", "X", "Square"],
	JOY_BUTTON_Y: ["button_y", "button_triangle", "Y", "Triangle"],
	JOY_BUTTON_LEFT_SHOULDER: ["lb", "l1", "LB", "L1"],
	JOY_BUTTON_RIGHT_SHOULDER: ["rb", "r1", "RB", "R1"],
	JOY_BUTTON_LEFT_STICK: ["stick_l_press", "stick_l_press", "L3", "L3"],
	JOY_BUTTON_RIGHT_STICK: ["stick_r_press", "stick_r_press", "R3", "R3"],
	JOY_BUTTON_START: ["button_start", "button_options", "Start", "Options"],
	JOY_BUTTON_BACK: ["button_select", "button_share", "Select", "Share"],
	JOY_BUTTON_DPAD_UP: ["dpad_up", "dpad_up", "D-Pad Up", "D-Pad Up"],
	JOY_BUTTON_DPAD_DOWN: ["dpad_down", "dpad_down", "D-Pad Down", "D-Pad Down"],
	JOY_BUTTON_DPAD_LEFT: ["dpad_left", "dpad_left", "D-Pad Left", "D-Pad Left"],
	JOY_BUTTON_DPAD_RIGHT: ["dpad_right", "dpad_right", "D-Pad Right", "D-Pad Right"],
}

var current_device: StringName = DEVICE_KEYBOARD_MOUSE

var _texture_cache: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Input.joy_connection_changed.connect(_on_joy_connection_changed)


func _input(event: InputEvent) -> void:
	if event is InputEventKey or event is InputEventMouseButton:
		_set_device(DEVICE_KEYBOARD_MOUSE)
	elif event is InputEventMouseMotion:
		if (event as InputEventMouseMotion).relative.length() > 0.0:
			_set_device(DEVICE_KEYBOARD_MOUSE)
	elif event is InputEventJoypadButton:
		_set_device(device_for_joy_name(Input.get_joy_name(event.device)))
	elif event is InputEventJoypadMotion:
		if absf((event as InputEventJoypadMotion).axis_value) > STICK_AXIS_DEADZONE:
			_set_device(device_for_joy_name(Input.get_joy_name(event.device)))


## Pure helper: PlayStation controllers by name, any other joypad is treated as Xbox.
static func device_for_joy_name(joy_name: String) -> StringName:
	var lowered := joy_name.to_lower()
	for hint in PLAYSTATION_NAME_HINTS:
		if lowered.contains(hint):
			return DEVICE_PLAYSTATION
	return DEVICE_XBOX


func is_gamepad() -> bool:
	return current_device != DEVICE_KEYBOARD_MOUSE


## Mouse icons live in the keyboard folder.
## Icon for the first event of `action` matching the current device (null if none/missing).
func get_glyph(action: StringName) -> Texture2D:
	var path := _glyph_path(_event_for_current_device(action))
	if path.is_empty():
		return null
	if _texture_cache.has(path):
		return _texture_cache[path]
	var texture: Texture2D = null
	if ResourceLoader.exists(path):
		texture = load(path) as Texture2D
	_texture_cache[path] = texture
	return texture


## Short text for the action's binding on the current device (e.g. "E", "Shift", "A").
func get_label(action: StringName) -> String:
	var event := _event_for_current_device(action)
	if event == null:
		return String(action)
	if event is InputEventKey:
		var key := event as InputEventKey
		var code := key.physical_keycode if key.physical_keycode != KEY_NONE else key.keycode
		return OS.get_keycode_string(code)
	if event is InputEventMouseButton:
		match (event as InputEventMouseButton).button_index:
			MOUSE_BUTTON_LEFT:
				return "LMB"
			MOUSE_BUTTON_RIGHT:
				return "RMB"
			MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN:
				return "Wheel"
			_:
				return "Mouse %d" % (event as InputEventMouseButton).button_index
	if event is InputEventJoypadButton:
		var entry: Array = JOY_BUTTONS.get((event as InputEventJoypadButton).button_index, [])
		if entry.is_empty():
			return "Button %d" % (event as InputEventJoypadButton).button_index
		return entry[3] if current_device == DEVICE_PLAYSTATION else entry[2]
	if event is InputEventJoypadMotion:
		return _axis_label(event as InputEventJoypadMotion)
	return String(action)


func _event_for_current_device(action: StringName) -> InputEvent:
	if not InputMap.has_action(action):
		return null
	var want_gamepad := is_gamepad()
	for event in InputMap.action_get_events(action):
		var is_pad := event is InputEventJoypadButton or event is InputEventJoypadMotion
		if is_pad == want_gamepad:
			return event
	return null


func _glyph_path(event: InputEvent) -> String:
	if event == null:
		return ""
	var folder := "keyboard"
	var stem := ""
	if event is InputEventKey:
		var key := event as InputEventKey
		var code := key.physical_keycode if key.physical_keycode != KEY_NONE else key.keycode
		stem = KEY_STEMS.get(code, "key_" + OS.get_keycode_string(code).to_lower())
	elif event is InputEventMouseButton:
		stem = MOUSE_STEMS.get((event as InputEventMouseButton).button_index, "")
	elif event is InputEventJoypadButton:
		folder = String(current_device)
		var entry: Array = JOY_BUTTONS.get((event as InputEventJoypadButton).button_index, [])
		if not entry.is_empty():
			stem = entry[1] if current_device == DEVICE_PLAYSTATION else entry[0]
	elif event is InputEventJoypadMotion:
		folder = String(current_device)
		stem = _axis_stem(event as InputEventJoypadMotion)
	if stem.is_empty():
		return ""
	return "%s%s/%s.png" % [GLYPH_DIR, folder, stem]


func _axis_stem(event: InputEventJoypadMotion) -> String:
	match event.axis:
		JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y:
			return "stick_l"
		JOY_AXIS_RIGHT_X, JOY_AXIS_RIGHT_Y:
			return "stick_r"
		JOY_AXIS_TRIGGER_LEFT:
			return "lt" if current_device == DEVICE_XBOX else "l2"
		JOY_AXIS_TRIGGER_RIGHT:
			return "rt" if current_device == DEVICE_XBOX else "r2"
	return ""


func _axis_label(event: InputEventJoypadMotion) -> String:
	var ps := current_device == DEVICE_PLAYSTATION
	match event.axis:
		JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y:
			return "Left Stick"
		JOY_AXIS_RIGHT_X, JOY_AXIS_RIGHT_Y:
			return "Right Stick"
		JOY_AXIS_TRIGGER_LEFT:
			return "L2" if ps else "LT"
		JOY_AXIS_TRIGGER_RIGHT:
			return "R2" if ps else "RT"
	return "Axis %d" % event.axis


func _set_device(device: StringName) -> void:
	if device == current_device:
		return
	current_device = device
	device_changed.emit(device)


func _on_joy_connection_changed(_device: int, connected: bool) -> void:
	if not connected and is_gamepad():
		_set_device(DEVICE_KEYBOARD_MOUSE)
