extends Node
## Global signal hub. Declares game-wide events only; holds no state or logic.
## Systems emit here and UI/managers listen, so they never need node paths to each other.
## Signals are emitted from other scripts, so the per-class "unused" warning does not apply.
@warning_ignore_start("unused_signal")

# --- Player ---
signal player_died
signal player_respawned
signal player_carry_changed(is_carrying: bool)

# --- Weapons ---
signal weapon_changed(weapon_id: StringName)
signal ammo_changed(magazine: int, reserve: int)

# --- Zombies ---
signal zombie_killed(zombie: Node3D)
signal zombie_count_changed(alive: int, pending: int)

# --- Animals ---
signal animal_registered(animal: Node3D)
signal animal_fed(animal_id: StringName)
signal animal_state_changed(animal_id: StringName, state: int)
signal animal_weak_changed(animal_id: StringName, is_weak: bool)
signal animal_escaped(animal_id: StringName)
signal animal_recaptured(animal_id: StringName, enclosure: Node3D)
signal animal_died(animal_id: StringName, position: Vector3)

# --- Enclosures ---
signal enclosure_damaged(enclosure: Node3D)
signal enclosure_destroyed(enclosure: Node3D)

# --- Waves ---
signal wave_started(index: int)
signal wave_break_started(index: int)

# --- Score and game flow ---
signal score_changed(score: int)
signal game_won(stats: Dictionary)
signal game_lost(stats: Dictionary)
