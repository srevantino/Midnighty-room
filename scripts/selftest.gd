extends Node
## Logic checks, run with:  godot --headless -- --selftest
## Exits with code 0 when everything passes, 1 otherwise. Main points the save
## at user://dev_save.json first, so the real save file is never touched.

var _failed := 0
var _count := 0


func check(condition: bool, what: String) -> void:
	_count += 1
	if condition:
		print("  ok    ", what)
	else:
		_failed += 1
		print("  FAIL  ", what)


func _find(room: Room, id: String) -> FurnitureItem:
	for it in room.all_items():
		if it.item_id == id:
			return it
	return null


## Pins today's goals so rewards in other tests are predictable.
func _quiet_goals() -> void:
	GameState.data["stats"]["goals"] = {"date": GameState.today_key(), "list": [
		{"id": "minutes", "target": 9999, "reward": 10, "done": false}]}
	GameState.data["stats"]["day"] = {"date": GameState.today_key()}


## Writes a short silent WAV, standing in for a song the player dropped in.
func _write_wav(path: String) -> void:
	var samples := 4410
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string("RIFF")
	f.store_32(36 + samples * 2)
	f.store_string("WAVEfmt ")
	f.store_32(16)
	f.store_16(1)
	f.store_16(1)
	f.store_32(44100)
	f.store_32(88200)
	f.store_16(2)
	f.store_16(16)
	f.store_string("data")
	f.store_32(samples * 2)
	f.store_buffer(PackedByteArray().duplicate() if samples == 0 else _zeros(samples * 2))
	f.close()


func _zeros(count: int) -> PackedByteArray:
	var bytes := PackedByteArray()
	bytes.resize(count)
	return bytes


