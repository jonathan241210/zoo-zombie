extends Control
## Pause panel (spec 001 RF-107): resume, controls reference, restart and quit to menu.

const MAIN_MENU := "res://scenes/ui/menus/main_menu.tscn"

@export var player: PlayerController

@onready var _menu_panel: Control = %MenuPanel
@onready var _continue_button: Button = %ContinueButton
@onready var _controls_button: Button = %ControlsButton
@onready var _restart_button: Button = %RestartButton
@onready var _quit_button: Button = %QuitButton
@onready var _controls: ControlsMenu = %ControlsMenu
@onready var _title: Label = %PauseTitle


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_title.text = tr("MENU_PAUSED")
	_continue_button.text = tr("MENU_RESUME")
	_controls_button.text = tr("MENU_CONTROLS")
	_restart_button.text = tr("MENU_RESTART")
	_quit_button.text = tr("MENU_QUIT_TO_MENU")
	_restart_button.pressed.connect(GameManager.restart_match)
	_quit_button.pressed.connect(func() -> void: GameManager.return_to_menu(MAIN_MENU))
	_continue_button.pressed.connect(_close_pause)
	_controls_button.pressed.connect(_show_controls)
	_controls.back_requested.connect(_show_main)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed(&"pause") or GameManager.is_match_over():
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
	_controls.open()


func _show_main() -> void:
	_controls.visible = false
	_menu_panel.visible = true
	_controls_button.grab_focus()
