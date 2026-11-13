extends Node
## Autoload "SteamService": optional Steam integration.
##
## The game runs fine without Steam. Once the GodotSteam GDExtension is
## installed (AssetLib > "GodotSteam GDExtension 4.4+") and steam_appid.txt
## holds your App ID, this picks it up and starts reporting achievements and
## rich presence. Nothing else in the code talks to Steam directly.
##
## Create achievements with these API names in Steamworks:
##   FIRST_FOCUS, FOCUS_10_HOURS, STREAK_7, NIGHT_OWL, DECORATOR,
##   LEVEL_5, LEVEL_10, NEW_ROOM, DAILY_HAT_TRICK

var available := false
var _steam: Object


func _ready() -> void:
	if not Engine.has_singleton("Steam"):
		return
	_steam = Engine.get_singleton("Steam")
	var result: Dictionary = _steam.call("steamInitEx")
	available = int(result.get("status", 1)) == 0
	if not available:
		push_warning("Steam not initialised: %s" % str(result.get("verbal", "")))
		return
	FocusTimer.focus_completed.connect(_on_focus_completed)
	FocusTimer.phase_changed.connect(_on_phase_changed)
	GameState.room_changed.connect(func() -> void:
		if int(GameState.data["room"]) > 0:
			unlock("NEW_ROOM"))
	GameState.goals_changed.connect(func() -> void:
		if GameState.all_goals_done():
			unlock("DAILY_HAT_TRICK"))


func _process(_delta: float) -> void:
	if available:
		_steam.call("run_callbacks")


func unlock(achievement: String) -> void:
	if not available:
		return
	_steam.call("setAchievement", achievement)
	_steam.call("storeStats")


func _on_focus_completed(_minutes: int, _coins: int) -> void:
	var stats: Dictionary = GameState.data["stats"]
	unlock("FIRST_FOCUS")
	if int(stats["total_minutes"]) >= 600:
		unlock("FOCUS_10_HOURS")
	if int(stats["streak"]) >= 7:
		unlock("STREAK_7")
	var hour: int = Time.get_time_dict_from_system()["hour"]
	if hour < 4:
		unlock("NIGHT_OWL")


func _on_phase_changed(phase: String) -> void:
	if not available:
		return
	var text := {"idle": "Relaxing in the room", "focus": "In a focus session", "rest": "Taking a break"}
	_steam.call("setRichPresence", "steam_display", text[phase])


func on_level(level: int) -> void:
	if level >= 5:
		unlock("LEVEL_5")
	if level >= 10:
		unlock("LEVEL_10")


func on_items_placed(count: int) -> void:
	if count >= 20:
		unlock("DECORATOR")
