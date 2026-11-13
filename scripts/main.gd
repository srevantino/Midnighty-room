extends Control
## Entry point. Builds the pixel-art room viewport, the HUD and the panels,
## routes input between them, and owns the window modes (full, mini, widget)
## and the system tray icon.
##
## Developer flags (after `--` on the command line):
##   --hour=23.5          pin the time of day
##   --panel=focus,sounds open panels at start (focus tasks progress sounds decorate settings)
##   --room=1             start in room 0, 1 or 2 (ignores level locks)
##   --xp=500             grant XP for this run
##   --locale=ms          force a language
##   --onboarding         show the first-run guide
##   --shot=out.png       save a screenshot after a few frames, then quit
##   --selftest           run the logic checks in scripts/selftest.gd, then quit
##   --fresh              start from a new game without touching the real save

const PANEL_SCRIPTS := {
	"focus": ["res://scripts/ui/timer_panel.gd", "left"],
	"tasks": ["res://scripts/ui/todo_panel.gd", "left"],
	"progress": ["res://scripts/ui/progress_panel.gd", "left"],
	"sounds": ["res://scripts/ui/mixer_panel.gd", "right"],
	"decorate": ["res://scripts/ui/decorate_panel.gd", "right"],
	"settings": ["res://scripts/ui/settings_panel.gd", "right"],
}
const DOCK := [
	["focus", "timer", "Focus timer"],
	["tasks", "tasks", "Tasks"],
	["progress", "stats", "Progress and daily goals"],
	["sounds", "sound", "Sounds"],
	["decorate", "decorate", "Decorate"],
	["settings", "settings", "Settings"],
]
const MINI_SIZES := {"room": Vector2i(480, 270), "small": Vector2i(320, 180), "widget": Vector2i(320, 180)}

var room: Room
var _view: TextureRect
var _hud: Control
var _panels: Dictionary = {}
var _dock_buttons: Dictionary = {}
var _clock: Label
var _date: Label
var _coins: Label
var _level: Label
var _timer_pill: PanelContainer
var _timer_text: Label
var _toast: PanelContainer
var _toast_text: Label
var _toast_tween: Tween
var _mini_bar: HBoxContainer
var _mini_timer: Label
var _widget: PanelContainer
var _widget_time: Label
var _widget_play: Button
var _tray: StatusIndicator
var _mini := false
var _mini_style := "room"
var _before_mini: Dictionary = {}
var _drag_from := Vector2i.ZERO
var _window_from := Vector2i.ZERO
var _dragging_window := false
var _args: Dictionary = {}


func _ready() -> void:
	_parse_args()
	if _args.has("fresh") or _args.has("selftest"):
		GameState.save_path = "user://dev_save.json"
		GameState.data = GameState._defaults()
	if _args.has("xp"):
		GameState.data["stats"]["xp_bonus"] = int(_args["xp"])
		GameState.data["stats"]["level_paid"] = GameState.level()
	if _args.has("room"):
		GameState.data["room"] = clampi(int(_args["room"]), 0, Catalog.ROOMS.size() - 1)
	_apply_locale()
	theme = UIKit.build_theme()
	_build_room()
	_build_hud()
	_build_panels()
	_build_tray()
	_apply_window_settings()
	GameState.settings_changed.connect(_apply_window_settings)
	GameState.coins_changed.connect(func(amount: int) -> void: _coins.text = str(amount))
	GameState.stats_changed.connect(_refresh_level)
	GameState.toast.connect(show_toast)
	GameState.level_up.connect(func(level: int) -> void:
		AudioMixer.play_sfx("chime")
		show_toast(tr("Level %d!  +%d moonlight") % [level, GameState.LEVEL_REWARD])
		SteamService.on_level(level))
	FocusTimer.tick.connect(func(_s: int) -> void: _refresh_timer_pill())
	FocusTimer.phase_changed.connect(_on_phase_changed)
	FocusTimer.focus_completed.connect(func(minutes: int, earned: int) -> void:
		AudioMixer.play_sfx("coin")
		show_toast(tr("%d minutes of focus  +%d moonlight") % [minutes, earned]))
	room.dragging_changed.connect(func(active: bool) -> void:
		for panel_name: String in _panels:
			(_panels[panel_name] as BasePanel).set_ghost(active))
	_refresh_timer_pill()
	_refresh_level()
	_run_dev_args()
	if (not GameState.setting("onboarded") and _args.is_empty()) or _args.has("onboarding"):
		var guide := Control.new()
		guide.set_script(load("res://scripts/ui/onboarding.gd"))
		add_child(guide)


