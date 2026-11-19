extends GutTest
## Vegetation survives any import mode: every MultiMesh keeps its instance transforms as
## metadata so ZooLevel can restore them (a headless import saves empty buffers).

const MAP := preload("res://assets/models/map/zoo_map.glb")


func test_every_vegetation_multimesh_stores_its_transforms() -> void:
	var map := MAP.instantiate()
	autofree(map)
	var nodes := map.find_children("MM_*", "MultiMeshInstance3D", true, false)
	assert_gt(nodes.size(), 0, "vegetation was converted to MultiMesh")
	var trees := 0
	for node: MultiMeshInstance3D in nodes:
		assert_true(node.has_meta(&"instance_transforms"), "%s has stored transforms" % node.name)
		var transforms: Array = node.get_meta(&"instance_transforms", [])
		assert_eq(transforms.size(), node.multimesh.instance_count, String(node.name))
		if String(node.name).begins_with("MM_ARBOL"):
			trees += transforms.size()
			for xform: Transform3D in transforms:
				assert_ne(xform.basis.get_scale(), Vector3.ZERO, "%s instance has a real scale" % node.name)
	assert_eq(trees, 106, "all trees from the Blender map (63 conifers, 15 wide, 28 broadleaf)")
