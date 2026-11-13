class_name BasePanel
extends PanelContainer
## A titled, closable floating panel. Subclasses add their widgets to `body`.

signal close_requested

var body: VBoxContainer


func build(title: String, width: int) -> void:
	custom_minimum_size.x = width
	body = VBoxContainer.new()
	body.add_theme_constant_override("separation", 10)
	add_child(body)
	var header := HBoxContainer.new()
	var title_label := UIKit.label(title, 22)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_label)
	var close := Button.new()
	close.icon = UIKit.icon("close")
	close.flat = true
	close.tooltip_text = "Close"
	close.custom_minimum_size = Vector2(32, 32)
	close.pressed.connect(func() -> void: close_requested.emit())
	header.add_child(close)
	body.add_child(header)
