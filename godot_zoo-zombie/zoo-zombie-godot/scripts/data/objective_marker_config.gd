class_name ObjectiveMarkerConfig
extends Resource
## On-screen markers toward escaped animals and free refuges (spec 001 RF-104).

@export var animal_color: Color = Color(1.0, 0.45, 0.2, 1.0)
@export var refuge_color: Color = Color(0.35, 0.85, 1.0, 1.0)
## Height above the target's origin where the marker points (metres).
@export var height_offset: float = 2.5
## Distance from the screen edge for clamped (off-screen) markers, in pixels.
@export var edge_margin: float = 48.0
@export var marker_size: float = 14.0
@export var font_size: int = 16
## Refuges only matter while an animal is loose, so they are hidden otherwise.
@export var refuges_only_while_escaped: bool = true
