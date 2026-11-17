extends SceneTree
## Validates level markers: each must stand on ground, be free of colliders and be on
## (or very near) the ground navmesh. Also checks that buildings have collision.
##   godot --headless --path . -s tools/validate_level.gd

const LEVEL_PATH := "res://scenes/levels/zoo_level.tscn"
const MAX_NAV_DISTANCE := 1.0
## Navmesh polygons above this height (roofs) are not ground.
const GROUND_MAX_HEIGHT := 2.6

var _failures := 0
var _nav_polygons: Array[PackedVector2Array] = []  # ground-level polygons projected to XZ


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var level := (load(LEVEL_PATH) as PackedScene).instantiate() as Node3D
	root.add_child(level)
	await physics_frame
	await physics_frame
	var space := level.get_world_3d().direct_space_state
	_load_navmesh(level)

	for marker in _all_markers(level):
		_check_marker(marker, space)

	# Buildings must be solid: a ray from above their center has to hit their roof
	# (Blender (x, y) -> Godot (x, -y)). Hollow interiors may still be navmesh islands.
	for building: Array in [["EST_CAFETERIA", Vector3(19.3, 0.0, 8.7)],
			["EST_ADMINISTRACION", Vector3(-18.8, 0.0, -37.5)],
			["EST_VETERINARIA", Vector3(-59.2, 0.0, 59.7)]]:
		var center: Vector3 = building[1]
		var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(center + Vector3.UP * 30.0, center))
		var roof_y: float = (hit.position as Vector3).y if not hit.is_empty() else 0.0
		_report(roof_y > 3.0, "%s has collision (roof hit at y=%.1f)" % [building[0], roof_y])

	print("[validate_level] %s (%d failures)" % ["PASS" if _failures == 0 else "FAIL", _failures])
	quit(0 if _failures == 0 else 1)


func _check_marker(marker: Marker3D, space: PhysicsDirectSpaceState3D) -> void:
	var pos := marker.global_position
	var ray := PhysicsRayQueryParameters3D.create(pos + Vector3.UP * 3.0, pos + Vector3.DOWN * 5.0)
	var hit := space.intersect_ray(ray)
	var ground_ok := not hit.is_empty() and absf((hit.position as Vector3).y - pos.y) < 1.0

	var sphere := SphereShape3D.new()
	sphere.radius = 0.4
	var shape_query := PhysicsShapeQueryParameters3D.new()
	shape_query.shape = sphere
	shape_query.transform = Transform3D(Basis(), pos + Vector3.UP * 0.9)
	var blocked := space.intersect_shape(shape_query, 4)

	var nav_dist := _distance_to_navmesh(Vector2(pos.x, pos.z))

	var ok := ground_ok and blocked.is_empty() and nav_dist <= MAX_NAV_DISTANCE
	var detail := "ground=%s free=%s nav=%.1fm" % [ground_ok, blocked.is_empty(), nav_dist]
	if not hit.is_empty():
		detail += " groundY=%.2f" % (hit.position as Vector3).y
	if not blocked.is_empty():
		detail += " blockedBy=%s" % (blocked[0].collider as Node).name
	_report(ok, "%s %s %s" % [marker.get_parent().name, marker.name, detail])


func _report(ok: bool, message: String) -> void:
	if not ok:
		_failures += 1
	print("  [%s] %s" % ["ok" if ok else "FAIL", message])


func _all_markers(node: Node) -> Array[Marker3D]:
	var result: Array[Marker3D] = []
	for child in node.get_children():
		if child is Marker3D:
			result.append(child)
		result.append_array(_all_markers(child))
	return result


func _load_navmesh(level: Node) -> void:
	var navmesh := (level.get_node("NavigationRegion3D") as NavigationRegion3D).navigation_mesh
	var vertices := navmesh.get_vertices()
	for i in navmesh.get_polygon_count():
		var polygon := PackedVector2Array()
		var height := 0.0
		for index in navmesh.get_polygon(i):
			polygon.append(Vector2(vertices[index].x, vertices[index].z))
			height += vertices[index].y
		# Ignore roofs and other raised surfaces; only ground-level walkable area counts.
		if height / polygon.size() < GROUND_MAX_HEIGHT:
			_nav_polygons.append(polygon)


## 0 if the XZ point lies on the navmesh, otherwise the distance to its nearest edge.
func _distance_to_navmesh(point: Vector2) -> float:
	var best := INF
	for polygon in _nav_polygons:
		if Geometry2D.is_point_in_polygon(point, polygon):
			return 0.0
		for i in polygon.size():
			var closest := Geometry2D.get_closest_point_to_segment(point, polygon[i], polygon[(i + 1) % polygon.size()])
			best = minf(best, point.distance_to(closest))
	return best
