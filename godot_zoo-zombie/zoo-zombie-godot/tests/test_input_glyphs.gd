extends GutTest
## InputGlyphs: controller family detection and labels.

const GlyphsScript := preload("res://scripts/autoload/input_glyphs.gd")


func test_playstation_detection() -> void:
	for joy_name in ["PS5 Controller", "DualSense Wireless Controller", "Sony DualShock 4", "PlayStation 4 Pad"]:
		assert_eq(GlyphsScript.device_for_joy_name(joy_name), GlyphsScript.DEVICE_PLAYSTATION, joy_name)


func test_other_joypads_are_xbox() -> void:
	assert_eq(GlyphsScript.device_for_joy_name("Xbox 360 Controller"), GlyphsScript.DEVICE_XBOX)
	assert_eq(GlyphsScript.device_for_joy_name("Generic Gamepad"), GlyphsScript.DEVICE_XBOX)


func test_label_follows_input_map() -> void:
	var glyphs: Node = GlyphsScript.new()
	add_child_autofree(glyphs)
	assert_eq(glyphs.get_label(&"interact"), "E")
	glyphs.current_device = GlyphsScript.DEVICE_XBOX
	assert_eq(glyphs.get_label(&"interact"), "A")
	glyphs.current_device = GlyphsScript.DEVICE_PLAYSTATION
	assert_eq(glyphs.get_label(&"interact"), "Cross")


func test_unknown_action_returns_name_and_no_glyph() -> void:
	var glyphs: Node = GlyphsScript.new()
	add_child_autofree(glyphs)
	assert_eq(glyphs.get_label(&"does_not_exist"), "does_not_exist")
	assert_null(glyphs.get_glyph(&"does_not_exist"))
