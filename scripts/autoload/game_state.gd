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
signal room_changed
signal goals_changed
signal level_up(level: int)
## Any script can emit this to show a short message at the top of the screen.
signal toast(message: String)

const SAVE_VERSION := 2
const COINS_PER_FOCUS_MINUTE := 1
const SESSION_BONUS := 5
const TASK_REWARD := 2
const MAX_TASK_REWARDS_PER_DAY := 10
const LEVEL_REWARD := 25
const MAX_LEVEL := 20
const DEFAULT_KEYS := {
	"timer": KEY_SPACE, "music": KEY_M, "decorate": KEY_D, "flip": KEY_F, "remove": KEY_DELETE,
	"mini": KEY_F10, "fullscreen": KEY_F11, "screenshot": KEY_F12,
}
const KEY_LABELS := {
	"timer": "Start or pause the timer", "music": "Music on or off", "decorate": "Open Decorate",
	"flip": "Flip selected item", "remove": "Remove selected item", "mini": "Mini window",
	"fullscreen": "Fullscreen", "screenshot": "Screenshot",
}
## Daily goal templates: counter to watch, text, possible targets.
const GOAL_TYPES := [
	{"id": "minutes", "text": "Focus for %d minutes", "targets": [25, 50, 90]},
	{"id": "sessions", "text": "Finish %d focus sessions", "targets": [1, 2, 3]},
	{"id": "tasks", "text": "Tick off %d tasks", "targets": [2, 3, 5]},
	{"id": "pets", "text": "Pet Miso %d times", "targets": [1, 3, 5]},
	{"id": "moves", "text": "Rearrange %d things in your room", "targets": [1, 3, 5]},
]

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


func is_demo() -> bool:
	return OS.has_feature("demo")


func _starter(room_index: int) -> Dictionary:
	var config: Dictionary = Catalog.ROOMS[room_index]
	var placed: Array = []
	for entry: Dictionary in config["starter"]:
		placed.append({"id": entry["id"], "x": entry["x"], "y": entry["y"], "flip": false, "on": true, "variant": entry.get("variant", "")})
	return {"placed": placed, "wall": config["wall"], "floor": config["floor"], "presets": {}}


