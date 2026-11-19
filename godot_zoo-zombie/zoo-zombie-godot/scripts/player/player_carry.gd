class_name PlayerCarry
extends Node
## ARMED / CARRYING state (spec 001 RF-04, RF-05, RF-12, RF-14). While carrying a food
## crate the player moves slower and cannot use weapons. Only one crate at a time.

enum State { ARMED, CARRYING }

signal state_changed(new_state: State)
signal crate_dropped(crate: FoodCrate)

@export var food_crate_scene: PackedScene
## Set by the game root (scripts/systems/game.gd) when the match starts.
@export var food_crate_director: FoodCrateDirector

var state: State = State.ARMED

## Optional: the controller whose speed depends on carrying (null in unit tests).
var _player: PlayerController = null


func _ready() -> void:
	_player = get_parent() as PlayerController
	EventBus.player_died.connect(_on_player_died)


func is_carrying() -> bool:
	return state == State.CARRYING


## Weapons (phase 5) must check this before firing, reloading or switching.
func can_use_weapons() -> bool:
	return state == State.ARMED


## Takes a crate. Fails if already carrying one (RF-12).
func pick_up() -> bool:
	if is_carrying():
		return false
	_set_state(State.CARRYING)
	return true


## Uses the carried crate (feeding). Returns false if there was nothing to consume.
func consume() -> bool:
	if not is_carrying():
		return false
	_set_state(State.ARMED)
	return true


## Drops the carried crate in front of the player. A dropped crate remains in the world
## and is tracked by the director, so it can be picked up again without creating stock.
func drop() -> bool:
	if not is_carrying() or food_crate_scene == null or food_crate_director == null:
		return false
	var player := get_parent() as PlayerController
	var camera := player.camera
	var crate := food_crate_scene.instantiate() as FoodCrate
	if crate == null:
		return false
	crate.set_dropped(true)
	# Same parent as the director (the match root), not current_scene, which may differ.
	food_crate_director.get_parent().add_child(crate)
	crate.global_position = _find_drop_position(player, camera)
	crate.global_rotation.y = player.global_rotation.y
	food_crate_director.register_dropped(crate)
	_set_state(State.ARMED)
	crate_dropped.emit(crate)
	return true


func _find_drop_position(player: PlayerController, camera: Camera3D) -> Vector3:
	var space := player.get_world_3d().direct_space_state
	var forward := -camera.global_basis.z
	forward.y = 0.0
	forward = forward.normalized()
	var start := player.global_position + Vector3.UP * 0.65
	var destination := start + forward * 1.1
	var wall_query := PhysicsRayQueryParameters3D.create(start, destination, 1)
	wall_query.exclude = [player.get_rid()]
	var wall_hit := space.intersect_ray(wall_query)
	if not wall_hit.is_empty():
		destination = wall_hit["position"] - forward * 0.4
	var ground_start := Vector3(destination.x, player.global_position.y + 2.0, destination.z)
	var ground_end := ground_start + Vector3.DOWN * 4.0
	var ground_query := PhysicsRayQueryParameters3D.create(ground_start, ground_end, 1)
	ground_query.exclude = [player.get_rid()]
	var ground_hit := space.intersect_ray(ground_query)
	if not ground_hit.is_empty():
		return ground_hit["position"]
	return Vector3(destination.x, player.global_position.y, destination.z)


func _on_player_died() -> void:
	# RF-14: the crate is lost on death; its spawn point already started respawning.
	if is_carrying():
		_set_state(State.ARMED)


func _set_state(new_state: State) -> void:
	state = new_state
	if _player != null:
		_player.is_carrying = state == State.CARRYING
	state_changed.emit(state)
	EventBus.player_carry_changed.emit(state == State.CARRYING)
