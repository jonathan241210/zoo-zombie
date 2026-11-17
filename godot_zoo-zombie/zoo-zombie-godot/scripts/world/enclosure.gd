class_name Enclosure
extends Node3D
## A map enclosure that can hold one animal (spec 001 §5.4). Built at runtime from the
## map mesh with the same name (e.g. "REC_HEX_CENTRAL"); its interior bounds come from
## that mesh. Integrity/destruction is added in phase 7.

const INTERIOR_MARGIN := 1.2
const POINT_ATTEMPTS := 32
const WORLD_LAYER := 1
## Points whose floor is higher than the enclosure ground by more than this (rocks,
## beams, shelter roofs) are rejected.
const MAX_FLOOR_STEP := 0.4
const GROUND_SAMPLES := 16

## Map node name, e.g. "REC_RECINTO_ESTE".
var map_name: String = ""
## Interior bounds in world space (ground level at position.y).
var interior: AABB
## Where this enclosure's feeder stands (local +Z points into the enclosure).
var feeder_anchor: Transform3D
var has_feeder_anchor: bool = false
var occupant: Node3D = null
## Fence outline seen from above (XZ, world space), shrunk by INTERIOR_MARGIN. Built
## from the convex hull of the map mesh, which matches hexagonal and rectangular pens.
var outline: PackedVector2Array = PackedVector2Array()

## Top of the map mesh bounds, used to cast floor rays from above.
var _top_y: float = 0.0
## Enclosure ground height, measured lazily with rays (the map mesh extends underground).
var _ground_y: float = NAN


func setup(map_node: Node3D, anchor: Marker3D) -> void:
	map_name = map_node.name
	name = "Enclosure_" + map_name
	var bounds := _world_bounds(map_node)
	var ground_y := bounds.position.y
	_top_y = bounds.end.y
	global_position = Vector3(bounds.get_center().x, ground_y, bounds.get_center().z)
	interior = AABB(
		Vector3(bounds.position.x + INTERIOR_MARGIN, ground_y, bounds.position.z + INTERIOR_MARGIN),
		Vector3(maxf(bounds.size.x - INTERIOR_MARGIN * 2.0, 0.5), 0.0,
			maxf(bounds.size.z - INTERIOR_MARGIN * 2.0, 0.5)))
	outline = _build_outline(map_node)
	if anchor != null:
		feeder_anchor = anchor.global_transform
		has_feeder_anchor = true


func is_free() -> bool:
	return occupant == null


## Random walkable point inside the enclosure. When `from` is given, the straight line
## from it must be unobstructed (so wandering never tries to cross fences or rocks).
func random_interior_point(body_radius: float, from: Variant = null,
		exclude: Array[RID] = []) -> Vector3:
	var space := get_world_3d().direct_space_state
	var ground := ground_height()
	for attempt in POINT_ATTEMPTS:
		var floor_y: Variant = _floor_at(space, randf_range(interior.position.x, interior.end.x),
			randf_range(interior.position.z, interior.end.z), exclude)
		if floor_y == null:
			continue
		var point: Vector3 = floor_y
		if point.y > ground + MAX_FLOOR_STEP:
			continue
		if not _is_free(space, point, body_radius, exclude):
			continue
		if not is_inside(point):
			continue
		if from is Vector3 and not _has_clear_path(space, from, point, body_radius, exclude):
			continue
		return point
	var fallback := interior.get_center()
	fallback.y = ground
	return fallback


## True if the point lies inside the fence outline (shrunk by INTERIOR_MARGIN).
func is_inside(point: Vector3) -> bool:
	return Geometry2D.is_point_in_polygon(Vector2(point.x, point.z), outline)


## Lowest floor height found inside the enclosure (cached after the first measure).
func ground_height() -> float:
	if not is_nan(_ground_y):
		return _ground_y
	var space := get_world_3d().direct_space_state
	var lowest := INF
	for i in GROUND_SAMPLES:
		var hit: Variant = _floor_at(space, randf_range(interior.position.x, interior.end.x),
			randf_range(interior.position.z, interior.end.z), [])
		if hit != null:
			lowest = minf(lowest, (hit as Vector3).y)
	_ground_y = lowest if lowest < INF else interior.position.y
	global_position.y = _ground_y
	return _ground_y


## World point where a vertical ray at (x, z) hits the floor, or null.
func _floor_at(space: PhysicsDirectSpaceState3D, x: float, z: float, exclude: Array[RID]) -> Variant:
	var ray := PhysicsRayQueryParameters3D.create(Vector3(x, _top_y + 2.0, z),
		Vector3(x, interior.position.y - 2.0, z), 1 << (WORLD_LAYER - 1), exclude)
	var hit := space.intersect_ray(ray)
	return hit.position if not hit.is_empty() else null


func _is_free(space: PhysicsDirectSpaceState3D, point: Vector3, radius: float,
		exclude: Array[RID]) -> bool:
	var shape := SphereShape3D.new()
	shape.radius = radius
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.collision_mask = 1 << (WORLD_LAYER - 1)
	query.exclude = exclude
	query.transform = Transform3D(Basis(), point + Vector3.UP * (radius + 0.3))
	return space.intersect_shape(query, 1).is_empty()


## Sweeps a sphere as wide as the animal from `from` to `to`: a thin ray would pass
## beside a rock that the body still hits.
func _has_clear_path(space: PhysicsDirectSpaceState3D, from: Vector3, to: Vector3,
		radius: float, exclude: Array[RID]) -> bool:
	var shape := SphereShape3D.new()
	# 80% of the clearance radius (still wider than the animal's collider) so a sweep
	# that starts while brushing a rock is not considered blocked in every direction.
	shape.radius = radius * 0.8
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.collision_mask = 1 << (WORLD_LAYER - 1)
	query.exclude = exclude
	var lift := Vector3.UP * (radius + 0.3)
	query.transform = Transform3D(Basis(), from + lift)
	query.motion = (to + lift) - (from + lift)
	var result := space.cast_motion(query)
	return result[0] >= 1.0


func _build_outline(node: Node3D) -> PackedVector2Array:
	var points := PackedVector2Array()
	for mesh_node in _meshes_of(node):
		var mesh := mesh_node as MeshInstance3D
		for vertex in mesh.mesh.get_faces():
			var world := mesh.global_transform * vertex
			points.append(Vector2(world.x, world.z))
	var hull := Geometry2D.convex_hull(points)
	var shrunk := Geometry2D.offset_polygon(hull, -INTERIOR_MARGIN)
	return shrunk[0] if not shrunk.is_empty() else hull


func _meshes_of(node: Node3D) -> Array[Node]:
	var meshes: Array[Node] = node.find_children("*", "MeshInstance3D", true, false)
	if node is MeshInstance3D:
		meshes.append(node)
	return meshes


func _world_bounds(node: Node3D) -> AABB:
	var result := AABB()
	var first := true
	for mesh_node in _meshes_of(node):
		var mesh := mesh_node as MeshInstance3D
		var box := mesh.global_transform * mesh.get_aabb()
		result = box if first else result.merge(box)
		first = false
	return result
