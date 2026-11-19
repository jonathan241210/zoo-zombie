class_name EnclosureRegistry
extends Node
## Owns every Enclosure in the match (animal homes + refuges) and which animal lives in
## each one. Other systems ask the registry instead of searching the scene tree.
## Phase 7: releases the animal when its enclosure is destroyed (RF-33) and recaptures a
## following animal that reaches a free, intact refuge (RF-45).

const RECAPTURE_CHECK_INTERVAL := 0.25

@export var config: EnclosureConfig

var _enclosures: Dictionary = {}  # map name -> Enclosure
var _recapture_timer := 0.0


## Creates enclosures for the given home names plus the configured refuges.
func setup(level: ZooLevel, home_names: PackedStringArray) -> void:
	var names := home_names.duplicate()
	for refuge in config.refuge_enclosures:
		if not names.has(refuge):
			names.append(refuge)
	for map_name in names:
		var map_node := level.find_map_node(map_name)
		if map_node == null:
			push_error("EnclosureRegistry: map node '%s' not found" % map_name)
			continue
		var enclosure := Enclosure.new()
		level.add_child(enclosure)
		enclosure.setup(map_node, level.get_feeder_anchor(map_name), config,
			_colliders_for(level, map_node))
		enclosure.destroyed.connect(_on_enclosure_destroyed)
		_enclosures[map_name] = enclosure
	EventBus.animal_died.connect(_on_animal_died)


func get_enclosure(map_name: String) -> Enclosure:
	return _enclosures.get(map_name) as Enclosure


func get_all() -> Array[Enclosure]:
	var result: Array[Enclosure] = []
	for enclosure: Enclosure in _enclosures.values():
		result.append(enclosure)
	return result


## Moves an animal into an enclosure. At the start it is placed anywhere inside; on
## recapture (`near` given) it is placed inside next to where it reached the fence.
func assign(animal: Animal, enclosure: Enclosure, near: Variant = null) -> void:
	if animal.enclosure != null and animal.enclosure.occupant == animal:
		animal.enclosure.occupant = null
	enclosure.occupant = animal
	enclosure.health.reset(config.max_integrity)
	animal.enter_enclosure(enclosure, near)


## Nearest enclosure that holds an animal and still stands (breaker target, RF-60).
func nearest_attackable(from: Vector3) -> Enclosure:
	var best: Enclosure = null
	var best_distance := INF
	for enclosure: Enclosure in _enclosures.values():
		if not enclosure.can_be_attacked():
			continue
		var distance := enclosure.global_position.distance_squared_to(from)
		if distance < best_distance:
			best_distance = distance
			best = enclosure
	return best


## Free, intact refuges (RF-34).
func free_refuges() -> Array[Enclosure]:
	var result: Array[Enclosure] = []
	for map_name in config.refuge_enclosures:
		var enclosure := get_enclosure(map_name)
		if enclosure != null and enclosure.can_receive_animal():
			result.append(enclosure)
	return result


func _physics_process(delta: float) -> void:
	_recapture_timer -= delta
	if _recapture_timer > 0.0:
		return
	_recapture_timer = RECAPTURE_CHECK_INTERVAL
	for node in get_tree().get_nodes_in_group(&"animals"):
		var animal := node as Animal
		if animal == null or animal.state != Animal.State.FOLLOWING:
			continue
		for refuge in free_refuges():
			if refuge.distance_to_outline(animal.global_position) <= config.recapture_radius:
				assign(animal, refuge, animal.global_position)
				EventBus.animal_recaptured.emit(animal.config.animal_id, refuge)
				break


func _on_enclosure_destroyed(enclosure: Enclosure) -> void:
	var animal := enclosure.occupant as Animal
	enclosure.occupant = null
	if animal != null and is_instance_valid(animal):
		animal.escape(enclosure)


func _on_animal_died(_animal_id: StringName, _position: Vector3) -> void:
	for enclosure: Enclosure in _enclosures.values():
		var occupant := enclosure.occupant as Animal
		if occupant != null and (not is_instance_valid(occupant) or occupant.state == Animal.State.DEAD):
			enclosure.occupant = null


## The map's collision shapes for an enclosure (named "<mesh>_col" by the post-import).
func _colliders_for(level: ZooLevel, map_node: Node3D) -> Array[CollisionShape3D]:
	var result: Array[CollisionShape3D] = []
	var colliders := level.map.find_child("WorldColliders", true, false)
	if colliders == null:
		return result
	var names: Array[String] = [String(map_node.name)]
	for mesh in map_node.find_children("*", "MeshInstance3D", true, false):
		names.append(String(mesh.name))
	for mesh_name in names:
		var shape := colliders.get_node_or_null(mesh_name + "_col") as CollisionShape3D
		if shape != null:
			result.append(shape)
	return result
