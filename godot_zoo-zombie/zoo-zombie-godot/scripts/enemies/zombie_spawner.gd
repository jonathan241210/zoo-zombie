class_name ZombieSpawner
extends Node
## Creates zombies at the level's perimeter spawn points or at a given position. Phase 8
## (WaveManager) drives it with intervals, caps and multipliers; phase 7 uses spawn_at()
## for the zombification horde (RF-47). Until waves exist, `test_zombie_count` zombies
## appear at the start so combat can be played; `test_breaker_ratio` of them are breakers.

signal zombie_spawned(zombie: Zombie)

@export var zombie_scene: PackedScene
## Temporary until the WaveManager exists (phase 8): zombies spawned when the match starts.
@export var test_zombie_count: int = 0
## Temporary until waves set it per wave (phase 8): share of breakers (0-1).
@export_range(0.0, 1.0) var test_breaker_ratio: float = 0.5
## Random offset around a spawn point so a group does not overlap (meters).
@export var spawn_jitter: float = 1.5

var target: Node3D = null
var selector: ZombieTargetSelector = null
var _points: Array[Marker3D] = []


func setup(points: Array[Marker3D], new_target: PlayerController, registry: EnclosureRegistry = null) -> void:
	_points = points
	target = new_target
	selector = ZombieTargetSelector.new(new_target, registry)
	if test_zombie_count > 0:
		var breakers := roundi(test_zombie_count * test_breaker_ratio)
		for i in test_zombie_count:
			var role := Zombie.Role.BREAKER if i < breakers else Zombie.Role.HUNTER
			spawn_random(1, role)


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


func spawn_at(position: Vector3, alerted: bool = true, role: Zombie.Role = Zombie.Role.HUNTER) -> Zombie:
	var zombie := zombie_scene.instantiate() as Zombie
	zombie.setup(target, alerted)
	zombie.set_ai(selector, role)
	var offset := Vector3(randf_range(-1.0, 1.0), 0.0, randf_range(-1.0, 1.0)) * spawn_jitter
	get_parent().add_child(zombie)
	zombie.global_position = position + offset
	zombie.rotation.y = randf() * TAU
	zombie_spawned.emit(zombie)
	return zombie
