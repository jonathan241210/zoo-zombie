class_name ViewModel
extends Node3D
## First-person view model (spec 001 RF-03, RF-05). ARMED shows the arm with the
## shotgun; CARRYING hides it and shows the food crate held low in front of the camera,
## bobbing while the player walks. (The rig has a single arm, so it cannot hold a crate.)

## Meters walked per bob (one footstep). ~2 bobs/s walking, ~3 sprinting.
const STEP_LENGTH := 2.2
const BOB_AMOUNT := Vector2(0.025, 0.02)
const SWITCH_TIME := 0.25

@export var carry: PlayerCarry
@export var player: CharacterBody3D

var _bob_phase := 0.0

@onready var _arms: Node3D = $Arms
@onready var _crate: Node3D = $Crate
@onready var _arms_rest: Transform3D = _arms.transform
@onready var _crate_rest: Transform3D = _crate.transform


func _ready() -> void:
	# View model meshes float in front of the camera: their shadows would land on the
	# world in odd places, so they never cast shadows.
	for geometry: GeometryInstance3D in find_children("*", "GeometryInstance3D", true, false):
		geometry.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var players := _arms.find_children("*", "AnimationPlayer", true, false)
	if not players.is_empty():
		var animation_player := players[0] as AnimationPlayer
		animation_player.get_animation(&"shotgun_idle").loop_mode = Animation.LOOP_LINEAR
		animation_player.play(&"shotgun_idle")
	carry.state_changed.connect(_on_carry_state_changed)
	_on_carry_state_changed(carry.state)


func _process(delta: float) -> void:
	var horizontal := Vector2(player.velocity.x, player.velocity.z).length()
	if player.is_on_floor() and horizontal > 0.2:
		# One bob (|sin| period = PI) per step.
		_bob_phase += horizontal / STEP_LENGTH * PI * delta
	else:
		_bob_phase = lerpf(_bob_phase, roundf(_bob_phase / PI) * PI, clampf(delta * 6.0, 0.0, 1.0))
	var bob := Vector3(sin(_bob_phase * 0.5) * BOB_AMOUNT.x, -absf(sin(_bob_phase)) * BOB_AMOUNT.y, 0.0)
	_arms.transform = _arms_rest.translated(bob)
	_crate.transform = _crate_rest.translated(bob * 1.5)


func _on_carry_state_changed(state: PlayerCarry.State) -> void:
	var carrying := state == PlayerCarry.State.CARRYING
	_arms.visible = not carrying
	_crate.visible = carrying
	# Small "raise" so swapping does not pop.
	var shown := _crate if carrying else _arms
	var rest := _crate_rest if carrying else _arms_rest
	shown.transform = rest.translated(Vector3.DOWN * 0.25)
	create_tween().tween_property(shown, "transform", rest, SWITCH_TIME) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
