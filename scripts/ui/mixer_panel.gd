extends BasePanel
## Sound mixer: the music player (built-in loops plus your own files) and one
## slider per ambience layer.

var _title: Label
var _play: Button
var _own: Label


func _ready() -> void:
	build("Sounds", 360)
	body.add_child(UIKit.section("Lofi player"))
	_title = UIKit.label("", 19, UIKit.ACCENT)
	_title.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_title.clip_text = true
	body.add_child(_title)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.add_child(UIKit.button("Prev", func() -> void: AudioMixer.next_track(-1), 70))
	_play = UIKit.button("Pause", AudioMixer.toggle_music, 100)
	row.add_child(_play)
	row.add_child(UIKit.button("Next", func() -> void: AudioMixer.next_track(1), 70))
	body.add_child(row)
	body.add_child(UIKit.slider_row("Music", float(GameState.setting("music")), func(v: float) -> void:
		GameState.set_setting("music", v)
		AudioMixer.apply_volumes()))

	body.add_child(UIKit.section("Your own music"))
	_own = UIKit.label("", 13, UIKit.MUTED)
	_own.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(_own)
	var own_row := HBoxContainer.new()
	own_row.add_theme_constant_override("separation", 8)
	own_row.add_child(UIKit.button("Open music folder", func() -> void: OS.shell_open(AudioMixer.user_music_folder())))
	own_row.add_child(UIKit.button("Rescan", func() -> void:
		var found := AudioMixer.scan_user_music()
		GameState.toast.emit(tr("Found %d of your tracks") % found)))
	body.add_child(own_row)

	body.add_child(UIKit.section("Ambience"))
	for layer: Dictionary in AudioMixer.LAYERS:
		var id: String = layer["id"]
		body.add_child(UIKit.slider_row(layer["name"], AudioMixer.layer_volume(id), func(v: float) -> void:
			AudioMixer.set_layer_volume(id, v)))
	body.add_child(UIKit.label("Turn the rain up and watch the window.", 13, UIKit.MUTED))

	AudioMixer.track_changed.connect(func(_t: String) -> void: _refresh())
	AudioMixer.music_state_changed.connect(func(_p: bool) -> void: _refresh())
	AudioMixer.playlist_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	_title.text = tr(AudioMixer.track_title())
	_play.text = "Pause" if AudioMixer.is_music_playing() else "Play"
	var own := AudioMixer.playlist.size() - AudioMixer.TRACKS.size()
	_own.text = tr("Drop MP3, OGG or WAV files into the music folder, then press Rescan.") if own == 0 else tr("%d of your tracks are in the playlist.") % own
