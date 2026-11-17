class_name PlayerCarry
extends Node
## ARMED / CARRYING state (spec 001 RF-04, RF-05, RF-12, RF-14). While carrying a food
## crate the player moves slower and cannot use weapons. Only one crate at a time.

enum State { ARMED, CARRYING }

signal state_changed(new_state: State)

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
