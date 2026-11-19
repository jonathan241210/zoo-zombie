class_name ActionFeed
extends Control
## Short on-screen messages that confirm player actions and warn about animals
## (spec 001 RF-10B). Only listens to EventBus; every text is a translation key.

enum Kind { POSITIVE, INFO, WARNING, DANGER }

@export var config: ActionFeedConfig

var _stack: VBoxContainer
## Message key -> time (s) when it was last shown, for the repeat cooldown.
var _last_shown: Dictionary = {}


func _ready() -> void:
	assert(config != null, "ActionFeed needs an ActionFeedConfig")
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_stack = VBoxContainer.new()
	_stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stack.alignment = BoxContainer.ALIGNMENT_END
	_stack.add_theme_constant_override("separation", 6)
	add_child(_stack)
	resized.connect(_layout)
	_layout()
	EventBus.food_crate_picked_up.connect(func() -> void: show_message("MSG_CRATE_PICKED_UP", Kind.POSITIVE))
	EventBus.food_crate_dropped.connect(func() -> void: show_message("MSG_CRATE_DROPPED", Kind.INFO))
	EventBus.ammo_collected.connect(func(amount: int) -> void:
		show_message("MSG_AMMO_COLLECTED", Kind.POSITIVE, {"amount": amount}))
	EventBus.ammo_reserve_full.connect(func() -> void: show_message("MSG_AMMO_FULL", Kind.WARNING))
	EventBus.weapon_empty.connect(_on_weapon_empty)
	EventBus.action_blocked.connect(_on_action_blocked)
	EventBus.weapon_changed.connect(_on_weapon_changed)
	EventBus.animal_fed.connect(func(animal_id: StringName) -> void:
		show_message(_animal_key("MSG_FED", animal_id), Kind.POSITIVE))
	EventBus.animal_weak_changed.connect(func(animal_id: StringName, is_weak: bool) -> void:
		if is_weak:
			show_message(_animal_key("MSG_WEAK", animal_id), Kind.WARNING))
	EventBus.animal_died.connect(func(animal_id: StringName, _position: Vector3) -> void:
		show_message(_animal_key("MSG_DIED", animal_id), Kind.DANGER))
	EventBus.player_died.connect(func() -> void: show_message("MSG_PLAYER_DIED", Kind.DANGER))
	EventBus.player_respawned.connect(func() -> void: show_message("MSG_PLAYER_RESPAWNED", Kind.INFO))
	EventBus.enclosure_damaged.connect(_on_enclosure_damaged)
	EventBus.animal_escaped.connect(func(animal_id: StringName) -> void:
		show_message(_animal_key("MSG_ESCAPED", animal_id), Kind.DANGER))
	EventBus.animal_state_changed.connect(_on_animal_state_changed)
	EventBus.animal_recaptured.connect(func(animal_id: StringName, _enclosure: Node3D) -> void:
		show_message(_animal_key("MSG_RECAPTURED", animal_id), Kind.POSITIVE))


## Shows a translated message unless the same one was shown less than
## `repeat_cooldown` seconds ago. Returns the label, or null when skipped.
func show_message(key: String, kind: Kind, args: Dictionary = {}, cooldown: float = -1.0) -> Label:
	var now := Time.get_ticks_msec() / 1000.0
	var cooldown_key := key + str(args)
	var wait := config.repeat_cooldown if cooldown < 0.0 else cooldown
	if _last_shown.has(cooldown_key) and now - float(_last_shown[cooldown_key]) < wait:
		return null
	_last_shown[cooldown_key] = now
	var text := tr(key)
	if not args.is_empty():
		text = text.format(args)
	var label := _make_label(text, kind)
	_stack.add_child(label)
	while _stack.get_child_count() > maxi(config.max_visible, 1):
		var oldest := _stack.get_child(0)
		_stack.remove_child(oldest)
		oldest.queue_free()
	var tween := label.create_tween()
	tween.tween_interval(maxf(config.message_duration - config.fade_time, 0.0))
	tween.tween_property(label, "modulate:a", 0.0, config.fade_time)
	tween.tween_callback(label.queue_free)
	return label


## Texts of the messages on screen, oldest first (for tests and debugging).
func visible_texts() -> PackedStringArray:
	var texts := PackedStringArray()
	for child in _stack.get_children():
		if child is Label and not child.is_queued_for_deletion():
			texts.append((child as Label).text)
	return texts


func _on_weapon_empty(has_reserve: bool) -> void:
	if has_reserve:
		show_message("MSG_RELOAD_HINT", Kind.WARNING, {"key": _action_key(&"reload")})
	else:
		show_message("MSG_NO_AMMO", Kind.DANGER)


func _on_action_blocked(reason: StringName) -> void:
	if reason == &"weapons_while_carrying":
		show_message("MSG_WEAPONS_BLOCKED", Kind.WARNING, {"key": _action_key(&"interact")})


func _on_enclosure_damaged(enclosure: Node3D) -> void:
	var holder := enclosure as Enclosure
	if holder == null or holder.is_destroyed or not (holder.occupant is Animal):
		return
	var animal_id := (holder.occupant as Animal).config.animal_id
	show_message(_animal_key("MSG_ENCLOSURE_ATTACKED", animal_id), Kind.WARNING, {}, config.alert_cooldown)


func _on_animal_state_changed(animal_id: StringName, state: int) -> void:
	if state == Animal.State.FOLLOWING:
		show_message(_animal_key("MSG_FOLLOWING", animal_id), Kind.INFO, {}, config.alert_cooldown)


func _on_weapon_changed(weapon_id: StringName) -> void:
	show_message("MSG_WEAPON_" + String(weapon_id).to_upper(), Kind.INFO)


## Per-species key (e.g. MSG_FED_GIRAFFE) so Spanish articles agree ("a la jirafa",
## "al elefante"); falls back to the generic key with the animal name.
func _animal_key(prefix: String, animal_id: StringName) -> String:
	var specific := "%s_%s" % [prefix, String(animal_id).to_upper()]
	return specific if tr(specific) != specific else prefix


## Name of the first keyboard/mouse binding of an action, e.g. "R".
func _action_key(action: StringName) -> String:
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			var key := event as InputEventKey
			var code := key.physical_keycode if key.physical_keycode != KEY_NONE else key.keycode
			return OS.get_keycode_string(code)
	return String(action)


func _make_label(text: String, kind: Kind) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	label.add_theme_font_size_override("font_size", config.font_size)
	label.add_theme_color_override("font_color", _color(kind))
	label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.85))
	label.add_theme_constant_override("outline_size", 4)
	var style := StyleBoxFlat.new()
	style.bg_color = config.background_color
	style.set_corner_radius_all(6)
	style.content_margin_left = 14.0
	style.content_margin_right = 14.0
	style.content_margin_top = 4.0
	style.content_margin_bottom = 4.0
	label.add_theme_stylebox_override("normal", style)
	return label


func _color(kind: Kind) -> Color:
	match kind:
		Kind.POSITIVE:
			return config.positive_color
		Kind.WARNING:
			return config.warning_color
		Kind.DANGER:
			return config.danger_color
	return config.info_color


func _layout() -> void:
	# The stack grows upward from a point below the crosshair.
	var bottom := size.y * config.vertical_position
	_stack.position = Vector2(0.0, 0.0)
	_stack.size = Vector2(size.x, bottom)
