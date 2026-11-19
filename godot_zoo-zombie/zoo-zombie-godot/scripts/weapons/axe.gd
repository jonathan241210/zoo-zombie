class_name Axe
extends Node
## Melee secondary weapon (spec 001 RF-5A, RF-5C): unlimited use, slow swing that hits up
## to `max_targets` bodies inside a short frontal arc and pushes them back.

signal swung
signal hit_confirmed(target: Node)

## Physics layers the blade can hit: zombies (3), animals (4) and hurtboxes (7).
const TARGET_MASK := (1 << 2) | (1 << 3) | (1 << 6)
## World geometry (1) blocks the blade, so it does not hit through walls or fences.
const WORLD_MASK := 1

@export var config: AxeConfig
@export var player: PlayerController
@export var carry: PlayerCarry
@export var camera: Camera3D
@export var view_model: ViewModel
@export var swing_sound: AudioStream
@export var hit_sound: AudioStream

## Set by the WeaponManager: only the equipped weapon reads input.
var active := false

var _next_swing_time := 0.0


func _ready() -> void:
	assert(config != null and player != null and carry != null and camera != null)


func _process(_delta: float) -> void:
	if active and player.input_enabled and Input.is_action_pressed(&"fire"):
		swing()


func can_swing() -> bool:
	return _can_use() and _now() >= _next_swing_time


## Starts a swing; the blade connects `hit_delay` seconds later.
func swing() -> bool:
	if not can_swing():
		return false
	_next_swing_time = _now() + config.swing_interval
	if view_model != null:
		view_model.play_axe_swing()
	Sfx.play(player, swing_sound)
	swung.emit()
	if config.hit_delay > 0.0:
		await get_tree().create_timer(config.hit_delay, false).timeout
	# Switching weapons or picking up a crate mid-swing cancels the hit.
	if _can_use():
		strike()
	return true


## Applies the hit immediately and returns the health pools that were damaged.
func strike() -> Array[HealthComponent]:
	var hits := find_targets()
	for hit: Dictionary in hits:
		var health: HealthComponent = hit["health"]
		health.take_damage(config.damage, player)
		var body: Node = health.get_parent()
		var push: Vector3 = hit["direction"] * config.knockback
		if body != null and body.has_method(&"apply_knockback"):
			body.call(&"apply_knockback", push)
		HitEffects.spawn_impact(player, hit["point"], -hit["direction"] as Vector3, Color(0.75, 0.05, 0.05), 0.06)
		Sfx.play_at(player, hit_sound, hit["point"])
		hit_confirmed.emit(body)
	var damaged: Array[HealthComponent] = []
	for hit: Dictionary in hits:
		damaged.append(hit["health"])
	return damaged


## Bodies in range, inside the frontal arc and in line of sight, nearest first, capped
## at `max_targets`. Each entry: {health, point, direction, distance}.
func find_targets() -> Array[Dictionary]:
	var space := player.get_world_3d().direct_space_state
	var origin := camera.global_position
	var forward := -camera.global_basis.z
	forward.y = 0.0
	forward = forward.normalized()
	var shape := SphereShape3D.new()
	shape.radius = config.max_range
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = Transform3D(Basis.IDENTITY, origin)
	query.collision_mask = TARGET_MASK
	query.collide_with_areas = true
	query.exclude = [player.get_rid()]
	var half_arc := deg_to_rad(config.arc_degrees) * 0.5
	var seen: Dictionary = {}  # HealthComponent -> true
	var candidates: Array[Dictionary] = []
	for result: Dictionary in space.intersect_shape(query, 32):
		var collider := result.get("collider") as Node3D
		if collider == null:
			continue
		var health := HealthComponent.find_for_hit(collider, player)
		if health == null or health.is_dead or seen.has(health):
			continue
		var point := _closest_point(collider, origin)
		var to_target := point - origin
		var flat := Vector3(to_target.x, 0.0, to_target.z)
		var distance := flat.length()
		if distance > config.max_range:
			continue
		if distance > 0.05 and forward.angle_to(flat / distance) > half_arc:
			continue
		if not _has_line_of_sight(space, origin, point, collider as CollisionObject3D):
			continue
		seen[health] = true
		var direction := flat / distance if distance > 0.05 else forward
		candidates.append({"health": health, "point": point, "direction": direction, "distance": distance})
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["distance"] < b["distance"])
	return candidates.slice(0, maxi(config.max_targets, 0))


func _can_use() -> bool:
	return active and is_instance_valid(player) and is_instance_valid(carry) \
		and is_instance_valid(camera) and player.input_enabled and carry.can_use_weapons()


## Approximate contact point: the collider origin raised to the camera height when the
## body is tall enough, so short and tall bodies are measured at a sensible point.
func _closest_point(collider: Node3D, origin: Vector3) -> Vector3:
	var point := collider.global_position
	point.y = clampf(origin.y, collider.global_position.y, collider.global_position.y + 1.6)
	return point


func _has_line_of_sight(space: PhysicsDirectSpaceState3D, origin: Vector3, point: Vector3,
		collider: CollisionObject3D) -> bool:
	var ray := PhysicsRayQueryParameters3D.create(origin, point, WORLD_MASK)
	var excluded: Array[RID] = [player.get_rid()]
	if collider != null:
		excluded.append(collider.get_rid())
	ray.exclude = excluded
	return space.intersect_ray(ray).is_empty()


func _now() -> float:
	return Time.get_ticks_msec() / 1000.0
