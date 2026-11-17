@tool
extends EditorScenePostImport
## Post-import for assets/models/map/zoo_map.glb (plan 001 §3.3).
## - Repeated vegetation (shared meshes) becomes one MultiMeshInstance3D per mesh.
## - Tree trunks get cylinder colliders; grass and shrubs get none.
## - Terrain, structures, enclosures, fences and props get static colliders on the
##   "world" layer so the player collides and the navmesh can be baked from them.
## Blender object names are preserved by the glTF importer, so we classify by prefix.

const WORLD_LAYER := 1

## Prefixes merged into MultiMesh instances.
const VEGETATION_PREFIXES: Array[String] = ["ARBOL_", "ARBUSTO_", "PASTO_Mechon"]
## Vegetation that blocks movement (gets a trunk collider).
const TREE_PREFIXES: Array[String] = ["ARBOL_"]
const TRUNK_RADIUS := 0.35
const TRUNK_HEIGHT := 3.0
## Vegetation that should not cast shadows (cheap ground cover).
const NO_SHADOW_PREFIXES: Array[String] = ["PASTO", "ARBUSTO_"]

## Concave (trimesh) colliders: ground and large walk-around geometry.
const TRIMESH_PREFIXES: Array[String] = ["BASE_", "HAB_", "EST_", "REC_", "CERCA_"]
## Convex colliders: small props.
const CONVEX_PREFIXES: Array[String] = ["DET_"]


func _post_import(scene: Node) -> Object:
	var vegetation: Array[MeshInstance3D] = []
	var collidable: Array[MeshInstance3D] = []
	for node in _all_children(scene):
		var mesh_instance := node as MeshInstance3D
		if mesh_instance == null or mesh_instance.mesh == null:
			continue
		var node_name := String(mesh_instance.name)
		if _has_prefix(node_name, VEGETATION_PREFIXES):
			vegetation.append(mesh_instance)
		elif _has_prefix(node_name, TRIMESH_PREFIXES) or _has_prefix(node_name, CONVEX_PREFIXES):
			collidable.append(mesh_instance)

	var colliders_root := StaticBody3D.new()
	colliders_root.name = "WorldColliders"
	colliders_root.collision_layer = 0
	colliders_root.set_collision_layer_value(WORLD_LAYER, true)
	colliders_root.collision_mask = 0
	scene.add_child(colliders_root)
	colliders_root.owner = scene

	var collider_count := 0
	for mesh_instance in collidable:
		collider_count += _add_mesh_collider(mesh_instance, colliders_root, scene)

	var multimesh_count := _build_vegetation(vegetation, scene, colliders_root)
	print("[zoo_map_post_import] colliders: %d, vegetation instances: %d -> %d MultiMesh nodes"
		% [collider_count, vegetation.size(), multimesh_count])
	return scene


func _add_mesh_collider(mesh_instance: MeshInstance3D, body: StaticBody3D, scene: Node) -> int:
	var node_name := String(mesh_instance.name)
	var shape: Shape3D
	if _has_prefix(node_name, CONVEX_PREFIXES):
		shape = mesh_instance.mesh.create_convex_shape(true, true)
	else:
		shape = mesh_instance.mesh.create_trimesh_shape()
	if shape == null:
		return 0
	var collision := CollisionShape3D.new()
	collision.name = node_name + "_col"
	collision.shape = shape
	collision.transform = _transform_to_root(mesh_instance, scene)
	body.add_child(collision)
	collision.owner = scene
	return 1


func _build_vegetation(instances: Array[MeshInstance3D], scene: Node, colliders: StaticBody3D) -> int:
	var root := Node3D.new()
	root.name = "Vegetation"
	scene.add_child(root)
	root.owner = scene

	# Group by shared mesh resource (linked duplicates in Blender share one mesh).
	var groups: Dictionary = {}  # Mesh -> Array[Transform3D]
	var group_names: Dictionary = {}  # Mesh -> representative name
	var cast_shadows: Dictionary = {}  # Mesh -> bool
	for mesh_instance in instances:
		var xform := _transform_to_root(mesh_instance, scene)
		var mesh := mesh_instance.mesh
		if not groups.has(mesh):
			groups[mesh] = []
			group_names[mesh] = String(mesh_instance.name)
			cast_shadows[mesh] = not _has_prefix(String(mesh_instance.name), NO_SHADOW_PREFIXES)
		(groups[mesh] as Array).append(xform)
		if _has_prefix(String(mesh_instance.name), TREE_PREFIXES):
			_add_trunk_collider(xform, colliders, scene)
		mesh_instance.get_parent().remove_child(mesh_instance)
		mesh_instance.queue_free()

	for mesh: Mesh in groups:
		var transforms: Array = groups[mesh]
		var multimesh := MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.mesh = mesh
		multimesh.instance_count = transforms.size()
		for i in transforms.size():
			multimesh.set_instance_transform(i, transforms[i])
		var mm_instance := MultiMeshInstance3D.new()
		mm_instance.name = "MM_" + String(group_names[mesh]).rstrip("0123456789_")
		mm_instance.multimesh = multimesh
		if not cast_shadows[mesh]:
			mm_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(mm_instance, true)
		mm_instance.owner = scene
	return groups.size()


func _add_trunk_collider(xform: Transform3D, body: StaticBody3D, scene: Node) -> void:
	var shape := CylinderShape3D.new()
	shape.radius = TRUNK_RADIUS
	shape.height = TRUNK_HEIGHT
	var collision := CollisionShape3D.new()
	collision.name = "Trunk"
	collision.shape = shape
	collision.position = xform.origin + Vector3.UP * (TRUNK_HEIGHT * 0.5)
	body.add_child(collision, true)
	collision.owner = scene


## Accumulates local transforms up to the scene root (the scene is not in a tree yet,
## so global_transform is unavailable during import).
func _transform_to_root(node: Node3D, scene: Node) -> Transform3D:
	var xform := node.transform
	var parent := node.get_parent()
	while parent != null and parent != scene:
		if parent is Node3D:
			xform = (parent as Node3D).transform * xform
		parent = parent.get_parent()
	return xform


func _all_children(node: Node) -> Array[Node]:
	var result: Array[Node] = []
	for child in node.get_children():
		result.append(child)
		result.append_array(_all_children(child))
	return result


func _has_prefix(node_name: String, prefixes: Array[String]) -> bool:
	for prefix in prefixes:
		if node_name.begins_with(prefix):
			return true
	return false
