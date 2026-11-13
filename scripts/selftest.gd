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


func run(main: Control) -> void:
	var room: Room = main.get("room")
	print("Midnighty Room self-test")

	# catalogue integrity
	for id: String in Catalog.ITEMS:
		check(Catalog.texture_for(id) != null, "sprite exists for " + id)
	for entry: Dictionary in Catalog.STARTER_ROOM:
		check(Catalog.ITEMS.has(entry["id"]), "starter item is in the catalogue: " + entry["id"])

	# starter room
	check(room.all_items().size() == Catalog.STARTER_ROOM.size(), "starter room is fully placed")
	check(GameState.coins() == 30, "new player starts with 30 moonlight")

	# buying
	check(not GameState.is_unlocked("fireplace"), "fireplace starts locked")
	check(not GameState.buy("fireplace"), "cannot buy what you cannot afford")
	check(GameState.buy("candle") and GameState.coins() == 20, "buying a candle costs 10")
	check(GameState.buy("candle") and GameState.coins() == 20, "buying twice does not charge twice")

	# placing, moving, flipping, removing
	var before := room.all_items().size()
	check(room.spawn("candle"), "candle can be placed")
	check(room.all_items().size() == before + 1 and room.selected != null, "placed item is selected")
	room.decorate_mode = true
	var item := room.selected
	var start := item.position
	room.pointer_down(start + Vector2(0, -3))
	room.pointer_move(start + Vector2(40, 5))
	room.pointer_up(start + Vector2(40, 5))
	check(item.position.distance_to(start + Vector2(40, 8)) < 2.0, "dragging moves the item")
	room.pointer_down(Vector2(-50, -50) + item.position)
	room.pointer_move(Vector2(-900, -900))
	check(Rect2(0, 0, 320, 180).has_point(item.position), "items cannot be dragged out of the room")
	room.pointer_up(Vector2.ZERO)
	room.select(item)
	room.flip_selected()
	check(item.flipped, "flip works")
	room.remove_selected()
	await get_tree().process_frame
	check(room.all_items().size() == before, "remove works")
	room.decorate_mode = false
	check(room.selected == null, "leaving decorate mode clears the selection")

	# interactions
	var lamp: FurnitureItem
	for it in room.all_items():
		if it.item_id == "desk_lamp":
			lamp = it
	check(lamp != null and lamp.is_on, "desk lamp starts on")
	room.pointer_down(lamp.position + Vector2(-2, -12))
	check(not lamp.is_on, "clicking the lamp switches it off")

	# save and load round trip
	GameState.save_game()
	var saved_count: int = GameState.data["placed"].size()
	GameState.load_game()
	check(GameState.data["placed"].size() == saved_count, "layout survives save and load")
	check(GameState.is_unlocked("candle"), "unlocks survive save and load")
	var lamp_saved := false
	for entry: Dictionary in GameState.data["placed"]:
		if entry["id"] == "desk_lamp":
			lamp_saved = entry["on"] == false
	check(lamp_saved, "lamp state survives save and load")

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
	check(int(GameState.data["stats"]["streak"]) == 1, "streak starts at one day")
	FocusTimer.skip_to_end()
	await get_tree().create_timer(0.8).timeout
	check(FocusTimer.phase == FocusTimer.Phase.IDLE, "break ends back at idle")

	# audio
	AudioMixer.set_layer_volume("fire", 0.5)
	check(is_equal_approx(AudioMixer.layer_volume("fire"), 0.5), "ambience volume is stored")
	var title := AudioMixer.track_title()
	AudioMixer.next_track()
	check(AudioMixer.track_title() != title, "next track changes the track")

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
	room.reload()
	await get_tree().process_frame
	check(GameState.coins() == 30 and room.all_items().size() == Catalog.STARTER_ROOM.size(), "reset restores the starter room")

	DirAccess.remove_absolute(ProjectSettings.globalize_path(GameState.save_path))
	print("%d checks, %d failed" % [_count, _failed])
	get_tree().quit(1 if _failed > 0 else 0)
