class_name ZombieSpawner
extends Node
## Creates zombies at the level's perimeter spawn points or at a given position. Phase 8
## (WaveManager) drives it with intervals, caps and multipliers; phase 7 uses spawn_at()
## for the zombification horde. Until waves exist, `test_zombie_count` zombies appear at
## the start so combat can be played (phase 6).

signal zombie_spawned(zombie: Zombie)

@export var zombie_scene: PackedScene
## Temporary until the WaveManager exists (phase 8): zombies spawned when the match starts.
@export var test_zombie_count: int = 0
## Random offset around a spawn point so a group does not overlap (meters).
@export var spawn_jitter: float = 1.5

var target: Node3D = null
var _points: Array[Marker3D] = []


func setup(points: Array[Marker3D], new_target: Node3D) -> void:
	_points = points
	target = new_target
	if test_zombie_count > 0:
		spawn_random(test_zombie_count)


func alive_count() -> int:
	return get_tree().get_nodes_in_group(&"zombies").size()


## Spawns `count` zombies at random spawn points, already hunting the target (RF-63).
func spawn_random(count: int) -> Array[Zombie]:
	var spawned: Array[Zombie] = []
	if _points.is_empty():
		return spawned
	for i in count:
		var point: Marker3D = _points.pick_random()
		spawned.append(spawn_at(point.global_position, true))
	return spawned


func spawn_at(position: Vector3, alerted: bool = true) -> Zombie:
	var zombie := zombie_scene.instantiate() as Zombie
	zombie.setup(target, alerted)
	var offset := Vector3(randf_range(-1.0, 1.0), 0.0, randf_range(-1.0, 1.0)) * spawn_jitter
	get_parent().add_child(zombie)
	zombie.global_position = position + offset
	zombie.rotation.y = randf() * TAU
	zombie_spawned.emit(zombie)
	return zombie
