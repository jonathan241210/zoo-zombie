class_name AnimalHealthIndicator
extends HBoxContainer
## Compact heart and green health bar with a separate, time-worn yellow outline.
## While the animal is weak (RF-27) the fill turns red and a "Weak" label appears.

var animal: Animal
var config: AnimalHealthHudConfig

var _health_bar: ProgressBar
var _weak_label: Label


func configure(source_animal: Animal, hud_config: AnimalHealthHudConfig) -> void:
	animal = source_animal
	config = hud_config


func _ready() -> void:
	add_theme_constant_override("separation", 6)
	custom_minimum_size = Vector2(0.0, config.bar_height + 4.0)
	var heart := Label.new()
	heart.text = "♥"
	heart.custom_minimum_size = Vector2(18.0, config.bar_height)
	heart.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	heart.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heart.add_theme_color_override("font_color", config.heart_color)
	heart.add_theme_font_size_override("font_size", 16)
	add_child(heart)
	var animal_name := Label.new()
	animal_name.text = tr(animal.config.display_name_key)
	animal_name.custom_minimum_size = Vector2(64.0, config.bar_height)
	animal_name.clip_text = true
	animal_name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	animal_name.add_theme_font_size_override("font_size", 13)
	add_child(animal_name)

	_health_bar = ProgressBar.new()
	_health_bar.custom_minimum_size = Vector2(config.bar_width, config.bar_height)
	_health_bar.show_percentage = false
	_health_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var background := _make_style(config.bar_back_color)
	background.set_border_width_all(roundi(config.border_width))
	background.border_color = config.bar_border_color
	_health_bar.add_theme_stylebox_override("background", background)
	_health_bar.add_theme_stylebox_override("fill", _make_style(config.health_fill_color))
	add_child(_health_bar)

	_weak_label = Label.new()
	_weak_label.text = tr("ANIMAL_STATUS_WEAK")
	_weak_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_weak_label.add_theme_color_override("font_color", config.weak_fill_color)
	_weak_label.add_theme_font_size_override("font_size", 13)
	_weak_label.visible = false
	add_child(_weak_label)

	if animal != null:
		animal.health.health_changed.connect(_on_health_changed)
		animal.weak_changed.connect(_on_weak_changed)
		_on_weak_changed(animal.is_weak)
		_on_health_changed(animal.health.current_health, animal.health.max_health)


func _on_weak_changed(is_weak: bool) -> void:
	_weak_label.visible = is_weak
	var fill := config.weak_fill_color if is_weak else config.health_fill_color
	_health_bar.add_theme_stylebox_override("fill", _make_style(fill))


func _on_health_changed(current: float, maximum: float) -> void:
	_health_bar.max_value = maxf(maximum, 1.0)
	_health_bar.value = clampf(current, 0.0, _health_bar.max_value)


func _make_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.content_margin_left = 0.0
	style.content_margin_top = 0.0
	style.content_margin_right = 0.0
	style.content_margin_bottom = 0.0
	return style
