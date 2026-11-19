class_name Sfx
extends RefCounted
## Fire-and-forget sound effects on the SFX bus. Each call creates a one-shot player
## that frees itself when the sound ends, so the emitter can be freed meanwhile.

const BUS := &"SFX"


## Non-positional sound, e.g. the player's own weapon.
static func play(context: Node, stream: AudioStream, volume_db: float = 0.0, pitch_jitter: float = 0.05) -> void:
	if stream == null or not is_instance_valid(context) or not context.is_inside_tree():
		return
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.bus = BUS
	player.volume_db = volume_db
	player.pitch_scale = 1.0 + randf_range(-pitch_jitter, pitch_jitter)
	_host(context).add_child(player)
	player.finished.connect(player.queue_free)
	player.play()


## Sound placed in the world, e.g. a pickup or an impact.
static func play_at(context: Node, stream: AudioStream, position: Vector3, volume_db: float = 0.0) -> void:
	if stream == null or not is_instance_valid(context) or not context.is_inside_tree():
		return
	var player := AudioStreamPlayer3D.new()
	player.stream = stream
	player.bus = BUS
	player.volume_db = volume_db
	_host(context).add_child(player)
	player.global_position = position
	player.finished.connect(player.queue_free)
	player.play()


static func _host(context: Node) -> Node:
	var tree := context.get_tree()
	return tree.current_scene if tree.current_scene != null else tree.root
