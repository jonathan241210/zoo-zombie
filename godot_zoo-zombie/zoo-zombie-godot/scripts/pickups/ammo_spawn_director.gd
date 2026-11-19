class_name AmmoSpawnDirector
extends Node
## Map ammo crates (spec 001 RF-58, RF-59): at the start, `active_count` random candidate
## points get a glowing crate. After one is collected, `respawn_delay` seconds later
## (paused with the game) another crate appears at a random free point, never the one
## that was just emptied while any other point is free.

signal crate_spawned(pickup: AmmoPickup, point: Marker3D)

@export var config: AmmoSpawnConfig
@export var pickup_scene: PackedScene

var _points: Array[Marker3D] = []
var _occupied: Dictionary = {}  # Marker3D -> AmmoPickup
var _pending_respawns := 0


func setup(points: Array[Marker3D]) -> void:
	_points = points
	for i in mini(config.active_count, _points.size()):
		_spawn_one(null)


func active_count() -> int:
	return _occupied.size()


func pending_respawns() -> int:
	return _pending_respawns


func occupied_points() -> Array[Marker3D]:
	var result: Array[Marker3D] = []
	for point: Marker3D in _occupied.keys():
		result.append(point)
	return result


func _spawn_one(avoid: Marker3D) -> AmmoPickup:
	if active_count() >= config.active_count:
		return null
	var free_points: Array[Marker3D] = []
	for point in _points:
		if not _occupied.has(point) and point != avoid:
			free_points.append(point)
	if free_points.is_empty() and avoid != null and not _occupied.has(avoid):
		free_points.append(avoid)  # only one candidate left
	if free_points.is_empty():
		return null
	var point: Marker3D = free_points.pick_random()
	var pickup := pickup_scene.instantiate() as AmmoPickup
	pickup.configure(config.shells_per_crate, 0.0, config)
	point.add_child(pickup)
	pickup.rotation.y = randf() * TAU
	_occupied[point] = pickup
	pickup.collected.connect(_on_collected.bind(point))
	crate_spawned.emit(pickup, point)
	return pickup


func _on_collected(_pickup: AmmoPickup, point: Marker3D) -> void:
	_occupied.erase(point)
	_pending_respawns += 1
	var timer := get_tree().create_timer(config.respawn_delay, false)
	timer.timeout.connect(_on_respawn_timeout.bind(point))


func _on_respawn_timeout(emptied_point: Marker3D) -> void:
	_pending_respawns -= 1
	_spawn_one(emptied_point)
