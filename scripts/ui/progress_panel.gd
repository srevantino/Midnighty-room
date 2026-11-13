extends BasePanel
## Progress: level, what unlocks next, today's goals, a focus calendar and totals.

const WEEKS := 14

var _level: Label
var _xp_bar: ProgressBar
var _xp_text: Label
var _next: Label
var _goals: VBoxContainer
var _calendar: Control
var _totals: Dictionary = {}


func _ready() -> void:
	build("Progress", 340)
	var level_row := HBoxContainer.new()
	level_row.add_theme_constant_override("separation", 10)
	var star := TextureRect.new()
	star.texture = UIKit.icon("star")
	star.custom_minimum_size = Vector2(32, 32)
	star.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	level_row.add_child(star)
	_level = UIKit.label("", 26)
	_level.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	level_row.add_child(_level)
	_xp_text = UIKit.label("", 14, UIKit.MUTED)
	level_row.add_child(_xp_text)
	body.add_child(level_row)
	_xp_bar = ProgressBar.new()
	_xp_bar.show_percentage = false
	_xp_bar.custom_minimum_size.y = 10
	body.add_child(_xp_bar)
	_next = UIKit.label("", 13, UIKit.MUTED)
	_next.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(_next)

	body.add_child(UIKit.section("Today's goals"))
	_goals = VBoxContainer.new()
	_goals.add_theme_constant_override("separation", 6)
	body.add_child(_goals)

	body.add_child(UIKit.section("Focus calendar"))
	_calendar = Control.new()
	_calendar.custom_minimum_size = Vector2(300, 7 * 15 + 2)
	_calendar.draw.connect(_draw_calendar)
	_calendar.tooltip_text = "Each square is a day. Brighter means more focus."
	body.add_child(_calendar)

	var grid := GridContainer.new()
	grid.columns = 4
	for key: String in ["Focus", "Sessions", "Best streak", "Tasks"]:
		var cell := VBoxContainer.new()
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var value := UIKit.label("0", 19, UIKit.ACCENT)
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var caption := UIKit.label(key, 12, UIKit.MUTED)
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cell.add_child(value)
		cell.add_child(caption)
		grid.add_child(cell)
		_totals[key] = value
	body.add_child(grid)

	GameState.stats_changed.connect(_refresh)
	GameState.goals_changed.connect(_refresh)
	visibility_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	if not visible:
		return
	var level := GameState.level()
	var progress := GameState.level_progress()
	_level.text = tr("Level %d") % level
	_xp_bar.max_value = progress[1]
	_xp_bar.value = progress[0]
	_xp_text.text = "%d / %d XP" % [progress[0], progress[1]] if level < GameState.MAX_LEVEL else tr("Max level")
	_next.text = _next_unlocks(level + 1)

	for child in _goals.get_children():
		child.queue_free()
	for goal: Dictionary in GameState.goals():
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var tick := TextureRect.new()
		tick.texture = UIKit.icon("check")
		tick.custom_minimum_size = Vector2(20, 20)
		tick.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tick.modulate.a = 1.0 if goal["done"] else 0.15
		row.add_child(tick)
		var text := UIKit.label(GameState.goal_text(goal), 15, UIKit.MUTED if goal["done"] else UIKit.TEXT)
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text.clip_text = true
		row.add_child(text)
		row.add_child(UIKit.label("%d/%d" % [GameState.goal_progress(goal), int(goal["target"])], 14, UIKit.MUTED))
		row.add_child(UIKit.label("+%d" % int(goal["reward"]), 14, UIKit.ACCENT))
		_goals.add_child(row)

	var stats: Dictionary = GameState.data["stats"]
	var total := int(stats["total_minutes"])
	(_totals["Focus"] as Label).text = ("%.1fh" % (total / 60.0)) if total >= 60 else "%dm" % total
	(_totals["Sessions"] as Label).text = str(int(stats["sessions"]))
	(_totals["Best streak"] as Label).text = "%dd" % int(stats["best_streak"])
	(_totals["Tasks"] as Label).text = str(int(stats["tasks_done"]))
	_calendar.queue_redraw()


func _next_unlocks(level: int) -> String:
	if level > GameState.MAX_LEVEL:
		return ""
	var names: Array[String] = []
	for config: Dictionary in Catalog.ROOMS:
		if int(config["level"]) == level:
			names.append(tr(config["name"]))
	for id: String in Catalog.ITEMS:
		if Catalog.level_of(id) == level and names.size() < 4:
			names.append(tr(Catalog.ITEMS[id]["name"]))
	if names.is_empty():
		return tr("Level %d pays %d moonlight") % [level, GameState.LEVEL_REWARD]
	return tr("Level %d unlocks: %s") % [level, ", ".join(names)]


func _draw_calendar() -> void:
	var history: Dictionary = GameState.data["stats"]["history"]
	var now := int(Time.get_unix_time_from_system()) + GameState._utc_offset_seconds()
	var weekday: int = Time.get_datetime_dict_from_unix_time(now)["weekday"]
	var cell := 15.0
	var width := _calendar.size.x
	var left := maxf(0.0, (width - WEEKS * cell) / 2.0)
	for week in WEEKS:
		for day in 7:
			var days_ago := (WEEKS - 1 - week) * 7 + (weekday - day)
			if days_ago < 0:
				continue
			var key := Time.get_date_string_from_unix_time(now - days_ago * 86400)
			var minutes := int(history.get(key, 0))
			var colour := Color(1, 1, 1, 0.06)
			if minutes > 0:
				colour = UIKit.ACCENT.darkened(0.55).lerp(UIKit.ACCENT, clampf(minutes / 120.0, 0.0, 1.0))
			var rect := Rect2(left + week * cell, day * cell, cell - 3, cell - 3)
			_calendar.draw_rect(rect, colour)
			if days_ago == 0:
				_calendar.draw_rect(rect.grow(1), UIKit.TEXT, false, 1.0)
