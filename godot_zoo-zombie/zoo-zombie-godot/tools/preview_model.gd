extends SceneTree
## Renders an imported model inside Godot (the real consumer) for visual review.
## Plays one animation, samples it at several times and views it from several
## directions, then saves a single contact-sheet PNG (rows = times, cols = views).
##   Godot --path . -s tools/preview_model.gd -- <res://model.glb> <out.png> <anim> <t1,t2,...> [<x,y,z;x,y,z;...>]
## Directions point from the model towards the camera. Default: front, side, 3/4.

const CELL := Vector2i(360, 360)


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var model_path := args[0]
	var output := args[1]
	var anim_name := args[2]
	var times: Array[float] = []
	for t in args[3].split(","):
		times.append(float(t))
	var directions: Array[Vector3] = [Vector3(0, 0.3, 1), Vector3(1, 0.3, 0), Vector3(1, 0.5, 1)]
	if args.size() > 4:
		directions.clear()
		for d in args[4].split(";"):
			var c := d.split(",")
			directions.append(Vector3(float(c[0]), float(c[1]), float(c[2])))

	root.size = CELL
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.3, 0.33, 0.36)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.6, 0.6, 0.6)
	root.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation = Vector3(-0.8, 0.6, 0)
	root.add_child(sun)
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(40, 40)
	ground.mesh = plane
	root.add_child(ground)

	var model := (load(model_path) as PackedScene).instantiate() as Node3D
	root.add_child(model)
	var player: AnimationPlayer = null
	var players := model.find_children("*", "AnimationPlayer", true, false)
	if not players.is_empty():
		player = players[0]
		print("[preview] animations: ", player.get_animation_list())
	var camera := Camera3D.new()
	camera.fov = 40.0
	root.add_child(camera)
	camera.current = true

	var sheet := Image.create(CELL.x * directions.size(), CELL.y * times.size(), false, Image.FORMAT_RGBA8)
	for row in times.size():
		if player != null and player.has_animation(anim_name):
			player.play(anim_name)
			player.seek(times[row], true)
			player.pause()
		await process_frame
		var bounds := _bounds(model)
		ground.position.y = 0.0
		ground.visible = bounds.position.y > -0.5
		var center := bounds.get_center()
		var radius := maxf(bounds.size.length() * 0.5, 0.05)
		var distance := radius / tan(deg_to_rad(camera.fov * 0.5)) * 1.1
		for col in directions.size():
			camera.position = center + directions[col].normalized() * distance
			camera.look_at(center)
			camera.near = distance * 0.01
			await process_frame
			await process_frame
			var image := root.get_texture().get_image()
			image.convert(Image.FORMAT_RGBA8)
			sheet.blit_rect(image, Rect2i(Vector2i.ZERO, CELL), Vector2i(col * CELL.x, row * CELL.y))
		print("[preview] t=%.2f bounds=%s" % [times[row], bounds])
	sheet.save_png(output)
	quit()


## Approximate world bounds from mesh AABBs (skinning is not included for
## MeshInstance3D.get_aabb, so we use skeleton bone positions when there is one).
func _bounds(model: Node3D) -> AABB:
	var result := AABB()
	var first := true
	for skeleton: Skeleton3D in model.find_children("*", "Skeleton3D", true, false):
		for i in skeleton.get_bone_count():
			var p := (skeleton.global_transform * skeleton.get_bone_global_pose(i)).origin
			if first:
				result = AABB(p, Vector3.ZERO)
				first = false
			else:
				result = result.expand(p)
	for mesh: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		if mesh.skeleton != NodePath():
			continue
		var box := mesh.global_transform * mesh.get_aabb()
		if first:
			result = box
			first = false
		else:
			result = result.merge(box)
	return result.grow(result.size.length() * 0.05)
