extends Node
## Background scene loading with progress reporting. The loading screen UI listens to the signals.

signal load_progress(ratio: float)
signal load_finished(path: String)
signal load_failed(path: String)

var _path: String = ""
var _loading: bool = false
var _progress: Array = []


func _ready() -> void:
	set_process(false)


func is_loading() -> bool:
	return _loading


## Starts loading `path` in a background thread and switches to it when done.
func change_scene(path: String) -> void:
	if _loading:
		push_warning("SceneLoader: already loading %s" % _path)
		return
	var err := ResourceLoader.load_threaded_request(path)
	if err != OK:
		push_error("SceneLoader: cannot load %s (%s)" % [path, error_string(err)])
		load_failed.emit(path)
		return
	_path = path
	_loading = true
	load_progress.emit(0.0)
	set_process(true)


func _process(_delta: float) -> void:
	var status := ResourceLoader.load_threaded_get_status(_path, _progress)
	match status:
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			if not _progress.is_empty():
				load_progress.emit(float(_progress[0]))
		ResourceLoader.THREAD_LOAD_LOADED:
			load_progress.emit(1.0)
			var scene := ResourceLoader.load_threaded_get(_path) as PackedScene
			var finished_path := _path
			_finish()
			if scene == null:
				load_failed.emit(finished_path)
				return
			get_tree().change_scene_to_packed(scene)
			load_finished.emit(finished_path)
		_:
			var failed_path := _path
			_finish()
			push_error("SceneLoader: failed to load %s" % failed_path)
			load_failed.emit(failed_path)


func _finish() -> void:
	_loading = false
	_path = ""
	set_process(false)
