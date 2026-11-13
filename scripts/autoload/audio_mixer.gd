extends Node
## Autoload "AudioMixer": ambience layers, the music player and UI sounds.
## Buses are created at runtime (Master > Music, Ambience, SFX) so there is no
## bus layout resource to keep in sync.

signal track_changed(title: String)
signal music_state_changed(playing: bool)
signal layer_changed(id: String, volume: float)

const AUDIO_DIR := "res://assets/audio/"
const LAYERS := [
	{"id": "rain", "name": "Rain"},
	{"id": "fire", "name": "Fireplace"},
	{"id": "wind", "name": "Wind"},
	{"id": "vinyl", "name": "Vinyl crackle"},
	{"id": "city", "name": "City hum"},
	{"id": "crickets", "name": "Crickets"},
	{"id": "brown", "name": "Brown noise"},
]
const TRACKS := [
	{"file": "music_midnight_tea", "title": "Midnight Tea"},
	{"file": "music_paper_lanterns", "title": "Paper Lanterns"},
	{"file": "music_slow_rain", "title": "Slow Rain"},
]
const LOOPS_PER_TRACK := 4

var _layer_players: Dictionary = {}
var _music: AudioStreamPlayer
var _sfx: Dictionary = {}
var _track := 0
var _loops := 0
var _last_pos := 0.0


func _ready() -> void:
	for bus_name: String in ["Music", "Ambience", "SFX"]:
		if AudioServer.get_bus_index(bus_name) == -1:
			AudioServer.add_bus()
			var idx := AudioServer.bus_count - 1
			AudioServer.set_bus_name(idx, bus_name)
			AudioServer.set_bus_send(idx, "Master")
	for layer: Dictionary in LAYERS:
		var player := AudioStreamPlayer.new()
		var stream := load(AUDIO_DIR + "amb_" + layer["id"] + ".ogg") as AudioStreamOggVorbis
		stream.loop = true
		player.stream = stream
		player.bus = "Ambience"
		add_child(player)
		_layer_players[layer["id"]] = player
		_apply_layer(layer["id"])
	_music = AudioStreamPlayer.new()
	_music.bus = "Music"
	add_child(_music)
	for sfx_name: String in ["chime", "click", "place", "coin", "purr", "switch"]:
		var p := AudioStreamPlayer.new()
		p.stream = load(AUDIO_DIR + sfx_name + ".wav")
		p.bus = "SFX"
		add_child(p)
		_sfx[sfx_name] = p
	apply_volumes()
	_track = clampi(int(GameState.data["music"]["track"]), 0, TRACKS.size() - 1)
	_load_track()
	if GameState.data["music"]["playing"]:
		_music.play()


func _process(_delta: float) -> void:
	if not _music.playing:
		return
	var pos := _music.get_playback_position()
	if pos + 1.0 < _last_pos:  # the loop wrapped around
		_loops += 1
		if _loops >= LOOPS_PER_TRACK:
			next_track()
			return
	_last_pos = pos


func apply_volumes() -> void:
	_set_bus("Master", float(GameState.setting("master")))
	_set_bus("Music", float(GameState.setting("music")))


func _set_bus(bus_name: String, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	AudioServer.set_bus_mute(idx, linear <= 0.001)
	AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(linear, 0.001)))


# ----------------------------------------------------------------- layers
func layer_volume(id: String) -> float:
	return float(GameState.data["mixer"].get(id, 0.0))


func set_layer_volume(id: String, volume: float) -> void:
	GameState.data["mixer"][id] = volume
	GameState.mark_dirty()
	_apply_layer(id)
	layer_changed.emit(id, volume)


func _apply_layer(id: String) -> void:
	var player: AudioStreamPlayer = _layer_players[id]
	var volume := layer_volume(id)
	if volume <= 0.01:
		player.stop()
		return
	player.volume_db = linear_to_db(volume)
	if not player.playing:
		player.play()


# ------------------------------------------------------------------ music
func _load_track() -> void:
	var stream := load(AUDIO_DIR + TRACKS[_track]["file"] + ".ogg") as AudioStreamOggVorbis
	stream.loop = true
	_music.stream = stream
	_loops = 0
	_last_pos = 0.0
	track_changed.emit(track_title())


func track_title() -> String:
	return TRACKS[_track]["title"]


func is_music_playing() -> bool:
	return _music.playing


func toggle_music() -> void:
	if _music.playing:
		_music.stop()
	else:
		_music.play()
	GameState.data["music"]["playing"] = _music.playing
	GameState.mark_dirty()
	music_state_changed.emit(_music.playing)


func next_track(step: int = 1) -> void:
	var was_playing := _music.playing
	_track = posmod(_track + step, TRACKS.size())
	GameState.data["music"]["track"] = _track
	GameState.mark_dirty()
	_load_track()
	if was_playing:
		_music.play()


func play_sfx(sfx_name: String) -> void:
	if _sfx.has(sfx_name):
		(_sfx[sfx_name] as AudioStreamPlayer).play()
