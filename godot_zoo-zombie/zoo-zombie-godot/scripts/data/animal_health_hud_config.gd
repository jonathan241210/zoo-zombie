class_name AnimalHealthHudConfig
extends Resource
## Proximity and presentation settings for animal health rows in the HUD.

@export var visible_distance: float = 12.0
@export var update_frequency: float = 10.0
@export var bar_width: float = 210.0
@export var bar_height: float = 14.0
@export var border_width: float = 2.0
@export var health_fill_color: Color = Color(0.24, 0.78, 0.32, 1.0)
## Health fill and status label color while the animal is weak (RF-27).
@export var weak_fill_color: Color = Color(0.9, 0.2, 0.18, 1.0)
@export var bar_back_color: Color = Color(0.08, 0.12, 0.08, 0.9)
@export var bar_border_color: Color = Color(0.03, 0.04, 0.03, 1.0)
@export var heart_color: Color = Color(1.0, 0.3, 0.34, 1.0)
