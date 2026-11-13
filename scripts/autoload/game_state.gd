extends Node
## Autoload "GameState": everything that persists between sessions.
## Saved as JSON at user://save.json (on Windows:
## %APPDATA%/Godot/app_userdata/Midnighty Room/save.json). Point Steam Auto-Cloud
## at that file and cloud saves work with no extra code.

signal coins_changed(amount: int)
signal unlocks_changed
signal todos_changed
signal stats_changed
signal settings_changed
signal look_changed
## Any script can emit this to show a short message at the top of the screen.
signal toast(message: String)

const SAVE_VERSION := 1
const COINS_PER_FOCUS_MINUTE := 1
const SESSION_BONUS := 5
const TASK_REWARD := 2
const MAX_TASK_REWARDS_PER_DAY := 10

var data: Dictionary = {}
## Where the save lives. Dev flags and the self-test point this elsewhere so
## they never touch a real save.
var save_path := "user://save.json"
var _dirty := false
var _save_timer := 0.0


func _ready() -> void:
	load_game()


func _process(delta: float) -> void:
	if _dirty:
		_save_timer -= delta
		if _save_timer <= 0.0:
			save_game()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		save_game()


func _defaults() -> Dictionary:
	var unlocked: Array = []
	for id: String in Catalog.ITEMS:
		if int(Catalog.ITEMS[id]["price"]) == 0:
			unlocked.append(id)
	var placed: Array = []
	for entry: Dictionary in Catalog.STARTER_ROOM:
		placed.append({"id": entry["id"], "x": entry["x"], "y": entry["y"], "flip": false, "on": true})
	return {
		"version": SAVE_VERSION,
		"coins": 30,
		"unlocked": unlocked,
		"placed": placed,
		"wall": 0,
		"floor": 0,
		"todos": [],
		"stats": {"total_minutes": 0, "sessions": 0, "streak": 0, "last_day": "", "history": {}, "task_rewards": {}},
		"settings": {"master": 0.8, "music": 0.6, "time_mode": "real", "fullscreen": false, "fps": 60, "on_top": false},
		"mixer": {"rain": 0.45, "vinyl": 0.25},
		"music": {"track": 0, "playing": true},
		"timer": {"focus": 25, "rest": 5, "auto_loop": false},
	}


func load_game() -> void:
	data = _defaults()
	if not FileAccess.file_exists(save_path):
		return
	var file := FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Save file unreadable, starting fresh (old file kept as save.bak.json)")
		DirAccess.copy_absolute(ProjectSettings.globalize_path(save_path), ProjectSettings.globalize_path("user://save.bak.json"))
		return
	_merge(data, parsed)


## Copies saved values over the defaults so new keys added in later versions
## keep their default instead of going missing.
func _merge(base: Dictionary, saved: Dictionary) -> void:
	for key: Variant in saved:
		if base.has(key) and typeof(base[key]) == TYPE_DICTIONARY and typeof(saved[key]) == TYPE_DICTIONARY \
				and key not in ["mixer", "history", "task_rewards"]:
			_merge(base[key], saved[key])
		else:
			base[key] = saved[key]


func save_game() -> void:
	_dirty = false
	var file := FileAccess.open(save_path + ".tmp", FileAccess.WRITE)
	if file == null:
		push_error("Could not write save file")
		return
	file.store_string(JSON.stringify(data, "  "))
	file.close()
	DirAccess.rename_absolute(ProjectSettings.globalize_path(save_path + ".tmp"), ProjectSettings.globalize_path(save_path))


func mark_dirty() -> void:
	if not _dirty:
		_dirty = true
		_save_timer = 1.5


func reset_all() -> void:
	data = _defaults()
	save_game()
	coins_changed.emit(coins())
	unlocks_changed.emit()
	todos_changed.emit()
	stats_changed.emit()
	look_changed.emit()
	settings_changed.emit()


# ------------------------------------------------------------------ coins
func coins() -> int:
	return int(data["coins"])


func add_coins(amount: int) -> void:
	data["coins"] = coins() + amount
	coins_changed.emit(coins())
	mark_dirty()


func is_unlocked(id: String) -> bool:
	return id in data["unlocked"]


func buy(id: String) -> bool:
	if is_unlocked(id):
		return true
	var price := int(Catalog.get_def(id).get("price", 0))
	if coins() < price:
		return false
	data["unlocked"].append(id)
	add_coins(-price)
	unlocks_changed.emit()
	return true


# ------------------------------------------------------------------- room
func set_placed(items: Array) -> void:
	data["placed"] = items
	mark_dirty()


func set_look(wall: int, floor_index: int) -> void:
	data["wall"] = wall
	data["floor"] = floor_index
	look_changed.emit()
	mark_dirty()


# ------------------------------------------------------------------ todos
func add_todo(text: String) -> void:
	text = text.strip_edges()
	if text.is_empty():
		return
	data["todos"].append({"text": text, "done": false})
	todos_changed.emit()
	mark_dirty()


func set_todo_done(index: int, done: bool) -> int:
	var todo: Dictionary = data["todos"][index]
	var reward := 0
	if done and not todo["done"] and not todo.get("rewarded", false):
		var rewards: Dictionary = data["stats"]["task_rewards"]
		var today := today_key()
		if int(rewards.get(today, 0)) < MAX_TASK_REWARDS_PER_DAY:
			data["stats"]["task_rewards"] = {today: int(rewards.get(today, 0)) + 1}
			todo["rewarded"] = true
			reward = TASK_REWARD
			add_coins(reward)
	todo["done"] = done
	todos_changed.emit()
	mark_dirty()
	return reward


func remove_todo(index: int) -> void:
	data["todos"].remove_at(index)
	todos_changed.emit()
	mark_dirty()


func clear_done_todos() -> void:
	data["todos"] = data["todos"].filter(func(t: Dictionary) -> bool: return not t["done"])
	todos_changed.emit()
	mark_dirty()


# ------------------------------------------------------------------ stats
func today_key() -> String:
	return Time.get_date_string_from_system()


func minutes_today() -> int:
	return int(data["stats"]["history"].get(today_key(), 0))


## Called by FocusTimer when a focus block finishes. Returns coins earned.
func record_focus(minutes: int) -> int:
	var stats: Dictionary = data["stats"]
	var today := today_key()
	stats["total_minutes"] = int(stats["total_minutes"]) + minutes
	stats["sessions"] = int(stats["sessions"]) + 1
	stats["history"][today] = int(stats["history"].get(today, 0)) + minutes
	if stats["last_day"] != today:
		var yesterday := Time.get_date_string_from_unix_time(int(Time.get_unix_time_from_system()) + _utc_offset_seconds() - 86400)
		stats["streak"] = int(stats["streak"]) + 1 if stats["last_day"] == yesterday else 1
		stats["last_day"] = today
	var earned := minutes * COINS_PER_FOCUS_MINUTE + SESSION_BONUS
	add_coins(earned)
	stats_changed.emit()
	return earned


func _utc_offset_seconds() -> int:
	return int(Time.get_time_zone_from_system()["bias"]) * 60


# --------------------------------------------------------------- settings
func setting(key: String) -> Variant:
	return data["settings"][key]


func set_setting(key: String, value: Variant) -> void:
	data["settings"][key] = value
	settings_changed.emit()
	mark_dirty()
