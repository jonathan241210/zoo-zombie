extends Control
## Pause panel with access to the read-only controls reference.

@export var player: PlayerController

@onready var _menu_panel: Control = %MenuPanel
@onready var _continue_button: Button = %ContinueButton
@onready var _controls_button: Button = %ControlsButton
@onready var _controls: ControlsMenu = %ControlsMenu
@onready var _title: Label = %PauseTitle


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_title.text = tr("MENU_PAUSED")
	_continue_button.text = tr("MENU_RESUME")
	_controls_button.text = tr("MENU_CONTROLS")
	_continue_button.pressed.connect(_close_pause)
	_controls_button.pressed.connect(_show_controls)
	_controls.back_requested.connect(_show_main)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed(&"pause"):
		return
	if not visible:
		_open_pause()
	elif _controls.visible:
		_show_main()
	else:
		_close_pause()
	get_viewport().set_input_as_handled()


func _open_pause() -> void:
	visible = true
	get_tree().paused = true
	player.set_mouse_captured(false)
	_continue_button.grab_focus()


func _close_pause() -> void:
	get_tree().paused = false
	visible = false
	_controls.visible = false
	player.set_mouse_captured(true)


func _show_controls() -> void:
	_menu_panel.visible = false
	_controls.open()


func _show_main() -> void:
	_controls.visible = false
	_menu_panel.visible = true
	_controls_button.grab_focus()
