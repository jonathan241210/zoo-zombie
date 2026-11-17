class_name PlayerInteractor
extends Area3D
## Finds the best Interactable near the player (spec 001 RF-11, RF-25) and triggers it
## with the "interact" action. Proximity-based (not a raycast) so feeders behind a fence
## still work; among candidates it prefers what the camera is looking at.

signal focus_changed(interactable: Interactable)

const INTERACTABLE_LAYER := 5
## Candidates further than this angle from the view direction are ignored (cosine).
const MIN_FACING_DOT := 0.2

@export var camera: Camera3D

var focused: Interactable = null
## Tracks whether `focused` was set, because a freed object compares equal to null.
var _has_focus := false

@onready var _player: Node3D = get_parent() as Node3D


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1 << (INTERACTABLE_LAYER - 1)
	monitoring = true
	monitorable = false


func _physics_process(_delta: float) -> void:
	# A focused interactable can be freed (e.g. a crate just picked up). Freed objects
	# compare equal to null, so clear it explicitly or the prompt would stay on screen.
	if _has_focus and not is_instance_valid(focused):
		focused = null
		_has_focus = false
		focus_changed.emit(null)
	var best: Interactable = null
	var best_score := -INF
	var forward := -camera.global_basis.z
	for area in get_overlapping_areas():
		var interactable := area as Interactable
		if interactable == null or not interactable.can_interact(_player):
			continue
		var to_target := interactable.global_position - camera.global_position
		to_target.y = 0.0
		var flat_forward := Vector3(forward.x, 0.0, forward.z).normalized()
		var facing := flat_forward.dot(to_target.normalized()) if to_target.length() > 0.01 else 1.0
		if facing < MIN_FACING_DOT:
			continue
		var score := facing - to_target.length() * 0.1
		if score > best_score:
			best_score = score
			best = interactable
	if best != focused:
		if focused != null and is_instance_valid(focused):
			focused.set_focused(false)
		focused = best
		_has_focus = focused != null
		if _has_focus:
			focused.set_focused(true)
		focus_changed.emit(focused)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"interact") and focused != null and is_instance_valid(focused):
		focused.interact(_player)
		get_viewport().set_input_as_handled()
