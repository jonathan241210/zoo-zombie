class_name InteractionPrompt
extends Control
## Contextual prompt (spec 001 RF-81/RF-102): "[E] Recoger" near a crate, "[E] Alimentar"
## near a feeder while carrying food. Shows the glyph of the current input device.
## Part of the HUD; the full HUD (phase 9) will host this widget.

@export var interactor: PlayerInteractor

var _current: Interactable = null

@onready var _glyph: TextureRect = %Glyph
@onready var _key_label: Label = %KeyLabel
@onready var _text: Label = %Text


func _ready() -> void:
	visible = false
	interactor.focus_changed.connect(_on_focus_changed)
	InputGlyphs.device_changed.connect(func(_device: StringName) -> void: _refresh())


func _on_focus_changed(interactable: Interactable) -> void:
	_current = interactable
	_refresh()


func _refresh() -> void:
	visible = _current != null and is_instance_valid(_current)
	if not visible:
		return
	var texture := InputGlyphs.get_glyph(_current.action)
	_glyph.texture = texture
	_glyph.visible = texture != null
	_key_label.text = "[%s]" % InputGlyphs.get_label(_current.action)
	_key_label.visible = texture == null
	_text.text = tr(_current.prompt_key)