func _defaults() -> Dictionary:
	var unlocked: Array = []
	for id: String in Catalog.ITEMS:
		if int(Catalog.ITEMS[id]["price"]) == 0:
			unlocked.append(id)
	var rooms: Array = []
	for i in Catalog.ROOMS.size():
		rooms.append(_starter(i))
	return {
		"version": SAVE_VERSION,
		"coins": 30,
		"unlocked": unlocked,
		"rooms": rooms,
		"room": 0,
		"todos": [],
		"stats": {"total_minutes": 0, "sessions": 0, "streak": 0, "best_streak": 0, "last_day": "", "history": {},
			"task_rewards": {}, "tasks_done": 0, "xp_bonus": 0, "level_paid": 1, "goals_done": 0,
			"day": {"date": ""}, "goals": {"date": "", "list": []}},
		"settings": {"master": 0.8, "music": 0.6, "ambience": 1.0, "sfx": 0.8, "time_mode": "real", "fullscreen": false,
			"fps": 60, "on_top": false, "ui_scale": 1.0, "locale": "", "onboarded": false, "notify": true,
			"mini_style": "room", "mini_pos": {}, "keys": {}},
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
	_migrate(parsed)
	_merge(data, parsed)
	# rooms added in later versions get their starter layout
	while data["rooms"].size() < Catalog.ROOMS.size():
		data["rooms"].append(_starter(data["rooms"].size()))
	data["room"] = clampi(int(data["room"]), 0, Catalog.ROOMS.size() - 1)
	for id: String in Catalog.ITEMS:
		if int(Catalog.ITEMS[id]["price"]) == 0 and id not in data["unlocked"]:
			data["unlocked"].append(id)
	data["version"] = SAVE_VERSION


## Upgrades older save layouts in place before they are merged.
func _migrate(saved: Dictionary) -> void:
	if int(saved.get("version", 1)) < 2:
		var first := _starter(0)
		first["placed"] = saved.get("placed", first["placed"])
		first["wall"] = saved.get("wall", 0)
		first["floor"] = saved.get("floor", 0)
		var rooms: Array = [first]
		for i in range(1, Catalog.ROOMS.size()):
			rooms.append(_starter(i))
		saved["rooms"] = rooms
		saved["room"] = 0
		for key: String in ["placed", "wall", "floor"]:
			saved.erase(key)


## Copies saved values over the defaults so new keys added in later versions
## keep their default instead of going missing.
func _merge(base: Dictionary, saved: Dictionary) -> void:
	for key: Variant in saved:
		if base.has(key) and typeof(base[key]) == TYPE_DICTIONARY and typeof(saved[key]) == TYPE_DICTIONARY \
				and key not in ["mixer", "history", "task_rewards", "day", "goals", "keys", "mini_pos"]:
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
	var keep: Dictionary = data["settings"].duplicate(true)
	data = _defaults()
	for key: String in ["keys", "ui_scale", "locale", "master", "music", "ambience", "sfx", "fullscreen", "fps"]:
		data["settings"][key] = keep[key]
	data["settings"]["onboarded"] = true
	save_game()
	coins_changed.emit(coins())
	unlocks_changed.emit()
	todos_changed.emit()
	stats_changed.emit()
	goals_changed.emit()
	room_changed.emit()
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


## "" when the item can be bought now, otherwise the reason it cannot.
func lock_reason(id: String) -> String:
	if is_unlocked(id):
		return ""
	if is_demo() and not Catalog.in_demo(id):
		return tr("Full game only")
	if level() < Catalog.level_of(id):
		return tr("Reach level %d") % Catalog.level_of(id)
	if coins() < int(Catalog.ITEMS[id]["price"]):
		return tr("Not enough moonlight yet")
	return ""


func buy(id: String) -> bool:
	if is_unlocked(id):
		return true
	if lock_reason(id) != "":
		return false
	data["unlocked"].append(id)
	add_coins(-int(Catalog.ITEMS[id]["price"]))
	unlocks_changed.emit()
	return true


# ------------------------------------------------------------------ rooms
func room() -> Dictionary:
	return data["rooms"][int(data["room"])]


func room_config() -> Dictionary:
	return Catalog.ROOMS[int(data["room"])]


func room_lock_reason(index: int) -> String:
	if is_demo() and index > 0:
		return tr("Full game only")
	var needed := int(Catalog.ROOMS[index]["level"])
	return tr("Reach level %d") % needed if level() < needed else ""


func switch_room(index: int) -> bool:
	index = posmod(index, Catalog.ROOMS.size())
	if room_lock_reason(index) != "":
		return false
	data["room"] = index
	mark_dirty()
	room_changed.emit()
	return true


func set_placed(items: Array) -> void:
	room()["placed"] = items
	mark_dirty()


func set_look(wall: int, floor_index: int) -> void:
	room()["wall"] = wall
	room()["floor"] = floor_index
	look_changed.emit()
	mark_dirty()


func has_preset(slot: String) -> bool:
	return room()["presets"].has(slot)


func save_preset(slot: String) -> void:
	room()["presets"][slot] = {"placed": room()["placed"].duplicate(true), "wall": room()["wall"], "floor": room()["floor"]}
	mark_dirty()


func load_preset(slot: String) -> bool:
	if not has_preset(slot):
		return false
	var preset: Dictionary = room()["presets"][slot]
	room()["placed"] = preset["placed"].duplicate(true)
	room()["wall"] = preset["wall"]
	room()["floor"] = preset["floor"]
	mark_dirty()
	room_changed.emit()
	return true


func reset_room() -> void:
	var presets: Dictionary = room()["presets"]
	data["rooms"][int(data["room"])] = _starter(int(data["room"]))
	room()["presets"] = presets
	mark_dirty()
	room_changed.emit()


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
			data["stats"]["tasks_done"] = int(data["stats"]["tasks_done"]) + 1
			add_coins(reward)
			add_xp(2)
			bump("tasks")
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
		stats["best_streak"] = maxi(int(stats["best_streak"]), int(stats["streak"]))
		stats["last_day"] = today
	var earned := minutes * COINS_PER_FOCUS_MINUTE + SESSION_BONUS
	add_coins(earned)
	bump("minutes", minutes)
	bump("sessions")
	_check_level()
	stats_changed.emit()
	return earned


func _utc_offset_seconds() -> int:
	return int(Time.get_time_zone_from_system()["bias"]) * 60


# ----------------------------------------------------------------- levels
func xp() -> int:
	return int(data["stats"]["total_minutes"]) + int(data["stats"]["xp_bonus"])


## XP needed to reach `lvl` from zero: 30, 90, 180, 300 ...
static func xp_for_level(lvl: int) -> int:
	return 15 * lvl * (lvl - 1)


func level() -> int:
	var lvl := 1
	while lvl < MAX_LEVEL and xp() >= xp_for_level(lvl + 1):
		lvl += 1
	return lvl


## [xp into this level, xp this level needs]
func level_progress() -> Array[int]:
	var lvl := level()
	if lvl >= MAX_LEVEL:
		return [1, 1]
	return [xp() - xp_for_level(lvl), xp_for_level(lvl + 1) - xp_for_level(lvl)]


func add_xp(amount: int) -> void:
	data["stats"]["xp_bonus"] = int(data["stats"]["xp_bonus"]) + amount
	_check_level()
	stats_changed.emit()
	mark_dirty()


func _check_level() -> void:
	var now := level()
	var paid := int(data["stats"]["level_paid"])
	if now <= paid:
		return
	data["stats"]["level_paid"] = now
	add_coins(LEVEL_REWARD * (now - paid))
	level_up.emit(now)
	unlocks_changed.emit()


# ------------------------------------------------------------ daily goals
func _day() -> Dictionary:
	var stats: Dictionary = data["stats"]
	if stats["day"].get("date", "") != today_key():
		stats["day"] = {"date": today_key()}
	return stats["day"]


## Adds to one of today's counters (minutes, sessions, tasks, pets, moves).
func bump(counter: String, amount: int = 1) -> void:
	var day := _day()
	day[counter] = int(day.get(counter, 0)) + amount
	mark_dirty()
	for goal: Dictionary in goals():
		if goal["id"] == counter and not goal["done"] and int(day[counter]) >= int(goal["target"]):
			goal["done"] = true
			data["stats"]["goals_done"] = int(data["stats"]["goals_done"]) + 1
			add_coins(int(goal["reward"]))
			add_xp(10)
			toast.emit(tr("Daily goal done  +%d moonlight") % int(goal["reward"]))
	goals_changed.emit()


## Today's three goals, generated from the date so they are stable all day.
func goals() -> Array:
	var stats: Dictionary = data["stats"]
	if stats["goals"].get("date", "") != today_key():
		var rng := RandomNumberGenerator.new()
		rng.seed = hash(today_key())
		var pool: Array = range(GOAL_TYPES.size())
		var list: Array = []
		for i in 3:
			var type: Dictionary = GOAL_TYPES[pool.pop_at(rng.randi_range(0, pool.size() - 1))]
			var tier := rng.randi_range(0, mini(2, level() / 2))
			list.append({"id": type["id"], "target": type["targets"][tier], "reward": 10 + tier * 5, "done": false})
		stats["goals"] = {"date": today_key(), "list": list}
	return stats["goals"]["list"]


func goal_text(goal: Dictionary) -> String:
	for type: Dictionary in GOAL_TYPES:
		if type["id"] == goal["id"]:
			return tr(type["text"]) % int(goal["target"])
	return ""


func goal_progress(goal: Dictionary) -> int:
	return mini(int(_day().get(goal["id"], 0)), int(goal["target"]))


func all_goals_done() -> bool:
	return goals().all(func(g: Dictionary) -> bool: return g["done"])


# --------------------------------------------------------------- settings
func setting(key: String) -> Variant:
	return data["settings"][key]


func set_setting(key: String, value: Variant) -> void:
	data["settings"][key] = value
	settings_changed.emit()
	mark_dirty()


func key_for(action: String) -> Key:
	return int(data["settings"]["keys"].get(action, DEFAULT_KEYS[action])) as Key


func set_key(action: String, keycode: Key) -> void:
	data["settings"]["keys"][action] = int(keycode)
	settings_changed.emit()
	mark_dirty()