func run(main: Control) -> void:
	var room: Room = main.get("room")
	var starter: Array = Catalog.ROOMS[0]["starter"]
	TranslationServer.set_locale("en")
	_quiet_goals()
	print("Midnighty Room self-test")

	# catalogue integrity
	var missing := 0
	for id: String in Catalog.ITEMS:
		var def: Dictionary = Catalog.ITEMS[id]
		if not ResourceLoader.exists(Catalog.SPRITE_DIR + str(def.get("sprite", id)) + ".png"):
			missing += 1
			print("    missing sprite: ", id)
		for frame: String in def.get("frames", []):
			if not ResourceLoader.exists(Catalog.SPRITE_DIR + frame + ".png"):
				missing += 1
				print("    missing frame: ", frame)
		for variant: String in def.get("variants", []):
			if variant != "" and not ResourceLoader.exists("%s%s__%s.png" % [Catalog.SPRITE_DIR, def.get("sprite", id), variant]):
				missing += 1
				print("    missing variant: ", id, " ", variant)
		if def.get("set", "") not in Catalog.SETS:
			missing += 1
			print("    unknown set on: ", id)
	check(missing == 0, "all %d items have their sprites, frames, variants and a set" % Catalog.ITEMS.size())
	for pose: String in ["idle", "type", "rest", "sleep"]:
		for variant: String in ["", "teal", "rose", "amber"]:
			if Catalog.sprite("avatar_%s_1" % pose, variant) == null:
				missing += 1
	check(missing == 0, "avatar has every pose in every colour")
	for config: Dictionary in Catalog.ROOMS:
		var ok := Catalog.sprite(config["window"]) != null
		for entry: Dictionary in config["starter"]:
			ok = ok and Catalog.ITEMS.has(entry["id"])
		check(ok, "room '%s' has a window and a valid starter layout" % config["name"])

	# starter room
	check(room.all_items().size() == starter.size(), "starter room is fully placed")
	check(GameState.coins() == 30 and GameState.level() == 1, "new player starts at level 1 with 30 moonlight")

	# buying and locks
	check(not GameState.is_unlocked("fireplace") and GameState.lock_reason("fireplace") != "", "fireplace starts locked behind a level")
	check(not GameState.buy("fireplace"), "cannot buy a level-locked item")
	check(GameState.lock_reason("floor_lamp") == "" and GameState.lock_reason("beanbag") == "", "level 1 items within budget are buyable")
	check(GameState.buy("candle") and GameState.coins() == 20, "buying a candle costs 10")
	check(GameState.buy("candle") and GameState.coins() == 20, "buying twice does not charge twice")

	# placing, moving, flipping, removing
	var before := room.all_items().size()
	check(room.spawn("candle"), "candle can be placed")
	check(room.all_items().size() == before + 1 and room.selected != null, "placed item is selected")
	room.decorate_mode = true
	var item := room.selected
	item.position = Vector2(200, 160)
	var start := item.position
	room.pointer_down(start + Vector2(0, -3))
	room.pointer_move(start + Vector2(40, 5))
	room.pointer_up(start + Vector2(40, 5))
	check(item.position.distance_to(start + Vector2(40, 8)) < 2.0, "dragging moves the item")
	room.pointer_down(item.position + Vector2(0, -3))
	room.pointer_move(Vector2(-900, -900))
	check(Rect2(0, 0, 320, 180).has_point(item.position), "items cannot be dragged out of the room")
	room.pointer_up(Vector2.ZERO)

	# surfaces: small items snap onto furniture and ride along with it
	var desk := _find(room, "desk")
	var ledge := desk.surface()
	room.select(item)
	item.position = Vector2(float(ledge["x0"]) + 20, float(ledge["y"]) + 20)
	room.pointer_down(item.position + Vector2(0, -3))
	room.pointer_move(Vector2(float(ledge["x0"]) + 20, float(ledge["y"]) - 6))
	room.pointer_up(Vector2.ZERO)
	check(is_equal_approx(item.position.y, float(ledge["y"])), "a candle dropped near the desk snaps onto it")
	var candle_x := item.position.x
	var monitor := _find(room, "monitor")
	var monitor_x := monitor.position.x
	room.pointer_down(desk.position + Vector2(-28, -20))
	check(room.selected == desk, "clicking the desk leg selects the desk")
	room.pointer_move(desk.position + Vector2(-28 + 30, -20))
	room.pointer_up(Vector2.ZERO)
	check(is_equal_approx(item.position.x, candle_x + 30) and is_equal_approx(monitor.position.x, monitor_x + 30), "things on the desk move with the desk")
	room.nudge_selected(Vector2(-30, 0))
	check(is_equal_approx(monitor.position.x, monitor_x), "arrow-key nudging moves the desk and its riders back")

	room.select(item)
	room.flip_selected()
	check(item.flipped, "flip works")
	room.remove_selected()
	await get_tree().process_frame
	check(room.all_items().size() == before, "remove works")

	# colour variants
	var bed := _find(room, "bed")
	room.select(bed)
	room.set_selected_variant("teal")
	var saved_variant := ""
	for entry: Dictionary in GameState.room()["placed"]:
		if entry["id"] == "bed":
			saved_variant = entry["variant"]
	check(bed.variant == "teal" and saved_variant == "teal", "recolouring the bed is applied and saved")
	room.decorate_mode = false
	check(room.selected == null, "leaving decorate mode clears the selection")

	# interactions and hover
	var lamp := _find(room, "desk_lamp")
	check(lamp != null and lamp.is_on, "desk lamp starts on")
	check(room.pointer_move(lamp.position + Vector2(-2, -12)) and lamp.hovered, "hovering the lamp highlights it")
	room.pointer_down(lamp.position + Vector2(-2, -12))
	check(not lamp.is_on, "clicking the lamp switches it off")
	check(not room.pointer_move(Vector2(160, 5)), "empty wall is not clickable")
	var cat := _find(room, "cat")
	cat.interact()
	check(int(GameState.data["stats"]["day"].get("pets", 0)) == 1, "petting Miso is counted")

	# save and load round trip
	GameState.save_game()
	var saved_count: int = GameState.room()["placed"].size()
	GameState.load_game()
	_quiet_goals()
	check(GameState.room()["placed"].size() == saved_count, "layout survives save and load")
	check(GameState.is_unlocked("candle"), "unlocks survive save and load")
	var lamp_saved := false
	for entry: Dictionary in GameState.room()["placed"]:
		if entry["id"] == "desk_lamp":
			lamp_saved = entry["on"] == false
	check(lamp_saved, "lamp state survives save and load")

	# migration from the 0.1 save format
	var old := {"version": 1, "coins": 77, "unlocked": ["bed", "sofa"], "wall": 2, "floor": 3,
		"placed": [{"id": "sofa", "x": 100, "y": 150, "flip": true, "on": true}], "todos": [],
		"stats": {"total_minutes": 100, "sessions": 4, "streak": 2, "last_day": "", "history": {}, "task_rewards": {}},
		"settings": {"master": 0.5, "music": 0.6, "time_mode": "night", "fullscreen": false, "fps": 60, "on_top": false}}
	var file := FileAccess.open(GameState.save_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(old))
	file.close()
	GameState.load_game()
	check(GameState.coins() == 77 and GameState.room()["placed"].size() == 1 and int(GameState.room()["wall"]) == 2, "a 0.1 save keeps its coins, layout and wall colour")
	check(GameState.data["rooms"].size() == Catalog.ROOMS.size() and float(GameState.setting("sfx")) > 0.0, "a 0.1 save gains the new rooms and settings")
	check(GameState.level() == 3 and GameState.is_unlocked("avatar"), "a 0.1 save gets a level from its focus time and the new free items")
	GameState.data = GameState._defaults()
	GameState.data["unlocked"].append("candle")
	_quiet_goals()
	GameState.room_changed.emit()

	# tasks
	GameState.add_todo("  write tests  ")
	check(GameState.data["todos"].size() == 1 and GameState.data["todos"][0]["text"] == "write tests", "tasks are trimmed and stored")
	GameState.add_todo("   ")
	check(GameState.data["todos"].size() == 1, "empty tasks are ignored")
	var coins_before := GameState.coins()
	check(GameState.set_todo_done(0, true) == GameState.TASK_REWARD, "finishing a task pays out")
	GameState.set_todo_done(0, false)
	check(GameState.set_todo_done(0, true) == 0 and GameState.coins() == coins_before + GameState.TASK_REWARD, "re-ticking a task does not pay twice")

	# focus timer
	FocusTimer.set_lengths(25, 5)
	check(FocusTimer.seconds_left() == 1500, "idle timer shows the focus length")
	coins_before = GameState.coins()
	FocusTimer.start_focus()
	check(FocusTimer.phase == FocusTimer.Phase.FOCUS, "timer starts")
	FocusTimer.toggle_pause()
	var frozen := FocusTimer.seconds_left()
	await get_tree().create_timer(1.2).timeout
	check(FocusTimer.seconds_left() == frozen, "paused timer does not count down")
	FocusTimer.toggle_pause()
	FocusTimer.skip_to_end()
	await get_tree().create_timer(0.8).timeout
	check(FocusTimer.phase == FocusTimer.Phase.REST, "focus rolls into a break")
	check(GameState.coins() == coins_before + 25 + GameState.SESSION_BONUS, "a 25 minute session pays 30 moonlight")
	check(int(GameState.data["stats"]["sessions"]) == 1 and GameState.minutes_today() == 25, "stats record the session")
	check(int(GameState.data["stats"]["streak"]) == 1 and int(GameState.data["stats"]["best_streak"]) == 1, "streak starts at one day")
	FocusTimer.skip_to_end()
	await get_tree().create_timer(0.8).timeout
	check(FocusTimer.phase == FocusTimer.Phase.IDLE, "break ends back at idle")

	# levels
	check(GameState.xp_for_level(2) == 30 and GameState.xp_for_level(3) == 90, "level thresholds are 30 and 90 XP")
	check(GameState.level() == 1, "27 XP is still level 1")
	coins_before = GameState.coins()
	var levels_seen: Array = []
	var on_level := func(l: int) -> void: levels_seen.append(l)
	GameState.level_up.connect(on_level)
	GameState.add_xp(70)
	check(GameState.level() == 3 and levels_seen == [3], "97 XP reaches level 3 and announces it once")
	check(GameState.coins() == coins_before + 2 * GameState.LEVEL_REWARD, "two levels pay two rewards")
	GameState.add_xp(1)
	check(GameState.coins() == coins_before + 2 * GameState.LEVEL_REWARD, "levels are not paid twice")
	GameState.level_up.disconnect(on_level)

	# rooms
	check(GameState.room_lock_reason(1) == "" and GameState.room_lock_reason(2) != "", "level 3 opens the attic but not the loft")
	check(not GameState.switch_room(2) and int(GameState.data["room"]) == 0, "a locked room cannot be entered")
	check(GameState.switch_room(1), "the attic can be entered")
	await get_tree().process_frame
	check(room.all_items().size() == Catalog.ROOMS[1]["starter"].size() and room.pane == Catalog.ROOMS[1]["pane"], "switching rooms swaps the layout and the window")
	room.spawn("candle")
	GameState.switch_room(0)
	await get_tree().process_frame
	check(room.all_items().size() == GameState.data["rooms"][0]["placed"].size(), "each room keeps its own layout")
	check(GameState.data["rooms"][1]["placed"].size() == Catalog.ROOMS[1]["starter"].size() + 1, "the attic kept the candle")

	# layout presets
	var count_before := room.all_items().size()
	GameState.save_preset("1")
	room.spawn("candle")
	room.spawn("candle")
	check(GameState.load_preset("1"), "a saved layout can be loaded")
	await get_tree().process_frame
	check(room.all_items().size() == count_before, "loading a layout restores the room")
	check(not GameState.load_preset("2"), "an empty layout slot does nothing")
	GameState.reset_room()
	await get_tree().process_frame
	check(room.all_items().size() == starter.size() and GameState.has_preset("1"), "resetting a room keeps its saved layouts")

	# daily goals
	GameState.data["stats"]["goals"] = {"date": "", "list": []}
	var goals := GameState.goals()
	var ids := {}
	for goal: Dictionary in goals:
		ids[goal["id"]] = true
	check(goals.size() == 3 and ids.size() == 3, "three different daily goals are generated")
	check(GameState.goals() == goals, "goals are stable within a day")
	GameState.data["stats"]["goals"]["list"] = [{"id": "pets", "target": 2, "reward": 15, "done": false}]
	GameState.data["stats"]["day"] = {"date": GameState.today_key()}
	coins_before = GameState.coins()
	GameState.bump("pets")
	check(GameState.coins() == coins_before and GameState.goal_progress(GameState.goals()[0]) == 1, "goal progress is tracked")
	GameState.bump("pets")
	check(GameState.coins() == coins_before + 15 and GameState.all_goals_done(), "finishing a goal pays its reward")
	GameState.bump("pets")
	check(GameState.coins() == coins_before + 15, "a finished goal does not pay again")

	# key bindings
	check(GameState.key_for("timer") == KEY_SPACE, "default timer key is Space")
	GameState.set_key("timer", KEY_T)
	check(GameState.key_for("timer") == KEY_T and GameState.key_for("music") == KEY_M, "rebinding one key leaves the others alone")

	# audio
	AudioMixer.set_layer_volume("fire", 0.5)
	check(is_equal_approx(AudioMixer.layer_volume("fire"), 0.5), "ambience volume is stored")
	var title := AudioMixer.track_title()
	AudioMixer.next_track()
	check(AudioMixer.track_title() != title, "next track changes the track")
	var folder := AudioMixer.user_music_folder()
	_write_wav(folder + "/selftest_song.wav")
	if FileAccess.file_exists(folder + "/selftest_song.wav"):
		check(AudioMixer.scan_user_music() >= 1 and AudioMixer.playlist.size() > AudioMixer.TRACKS.size(), "music dropped in the folder joins the playlist")
		var own_index := AudioMixer.playlist.size() - 1
		while AudioMixer.track_index() != own_index:
			AudioMixer.next_track()
		check(AudioMixer.track_title() == "selftest song", "a user track can be selected and loads")
		DirAccess.remove_absolute(folder + "/selftest_song.wav")
		AudioMixer.scan_user_music()
		AudioMixer.next_track(-AudioMixer.track_index())

	# languages
	TranslationServer.set_locale("en")
	check("en" in TranslationServer.get_loaded_locales(), "the English strings are loaded")
	check(tr("Decorate") == "Decorate", "English text comes back unchanged")

	# time of day
	room.time_override = 12.0
	await get_tree().process_frame
	await get_tree().process_frame
	check(room.night < 0.1, "noon is not night")
	room.time_override = 23.0
	await get_tree().process_frame
	await get_tree().process_frame
	check(room.night > 0.9, "11pm is night")

	# reset
	GameState.reset_all()
	await get_tree().process_frame
	check(GameState.coins() == 30 and room.all_items().size() == starter.size(), "reset restores the starter room")
	check(GameState.key_for("timer") == KEY_T, "reset keeps your key bindings")

	DirAccess.remove_absolute(ProjectSettings.globalize_path(GameState.save_path))
	print("%d checks, %d failed" % [_count, _failed])
	get_tree().quit(1 if _failed > 0 else 0)