# -------------------------------------------------------------------- build
func _build_room() -> void:
	var viewport := SubViewport.new()
	viewport.size = Room.SIZE
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	add_child(viewport)
	room = Room.new()
	viewport.add_child(room)

	_view = TextureRect.new()
	_view.texture = viewport.get_texture()
	_view.stretch_mode = TextureRect.STRETCH_SCALE
	_view.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_view.set_anchors_preset(Control.PRESET_FULL_RECT)
	_view.mouse_filter = Control.MOUSE_FILTER_STOP
	_view.gui_input.connect(_on_view_input)
	add_child(_view)


func _pill() -> PanelContainer:
	var pill := PanelContainer.new()
	pill.add_theme_stylebox_override("panel", UIKit.box(UIKit.BG, 12, UIKit.BORDER, 10))
	return pill


func _icon_rect(icon_name: String, size: int = 24) -> TextureRect:
	var rect := TextureRect.new()
	rect.texture = UIKit.icon(icon_name)
	rect.custom_minimum_size = Vector2(size, size)
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	return rect


func _build_hud() -> void:
	_hud = Control.new()
	_hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hud)

	# clock, top left
	var clock_pill := _pill()
	clock_pill.position = Vector2(24, 20)
	var clock_box := HBoxContainer.new()
	clock_box.add_theme_constant_override("separation", 10)
	_clock = UIKit.label("00:00", 26)
	_date = UIKit.label("", 14, UIKit.MUTED)
	_date.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	clock_box.add_child(_clock)
	clock_box.add_child(_date)
	if GameState.is_demo():
		clock_box.add_child(UIKit.label("DEMO", 14, UIKit.ACCENT))
	clock_pill.add_child(clock_box)
	_hud.add_child(clock_pill)

	# timer, level and moonlight, top right
	var right := HBoxContainer.new()
	right.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	right.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	right.position = Vector2(-24, 20)
	right.add_theme_constant_override("separation", 10)
	right.alignment = BoxContainer.ALIGNMENT_END
	_timer_pill = _pill()
	_timer_text = UIKit.label("", 20, UIKit.ACCENT)
	_timer_pill.add_child(_timer_text)
	right.add_child(_timer_pill)
	var level_pill := _pill()
	level_pill.tooltip_text = "Your level. Focus to level up and unlock rooms and furniture."
	var level_box := HBoxContainer.new()
	level_box.add_theme_constant_override("separation", 6)
	level_box.add_child(_icon_rect("star"))
	_level = UIKit.label("1", 20)
	level_box.add_child(_level)
	level_pill.add_child(level_box)
	right.add_child(level_pill)
	var coin_pill := _pill()
	coin_pill.tooltip_text = "Moonlight. Earn it by focusing and finishing tasks, spend it in Decorate."
	var coin_box := HBoxContainer.new()
	coin_box.add_theme_constant_override("separation", 6)
	coin_box.add_child(_icon_rect("coin"))
	_coins = UIKit.label(str(GameState.coins()), 20)
	coin_box.add_child(_coins)
	coin_pill.add_child(coin_box)
	right.add_child(coin_pill)
	_hud.add_child(right)

	# dock, bottom centre
	var dock_pill := _pill()
	dock_pill.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	dock_pill.grow_horizontal = Control.GROW_DIRECTION_BOTH
	dock_pill.grow_vertical = Control.GROW_DIRECTION_BEGIN
	dock_pill.position.y -= 18
	var dock := HBoxContainer.new()
	dock.add_theme_constant_override("separation", 8)
	for entry: Array in DOCK:
		var b := _dock_button(entry[1], entry[2], func() -> void: toggle_panel(entry[0]))
		b.toggle_mode = true
		_dock_buttons[entry[0]] = b
		dock.add_child(b)
	dock.add_child(_dock_button("mini", "Mini window: a small always-on-top room for the corner of your screen", toggle_mini))
	dock_pill.add_child(dock)
	_hud.add_child(dock_pill)

	# toast, top centre
	_toast = _pill()
	_toast.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_toast.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_toast.position.y = 22
	_toast_text = UIKit.label("", 17, UIKit.ACCENT)
	_toast_text.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_toast.add_child(_toast_text)
	_toast.modulate.a = 0.0
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_toast)

	# mini room overlay: timer readout and a button back to the full window
	_mini_bar = HBoxContainer.new()
	_mini_bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	_mini_bar.position = Vector2(16, 16)
	_mini_bar.add_theme_constant_override("separation", 8)
	_mini_bar.visible = false
	_mini_bar.add_child(_dock_button("mini", "Back to the full window", toggle_mini))
	var mini_pill := _pill()
	_mini_timer = UIKit.label("", 20, UIKit.ACCENT)
	mini_pill.add_child(_mini_timer)
	_mini_bar.add_child(mini_pill)
	add_child(_mini_bar)

	# timer-only widget: a single pill on a see-through window
	_widget = _pill()
	_widget.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_widget.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_widget.grow_vertical = Control.GROW_DIRECTION_BOTH
	_widget.visible = false
	_widget.mouse_filter = Control.MOUSE_FILTER_STOP
	_widget.gui_input.connect(_on_widget_input)
	var widget_box := HBoxContainer.new()
	widget_box.add_theme_constant_override("separation", 24)
	_widget_time = UIKit.label("25:00", 150)
	_widget_time.mouse_filter = Control.MOUSE_FILTER_IGNORE
	widget_box.add_child(_widget_time)
	var widget_buttons := VBoxContainer.new()
	widget_buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	_widget_play = _dock_button("timer", "Start or pause", FocusTimer.toggle_pause)
	_widget_play.custom_minimum_size = Vector2(120, 120)
	var widget_back := _dock_button("mini", "Back to the full window", toggle_mini)
	widget_back.custom_minimum_size = Vector2(120, 120)
	widget_buttons.add_child(_widget_play)
	widget_buttons.add_child(widget_back)
	widget_box.add_child(widget_buttons)
	_widget.add_child(widget_box)
	add_child(_widget)


