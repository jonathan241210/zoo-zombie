class_name FoodCrateDirector
extends Node
## Keeps food crates on the map (spec 001 RF-10, RF-13): fills random free spawn points
## up to `max_active`, and after a crate is picked up waits `respawn_delay` seconds
## (paused with the game) before spawning another one at a random free point.

signal crate_spawned(crate: FoodCrate)

@export var config: FoodCrateConfig
@export var crate_scene: PackedScene

var _spawns: Array[Marker3D] = []
var _occupied: Dictionary = {}  # Marker3D -> FoodCrate
var _pending_respawns := 0


func setup(spawn_points: Array[Marker3D]) -> void:
	_spawns = spawn_points
	for i in mini(config.max_active, _spawns.size()):
		_spawn_one()


func active_count() -> int:
	return _occupied.size()


func pending_respawns() -> int:
	return _pending_respawns


func _spawn_one() -> FoodCrate:
	var free_points: Array[Marker3D] = []
	for point in _spawns:
		if not _occupied.has(point):
			free_points.append(point)
	if free_points.is_empty() or _occupied.size() >= config.max_active:
		return null
	var point: Marker3D = free_points.pick_random()
	var crate := crate_scene.instantiate() as FoodCrate
	point.add_child(crate)
	crate.rotation.y = randf() * TAU
	_occupied[point] = crate
	crate.picked_up.connect(_on_crate_picked_up.bind(point))
	crate_spawned.emit(crate)
	return crate


func _on_crate_picked_up(_crate: FoodCrate, point: Marker3D) -> void:
	_occupied.erase(point)
	_pending_respawns += 1
	# process_always = false: the timer stops while the game is paused.
	var timer := get_tree().create_timer(config.respawn_delay, false)
	timer.timeout.connect(_on_respawn_timeout)


func _on_respawn_timeout() -> void:
	_pending_respawns -= 1
	_spawn_one()
