class_name FoodCrate
extends Node3D
## A food crate lying on the map (spec 001 RF-10, RF-11). Interacting picks it up if
## the player is not already carrying one; the crate node is then removed.

signal picked_up(crate: FoodCrate)

@onready var interactable: Interactable = $Interactable


func _ready() -> void:
	interactable.prompt_key = "PROMPT_PICK_UP"
	interactable.validator = _can_pick_up
	interactable.interacted.connect(_on_interacted)


func _can_pick_up(interactor: Node) -> bool:
	var carry := interactor.get_node_or_null("PlayerCarry") as PlayerCarry
	return carry != null and not carry.is_carrying()


func _on_interacted(interactor: Node) -> void:
	var carry := interactor.get_node_or_null("PlayerCarry") as PlayerCarry
	if carry != null and carry.pick_up():
		picked_up.emit(self)
		queue_free()
