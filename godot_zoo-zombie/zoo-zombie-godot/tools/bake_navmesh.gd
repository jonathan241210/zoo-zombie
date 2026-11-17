extends SceneTree
## Bakes the level navmesh from the map's static colliders and saves it as a resource
## referenced by scenes/levels/zoo_level.tscn. Re-run whenever the map changes:
##   godot --headless --path . -s tools/bake_navmesh.gd

const LEVEL_PATH := "res://scenes/levels/zoo_level.tscn"
const NAVMESH_PATH := "res://assets/models/map/zoo_navmesh.res"


func _initialize() -> void:
	_bake.call_deferred()


func _bake() -> void:
	var level: Node = (load(LEVEL_PATH) as PackedScene).instantiate()
	root.add_child(level)
	# Baking parses the scene tree, so wait until the level is fully inside it.
	await process_frame
	var region := level.get_node("NavigationRegion3D") as NavigationRegion3D
	var navmesh := region.navigation_mesh.duplicate() as NavigationMesh
	region.navigation_mesh = navmesh
	var start := Time.get_ticks_msec()
	region.bake_navigation_mesh(false)
	var polygons := navmesh.get_polygon_count()
	print("[bake_navmesh] polygons: %d, vertices: %d, %.1f s" % [
		polygons, navmesh.get_vertices().size(), (Time.get_ticks_msec() - start) / 1000.0])
	var err := ResourceSaver.save(navmesh, NAVMESH_PATH)
	print("[bake_navmesh] saved %s: %s" % [NAVMESH_PATH, error_string(err)])
	quit(0 if err == OK and polygons > 0 else 1)