func _dock_button(icon_name: String, tip: String, on_press: Callable) -> Button:
	var b := Button.new()
	b.icon = UIKit.icon(icon_name)
	b.expand_icon = true
	b.custom_minimum_size = Vector2(52, 52)
	b.tooltip_text = tip
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.pressed.connect(func() -> void:
		AudioMixer.play_sfx("click")
		on_press.call())
	return b


func _build_panels() -> void:
	for panel_name: String in PANEL_SCRIPTS:
		var panel := PanelContainer.new()
		panel.set_script(load(PANEL_SCRIPTS[panel_name][0]))
		if panel_name == "decorate":
			panel.set("room", room)
		panel.visible = false
		panel.modulate.a = 0.0
		if PANEL_SCRIPTS[panel_name][1] == "left":
			panel.position = Vector2(24, 84)
		else:
			panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
			panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
			panel.position = Vector2(-24, 84)
		_hud.add_child(panel)
		_panels[panel_name] = panel
		panel.connect("close_requested", func() -> void: toggle_panel(panel_name))
	(_panels["settings"] as Control).connect("reset_requested", func() -> void:
		FocusTimer.stop()
		GameState.reset_all()
		_coins.text = str(GameState.coins())
		show_toast(tr("Fresh start")))


## Windows and macOS only: a tray icon with a small menu.
func _build_tray() -> void:
	if DisplayServer.get_name() == "headless" or not DisplayServer.has_feature(DisplayServer.FEATURE_STATUS_INDICATOR) or _args.has("shot"):
		return
	var menu := PopupMenu.new()
	menu.add_item(tr("Show Midnighty Room"), 0)
	menu.add_item(tr("Start or pause the timer"), 1)
	menu.add_item(tr("Mini window"), 2)
	menu.add_separator()
	menu.add_item(tr("Quit"), 3)
	menu.id_pressed.connect(_on_tray_menu)
	add_child(menu)
	_tray = StatusIndicator.new()
	_tray.icon = load("res://icon.png")
	_tray.tooltip = "Midnighty Room"
	add_child(_tray)
	_tray.menu = _tray.get_path_to(menu)
	_tray.pressed.connect(func(button: int, _pos: Vector2i) -> void:
		if button == MOUSE_BUTTON_LEFT:
			_show_window())


