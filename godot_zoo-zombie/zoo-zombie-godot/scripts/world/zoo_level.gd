class_name ZooLevel
extends Node3D
## Level root: exposes spawn markers and map nodes to gameplay systems so they never
## hardcode positions. Marker positions were derived from the Blender map
## (Blender (x, y, z) -> Godot (x, z, -y)), see plan 001 §1.3.

@onready var player_spawn: Marker3D = $Markers/PlayerSpawn
@onready var map: Node3D = $NavigationRegion3D/ZooMap


func get_food_crate_spawns() -> Array[Marker3D]:
	return _markers_in("Markers/FoodCrateSpawns")


func get_food_warehouse_markers() -> Array[Marker3D]:
	return _markers_in("Markers/FoodWarehouses")


## Candidate points for map ammo crates, in non-obvious spots (RF-58, RF-59).
func get_ammo_spawns() -> Array[Marker3D]:
	return _markers_in("Markers/AmmoSpawns")


func get_zombie_spawns() -> Array[Marker3D]:
	return _markers_in("Markers/ZombieSpawns")


## Feeder position authored for an enclosure (Markers/Enclosures/<name>/FeederAnchor).
func get_feeder_anchor(enclosure_name: String) -> Marker3D:
	return get_node_or_null("Markers/Enclosures/%s/FeederAnchor" % enclosure_name) as Marker3D


## Returns the map mesh node for an enclosure (e.g. "REC_ESTANQUE_1"), or null.
func find_map_node(node_name: String) -> Node3D:
	return map.find_child(node_name, true, false) as Node3D


func _markers_in(path: String) -> Array[Marker3D]:
	var result: Array[Marker3D] = []
	var parent := get_node_or_null(path)
	if parent == null:
		return result
	for child in parent.get_children():
		if child is Marker3D:
			result.append(child)
	return result


func _ready() -> void:
	_restore_vegetation()
	# Visual layer 2 is reserved for the static zoo map so the minimap viewport can
	# render the environment without drawing moving actors a second time.
	for visual: VisualInstance3D in map.find_children("*", "VisualInstance3D", true, false):
		visual.layers = 1 << 1
	if map is VisualInstance3D:
		(map as VisualInstance3D).layers = 1 << 1


## Re-applies vegetation instance transforms saved as metadata by the map post-import
## script; a headless import leaves the MultiMesh buffers empty (all trees invisible).
func _restore_vegetation() -> void:
	for node: MultiMeshInstance3D in map.find_children("*", "MultiMeshInstance3D", true, false):
		if node.multimesh == null or not node.has_meta(&"instance_transforms"):
			continue
		var transforms: Array = node.get_meta(&"instance_transforms")
		var multimesh := node.multimesh
		if multimesh.instance_count != transforms.size():
			multimesh.instance_count = transforms.size()
		for i in transforms.size():
			multimesh.set_instance_transform(i, transforms[i])
