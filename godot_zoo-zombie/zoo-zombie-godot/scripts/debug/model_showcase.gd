extends Node3D
## Development showcase of every game model (scenes/tests/model_showcase.tscn).
## Models stand in a row with a label; animated ones cycle through all their animations.
## The camera orbits the focused model.
##   Left/Right arrows (or D-pad): previous/next model
##   Up/Down arrows or mouse wheel: zoom
##   Space: pause/resume the orbit

const MODELS: Array[Array] = [
	["Giraffe", "res://assets/models/animals/giraffe.glb"],
	["Elephant", "res://assets/models/animals/elephant.glb"],
	["Zombie", "res://assets/models/zombies/zombie.glb"],
	["FP arms + shotgun", "res://assets/models/weapons/fp_arms_shotgun.glb"],
	["Axe", "res://assets/models/weapons/axe.glb"],
	["Giraffe feeder", "res://assets/models/props/giraffe_feeder.glb"],
	["Elephant feeder", "res://assets/models/props/elephant_feeder.glb"],
	["Food crate", "res://assets/models/props/food_crate.glb"],
	["Ammo box", "res://assets/models/props/ammo_box.glb"],
]
const SPACING := 7.0
const SECONDS_PER_ANIMATION := 4.0
const ORBIT_SPEED := 0.35

var _entries: Array[Dictionary] = []
var _focus := 0
var _angle := 0.0
var _zoom := 1.0
var _orbiting := true

@onready var _camera: Camera3D = $Camera3D
@onready var _help: Label = $UI/Help


func _ready() -> void:
	for i in MODELS.size():
		var model := (load(MODELS[i][1]) as PackedScene).instantiate() as Node3D
		model.position = Vector3(i * SPACING, 0.0, 0.0)
		add_child(model)
		var height := _estimate_height(model)
		# The FP arms are centered on their origin (they float in front of the camera in game).
		if MODELS[i][0].begins_with("FP arms"):
			model.position.y = 1.2
			height = 1.6
		var label := Label3D.new()
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.font_size = 64
		label.outline_size = 12
		label.position = model.position + Vector3.UP * (height + 0.6)
		add_child(label)
		var player: AnimationPlayer = null
		var players := model.find_children("*", "AnimationPlayer", true, false)
		if not players.is_empty():
			player = players[0]
		_entries.append({"name": MODELS[i][0], "model": model, "label": label, "player": player,
			"height": height, "anim_index": -1, "timer": 0.0})
		_next_animation(_entries[i])


func _process(delta: float) -> void:
	for entry in _entries:
		if entry.player == null:
			entry.label.text = entry.name
			continue
		entry.timer += delta
		if entry.timer >= SECONDS_PER_ANIMATION:
			_next_animation(entry)

	var target: Dictionary = _entries[_focus]
	if _orbiting:
		_angle += ORBIT_SPEED * delta
	var center: Vector3 = target.model.position + Vector3.UP * target.height * 0.5
	var distance: float = maxf(target.height * 1.8, 2.0) * _zoom
	_camera.position = center + Vector3(sin(_angle), 0.35, cos(_angle)) * distance
	_camera.look_at(center)
	_help.text = "%s  (%d/%d)\n←/→ cambiar modelo · ↑/↓ o rueda: zoom · Espacio: pausar giro" % [
		target.name, _focus + 1, _entries.size()]


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_right"):
		_focus = (_focus + 1) % _entries.size()
	elif event.is_action_pressed(&"ui_left"):
		_focus = (_focus - 1 + _entries.size()) % _entries.size()
	elif event.is_action_pressed(&"ui_up"):
		_zoom = maxf(_zoom * 0.85, 0.3)
	elif event.is_action_pressed(&"ui_down"):
		_zoom = minf(_zoom * 1.15, 3.0)
	elif event is InputEventMouseButton and event.is_pressed():
		var button := (event as InputEventMouseButton).button_index
		if button == MOUSE_BUTTON_WHEEL_UP:
			_zoom = maxf(_zoom * 0.9, 0.3)
		elif button == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom = minf(_zoom * 1.1, 3.0)
	elif event.is_action_pressed(&"ui_accept") or (event is InputEventKey and event.is_pressed()
			and (event as InputEventKey).physical_keycode == KEY_SPACE):
		_orbiting = not _orbiting


func _next_animation(entry: Dictionary) -> void:
	entry.timer = 0.0
	var player: AnimationPlayer = entry.player
	if player == null:
		return
	var animations := player.get_animation_list()
	if animations.is_empty():
		return
	entry.anim_index = (entry.anim_index + 1) % animations.size()
	var anim_name: StringName = animations[entry.anim_index]
	var animation := player.get_animation(anim_name)
	if animation.loop_mode == Animation.LOOP_NONE and anim_name != &"death":
		animation.loop_mode = Animation.LOOP_LINEAR
	player.play(anim_name, 0.3)
	entry.label.text = "%s\n%s" % [entry.name, anim_name]


func _estimate_height(model: Node3D) -> float:
	var top := 0.3
	for mesh: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		var box := mesh.global_transform * mesh.get_aabb()
		top = maxf(top, box.end.y)
	return top
