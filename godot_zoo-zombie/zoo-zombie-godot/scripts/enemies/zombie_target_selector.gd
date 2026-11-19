class_name ZombieTargetSelector
extends RefCounted
## Chooses what a zombie goes after (spec 001 RF-60 to RF-62):
## 1. Any zombie attacks an escaped animal inside its detection radius.
## 2. A breaker goes for the nearest occupied, intact enclosure, until it is hurt or the
##    player comes within breaker_aggro_radius (then it hunts the player for good).
## 3. Otherwise the player.

enum Kind { NONE, PLAYER, ANIMAL, ENCLOSURE }

var player: PlayerController
var registry: EnclosureRegistry


func _init(target_player: PlayerController, enclosure_registry: EnclosureRegistry) -> void:
	player = target_player
	registry = enclosure_registry


## Returns {"kind": Kind, "node": Node3D or null}. May set zombie.aggro_player.
func choose(zombie: Zombie) -> Dictionary:
	var position := zombie.global_position
	var animal := _nearest_escaped_animal(zombie, position, zombie.config.detection_radius)
	if animal != null:
		return {"kind": Kind.ANIMAL, "node": animal}
	var player_alive := is_instance_valid(player) and not player.health.is_dead
	if zombie.role == Zombie.Role.BREAKER and not zombie.aggro_player:
		if player_alive and _flat_distance(position, player.global_position) <= zombie.config.breaker_aggro_radius:
			zombie.aggro_player = true
		elif registry != null:
			var enclosure := registry.nearest_attackable(position)
			if enclosure != null:
				return {"kind": Kind.ENCLOSURE, "node": enclosure}
	if player_alive:
		return {"kind": Kind.PLAYER, "node": player}
	return {"kind": Kind.NONE, "node": null}


func _nearest_escaped_animal(zombie: Zombie, position: Vector3, radius: float) -> Animal:
	var best: Animal = null
	var best_distance := radius
	for node in zombie.get_tree().get_nodes_in_group(&"animals"):
		var animal := node as Animal
		if animal == null or not animal.is_escaped():
			continue
		var distance := _flat_distance(position, animal.global_position)
		if distance <= best_distance:
			best_distance = distance
			best = animal
	return best


static func _flat_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()
