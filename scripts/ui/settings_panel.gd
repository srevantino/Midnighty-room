extends BasePanel
## Settings: volume, time of day, window options, reset and quit.

signal reset_requested

const TIME_MODES := [
	["real", "Follow my clock"],
	["cycle", "Fast day and night (12 min)"],
	["night", "Always midnight"],
	["sunset", "Always sunset"],
	["day", "Always daytime"],
]

var _reset: Button
var _reset_armed := false


func _ready() -> void:
	build("Settings", 360)
	body.add_child(UIKit.slider_row("Master volume", float(GameState.setting("master")), func(v: float) -> void:
		GameState.set_setting("master", v)
		AudioMixer.apply_volumes()))

	body.add_child(UIKit.section("Time of day"))
	var time_pick := OptionButton.new()
	for i in TIME_MODES.size():
		time_pick.add_item(TIME_MODES[i][1], i)
		if TIME_MODES[i][0] == str(GameState.setting("time_mode")):
			time_pick.select(i)
	time_pick.item_selected.connect(func(i: int) -> void: GameState.set_setting("time_mode", TIME_MODES[i][0]))
	body.add_child(time_pick)

	body.add_child(UIKit.section("Window"))
	body.add_child(_check("Fullscreen  (F11)", "fullscreen"))
	body.add_child(_check("Keep on top of other windows", "on_top"))
	body.add_child(_check("Battery saver (30 fps)", "fps", 30, 60))

	body.add_child(UIKit.spacer(4))
	_reset = UIKit.button("Reset everything", _on_reset)
	body.add_child(_reset)
	body.add_child(UIKit.button("Quit", func() -> void:
		GameState.save_game()
		get_tree().quit()))
	var version := UIKit.label("Midnighty Room v%s" % ProjectSettings.get_setting("application/config/version"), 12, UIKit.MUTED)
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(version)
	visibility_changed.connect(_disarm)


func _check(text: String, key: String, on_value: Variant = true, off_value: Variant = false) -> CheckBox:
	var box := CheckBox.new()
	box.text = text
	box.button_pressed = GameState.setting(key) == on_value
	box.toggled.connect(func(on: bool) -> void: GameState.set_setting(key, on_value if on else off_value))
	GameState.settings_changed.connect(func() -> void: box.set_pressed_no_signal(GameState.setting(key) == on_value))
	return box


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
