extends Control
## Lightweight entry menu for starting the current playable build and viewing controls.

@onready var _menu_panel: Control = %MenuPanel
@onready var _play_button: Button = %PlayButton
@onready var _controls_button: Button = %ControlsButton
@onready var _quit_button: Button = %QuitButton
@onready var _controls: ControlsMenu = %ControlsMenu
@onready var _title: Label = %MainTitle


func _ready() -> void:
	_title.text = tr("MENU_TITLE")
	_play_button.text = tr("MENU_PLAY")
	_controls_button.text = tr("MENU_CONTROLS")
	_quit_button.text = tr("MENU_QUIT")
	_play_button.pressed.connect(_start_game)
	_controls_button.pressed.connect(_show_controls)
	_quit_button.pressed.connect(func() -> void: get_tree().quit())
	_controls.back_requested.connect(_show_main)
	_play_button.grab_focus()


func _start_game() -> void:
	get_tree().change_scene_to_file("res://scenes/main/game.tscn")


func _show_controls() -> void:
	_controls.open()


func _show_main() -> void:
	_controls.visible = false
	_menu_panel.visible = true
	_controls_button.grab_focus()
