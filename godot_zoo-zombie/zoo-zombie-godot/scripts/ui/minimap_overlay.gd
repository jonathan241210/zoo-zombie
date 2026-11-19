class_name MinimapOverlay
extends Control
## Player marker, vision cone, north marker and circular outline.

var player: PlayerController
var config: MinimapConfig
var animals: Array[Animal] = []


func configure(source_player: PlayerController, minimap_config: MinimapConfig) -> void:
	player = source_player
	config = minimap_config
	queue_redraw()


func register_animal(animal: Node3D) -> void:
	if animal is Animal and not animals.has(animal):
		animals.append(animal)
		queue_redraw()


func _draw() -> void:
	if player == null or config == null:
		return
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.5
	var yaw := player.global_rotation.y
	var heading := 0.0 if config.rotate_map_with_player else -yaw
	var half_cone := deg_to_rad(config.player_cone_degrees * 0.5)
	var cone_points := PackedVector2Array([
		center,
		center + _direction(heading - half_cone) * radius * 0.74,
		center + _direction(heading + half_cone) * radius * 0.74,
	])
	draw_colored_polygon(cone_points, config.cone_color)
	draw_arc(center, radius - 2.0, 0.0, TAU, 96, config.border_color, 2.0, true)
	_draw_player(center, heading)
	_draw_animals(center, radius)
	_draw_north(center, radius, -yaw if config.rotate_map_with_player else 0.0)


func _draw_animals(center: Vector2, radius: float) -> void:
	var visible_radius := config.far_radius if get_parent() is Minimap and (get_parent() as Minimap).is_far_zoom() else config.near_radius
	for animal in animals:
		if not is_instance_valid(animal):
			continue
		var offset := animal.global_position - player.global_position
		offset.y = 0.0
		if config.rotate_map_with_player:
			offset = offset.rotated(Vector3.UP, -player.global_rotation.y)
		var point := center + Vector2(offset.x, offset.z) / visible_radius * radius
		if point.distance_to(center) > radius - config.animal_marker_radius:
			continue
		var color := config.giraffe_marker_color if animal.config.animal_id == &"giraffe" else config.elephant_marker_color
		if animal.state == Animal.State.DEAD:
			color = config.dead_animal_marker_color
		draw_circle(point, config.animal_marker_radius, Color(0.08, 0.08, 0.08, 0.9))
		draw_circle(point, config.animal_marker_radius - 1.5, color)


func _draw_player(center: Vector2, heading: float) -> void:
	var points := PackedVector2Array([
		Vector2(0.0, -12.0), Vector2(7.0, 7.0), Vector2(0.0, 4.0), Vector2(-7.0, 7.0),
	])
	for index in points.size():
		points[index] = center + points[index].rotated(heading)
	draw_colored_polygon(points, config.player_color)
	draw_circle(center, 2.0, Color(0.12, 0.12, 0.12, 1.0))


func _draw_north(center: Vector2, radius: float, angle: float) -> void:
	var position := center + _direction(angle) * (radius - 17.0)
	draw_string(ThemeDB.fallback_font, position + Vector2(0.0, 5.0), "N",
		HORIZONTAL_ALIGNMENT_CENTER, 24.0, 14, config.north_color)


func _direction(angle: float) -> Vector2:
	return Vector2(sin(angle), -cos(angle))
