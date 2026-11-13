extends Node
## Autoload "FocusTimer": the pomodoro clock. Runs off the system clock, so it
## stays accurate when the window is minimised or the game drops frames.

signal tick(seconds_left: int)
signal phase_changed(phase: String)
signal focus_completed(minutes: int, coins: int)

enum Phase { IDLE, FOCUS, REST }

var phase: Phase = Phase.IDLE
var paused := false
var _ends_at_ms := 0
var _left_when_paused := 0
var _last_second := -1
var _block_minutes := 0


func focus_minutes() -> int:
	return int(GameState.data["timer"]["focus"])


func rest_minutes() -> int:
	return int(GameState.data["timer"]["rest"])


func set_lengths(focus: int, rest: int) -> void:
	GameState.data["timer"]["focus"] = focus
	GameState.data["timer"]["rest"] = rest
	GameState.mark_dirty()
	if phase == Phase.IDLE:
		tick.emit(seconds_left())


func seconds_left() -> int:
	if phase == Phase.IDLE:
		return focus_minutes() * 60
	if paused:
		return _left_when_paused
	return maxi(0, ceili((_ends_at_ms - Time.get_ticks_msec()) / 1000.0))


func phase_name() -> String:
	return ["idle", "focus", "rest"][phase]


func start_focus() -> void:
	_block_minutes = focus_minutes()
	_begin(Phase.FOCUS, _block_minutes * 60)


func start_rest() -> void:
	_begin(Phase.REST, rest_minutes() * 60)


func _begin(new_phase: Phase, seconds: int) -> void:
	phase = new_phase
	paused = false
	_ends_at_ms = Time.get_ticks_msec() + seconds * 1000
	_last_second = -1
	phase_changed.emit(phase_name())


func toggle_pause() -> void:
	if phase == Phase.IDLE:
		start_focus()
		return
	if paused:
		_ends_at_ms = Time.get_ticks_msec() + _left_when_paused * 1000
		paused = false
	else:
		_left_when_paused = seconds_left()
		paused = true
	phase_changed.emit(phase_name())


func stop() -> void:
	phase = Phase.IDLE
	paused = false
	phase_changed.emit(phase_name())
	tick.emit(seconds_left())


## Debug/testing helper: jump to the last second of the current block.
func skip_to_end() -> void:
	if phase != Phase.IDLE:
		paused = false
		_ends_at_ms = Time.get_ticks_msec() + 300


func _process(_delta: float) -> void:
	if phase == Phase.IDLE or paused:
		return
	var left := seconds_left()
	if left != _last_second:
		_last_second = left
		tick.emit(left)
	if left > 0:
		return
	if phase == Phase.FOCUS:
		var earned := GameState.record_focus(_block_minutes)
		AudioMixer.play_sfx("chime")
		focus_completed.emit(_block_minutes, earned)
		start_rest()
	else:
		AudioMixer.play_sfx("chime")
		if GameState.data["timer"]["auto_loop"]:
			start_focus()
		else:
			stop()
