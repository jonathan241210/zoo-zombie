class_name ViewModel
extends Node3D
## First-person view model (spec 001 RF-03, RF-05). ARMED shows the arm with the
## shotgun; CARRYING hides it and shows the food crate held low in front of the camera,
## bobbing while the player walks. (The rig has a single arm, so it cannot hold a crate.)
## The same arm holds either the shotgun (bone attachment in the GLB) or the axe, which is
## attached to the hand bone at runtime (RF-5A, RF-5B). The rig's hammer animation
## swings the arm out of the camera, so the axe swing is procedural: the arm rotates
## around the camera (wind-up, diagonal chop, recovery), like the procedural reload.

## Meters walked per bob (one footstep). ~2 bobs/s walking, ~3 sprinting.
const STEP_LENGTH := 2.2
const BOB_AMOUNT := Vector2(0.025, 0.02)
const SWITCH_TIME := 0.25

@export var carry: PlayerCarry
@export var player: CharacterBody3D
@export var axe_scene: PackedScene
## Axe pose relative to the right hand bone.
@export var axe_grip_transform: Transform3D = Transform3D.IDENTITY
@export var hand_bone: StringName = &"RightHand_06"
## How far the arm drops while switching weapons.
@export var switch_drop: float = 0.35
## Swing keyframes as Euler angles in degrees (pitch, yaw, roll) around the camera.
@export var swing_windup_degrees := Vector3(14.0, -8.0, -18.0)
@export var swing_chop_degrees := Vector3(-10.0, 20.0, 28.0)
## Seconds for wind-up, chop and recovery.
@export var swing_times := Vector3(0.16, 0.16, 0.38)

var weapon: StringName = &"shotgun"

var _bob_phase := 0.0
## Extra downward offset animated while switching weapons.
var _switch_offset := 0.0
## Current swing rotation around the camera (radians).
var _swing_rotation := Vector3.ZERO
var _swing_tween: Tween
var _animation_player: AnimationPlayer
var _shotgun_parts: Array[Node3D] = []
var _axe: Node3D

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
		_animation_player = players[0] as AnimationPlayer
		for idle: StringName in [&"shotgun_idle", &"axe_idle"]:
			if _animation_player.has_animation(idle):
				_animation_player.get_animation(idle).loop_mode = Animation.LOOP_LINEAR
	_setup_weapon_meshes()
	show_weapon(weapon)
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
	var swing := Transform3D(Basis.from_euler(_swing_rotation), Vector3.ZERO)
	_arms.transform = swing * _arms_rest.translated(bob + Vector3.DOWN * _switch_offset)
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


## Shows the given weapon ("shotgun" or "axe") in its idle pose immediately.
func show_weapon(weapon_name: StringName) -> void:
	weapon = weapon_name
	var is_axe := weapon == &"axe"
	for part in _shotgun_parts:
		part.visible = not is_axe
	if _axe != null:
		_axe.visible = is_axe
	_play(&"axe_idle" if is_axe else &"shotgun_idle")


## Lowers the arm, swaps the weapon halfway and raises it again over `duration`.
func play_switch(weapon_name: StringName, duration: float) -> void:
	var half := maxf(duration, 0.02) * 0.5
	var tween := create_tween()
	tween.tween_property(self, "_switch_offset", switch_drop, half) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(show_weapon.bind(weapon_name))
	tween.tween_property(self, "_switch_offset", 0.0, half) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func play_axe_swing() -> void:
	if _swing_tween != null and _swing_tween.is_valid():
		_swing_tween.kill()
	var windup := swing_windup_degrees * (PI / 180.0)
	var chop := swing_chop_degrees * (PI / 180.0)
	_swing_tween = create_tween()
	_swing_tween.tween_property(self, "_swing_rotation", windup, swing_times.x) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_swing_tween.tween_property(self, "_swing_rotation", chop, swing_times.y) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_swing_tween.tween_property(self, "_swing_rotation", Vector3.ZERO, swing_times.z) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)


func _setup_weapon_meshes() -> void:
	for attachment: BoneAttachment3D in _arms.find_children("*", "BoneAttachment3D", true, false):
		for child in attachment.get_children():
			if child is Node3D:
				_shotgun_parts.append(child)
	var skeletons := _arms.find_children("*", "Skeleton3D", true, false)
	if axe_scene == null or skeletons.is_empty():
		return
	var skeleton := skeletons[0] as Skeleton3D
	var hand := BoneAttachment3D.new()
	hand.name = "AxeAttachment"
	hand.bone_name = hand_bone
	skeleton.add_child(hand)
	_axe = axe_scene.instantiate() as Node3D
	_axe.transform = axe_grip_transform
	hand.add_child(_axe)
	for geometry: GeometryInstance3D in _axe.find_children("*", "GeometryInstance3D", true, false):
		geometry.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_axe.visible = false


func _play(animation_name: StringName) -> void:
	if _animation_player != null and _animation_player.has_animation(animation_name):
		_animation_player.play(animation_name)
