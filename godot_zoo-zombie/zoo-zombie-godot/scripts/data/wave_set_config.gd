class_name WaveSetConfig
extends Resource
## Ordered list of waves plus timing between them (spec 001 §6 Oleadas).
## Values in res://config/waves/wave_set.tres are the source of truth.

@export var waves: Array[WaveConfig] = []
## Seconds of rest between waves (no new spawns).
@export var break_duration: float = 15.0
## Countdown before wave 1 starts (spec 002 RF-22).
@export var initial_countdown: float = 5.0
