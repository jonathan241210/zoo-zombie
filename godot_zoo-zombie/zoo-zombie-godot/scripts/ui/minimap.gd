class_name Minimap
extends Control
## Circular real-world minimap with player heading and near/far zoom (spec 003 phase A).

@export var player: PlayerController
@export var level: ZooLevel
@export var config: MinimapConfig

@onready var _map_viewport: SubViewport = $MapViewport
@onready var _camera_pivot: Node3D = $MapViewport/CameraPivot
@onready var _map_camera: Camera3D = $MapViewport/CameraPivot/MapCamera
@onready var _map_texture: TextureRect = %MapTexture
@onready var _overlay: MinimapOverlay = %Overlay

var _refresh_elapsed := 0.0
var _zoom_far := false
var _last_viewport_size := Vector2.ZERO


func _ready() -> void:
	assert(player != null and level != null and config != null)
	_map_viewport.size = Vector2i(config.viewport_resolution, config.viewport_resolution)
	_map_viewport.world_3d = get_viewport().world_3d
	_map_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	_map_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_map_camera.size = config.near_radius * 2.0
	_map_camera.cull_mask = 1 << 1
	_map_camera.current = true
	_map_camera.rotation.x = -PI * 0.5
	_map_texture.texture = _map_viewport.get_texture()
	_overlay.configure(player, config, level.get_food_warehouse_markers())
	EventBus.animal_registered.connect(_overlay.register_animal)
	InputGlyphs.device_changed.connect(_on_device_changed)
	_update_layout()
	_update_camera()
	_request_viewport_update()


func _process(delta: float) -> void:
	if Input.is_action_just_pressed(&"minimap_zoom"):
		_zoom_far = not _zoom_far
		_update_camera()
	_refresh_elapsed += delta
	var refresh_period := 1.0 / maxf(config.update_frequency, 1.0)
	if _refresh_elapsed >= refresh_period:
		_refresh_elapsed = 0.0
		if get_viewport_rect().size != _last_viewport_size:
			_update_layout()
		_update_camera()
		_overlay.queue_redraw()
		_request_viewport_update()


func _update_camera() -> void:
	_camera_pivot.global_position = player.global_position + Vector3.UP * config.camera_height
	_camera_pivot.rotation.y = player.global_rotation.y if config.rotate_map_with_player else 0.0
	_map_camera.size = (config.far_radius if _zoom_far else config.near_radius) * 2.0


func _request_viewport_update() -> void:
	_map_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE


func _update_layout() -> void:
	var viewport_size := get_viewport_rect().size
	_last_viewport_size = viewport_size
	var scale_factor := viewport_size.y / 1080.0
	var side := config.size_at_1080 * scale_factor
	var margin := config.margin_at_1080 * scale_factor
	var origin := Vector2(viewport_size.x - side - margin, margin)
	# Positioned by code: anchor both to the top-left so setting the size is allowed.
	for control: Control in [_map_texture, _overlay]:
		control.set_anchors_preset(Control.PRESET_TOP_LEFT)
		control.position = origin
		control.size = Vector2(side, side)
	_overlay.queue_redraw()


func _on_device_changed(_device: StringName) -> void:
	_overlay.queue_redraw()


func is_far_zoom() -> bool:
	return _zoom_far
