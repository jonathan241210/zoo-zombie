class_name ZombieSpawner
extends Node
## Creates zombies at the level's perimeter spawn points or at a given position. The
## WaveManager drives it (spawn_wave_zombie, with the wave's multipliers, away from the
## player, RF-74); the zombification horde uses spawn_horde (RF-47).

signal zombie_spawned(zombie: Zombie)

@export var zombie_scene: PackedScene
## Random offset around a spawn point so a group does not overlap (meters).
@export var spawn_jitter: float = 1.5

var target: Node3D = null
var selector: ZombieTargetSelector = null
var _points: Array[Marker3D] = []


func setup(points: Array[Marker3D], new_target: PlayerController, registry: EnclosureRegistry = null) -> void:
	_points = points
	target = new_target
	selector = ZombieTargetSelector.new(new_target, registry)


## One wave zombie at a random perimeter point at least `min_distance` from the player
## (the farthest point if none is that far), with the wave multipliers (RF-71, RF-74).
func spawn_wave_zombie(role: Zombie.Role, wave: WaveConfig, min_distance: float) -> Zombie:
	if _points.is_empty():
		return null
	var candidates: Array[Marker3D] = []
	var farthest: Marker3D = _points[0]
	for point in _points:
		var distance := _distance_to_target(point.global_position)
		if distance >= min_distance:
			candidates.append(point)
		if distance > _distance_to_target(farthest.global_position):
			farthest = point
	var chosen: Marker3D = candidates.pick_random() if not candidates.is_empty() else farthest
	return spawn_at(chosen.global_position, true, role, wave)


## RF-47: extra horde where an animal died, already hunting.
func spawn_horde(position: Vector3, count: int) -> Array[Zombie]:
	var spawned: Array[Zombie] = []
	for i in count:
		spawned.append(spawn_at(position, true))
	return spawned


func alive_count() -> int:
	return get_tree().get_nodes_in_group(&"zombies").size()


## Spawns `count` zombies at random spawn points, already hunting the target (RF-63).
func spawn_random(count: int, role: Zombie.Role = Zombie.Role.HUNTER) -> Array[Zombie]:
	var spawned: Array[Zombie] = []
	if _points.is_empty():
		return spawned
	for i in count:
		var point: Marker3D = _points.pick_random()
		spawned.append(spawn_at(point.global_position, true, role))
	return spawned


func spawn_at(position: Vector3, alerted: bool = true, role: Zombie.Role = Zombie.Role.HUNTER,
		wave: WaveConfig = null) -> Zombie:
	var zombie := zombie_scene.instantiate() as Zombie
	zombie.setup(target, alerted)
	zombie.set_ai(selector, role)
	if wave != null:
		zombie.speed_multiplier = wave.speed_multiplier
		zombie.health_multiplier = wave.health_multiplier
		zombie.damage_multiplier = wave.damage_multiplier
	var offset := Vector3(randf_range(-1.0, 1.0), 0.0, randf_range(-1.0, 1.0)) * spawn_jitter
	get_parent().add_child(zombie)
	zombie.global_position = position + offset
	zombie.rotation.y = randf() * TAU
	zombie_spawned.emit(zombie)
	return zombie


func _distance_to_target(point: Vector3) -> float:
	if not is_instance_valid(target):
		return INF
	return Vector2(point.x - target.global_position.x, point.z - target.global_position.z).length()