func _on_tray_menu(id: int) -> void:
	match id:
		0:
			_show_window()
		1:
			FocusTimer.toggle_pause()
		2:
			toggle_mini()
		3:
			GameState.save_game()
			get_tree().quit()


func _show_window() -> void:
	var window := get_window()
	if window.mode == Window.MODE_MINIMIZED:
		window.mode = Window.MODE_WINDOWED
	window.grab_focus()


# ------------------------------------------------------------------- panels
func toggle_panel(panel_name: String) -> void:
	var panel: Control = _panels[panel_name]
	var show_it := not panel.visible
	if show_it:
		for other: String in _panels:
			if other != panel_name and PANEL_SCRIPTS[other][1] == PANEL_SCRIPTS[panel_name][1]:
				_set_panel(other, false)
	_set_panel(panel_name, show_it)


func _set_panel(panel_name: String, on: bool) -> void:
	var panel: BasePanel = _panels[panel_name]
	if on:
		panel.open()
	else:
		panel.close()
	(_dock_buttons[panel_name] as Button).set_pressed_no_signal(on)
	if panel_name == "decorate":
		room.decorate_mode = on


func close_all_panels() -> void:
	for panel_name: String in _panels:
		_set_panel(panel_name, false)


func show_toast(message: String) -> void:
	if message == "":
		return
	_toast_text.text = message
	if _toast_tween:
		_toast_tween.kill()
	_toast.modulate.a = 1.0
	_toast_tween = create_tween()
	_toast_tween.tween_interval(2.6)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, 0.6)


func _refresh_level() -> void:
	_level.text = str(GameState.level())


func _refresh_timer_pill() -> void:
	var idle := FocusTimer.phase == FocusTimer.Phase.IDLE
	var clock := "%02d:%02d" % [FocusTimer.seconds_left() / 60, FocusTimer.seconds_left() % 60]
	_timer_pill.visible = not idle
	_widget_time.text = clock
	_widget_time.add_theme_color_override("font_color", UIKit.GOOD if FocusTimer.phase == FocusTimer.Phase.REST else UIKit.TEXT)
	var word := tr("Ready") if idle else (tr("Paused") if FocusTimer.paused else (tr("Focus") if FocusTimer.phase == FocusTimer.Phase.FOCUS else tr("Break")))
	_timer_text.text = "%s  %s" % [word, clock]
	_mini_timer.text = _timer_text.text
	if _tray:
		_tray.tooltip = "Midnighty Room: %s %s" % [word, clock]


func _on_phase_changed(phase: String) -> void:
	_refresh_timer_pill()
	# a block just ended: nudge the user if they are in another window
	if phase != "focus" and GameState.setting("notify") and not get_window().has_focus() and DisplayServer.get_name() != "headless":
		DisplayServer.window_request_attention()


