class_name ActionFeedConfig
extends Resource
## On-screen action messages (spec 001 RF-10B, §6 Mensajes de acción).
## Values in config/action_feed_config.tres are the source of truth.

@export var message_duration: float = 2.5
@export var fade_time: float = 0.4
@export var max_visible: int = 4
## The same message is not shown again before this many seconds.
@export var repeat_cooldown: float = 2.0
## Longer cooldown for repeated alerts such as "enclosure under attack".
@export var alert_cooldown: float = 10.0
@export var font_size: int = 20
## Fraction of the screen height where the stack is centered (below the crosshair).
@export_range(0.0, 1.0) var vertical_position: float = 0.82
@export var positive_color: Color = Color(0.55, 0.95, 0.5, 1.0)
@export var info_color: Color = Color(0.95, 0.95, 0.95, 1.0)
@export var warning_color: Color = Color(1.0, 0.8, 0.3, 1.0)
@export var danger_color: Color = Color(1.0, 0.4, 0.38, 1.0)
@export var background_color: Color = Color(0.05, 0.06, 0.05, 0.6)
