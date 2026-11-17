extends SceneTree
## Computes the first-person transform for the arms+shotgun viewmodel from its geometry
## instead of guessing rotations:
##   - barrel axis = principal axis (PCA) of the shotgun mesh; muzzle = the end on the side of
##     the hand gripping the pump
##   - weapon "up" = away from the elbow (the forearm hangs under the barrel)
## Then it rotates the model so the barrel points at the crosshair with no roll, places
## the muzzle at a camera-space anchor (x = 0 keeps the barrel on the screen's center
## line), prints the Transform3D for player.tscn and saves a preview.
##   Godot --path . -s tools/calibrate_viewmodel.gd -- <out.png> [gun_x,gun_y,gun_z] [scale] [roll_deg]

const MODEL := "res://assets/models/weapons/fp_arms_shotgun.glb"
const CAMERA_FOV := 80.0
## Point (camera space) the barrel aims at: the crosshair, far ahead.
## Aim direction (camera space). Straight ahead: the barrel stays parallel to the view.
const AIM_DIRECTION := Vector3(0.0, 0.0, -1.0)


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var output := args[0]
	var gun_anchor := Vector3(0.16, -0.24, -1.15)  # player.tscn uses this with roll 60
	if args.size() > 1:
		var c := args[1].split(",")
		gun_anchor = Vector3(float(c[0]), float(c[1]), float(c[2]))
	var model_scale := float(args[2]) if args.size() > 2 else 3.0
	## Extra roll (degrees) around the barrel, for fine visual tuning.
	var roll_degrees := float(args[3]) if args.size() > 3 else 0.0

	root.size = Vector2i(960, 540)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.45, 0.6, 0.45)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.7, 0.7, 0.7)
	root.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation = Vector3(-0.8, 0.4, 0)
	root.add_child(sun)
	var camera := Camera3D.new()
	camera.fov = CAMERA_FOV
	camera.near = 0.02
	root.add_child(camera)
	camera.current = true
	var crosshair := ColorRect.new()
	crosshair.color = Color.RED
	crosshair.size = Vector2(6, 6)
	crosshair.position = Vector2(477, 267)
	root.add_child(crosshair)

	var arms := (load(MODEL) as PackedScene).instantiate() as Node3D
	root.add_child(arms)
	var player := arms.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
	player.play(&"shotgun_idle")
	await process_frame
	await process_frame

	var gun := arms.find_child("Escopeta_Modelo_Escopeta_0", true, false) as MeshInstance3D
	var skeleton := arms.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	# Reference = the forearm/elbow: in first person the forearm must hang below the
	# barrel and come back toward the camera, so "down" is toward the elbow.
	var hand := (skeleton.global_transform * skeleton.get_bone_global_pose(skeleton.find_bone("RightHand_06"))).origin
	var elbow := (skeleton.global_transform * skeleton.get_bone_global_pose(skeleton.find_bone("RightForeArm__04"))).origin

	# Barrel axis = principal axis of the gun's vertices in world space (the mesh is
	# rotated inside its local frame, so its bounding box is not aligned with the barrel).
	var points := PackedVector3Array()
	for vertex in gun.mesh.get_faces():
		points.append(gun.global_transform * vertex)
	var gun_center := Vector3.ZERO
	for point in points:
		gun_center += point
	gun_center /= points.size()
	var barrel := _principal_axis(points, gun_center)
	var half_length := 0.0
	for point in points:
		half_length = maxf(half_length, absf((point - gun_center).dot(barrel)))
	# The supporting hand grips the pump, which is on the muzzle half of a shotgun.
	if (hand - gun_center).dot(barrel) < 0.0:
		barrel = -barrel
	var to_elbow := elbow - gun_center
	var up := -(to_elbow - barrel * to_elbow.dot(barrel)).normalized()
	print("[calibrate] barrel=%s up=%s hand=%s gun_center=%s" % [barrel, up, hand, gun_center])

	# Rotation mapping (barrel, up) onto (aim direction, camera up).
	var aim := AIM_DIRECTION.normalized()
	var target_up := (Vector3.UP - aim * Vector3.UP.dot(aim)).normalized()
	var from_frame := Basis(barrel.cross(up), up, -barrel)
	var to_frame := Basis(aim.cross(target_up), target_up, -aim)
	var rotation := Basis(aim, deg_to_rad(roll_degrees)) * to_frame * from_frame.inverse()

	# Muzzle point (arms root still at identity): the eye judges centering by the barrel,
	# so the muzzle (not the gun's bounding-box center) is placed at the anchor.
	var muzzle := gun_center + barrel * half_length
	var basis := rotation.scaled_local(Vector3.ONE * model_scale)
	arms.transform = Transform3D(basis, gun_anchor - basis * muzzle)
	await process_frame
	await process_frame
	print("[calibrate] Transform3D for player.tscn Arms node:")
	print(var_to_str(arms.transform))
	root.get_texture().get_image().save_png(output)
	quit()


## Dominant direction of a point cloud (power iteration on the covariance matrix).
func _principal_axis(points: PackedVector3Array, center: Vector3) -> Vector3:
	var xx := 0.0
	var xy := 0.0
	var xz := 0.0
	var yy := 0.0
	var yz := 0.0
	var zz := 0.0
	for point in points:
		var d := point - center
		xx += d.x * d.x
		xy += d.x * d.y
		xz += d.x * d.z
		yy += d.y * d.y
		yz += d.y * d.z
		zz += d.z * d.z
	var covariance := Basis(Vector3(xx, xy, xz), Vector3(xy, yy, yz), Vector3(xz, yz, zz))
	var axis := Vector3(1, 1, 1).normalized()
	for i in 64:
		axis = (covariance * axis).normalized()
	return axis
