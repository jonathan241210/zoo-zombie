class_name EnclosureConfig
extends Resource
## Enclosure tuning (spec 001 §6 Recintos).
## Values in the matching .tres under res://config/ are the source of truth.

@export var max_integrity: float = 300.0
## Map enclosures that can receive an escaped animal.
@export var refuge_enclosures: PackedStringArray = PackedStringArray("REC_ESTANQUE_1", "REC_RECINTO_RUSTICO_M5_CENTRO_SUR", "REC_RECINTO_NORTE_CENTRAL")
