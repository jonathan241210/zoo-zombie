class_name Feeder
extends Node3D
## An animal's feeder (spec 001 RF-24, RF-25). It always stands in the enclosure where
## its animal currently lives; the player feeds from outside the fence while carrying
## a food crate. Local +Z points into the enclosure.

@export var prompt_key: String = "PROMPT_FEED"
## Where the animal stands to eat, in local space (inside the enclosure).
@export var eat_offset: Vector3 = Vector3(0.0, 0.0, 1.6)

var animal: Animal = null

@onready var interactable: Interactable = $Interactable


func _ready() -> void:
	interactable.prompt_key = prompt_key
	interactable.validator = _can_feed
	interactable.interacted.connect(_on_interacted)


func attach(owner_animal: Animal, enclosure: Enclosure) -> void:
	animal = owner_animal
	if enclosure.has_feeder_anchor:
		global_transform = enclosure.feeder_anchor
	else:
		global_position = enclosure.global_position
	visible = true


func get_eat_position() -> Vector3:
	return global_transform * eat_offset


func _can_feed(interactor: Node) -> bool:
	var carry := _carry_of(interactor)
	return carry != null and carry.is_carrying() and animal != null and animal.can_be_fed()


func _on_interacted(interactor: Node) -> void:
	var carry := _carry_of(interactor)
	if carry != null and carry.consume():
		animal.feed()


static func _carry_of(interactor: Node) -> PlayerCarry:
	return interactor.get_node_or_null("PlayerCarry") as PlayerCarry
