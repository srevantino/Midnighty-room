extends BasePanel
## Focus timer: start/pause, block lengths, and focus statistics.

const FOCUS_CHOICES := [15, 25, 45, 60]
const REST_CHOICES := [5, 10, 15]

var _time: Label
var _phase: Label
var _start: Button
var _focus_buttons: Array[Button] = []
var _rest_buttons: Array[Button] = []
var _stats: Dictionary = {}


func _ready() -> void:
	build("Focus", 330)
	_phase = UIKit.label("Ready when you are", 15, UIKit.MUTED)
	_phase.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(_phase)
	_time = UIKit.label("25:00", 60)
	_time.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(_time)

	var controls := HBoxContainer.new()
	controls.alignment = BoxContainer.ALIGNMENT_CENTER
	controls.add_theme_constant_override("separation", 10)
	_start = UIKit.button("Start", FocusTimer.toggle_pause, 130)
	controls.add_child(_start)
	controls.add_child(UIKit.button("Reset", FocusTimer.stop, 90))
	body.add_child(controls)

	body.add_child(UIKit.spacer(2))
	body.add_child(UIKit.section("Focus minutes"))
	body.add_child(_choice_row(FOCUS_CHOICES, _focus_buttons, func(v: int) -> void: FocusTimer.set_lengths(v, FocusTimer.rest_minutes())))
	body.add_child(UIKit.section("Break minutes"))
	body.add_child(_choice_row(REST_CHOICES, _rest_buttons, func(v: int) -> void: FocusTimer.set_lengths(FocusTimer.focus_minutes(), v)))

	var loop := CheckBox.new()
	loop.text = "Start the next session automatically"
	loop.button_pressed = GameState.data["timer"]["auto_loop"]
	loop.toggled.connect(func(on: bool) -> void:
		GameState.data["timer"]["auto_loop"] = on
		GameState.mark_dirty())
	body.add_child(loop)

	body.add_child(UIKit.spacer(2))
	body.add_child(UIKit.section("Your focus"))
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 8)
	for key: String in ["Today", "Total", "Streak", "Sessions"]:
		var cell := VBoxContainer.new()
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var value := UIKit.label("0", 20, UIKit.ACCENT)
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var caption := UIKit.label(key, 12, UIKit.MUTED)
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cell.add_child(value)
		cell.add_child(caption)
		grid.add_child(cell)
		_stats[key] = value
	body.add_child(grid)
	var hint := UIKit.label(tr("Each focused minute earns 1 moonlight, plus %d for finishing a session.") % GameState.SESSION_BONUS, 13, UIKit.MUTED)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(hint)

	FocusTimer.tick.connect(func(_s: int) -> void: _refresh())
	FocusTimer.phase_changed.connect(func(_p: String) -> void: _refresh())
	GameState.stats_changed.connect(_refresh)
	_refresh()


func _choice_row(choices: Array, store: Array[Button], on_pick: Callable) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	for value: int in choices:
		var b := UIKit.button(str(value), func() -> void:
			on_pick.call(value)
			_refresh())
		b.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		b.toggle_mode = true
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.set_meta("value", value)
		row.add_child(b)
		store.append(b)
	return row


static func format_time(seconds: int) -> String:
	return "%02d:%02d" % [seconds / 60, seconds % 60]


func _refresh() -> void:
	_time.text = format_time(FocusTimer.seconds_left())
	var idle := FocusTimer.phase == FocusTimer.Phase.IDLE
	if idle:
		_phase.text = "Ready when you are"
		_start.text = "Start"
	elif FocusTimer.paused:
		_phase.text = "Paused"
		_start.text = "Resume"
	else:
		_phase.text = "Focusing" if FocusTimer.phase == FocusTimer.Phase.FOCUS else "Break time"
		_start.text = "Pause"
	_time.add_theme_color_override("font_color", UIKit.GOOD if FocusTimer.phase == FocusTimer.Phase.REST else UIKit.TEXT)
	for b in _focus_buttons:
		b.set_pressed_no_signal(int(b.get_meta("value")) == FocusTimer.focus_minutes())
		b.disabled = not idle
	for b in _rest_buttons:
		b.set_pressed_no_signal(int(b.get_meta("value")) == FocusTimer.rest_minutes())
	var stats: Dictionary = GameState.data["stats"]
	var total := int(stats["total_minutes"])
	(_stats["Today"] as Label).text = "%dm" % GameState.minutes_today()
	(_stats["Total"] as Label).text = ("%.1fh" % (total / 60.0)) if total >= 60 else "%dm" % total
	(_stats["Streak"] as Label).text = "%dd" % int(stats["streak"])
	(_stats["Sessions"] as Label).text = str(int(stats["sessions"]))
