class_name EnclosureConfig
extends Resource
## Enclosure tuning (spec 001 §6 Recintos).
## Values in the matching .tres under res://config/ are the source of truth.

@export var max_integrity: float = 300.0
## Points around the fence where breaker zombies stand to hit it.
@export var attack_point_count: int = 8
## Distance of those points outside the fence (m).
@export var attack_point_offset: float = 1.0
## A following animal this close to a free refuge's fence is recaptured (m, RF-45).
@export var recapture_radius: float = 3.0
## How much of its height a destroyed enclosure sinks (0-1), and in how many seconds.
@export var destroyed_sink_ratio: float = 0.85
@export var destroyed_sink_time: float = 1.2
## Map enclosures that can receive an escaped animal.
@export var refuge_enclosures: PackedStringArray = PackedStringArray(["REC_RECINTO_NORTE_CENTRAL", "REC_JAULA_NORTE_2", "REC_HEX_SUR_5"])