func _process(_delta: float) -> void:
	var now := Time.get_datetime_dict_from_system()
	_clock.text = "%02d:%02d" % [now["hour"], now["minute"]]
	_date.text = "%s %d %s" % [tr(["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"][now["weekday"]]), now["day"],
		tr(["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"][int(now["month"]) - 1])]


# -------------------------------------------------------------------- input
func _room_point(view_position: Vector2) -> Vector2:
	return view_position / (_view.size / Vector2(Room.SIZE))


func _on_view_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if _mini:
			_window_drag(event.pressed)
			if not event.pressed and (DisplayServer.mouse_get_position() - _drag_from).length() < 4:
				room.pointer_down(_room_point(event.position))
				room.pointer_up(_room_point(event.position))
			return
		if event.pressed:
			# clicking the room takes keyboard focus away from text fields
			var focused := get_viewport().gui_get_focus_owner()
			if focused:
				focused.release_focus()
			room.pointer_down(_room_point(event.position))
		else:
			room.pointer_up(_room_point(event.position))
	elif event is InputEventMouseMotion:
		if _mini and _dragging_window:
			get_window().position = _window_from + DisplayServer.mouse_get_position() - _drag_from
		else:
			var clickable := room.pointer_move(_room_point(event.position))
			_view.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if clickable else Control.CURSOR_ARROW


func _on_widget_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_window_drag(event.pressed)
	elif event is InputEventMouseMotion and _dragging_window:
		get_window().position = _window_from + DisplayServer.mouse_get_position() - _drag_from


func _window_drag(pressed: bool) -> void:
	if pressed:
		_drag_from = DisplayServer.mouse_get_position()
		_window_from = get_window().position
	elif _dragging_window:
		GameState.data["settings"]["mini_pos"][_mini_style] = [get_window().position.x, get_window().position.y]
		GameState.mark_dirty()
	_dragging_window = pressed


func _unhandled_key_input(event: InputEvent) -> void:
	if not event.pressed:
		return
	var keycode: Key = (event as InputEventKey).keycode
	if room.decorate_mode and keycode in [KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN]:
		var step := 5.0 if (event as InputEventKey).shift_pressed else 1.0
		var directions := {KEY_LEFT: Vector2.LEFT, KEY_RIGHT: Vector2.RIGHT, KEY_UP: Vector2.UP, KEY_DOWN: Vector2.DOWN}
		room.nudge_selected(directions[keycode] * step)
		return
	if event.echo:
		return
	if keycode == KEY_ESCAPE:
		if _mini:
			toggle_mini()
		else:
			close_all_panels()
	elif keycode == GameState.key_for("fullscreen"):
		GameState.set_setting("fullscreen", not GameState.setting("fullscreen"))
	elif keycode == GameState.key_for("flip") and room.decorate_mode:
		room.flip_selected()
	elif (keycode == GameState.key_for("remove") or keycode == KEY_BACKSPACE) and room.decorate_mode:
		room.remove_selected()
	elif keycode == GameState.key_for("timer"):
		FocusTimer.toggle_pause()
	elif keycode == GameState.key_for("music"):
		AudioMixer.toggle_music()
	elif keycode == GameState.key_for("decorate") and not _mini:
		toggle_panel("decorate")
	elif keycode == GameState.key_for("mini"):
		toggle_mini()
	elif keycode == GameState.key_for("screenshot"):
		var path := "user://screenshot_%d.png" % int(Time.get_unix_time_from_system())
		get_viewport().get_texture().get_image().save_png(path)
		show_toast(tr("Saved %s") % ProjectSettings.globalize_path(path))


# ------------------------------------------------------------------- window
func _apply_locale() -> void:
	var locale := str(_args.get("locale", GameState.setting("locale")))
	TranslationServer.set_locale(locale if locale != "" else OS.get_locale())


