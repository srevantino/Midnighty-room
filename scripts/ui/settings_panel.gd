extends BasePanel
## Settings: sound, time of day, display, companion modes, key bindings.

signal reset_requested

const TIME_MODES := [
	["real", "Follow my clock"],
	["cycle", "Fast day and night (12 min)"],
	["night", "Always midnight"],
	["sunset", "Always sunset"],
	["day", "Always daytime"],
]
const UI_SCALES := [[0.85, "Small"], [1.0, "Normal"], [1.15, "Large"]]
const MINI_STYLES := [["room", "Mini room"], ["small", "Tiny room"], ["widget", "Timer only (see-through)"]]
const LANGUAGE_NAMES := {"en": "English", "ms": "Bahasa Melayu", "zh_CN": "简体中文", "ja": "日本語", "ko": "한국어"}

var _reset: Button
var _reset_armed := false
var _capturing := ""
var _key_buttons: Dictionary = {}


func _ready() -> void:
	build("Settings", 384)
	body.add_child(UIKit.section("Sound"))
	for entry: Array in [["master", "Everything"], ["ambience", "Ambience"], ["sfx", "Effects"]]:
		var key: String = entry[0]
		body.add_child(UIKit.slider_row(entry[1], float(GameState.setting(key)), func(v: float) -> void:
			GameState.set_setting(key, v)
			AudioMixer.apply_volumes()))

	body.add_child(UIKit.section("Time of day"))
	body.add_child(_option(TIME_MODES, "time_mode"))

	body.add_child(UIKit.section("Display"))
	body.add_child(_check("Fullscreen", "fullscreen"))
	body.add_child(_check("Keep on top of other windows", "on_top"))
	body.add_child(_check("Battery saver (30 fps)", "fps", 30, 60))
	body.add_child(_labelled("Interface size", _option(UI_SCALES, "ui_scale")))
	var languages: Array = [["", "System language"]]
	for locale in TranslationServer.get_loaded_locales():
		languages.append([locale, LANGUAGE_NAMES.get(locale, locale)])
	body.add_child(_labelled("Language", _option(languages, "locale", false)))

	body.add_child(UIKit.section("Mini window"))
	body.add_child(_labelled("Style", _option(MINI_STYLES, "mini_style")))
	body.add_child(_check("Flash the taskbar when a timer ends", "notify"))

	body.add_child(UIKit.section("Keys"))
	for action: String in GameState.DEFAULT_KEYS:
		var b := UIKit.button("", func() -> void: _start_capture(action), 110)
		b.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		_key_buttons[action] = b
		body.add_child(_labelled(GameState.KEY_LABELS[action], b, 210))
	_refresh_keys()

	body.add_child(UIKit.spacer(4))
	_reset = UIKit.button("Reset everything", _on_reset)
	body.add_child(_reset)
	body.add_child(UIKit.button("Quit", func() -> void:
		GameState.save_game()
		get_tree().quit()))
	var version := UIKit.label("Midnighty Room v%s%s" % [ProjectSettings.get_setting("application/config/version"), " demo" if GameState.is_demo() else ""], 12, UIKit.MUTED)
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	version.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	body.add_child(version)
	visibility_changed.connect(_disarm)


func _labelled(text: String, control: Control, label_width: int = 130) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var name_label := UIKit.label(text, 15, UIKit.MUTED)
	name_label.custom_minimum_size.x = label_width
	name_label.clip_text = true
	row.add_child(name_label)
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(control)
	return row


## A dropdown bound to a setting. `options` is a list of [value, label].
func _option(options: Array, key: String, translate: bool = true) -> OptionButton:
	var pick := OptionButton.new()
	if not translate:
		pick.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	for i in options.size():
		pick.add_item(tr(options[i][1]) if not translate and i == 0 else options[i][1], i)
		if options[i][0] == GameState.setting(key):
			pick.select(i)
	pick.item_selected.connect(func(i: int) -> void: GameState.set_setting(key, options[i][0]))
	return pick


func _check(text: String, key: String, on_value: Variant = true, off_value: Variant = false) -> CheckBox:
	var box := CheckBox.new()
	box.text = text
	box.button_pressed = GameState.setting(key) == on_value
	box.toggled.connect(func(on: bool) -> void: GameState.set_setting(key, on_value if on else off_value))
	GameState.settings_changed.connect(func() -> void: box.set_pressed_no_signal(GameState.setting(key) == on_value))
	return box


# ------------------------------------------------------------ key bindings
func _refresh_keys() -> void:
	for action: String in _key_buttons:
		(_key_buttons[action] as Button).text = tr("Press a key...") if action == _capturing else OS.get_keycode_string(GameState.key_for(action))


func _start_capture(action: String) -> void:
	_capturing = action
	_refresh_keys()


func _input(event: InputEvent) -> void:
	if _capturing == "" or not (event is InputEventKey and event.pressed and not event.echo):
		return
	get_viewport().set_input_as_handled()
	var keycode: Key = (event as InputEventKey).keycode
	if keycode != KEY_ESCAPE:
		# a key can only do one thing: hand the old binding to whoever had this key
		for other: String in GameState.DEFAULT_KEYS:
			if other != _capturing and GameState.key_for(other) == keycode:
				GameState.set_key(other, GameState.key_for(_capturing))
		GameState.set_key(_capturing, keycode)
	_capturing = ""
	_refresh_keys()


func _on_reset() -> void:
	if not _reset_armed:
		_reset_armed = true
		_reset.text = "Really wipe all progress? Press again"
		return
	_disarm()
	reset_requested.emit()


func _disarm() -> void:
	_reset_armed = false
	_reset.text = "Reset everything"
	_capturing = ""
	_refresh_keys()
