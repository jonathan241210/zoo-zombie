class_name ObjectiveMarkers
extends Control
## Screen-space markers toward escaped animals and free refuges (spec 001 RF-104).
## On-screen targets get a diamond with name and distance; off-screen or behind-camera
## targets get an arrow clamped to the screen edge.

@export var player: PlayerController
@export var enclosures: EnclosureRegistry
@export var config: ObjectiveMarkerConfig

var _animals: Array[Animal] = []


func _ready() -> void:
	assert(player != null and enclosures != null and config != null)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	EventBus.animal_registered.connect(func(node: Node3D) -> void:
		if node is Animal and not _animals.has(node):
			_animals.append(node as Animal))


func _process(_delta: float) -> void:
	queue_redraw()


## Current targets as [{position, label_key, color}], also used by the tests.
func get_targets() -> Array[Dictionary]:
	var targets: Array[Dictionary] = []
	var any_escaped := false
	for animal in _animals:
		if is_instance_valid(animal) and animal.is_escaped():
			any_escaped = true
			targets.append({"position": animal.global_position, "label_key": animal.config.display_name_key,
				"color": config.animal_color})
	if any_escaped or not config.refuges_only_while_escaped:
		for refuge in enclosures.free_refuges():
			targets.append({"position": refuge.global_position, "label_key": "HUD_REFUGE",
				"color": config.refuge_color})
	return targets


func _draw() -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null or not player.is_inside_tree():
		return
	var font := get_theme_default_font()
	var screen := get_viewport_rect().size
	var safe := Rect2(Vector2.ONE * config.edge_margin, screen - Vector2.ONE * config.edge_margin * 2.0)
	for target in get_targets():
		var world: Vector3 = target["position"] + Vector3.UP * config.height_offset
		var color: Color = target["color"]
		var distance := player.global_position.distance_to(target["position"])
		var label := "%s · %d m" % [tr(target["label_key"]), roundi(distance)]
		var behind := camera.is_position_behind(world)
		var point := camera.unproject_position(world)
		if not behind and safe.has_point(point):
			_draw_diamond(point, color)
			_draw_label(font, point + Vector2(0.0, -config.marker_size - 14.0), label, color)
			continue
		# Off-screen: direction from the screen centre in camera space, clamped to the edge.
		var local := camera.global_transform.affine_inverse() * world
		var direction := Vector2(local.x, -local.y)
		if direction.length_squared() < 0.0001:
			direction = Vector2.DOWN
		direction = direction.normalized()
		var center := screen * 0.5
		var half := safe.size * 0.5
		var scale_to_edge := minf(half.x / maxf(absf(direction.x), 0.0001), half.y / maxf(absf(direction.y), 0.0001))
		var edge := center + direction * scale_to_edge
		_draw_arrow(edge, direction, color)
		_draw_label(font, edge - direction * (config.marker_size * 3.4), label, color)


func _draw_diamond(at: Vector2, color: Color) -> void:
	var s := config.marker_size
	var points := PackedVector2Array([at + Vector2(0, -s), at + Vector2(s, 0), at + Vector2(0, s), at + Vector2(-s, 0)])
	draw_colored_polygon(points, color)
	points.append(points[0])
	draw_polyline(points, Color.BLACK, 2.0)


func _draw_arrow(at: Vector2, direction: Vector2, color: Color) -> void:
	var s := config.marker_size * 1.3
	var side := direction.orthogonal()
	var points := PackedVector2Array([at + direction * s, at - direction * s * 0.6 + side * s * 0.8,
		at - direction * s * 0.6 - side * s * 0.8])
	draw_colored_polygon(points, color)
	points.append(points[0])
	draw_polyline(points, Color.BLACK, 2.0)


func _draw_label(font: Font, center: Vector2, text: String, color: Color) -> void:
	var size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, config.font_size)
	# `center` is the visual centre of the text; draw_string takes the baseline.
	var origin := center + Vector2(-size.x * 0.5, font.get_ascent(config.font_size) * 0.5)
	var screen_width := get_viewport_rect().size.x
	origin.x = clampf(origin.x, 8.0, maxf(screen_width - size.x - 8.0, 8.0))
	draw_string_outline(font, origin, text, HORIZONTAL_ALIGNMENT_LEFT, -1, config.font_size, 5, Color.BLACK)
	draw_string(font, origin, text, HORIZONTAL_ALIGNMENT_LEFT, -1, config.font_size, color)
