extends SceneTree
## Renders the game scene from fixed viewpoints and saves PNGs for visual review.
##   Godot --path . -s tools/capture_screenshots.gd -- <output_dir>


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	root.size = Vector2i(1280, 720)
	var game := (load("res://scenes/main/game.tscn") as PackedScene).instantiate()
	root.add_child(game)
	var player := game.get_node("Player") as CharacterBody3D
	await process_frame
	var shots := [[Vector3(9, 1.6, 8.7), -90.0, 0.0], [Vector3(9, 1.6, 8.7), 90.0, -5.0], [Vector3(15, 1.6, -15), 160.0, -10.0]]
	for i in shots.size():
		player.input_enabled = false
		player.global_position = shots[i][0]
		player.rotation_degrees.y = shots[i][1]
		player.get_node("Head").rotation_degrees.x = shots[i][2]
		for f in 30: await process_frame
		root.get_texture().get_image().save_png("%s/shot_%d.png" % [args[0], i])
	quit()
