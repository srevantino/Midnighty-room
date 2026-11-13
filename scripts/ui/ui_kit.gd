class_name UIKit
## Shared look for every panel: colours, the Theme, and small widget helpers.
## Change the constants here to restyle the whole interface.

const BG := Color(0.085, 0.075, 0.16, 0.93)
const BG_SOFT := Color(0.16, 0.14, 0.27, 0.95)
const BG_HOVER := Color(0.23, 0.20, 0.38, 1.0)
const BORDER := Color(0.47, 0.42, 0.72, 0.55)
const ACCENT := Color("f2b866")
const TEXT := Color("efe8f7")
const MUTED := Color("a9a2c4")
const GOOD := Color("8fd6a3")


static func box(colour: Color, radius: int = 10, border: Color = Color.TRANSPARENT, pad: int = 10) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = colour
	style.set_corner_radius_all(radius)
	style.set_content_margin_all(pad)
	if border.a > 0.0:
		style.set_border_width_all(1)
		style.border_color = border
	return style


static func build_theme() -> Theme:
	var theme := Theme.new()
	theme.default_font_size = 17
	theme.set_color("font_color", "Label", TEXT)
	theme.set_stylebox("panel", "PanelContainer", box(BG, 14, BORDER, 16))

	theme.set_stylebox("normal", "Button", box(BG_SOFT, 8, Color.TRANSPARENT, 8))
	theme.set_stylebox("hover", "Button", box(BG_HOVER, 8, BORDER, 8))
	theme.set_stylebox("pressed", "Button", box(ACCENT.darkened(0.45), 8, ACCENT, 8))
	theme.set_stylebox("disabled", "Button", box(Color(0.13, 0.12, 0.2, 0.7), 8, Color.TRANSPARENT, 8))
	theme.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	theme.set_color("font_color", "Button", TEXT)
	theme.set_color("font_hover_color", "Button", Color.WHITE)
	theme.set_color("font_pressed_color", "Button", ACCENT.lightened(0.3))
	theme.set_color("font_disabled_color", "Button", MUTED.darkened(0.3))

	for type: String in ["CheckBox", "OptionButton"]:
		theme.set_stylebox("normal", type, box(BG_SOFT, 8, Color.TRANSPARENT, 8))
		theme.set_stylebox("hover", type, box(BG_HOVER, 8, Color.TRANSPARENT, 8))
		theme.set_stylebox("pressed", type, box(BG_SOFT, 8, Color.TRANSPARENT, 8))
		theme.set_stylebox("hover_pressed", type, box(BG_HOVER, 8, Color.TRANSPARENT, 8))
		theme.set_stylebox("focus", type, StyleBoxEmpty.new())
		theme.set_color("font_color", type, TEXT)

	theme.set_stylebox("normal", "LineEdit", box(Color(0.05, 0.045, 0.1, 0.9), 8, BORDER, 8))
	theme.set_stylebox("focus", "LineEdit", box(Color(0.05, 0.045, 0.1, 0.9), 8, ACCENT, 8))
	theme.set_color("font_color", "LineEdit", TEXT)
	theme.set_color("font_placeholder_color", "LineEdit", MUTED.darkened(0.2))

	var track := box(Color(0.05, 0.045, 0.1, 0.9), 4, Color.TRANSPARENT, 0)
	track.content_margin_top = 4
	track.content_margin_bottom = 4
	var fill := box(ACCENT.darkened(0.15), 4, Color.TRANSPARENT, 0)
	theme.set_stylebox("slider", "HSlider", track)
	theme.set_stylebox("grabber_area", "HSlider", fill)
	theme.set_stylebox("grabber_area_highlight", "HSlider", fill)
	var grabber := _circle(14, ACCENT)
	theme.set_icon("grabber", "HSlider", grabber)
	theme.set_icon("grabber_highlight", "HSlider", _circle(14, ACCENT.lightened(0.3)))

	theme.set_stylebox("panel", "PopupMenu", box(BG, 8, BORDER, 6))
	theme.set_stylebox("hover", "PopupMenu", box(BG_HOVER, 6, Color.TRANSPARENT, 4))
	theme.set_stylebox("panel", "TooltipPanel", box(BG, 6, BORDER, 6))
	theme.set_color("font_color", "TooltipLabel", TEXT)
	return theme


static func _circle(size: int, colour: Color) -> ImageTexture:
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var centre := Vector2(size, size) / 2.0 - Vector2(0.5, 0.5)
	for y in size:
		for x in size:
			var d := Vector2(x, y).distance_to(centre)
			image.set_pixel(x, y, Color(colour, clampf(size / 2.0 - d, 0.0, 1.0)))
	return ImageTexture.create_from_image(image)


static func icon(icon_name: String) -> Texture2D:
	return load("res://assets/icons/%s.png" % icon_name) as Texture2D


static func label(text: String, size: int = 17, colour: Color = TEXT) -> Label:
	var node := Label.new()
	node.text = text
	node.add_theme_font_size_override("font_size", size)
	node.add_theme_color_override("font_color", colour)
	return node


static func button(text: String, on_press: Callable, min_width: int = 0) -> Button:
	var node := Button.new()
	node.text = text
	node.custom_minimum_size.x = min_width
	node.pressed.connect(func() -> void:
		AudioMixer.play_sfx("click")
		on_press.call())
	return node


static func slider(value: float, on_change: Callable) -> HSlider:
	var node := HSlider.new()
	node.min_value = 0.0
	node.max_value = 1.0
	node.step = 0.01
	node.value = value
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	node.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	node.custom_minimum_size = Vector2(120, 20)
	node.value_changed.connect(on_change)
	return node


## A "Name  [=====o---]" row.
static func slider_row(text: String, value: float, on_change: Callable, label_width: int = 120) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var name_label := label(text, 16, MUTED)
	name_label.custom_minimum_size.x = label_width
	row.add_child(name_label)
	row.add_child(slider(value, on_change))
	return row


static func section(text: String) -> Label:
	var node := label(text.to_upper(), 12, MUTED)
	return node


static func spacer(height: int = 6) -> Control:
	var node := Control.new()
	node.custom_minimum_size.y = height
	return node
