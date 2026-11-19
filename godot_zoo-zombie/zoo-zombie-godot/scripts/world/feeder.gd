class_name Feeder
extends Node3D
## An animal's feeder (spec 001 RF-24, RF-25). It always stands in the enclosure where
## its animal currently lives; the player feeds from outside the fence while carrying
## a food crate. Local +Z points into the enclosure.

@export var prompt_key: String = "PROMPT_FEED"
## Where the animal stands to eat, in local space (inside the enclosure).
@export var eat_offset: Vector3 = Vector3(0.0, 0.0, 1.6)

enum State { EMPTY, FULL }

signal state_changed(new_state: State)

var animal: Animal = null
var state: State = State.EMPTY

@onready var interactable: Interactable = $Interactable
@onready var _empty_contents: Node3D = get_node_or_null("Model/ContentsEmpty") as Node3D
@onready var _full_contents: Node3D = get_node_or_null("Model/ContentsFull") as Node3D


func _ready() -> void:
	interactable.prompt_key = prompt_key
	interactable.validator = _can_feed
	interactable.interacted.connect(_on_interacted)
	_sync_visual_state()


func attach(owner_animal: Animal, enclosure: Enclosure) -> void:
	animal = owner_animal
	if not animal.needs.satiety_depleted.is_connected(_on_satiety_depleted):
		animal.needs.satiety_depleted.connect(_on_satiety_depleted)
	if enclosure.has_feeder_anchor:
		global_transform = enclosure.feeder_anchor
	else:
		global_position = enclosure.global_position
	visible = true
	interactable.enabled = true
	set_filled(false)


## RF-33: while its animal is escaped the feeder is hidden and cannot be used.
func detach() -> void:
	visible = false
	interactable.enabled = false


func set_filled(filled: bool) -> void:
	var next_state := State.FULL if filled else State.EMPTY
	if state == next_state:
		_sync_visual_state()
		return
	state = next_state
	_sync_visual_state()
	state_changed.emit(state)


func get_eat_position() -> Vector3:
	return global_transform * eat_offset


func _can_feed(interactor: Node) -> bool:
	var carry := _carry_of(interactor)
	return carry != null and carry.is_carrying() and animal != null and animal.can_be_fed()


func _on_interacted(interactor: Node) -> void:
	var carry := _carry_of(interactor)
	if carry != null and carry.consume():
		animal.feed()


func _on_satiety_depleted() -> void:
	set_filled(false)


func _sync_visual_state() -> void:
	if _empty_contents != null:
		_empty_contents.visible = state == State.EMPTY
	if _full_contents != null:
		_full_contents.visible = state == State.FULL


static func _carry_of(interactor: Node) -> PlayerCarry:
	return interactor.get_node_or_null("PlayerCarry") as PlayerCarry
