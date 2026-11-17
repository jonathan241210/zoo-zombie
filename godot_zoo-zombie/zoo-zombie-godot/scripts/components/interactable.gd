class_name Interactable
extends Area3D
## Something the player can interact with (food crate, feeder...).
## The PlayerInteractor finds these by physics layer, asks can_interact() and shows
## prompt_key. Owners connect to `interacted` or override behaviour via `validator`.

signal interacted(interactor: Node)
signal focus_changed(focused: bool)

## Translation key shown in the HUD prompt (e.g. "PROMPT_PICK_UP").
@export var prompt_key: String = "PROMPT_INTERACT"
## Input action whose glyph is shown next to the prompt.
@export var action: StringName = &"interact"
@export var enabled: bool = true

## Optional callable(interactor: Node) -> bool set by the owner for extra rules
## (e.g. the feeder only accepts players that carry food).
var validator: Callable

const INTERACTABLE_LAYER := 5


func _ready() -> void:
	collision_layer = 0
	set_collision_layer_value(INTERACTABLE_LAYER, true)
	collision_mask = 0
	monitoring = false
	monitorable = true


func can_interact(interactor: Node) -> bool:
	if not enabled:
		return false
	if validator.is_valid():
		return validator.call(interactor)
	return true


func interact(interactor: Node) -> bool:
	if not can_interact(interactor):
		return false
	interacted.emit(interactor)
	return true


func set_focused(focused: bool) -> void:
	focus_changed.emit(focused)
