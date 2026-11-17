extends Node
## Performance probe for CA-15. Inactive unless the game is launched with `-- --perf`.
## Tours the level viewpoints (player spawn + food crate spawns), spinning the camera
## 360° at each one, with VSync off at 1920x1080, then prints a summary and quits.
##   Godot --path . -- --perf

const SECONDS_PER_VIEWPOINT := 4.0
const WARMUP_SECONDS := 2.0
const RESOLUTION := Vector2i(1920, 1080)

@export var level: ZooLevel
@export var player: PlayerController

var _viewpoints: Array[Transform3D] = []
var _index := -1
var _elapsed := 0.0
var _warmup := WARMUP_SECONDS
var _frame_times: Array[float] = []
var _per_viewpoint: Array[String] = []
var _viewpoint_times: Array[float] = []
var _max_draw_calls := 0
var _max_primitives := 0


func _ready() -> void:
	if not "--perf" in OS.get_cmdline_user_args():
		queue_free()
		return
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	DisplayServer.window_set_size(RESOLUTION)
	Engine.max_fps = 0
	_viewpoints.append(level.player_spawn.global_transform)
	for marker in level.get_food_crate_spawns():
		_viewpoints.append(marker.global_transform)
	player.input_enabled = false
	_next_viewpoint()


func _process(delta: float) -> void:
	if _warmup > 0.0:
		_warmup -= delta
		return
	_elapsed += delta
	_frame_times.append(delta)
	_viewpoint_times.append(delta)
	_max_draw_calls = maxi(_max_draw_calls,
		int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
	_max_primitives = maxi(_max_primitives,
		int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)))
	player.rotate_y(TAU * delta / SECONDS_PER_VIEWPOINT)
	if _elapsed >= SECONDS_PER_VIEWPOINT:
		_per_viewpoint.append("%d:%.0f" % [_index, _average_fps(_viewpoint_times)])
		_next_viewpoint()


func _next_viewpoint() -> void:
	_index += 1
	_elapsed = 0.0
	_viewpoint_times.clear()
	if _index >= _viewpoints.size():
		_report()
		return
	player.respawn_at(_viewpoints[_index])
	player.input_enabled = false


func _report() -> void:
	var sorted := _frame_times.duplicate()
	sorted.sort()
	var worst_count := maxi(1, floori(sorted.size() / 100.0))
	var worst := sorted.slice(sorted.size() - worst_count)
	print("[perf] resolution=%s frames=%d avg_fps=%.1f low1%%_fps=%.1f min_fps=%.1f max_draw_calls=%d max_primitives=%d" % [
		DisplayServer.window_get_size(), sorted.size(), _average_fps(_frame_times),
		_average_fps(worst), 1.0 / sorted[-1], _max_draw_calls, _max_primitives])
	print("[perf] per_viewpoint_avg_fps=", ", ".join(_per_viewpoint))
	get_tree().quit()


func _average_fps(times: Array) -> float:
	var total := 0.0
	for t: float in times:
		total += t
	return times.size() / total if total > 0.0 else 0.0
