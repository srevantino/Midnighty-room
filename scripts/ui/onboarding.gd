extends Control
## First-run guide: five short cards over a dimmed room.

signal finished

const STEPS := [
	["mini", "Welcome to Midnighty Room", "This is your quiet corner. Leave it open while you work, study or wind down."],
	["timer", "Focus", "Start the timer and get to work. Your character starts typing too, and every focused minute earns moonlight."],
	["sound", "Sounds", "Mix lofi music with rain, a fireplace and more. You can add your own tracks from the Sounds panel."],
	["decorate", "Decorate", "Spend moonlight on furniture, drag things where you like, recolour them, and unlock new rooms as you level up."],
	["stats", "Progress", "Daily goals and levels give you a reason to come back tomorrow. Miso likes being petted, by the way."],
]

var _index := 0
var _icon: TextureRect
var _title: Label
var _text: Label
var _dots: Label
var _next: Button


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.02, 0.08, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var centre := CenterContainer.new()
	centre.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(centre)
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(460, 0)
	centre.add_child(card)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	card.add_child(box)
	_icon = TextureRect.new()
	_icon.custom_minimum_size = Vector2(64, 64)
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	box.add_child(_icon)
	_title = UIKit.label("", 26)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_title)
	_text = UIKit.label("", 16, UIKit.MUTED)
	_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.custom_minimum_size.y = 72
	box.add_child(_text)
	_dots = UIKit.label("", 14, UIKit.ACCENT)
	_dots.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_dots.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	box.add_child(_dots)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 12)
	buttons.add_child(UIKit.button("Skip", _finish, 100))
	_next = UIKit.button("Next", _advance, 140)
	buttons.add_child(_next)
	box.add_child(buttons)
	_show()


func _show() -> void:
	var step: Array = STEPS[_index]
	_icon.texture = UIKit.icon(step[0])
	_title.text = step[1]
	_text.text = step[2]
	_dots.text = "%d / %d" % [_index + 1, STEPS.size()]
	_next.text = "Start" if _index == STEPS.size() - 1 else "Next"


func _advance() -> void:
	_index += 1
	if _index >= STEPS.size():
		_finish()
	else:
		_show()


func _finish() -> void:
	GameState.set_setting("onboarded", true)
	finished.emit()
	queue_free()
