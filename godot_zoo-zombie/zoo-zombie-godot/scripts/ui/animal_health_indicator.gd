class_name AnimalHealthIndicator
extends HBoxContainer
## Compact animal card (spec 001 RF-101, RF-108, CA-25): heart, name, a small yellow
## enclosure-integrity bar right above the green health bar, and the status label.
## The integrity bar only shows while the animal has an enclosure. No satiety bar.

var animal: Animal
var config: AnimalHealthHudConfig

var _health_bar: ProgressBar
var _integrity_bar: ProgressBar
var _status_label: Label
var _bound_enclosure: Enclosure = null


func configure(source_animal: Animal, hud_config: AnimalHealthHudConfig) -> void:
	animal = source_animal
	config = hud_config


func _ready() -> void:
	add_theme_constant_override("separation", 6)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var heart := Label.new()
	heart.text = "♥"
	heart.custom_minimum_size = Vector2(18.0, config.bar_height)
	heart.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	heart.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heart.add_theme_color_override("font_color", config.heart_color)
	heart.add_theme_font_size_override("font_size", 16)
	add_child(heart)
	var animal_name := Label.new()
	animal_name.text = tr(animal.config.display_name_key)
	animal_name.custom_minimum_size = Vector2(64.0, config.bar_height)
	animal_name.clip_text = true
	animal_name.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	animal_name.add_theme_font_size_override("font_size", 13)
	add_child(animal_name)

	var bars := VBoxContainer.new()
	bars.add_theme_constant_override("separation", 2)
	bars.alignment = BoxContainer.ALIGNMENT_END
	bars.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bars)
	_integrity_bar = _make_bar(Vector2(config.bar_width, config.integrity_bar_height),
		config.integrity_fill_color)
	bars.add_child(_integrity_bar)
	_health_bar = _make_bar(Vector2(config.bar_width, config.bar_height), config.health_fill_color)
	bars.add_child(_health_bar)

	_status_label = Label.new()
	_status_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_status_label.add_theme_font_size_override("font_size", 13)
	add_child(_status_label)

	if animal != null:
		animal.health.health_changed.connect(_on_health_changed)
		animal.weak_changed.connect(_on_weak_changed)
		_on_weak_changed(animal.is_weak)
		_on_health_changed(animal.health.current_health, animal.health.max_health)
	refresh()


## Called by AnimalHealthHud at its update frequency: follows enclosure changes
## (escape, recapture into another refuge) and the animal status.
func refresh() -> void:
	if animal == null or not is_instance_valid(animal):
		return
	var current := animal.enclosure if animal.enclosure != null and not animal.enclosure.is_destroyed else null
	if current != _bound_enclosure:
		if _bound_enclosure != null and is_instance_valid(_bound_enclosure) \
				and _bound_enclosure.health.health_changed.is_connected(_on_integrity_changed):
			_bound_enclosure.health.health_changed.disconnect(_on_integrity_changed)
		_bound_enclosure = current
		if _bound_enclosure != null:
			_bound_enclosure.health.health_changed.connect(_on_integrity_changed)
			_on_integrity_changed(_bound_enclosure.health.current_health, _bound_enclosure.health.max_health)
	_integrity_bar.visible = _bound_enclosure != null
	var key := animal.get_status_key()
	_status_label.text = tr(key)
	var alert := key in ["ANIMAL_STATUS_WEAK", "ANIMAL_STATUS_DEAD", "ANIMAL_STATUS_ESCAPED"]
	_status_label.add_theme_color_override("font_color",
		config.weak_fill_color if alert else config.status_color)


func get_integrity_ratio() -> float:
	return _integrity_bar.value / _integrity_bar.max_value if _integrity_bar.visible else -1.0


func get_health_ratio() -> float:
	return _health_bar.value / _health_bar.max_value


func get_status_text() -> String:
	return _status_label.text


func _on_weak_changed(is_weak: bool) -> void:
	var fill := config.weak_fill_color if is_weak else config.health_fill_color
	_health_bar.add_theme_stylebox_override("fill", _make_style(fill))
	refresh()


func _on_health_changed(current: float, maximum: float) -> void:
	_set_bar(_health_bar, current, maximum)


func _on_integrity_changed(current: float, maximum: float) -> void:
	_set_bar(_integrity_bar, current, maximum)


func _set_bar(bar: ProgressBar, current: float, maximum: float) -> void:
	bar.max_value = maxf(maximum, 1.0)
	bar.value = clampf(current, 0.0, bar.max_value)


func _make_bar(size: Vector2, fill: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.custom_minimum_size = size
	bar.show_percentage = false
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var background := _make_style(config.bar_back_color)
	background.set_border_width_all(roundi(config.border_width))
	background.border_color = config.bar_border_color
	bar.add_theme_stylebox_override("background", background)
	bar.add_theme_stylebox_override("fill", _make_style(fill))
	return bar


func _make_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.content_margin_left = 0.0
	style.content_margin_top = 0.0
	style.content_margin_right = 0.0
	style.content_margin_bottom = 0.0
	return style
