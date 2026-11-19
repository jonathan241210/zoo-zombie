class_name HitEffects
extends RefCounted
## Small visual feedback shared by the player's weapons (RF-53, RF-5C).


## Brief glowing spark at a hit point that shrinks and disappears.
static func spawn_impact(context: Node, point: Vector3, normal: Vector3,
		color: Color = Color(1.0, 0.48, 0.12), radius: float = 0.035) -> void:
	if not is_instance_valid(context) or not context.is_inside_tree():
		return
	var tree := context.get_tree()
	var host: Node = tree.current_scene if tree.current_scene != null else tree.root
	var marker := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	marker.mesh = mesh
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	marker.material_override = material
	marker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	host.add_child(marker)
	marker.global_position = point + normal * 0.025
	var tween := marker.create_tween()
	tween.tween_property(marker, "scale", Vector3.ZERO, 0.22)
	tween.tween_callback(marker.queue_free)
