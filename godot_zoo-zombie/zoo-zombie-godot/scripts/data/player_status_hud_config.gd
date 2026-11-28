class_name PlayerStatusHudConfig
extends Resource
## Presentation and alert thresholds for the player status HUD (spec 001 RF-100, RF-109).

## Reserve shells at or below this value turn the ammo readout to the warning color.
@export var low_reserve_threshold: int = 6
@export var ammo_color: Color = Color(1.0, 1.0, 1.0, 1.0)
## Low reserve.
@export var ammo_warning_color: Color = Color(1.0, 0.72, 0.2, 1.0)
## Empty magazine.
@export var ammo_empty_color: Color = Color(0.95, 0.25, 0.2, 1.0)
@export var shotgun_icon: Texture2D
@export var axe_icon: Texture2D
