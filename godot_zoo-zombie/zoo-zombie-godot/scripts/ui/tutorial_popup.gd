class_name TutorialPopup
extends Control
## Pauses the match until the player dismisses the first-run tutorial.

signal continued

@onready var _title: Label = %Title
@onready var _message: Label = %Message
@onready var _continue_button: Button = %ContinueButton


func _enter_tree() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _ready() -> void:
	_title.text = tr("TUTORIAL_TITLE")
	_message.text = tr("TUTORIAL_MESSAGE")
	_continue_button.text = tr("TUTORIAL_CONTINUE")
	_continue_button.pressed.connect(_continue_game)
	get_tree().paused = true
	_continue_button.grab_focus()


func _continue_game() -> void:
	visible = false
	get_tree().paused = false
	continued.emit()
