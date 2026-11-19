class_name AnimalConfig
extends Resource
## Per-animal tuning (spec 001 §6 Animales).
## Values in the matching .tres under res://config/ are the source of truth.

@export var animal_id: StringName = &"giraffe"
## Translation key.
@export var display_name_key: String = "ANIMAL_GIRAFFE"
## Initial enclosure node name in the map.
@export var home_enclosure: String = "REC_HEX_CENTRAL"
@export var max_health: float = 100.0
## Whether direct attacks from the player can damage this animal.
@export var player_damageable: bool = true
## Seconds without hunger damage after eating.
@export var grace_period: float = 30.0
@export var starvation_damage_per_second: float = 0.8
@export var heal_per_feeding: float = 50.0
## Health ratio below which the animal is weak.
@export var weak_threshold: float = 0.3
## Movement speed multiplier while weak (RF-27).
@export var weak_speed_multiplier: float = 0.5
@export var walk_speed: float = 2.0
@export var run_speed: float = 6.5
@export var tired_speed: float = 1.2
@export var max_stamina: float = 100.0
@export var stamina_drain_per_second: float = 15.0
@export var stamina_regen_per_second: float = 10.0
## Stamina ratio to stop being tired.
@export var tired_recovery_ratio: float = 0.5
## An escaped animal runs away from zombies closer than this (RF-40).
@export var flee_radius: float = 12.0
## Meters an escaping animal runs past its broken fence before roaming freely.
@export var exit_distance: float = 3.0
@export var lure_radius: float = 8.0
@export var follow_max_radius: float = 15.0
@export var follow_distance: float = 2.5
@export var feed_score: int = 150
## Ground speed (m/s) the walk/run animation clips were authored for, measured from the
## foot motion. Playback speed is scaled by actual_speed / anim_speed to avoid sliding.
@export var walk_anim_speed: float = 2.07
@export var run_anim_speed: float = 4.67
## Seconds the eat animation plays after being fed.
@export var eat_duration: float = 6.0
## Random pause range (seconds) between walks while wandering in the enclosure.
@export var idle_time_min: float = 3.0
@export var idle_time_max: float = 8.0
## Extra zombies spawned when it dies.
@export var death_horde_size: int = 6
## Fallback delay before removing the animal after its death animation starts.
@export var death_despawn_delay: float = 2.25
