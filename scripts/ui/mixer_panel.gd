extends BasePanel
## Sound mixer: the lofi player plus one slider per ambience layer.

var _title: Label
var _play: Button


func _ready() -> void:
	build("Sounds", 360)
	body.add_child(UIKit.section("Lofi player"))
	_title = UIKit.label(AudioMixer.track_title(), 19, UIKit.ACCENT)
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

	body.add_child(UIKit.spacer(2))
	body.add_child(UIKit.section("Ambience"))
	for layer: Dictionary in AudioMixer.LAYERS:
		var id: String = layer["id"]
		body.add_child(UIKit.slider_row(layer["name"], AudioMixer.layer_volume(id), func(v: float) -> void:
			AudioMixer.set_layer_volume(id, v)))
	var hint := UIKit.label("Turn the rain up and watch the window.", 13, UIKit.MUTED)
	body.add_child(hint)

	AudioMixer.track_changed.connect(func(title: String) -> void: _title.text = title)
	AudioMixer.music_state_changed.connect(func(_p: bool) -> void: _refresh())
	_refresh()


func _refresh() -> void:
	_play.text = "Pause" if AudioMixer.is_music_playing() else "Play"
