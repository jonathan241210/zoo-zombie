class_name HealthComponent
extends Node
## Reusable health pool for players, zombies, animals and enclosures (as integrity).
## The owner sets max_health from its config Resource; this node never hardcodes balance.

signal health_changed(current: float, maximum: float)
signal damaged(amount: float, source: Node)
signal healed(amount: float)
signal died

@export var max_health: float = 100.0:
	set(value):
		max_health = maxf(value, 0.0)
		current_health = minf(current_health, max_health)

var current_health: float = 0.0
var is_dead: bool = false


func _ready() -> void:
	if current_health <= 0.0 and not is_dead:
		current_health = max_health


## Re-initializes the pool, e.g. on respawn or when a config is applied.
func reset(new_max: float = -1.0) -> void:
	if new_max >= 0.0:
		max_health = new_max
	current_health = max_health
	is_dead = false
	health_changed.emit(current_health, max_health)


## Applies damage and returns the amount actually removed.
func take_damage(amount: float, source: Node = null) -> float:
	if is_dead or amount <= 0.0:
		return 0.0
	var applied := minf(amount, current_health)
	current_health -= applied
	damaged.emit(applied, source)
	health_changed.emit(current_health, max_health)
	if current_health <= 0.0:
		is_dead = true
		died.emit()
	return applied


## Restores health without exceeding the maximum and returns the amount healed.
func heal(amount: float) -> float:
	if is_dead or amount <= 0.0:
		return 0.0
	var applied := minf(amount, max_health - current_health)
	current_health += applied
	if applied > 0.0:
		healed.emit(applied)
		health_changed.emit(current_health, max_health)
	return applied


func get_ratio() -> float:
	return current_health / max_health if max_health > 0.0 else 0.0