func _apply_window_settings() -> void:
	Engine.max_fps = int(GameState.setting("fps"))
	_apply_locale()
	if _mini or DisplayServer.get_name() == "headless":
		return
	var window := get_window()
	window.content_scale_factor = float(GameState.setting("ui_scale"))
	var want := Window.MODE_FULLSCREEN if GameState.setting("fullscreen") else Window.MODE_WINDOWED
	if window.mode != want and not (want == Window.MODE_WINDOWED and window.mode in [Window.MODE_MAXIMIZED, Window.MODE_MINIMIZED]):
		window.mode = want
	window.always_on_top = bool(GameState.setting("on_top"))


## Shrinks the game to a small borderless always-on-top window (drag it
## anywhere; it remembers where you left it), or restores the full window.
## Styles: "room", "small" and "widget" (just the timer on a see-through window).
func toggle_mini() -> void:
	var window := get_window()
	if not _mini:
		_mini_style = str(GameState.setting("mini_style"))
		_before_mini = {"mode": window.mode, "size": window.size, "position": window.position}
		close_all_panels()
		_mini = true
		window.content_scale_factor = 1.0
		window.mode = Window.MODE_WINDOWED
		window.borderless = true
		window.always_on_top = true
		var size: Vector2i = MINI_SIZES[_mini_style]
		window.size = size
		var area := DisplayServer.screen_get_usable_rect(window.current_screen)
		var saved: Array = GameState.setting("mini_pos").get(_mini_style, [])
		var target := area.end - size - Vector2i(24, 24)
		if saved.size() == 2 and area.grow(-40).has_point(Vector2i(int(saved[0]), int(saved[1])) + size / 2):
			target = Vector2i(int(saved[0]), int(saved[1]))
		window.position = target
		if _mini_style == "widget":
			window.transparent = true
			get_viewport().transparent_bg = true
			_set_passthrough.call_deferred()
	else:
		GameState.data["settings"]["mini_pos"][_mini_style] = [window.position.x, window.position.y]
		GameState.mark_dirty()
		_mini = false
		window.transparent = false
		get_viewport().transparent_bg = false
		DisplayServer.window_set_mouse_passthrough(PackedVector2Array())
		window.borderless = false
		window.size = _before_mini["size"]
		window.position = _before_mini["position"]
		window.mode = _before_mini["mode"]
		_apply_window_settings()
	var widget := _mini and _mini_style == "widget"
	_hud.visible = not _mini
	_view.visible = not widget
	_widget.visible = widget
	_mini_bar.visible = _mini and not widget
	_mini_bar.scale = Vector2(3, 3) if _mini_style == "small" else Vector2(2, 2)


## In widget mode only the pill takes clicks; the rest of the window lets
## them through to whatever is underneath.
func _set_passthrough() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if not (_mini and _mini_style == "widget"):
		return
	var rect := get_viewport().get_screen_transform() * _widget.get_global_rect()
	DisplayServer.window_set_mouse_passthrough(PackedVector2Array([
		rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]))


# ---------------------------------------------------------------- dev tools
func _parse_args() -> void:
	for arg in OS.get_cmdline_user_args():
		var parts := arg.trim_prefix("--").split("=", true, 1)
		_args[parts[0]] = parts[1] if parts.size() > 1 else "1"


func _run_dev_args() -> void:
	if _args.has("hour"):
		room.time_override = float(_args["hour"])
	if _args.has("panel"):
		for panel_name: String in str(_args["panel"]).split(","):
			if _panels.has(panel_name):
				toggle_panel(panel_name)
	if _args.has("selftest"):
		var test: Node = (load("res://scripts/selftest.gd") as GDScript).new()
		add_child(test)
		test.call("run", self)
	elif _args.has("shot"):
		if _args.has("mini"):
			GameState.data["settings"]["mini_style"] = str(_args["mini"])
			toggle_mini()
		for i in int(_args.get("frames", "40")):
			await get_tree().process_frame
		get_viewport().get_texture().get_image().save_png(str(_args["shot"]))
		get_tree().quit()
