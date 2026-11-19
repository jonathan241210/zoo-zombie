class_name ControlsMenu
extends Control
## Read-only keyboard/mouse and gamepad reference (spec 002 RF-60 to RF-62).

signal back_requested

const CONTROL_ROWS: Array[Dictionary] = [
	{"action": &"move_forward", "label": "ACTION_MOVE_FORWARD"},
	{"action": &"move_back", "label": "ACTION_MOVE_BACK"},
	{"action": &"move_left", "label": "ACTION_MOVE_LEFT"},
	{"action": &"move_right", "label": "ACTION_MOVE_RIGHT"},
	{"action": &"look", "label": "ACTION_LOOK"},
	{"action": &"sprint", "label": "ACTION_SPRINT"},
	{"action": &"jump", "label": "ACTION_JUMP"},
	{"action": &"fire", "label": "ACTION_FIRE"},
	{"action": &"reload", "label": "ACTION_RELOAD"},
	{"action": &"interact", "label": "ACTION_INTERACT"},
	{"action": &"switch_weapon", "label": "ACTION_SWITCH_WEAPON"},
	{"action": &"weapon_1", "label": "ACTION_WEAPON_1"},
	{"action": &"weapon_2", "label": "ACTION_WEAPON_2"},
	{"action": &"pause", "label": "ACTION_PAUSE"},
	{"action": &"ui_accept", "label": "ACTION_UI_ACCEPT"},
	{"action": &"ui_cancel", "label": "ACTION_UI_BACK"},
	{"action": &"ui_up", "label": "ACTION_MENU_UP"},
	{"action": &"ui_down", "label": "ACTION_MENU_DOWN"},
	{"action": &"ui_left", "label": "ACTION_MENU_LEFT"},
	{"action": &"ui_right", "label": "ACTION_MENU_RIGHT"},
	{"action": &"ui_tab_prev", "label": "ACTION_UI_TAB_PREV"},
	{"action": &"ui_tab_next", "label": "ACTION_UI_TAB_NEXT"},
	{"action": &"minimap_zoom", "label": "ACTION_MINIMAP_ZOOM"},
]

@onready var _rows: VBoxContainer = %Rows
@onready var _scroll: ScrollContainer = %Scroll
@onready var _back_button: Button = %BackButton
@onready var _title: Label = %Title
@onready var _action_header: Label = %ActionHeader
@onready var _keyboard_header: Label = %KeyboardHeader
@onready var _gamepad_header: Label = %GamepadHeader


func _ready() -> void:
	visible = false
	_title.text = tr("MENU_CONTROLS")
	_action_header.text = tr("CONTROLS_ACTION")
	_keyboard_header.text = tr("CONTROLS_KEYBOARD")
	_gamepad_header.text = tr("CONTROLS_GAMEPAD")
	_back_button.text = tr("DIALOG_BACK")
	_build_rows()
	_back_button.pressed.connect(func() -> void: back_requested.emit())
	InputGlyphs.device_changed.connect(_refresh_bindings)


func open() -> void:
	visible = true
	_back_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed(&"ui_cancel"):
		back_requested.emit()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"ui_down"):
		_scroll.scroll_vertical += 40
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"ui_up"):
		_scroll.scroll_vertical = maxi(_scroll.scroll_vertical - 40, 0)
		get_viewport().set_input_as_handled()


func _build_rows() -> void:
	for row_data in CONTROL_ROWS:
		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var glyph := TextureRect.new()
		glyph.name = "ActionGlyph"
		glyph.custom_minimum_size = Vector2(32, 32)
		glyph.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		glyph.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var action_label := Label.new()
		action_label.text = tr(row_data["label"])
		action_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		action_label.custom_minimum_size.x = 205.0
		var keyboard_label := Label.new()
		keyboard_label.name = "KeyboardBinding"
		keyboard_label.custom_minimum_size.x = 205.0
		var gamepad_label := Label.new()
		gamepad_label.name = "GamepadBinding"
		gamepad_label.custom_minimum_size.x = 215.0
		row.add_child(glyph)
		row.add_child(action_label)
		row.add_child(keyboard_label)
		row.add_child(gamepad_label)
		_rows.add_child(row)
		row.set_meta("action_id", row_data["action"])
	_refresh_bindings(&"")


func _refresh_bindings(_device: StringName) -> void:
	for row in _rows.get_children():
		var action: StringName = row.get_meta("action_id")
		var glyph := row.get_node("ActionGlyph") as TextureRect
		var keyboard := row.get_node("KeyboardBinding") as Label
		var gamepad := row.get_node("GamepadBinding") as Label
		if action == &"look":
			keyboard.text = tr("BIND_MOUSE_MOVEMENT")
			gamepad.text = tr("BIND_RIGHT_STICK")
		else:
			keyboard.text = InputGlyphs.get_binding_label(action, false)
			gamepad.text = InputGlyphs.get_binding_label(action, true)
			glyph.texture = InputGlyphs.get_glyph(action)
		glyph.visible = glyph.texture != null

