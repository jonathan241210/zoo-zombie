class_name WeaponManager
extends Node
## Equipped weapon (spec 001 RF-5B, RF-05): switches between the shotgun and the axe with
## a short animation, and blocks switching while carrying a crate. The equipped weapon is
## kept while carrying (the arm is hidden), so it comes back after feeding or dropping.

signal weapon_switched(weapon: StringName)

const SHOTGUN := &"shotgun"
const AXE := &"axe"

@export var shotgun: Shotgun
@export var axe: Axe
@export var carry: PlayerCarry
@export var player: PlayerController
@export var view_model: ViewModel

var current: StringName = SHOTGUN
var is_switching := false


func _ready() -> void:
	assert(shotgun != null and axe != null and carry != null and player != null)
	_activate(current)
	if view_model != null:
		view_model.show_weapon(current)
	EventBus.weapon_changed.emit(current)


func _process(_delta: float) -> void:
	if not player.input_enabled:
		return
	if Input.is_action_just_pressed(&"switch_weapon"):
		switch_to(AXE if current == SHOTGUN else SHOTGUN)
	elif Input.is_action_just_pressed(&"weapon_1"):
		switch_to(SHOTGUN)
	elif Input.is_action_just_pressed(&"weapon_2"):
		switch_to(AXE)


func can_switch() -> bool:
	return not is_switching and player.input_enabled and carry.can_use_weapons()


## Starts switching; the new weapon becomes usable after its draw time.
func switch_to(weapon: StringName) -> bool:
	if weapon == current or not can_switch():
		return false
	is_switching = true
	shotgun.cancel_reload()
	_activate(&"")
	var duration := _draw_time(weapon)
	if view_model != null:
		view_model.play_switch(weapon, duration)
	if duration > 0.0:
		await get_tree().create_timer(duration, false).timeout
	current = weapon
	is_switching = false
	_activate(current)
	weapon_switched.emit(current)
	EventBus.weapon_changed.emit(current)
	return true


## Ammo pickups go to the shotgun reserve whatever is equipped (RF-56).
func add_ammo(amount: int) -> int:
	return shotgun.add_ammo(amount)


func is_reserve_full() -> bool:
	return shotgun.ammo.reserve >= shotgun.ammo.max_reserve


func _activate(weapon: StringName) -> void:
	shotgun.active = weapon == SHOTGUN
	axe.active = weapon == AXE


func _draw_time(weapon: StringName) -> float:
	return axe.config.draw_time if weapon == AXE else shotgun.config.draw_time
