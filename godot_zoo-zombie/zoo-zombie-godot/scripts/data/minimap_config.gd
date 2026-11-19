class_name MinimapConfig
extends Resource
## Minimap presentation and update settings (spec 003 §4).

@export var viewport_resolution: int = 256
@export var size_at_1080: float = 220.0
@export var margin_at_1080: float = 24.0
@export var near_radius: float = 40.0
@export var far_radius: float = 90.0
@export var update_frequency: float = 20.0
@export var camera_height: float = 250.0
@export var player_cone_degrees: float = 60.0
@export var rotate_map_with_player: bool = true
@export var player_color: Color = Color(0.95, 0.86, 0.42, 1.0)
@export var cone_color: Color = Color(0.95, 0.86, 0.42, 0.18)
@export var border_color: Color = Color(0.92, 0.82, 0.42, 1.0)
@export var north_color: Color = Color(1.0, 1.0, 1.0, 1.0)
@export var giraffe_marker_color: Color = Color(0.95, 0.72, 0.22, 1.0)
@export var elephant_marker_color: Color = Color(0.35, 0.78, 0.95, 1.0)
@export var dead_animal_marker_color: Color = Color(0.48, 0.48, 0.48, 1.0)
@export var animal_marker_radius: float = 6.0
