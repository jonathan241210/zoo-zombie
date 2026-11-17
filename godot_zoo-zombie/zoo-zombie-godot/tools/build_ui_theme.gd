extends SceneTree
## Generates scenes/ui/theme/ui_theme.tres (earthy "abandoned zoo" palette).
##   godot --headless --path . -s tools/build_ui_theme.gd

const OUT := "res://scenes/ui/theme/ui_theme.tres"
const BG_DARK := Color("1f1d17")
const PANEL := Color("2e2b21")
const PANEL_LIGHT := Color("45402f")
const BORDER := Color("6b6143")
const TEXT := Color("e8e0c8")
const TEXT_DIM := Color("9a937c")
const ACCENT := Color("c8a24a")
const FOCUS := Color("ffd23f")
const DANGER := Color("a8432f")


func _init() -> void:
	var theme := Theme.new()
	theme.default_font_size = 22
	var normal := _box(PANEL, BORDER, 2)
	var hover := _box(PANEL_LIGHT, ACCENT, 2)
	var pressed := _box(BG_DARK, ACCENT, 2)
	var disabled := _box(BG_DARK, PANEL, 2)
	var focus := _focus_box()

	theme.set_stylebox("normal", "Button", normal)
	theme.set_stylebox("hover", "Button", hover)
	theme.set_stylebox("pressed", "Button", pressed)
	theme.set_stylebox("disabled", "Button", disabled)
	theme.set_stylebox("focus", "Button", focus)
	_font_colors(theme, "Button")
	theme.set_font_size("font_size", "Button", 24)

	theme.set_stylebox("panel", "Panel", _box(PANEL, BORDER, 2))
	theme.set_stylebox("panel", "PanelContainer", _box(PANEL, BORDER, 2))
	theme.set_color("font_color", "Label", TEXT)
	theme.set_color("font_shadow_color", "Label", Color(0, 0, 0, 0.6))
	theme.set_constant("shadow_offset_x", "Label", 1)
	theme.set_constant("shadow_offset_y", "Label", 1)
	theme.set_font_size("font_size", "Label", 22)
	theme.set_color("default_color", "RichTextLabel", TEXT)
	theme.set_font_size("normal_font_size", "RichTextLabel", 22)

	# Sliders: thin track, accent fill, big grabber area.
	var track := _box(BG_DARK, BORDER, 1)
	track.content_margin_top = 6
	track.content_margin_bottom = 6
	var fill := _box(ACCENT, ACCENT, 1)
	fill.content_margin_top = 6
	fill.content_margin_bottom = 6
	for slider in ["HSlider", "VSlider"]:
		theme.set_stylebox("slider", slider, track)
		theme.set_stylebox("grabber_area", slider, fill)
		theme.set_stylebox("grabber_area_highlight", slider, fill)
		theme.set_stylebox("focus", slider, focus)
	theme.set_icon("grabber", "HSlider", _grabber(ACCENT))
	theme.set_icon("grabber_highlight", "HSlider", _grabber(FOCUS))
	theme.set_icon("grabber_disabled", "HSlider", _grabber(TEXT_DIM))

	theme.set_stylebox("normal", "OptionButton", normal)
	theme.set_stylebox("hover", "OptionButton", hover)
	theme.set_stylebox("pressed", "OptionButton", pressed)
	theme.set_stylebox("disabled", "OptionButton", disabled)
	theme.set_stylebox("focus", "OptionButton", focus)
	_font_colors(theme, "OptionButton")
	theme.set_stylebox("panel", "PopupMenu", _box(PANEL, ACCENT, 2))
	theme.set_stylebox("hover", "PopupMenu", _box(PANEL_LIGHT, FOCUS, 2))
	theme.set_color("font_color", "PopupMenu", TEXT)
	theme.set_color("font_hover_color", "PopupMenu", FOCUS)

	for box in ["CheckBox", "CheckButton"]:
		theme.set_stylebox("normal", box, StyleBoxEmpty.new())
		theme.set_stylebox("hover", box, _box(PANEL_LIGHT, PANEL_LIGHT, 0))
		theme.set_stylebox("pressed", box, StyleBoxEmpty.new())
		theme.set_stylebox("focus", box, focus)
		_font_colors(theme, box)

	theme.set_stylebox("panel", "TabContainer", _box(PANEL, BORDER, 2))
	theme.set_stylebox("tab_selected", "TabContainer", _box(PANEL_LIGHT, ACCENT, 2))
	theme.set_stylebox("tab_unselected", "TabContainer", _box(BG_DARK, BORDER, 2))
	theme.set_stylebox("tab_focus", "TabContainer", focus)
	theme.set_color("font_selected_color", "TabContainer", FOCUS)
	theme.set_color("font_unselected_color", "TabContainer", TEXT_DIM)

	theme.set_stylebox("background", "ProgressBar", _box(BG_DARK, BORDER, 2))
	theme.set_stylebox("fill", "ProgressBar", _box(ACCENT, ACCENT, 2))
	theme.set_color("font_color", "ProgressBar", TEXT)

	var err := ResourceSaver.save(theme, OUT)
	print("[build_ui_theme] saved ", OUT, ": ", error_string(err))
	quit(0 if err == OK else 1)


func _font_colors(theme: Theme, type_name: String) -> void:
	theme.set_color("font_color", type_name, TEXT)
	theme.set_color("font_hover_color", type_name, FOCUS)
	theme.set_color("font_focus_color", type_name, FOCUS)
	theme.set_color("font_pressed_color", type_name, ACCENT)
	theme.set_color("font_disabled_color", type_name, TEXT_DIM)


func _box(fill: Color, border: Color, border_width: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(border_width)
	box.set_corner_radius_all(4)
	box.content_margin_left = 16
	box.content_margin_right = 16
	box.content_margin_top = 8
	box.content_margin_bottom = 8
	return box


## High-contrast focus frame for gamepad/keyboard navigation (RF-100).
func _focus_box() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.draw_center = false
	box.border_color = FOCUS
	box.set_border_width_all(4)
	box.set_corner_radius_all(6)
	box.set_expand_margin_all(3)
	return box


func _grabber(color: Color) -> ImageTexture:
	var image := Image.create(20, 28, false, Image.FORMAT_RGBA8)
	image.fill(color)
	return ImageTexture.create_from_image(image)
