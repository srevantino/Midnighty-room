class_name FurnitureItem
extends Node2D
## One placed item. `position` is the anchor: the bottom-centre for things
## that stand ("floor" and "top" layers), the centre for wall items and rugs.
##
## Behaviours by `kind`:
##   lamp, monitor  click to switch on and off
##   fire, candle   flickering light
##   cat            naps, wanders, sits; click to pet
##   avatar         types while you focus, sips on breaks, dozes late at night
##   player         click to play or pause the music
##   mug            steam
##   clock          real clock hands

## Set by Room every frame: lamps glow harder as the room gets darker.
static var night_boost := 1.0
## True while decorating, so the cat stays where you put it.
static var frozen := false
static var hour := 22.0
static var _light_texture: GradientTexture2D
static var _images: Dictionary = {}

const WALK_AREA := Rect2(18, 128, 284, 46)

var item_id := ""
var def: Dictionary = {}
var layer := "floor"
var variant := ""
var flipped := false
var is_on := true
var selected := false:
	set(value):
		selected = value
		queue_redraw()
var hovered := false:
	set(value):
		if hovered != value:
			hovered = value
			_sprite.modulate = Color(1.3, 1.3, 1.3) if value else Color.WHITE

var _sprite: Sprite2D
var _light: PointLight2D
var _base_energy := 0.0
var _size := Vector2.ZERO
var _origin := Vector2.ZERO
var _t := 0.0
var _awake_until := 0.0
var _hands: Array[Line2D] = []
var _kind := ""
# cat brain
var _mood := "sleep"
var _mood_until := 0.0
var _target := Vector2.ZERO


func setup(id: String, pos: Vector2, flip: bool = false, on: bool = true, colour: String = "") -> void:
	item_id = id
	def = Catalog.get_def(id)
	layer = def.get("layer", "floor")
	_kind = def.get("kind", "")
	variant = colour
	flipped = flip
	is_on = on
	position = pos
	_t = randf() * 10.0
	_mood_until = _t + randf_range(8.0, 20.0)

	_sprite = Sprite2D.new()
	_sprite.centered = false
	add_child(_sprite)
	_set_texture(Catalog.texture_for(id, variant))
	_sprite.flip_h = flipped

	if def.has("light"):
		var spec: Dictionary = def["light"]
		_light = PointLight2D.new()
		_light.texture = get_light_texture()
		_light.color = spec["color"]
		_light.texture_scale = spec["size"]
		_base_energy = spec["energy"]
		_light.blend_mode = Light2D.BLEND_MODE_ADD
		add_child(_light)
		_place_light()

	match _kind:
		"mug":
			var steam := CPUParticles2D.new()
			steam.position = _origin + Vector2(4, 2)
			steam.amount = 5
			steam.lifetime = 2.4
			steam.direction = Vector2(0, -1)
			steam.spread = 18.0
			steam.gravity = Vector2.ZERO
			steam.initial_velocity_min = 3.0
			steam.initial_velocity_max = 5.0
			steam.color = Color(1, 1, 1, 0.35)
			add_child(steam)
		"clock":
			for i in 2:
				var hand := Line2D.new()
				hand.width = 1.0
				hand.default_color = Color("2a2438")
				hand.points = PackedVector2Array([Vector2.ZERO, Vector2.ZERO])
				add_child(hand)
				_hands.append(hand)
	_refresh_state()


func _set_texture(texture: Texture2D) -> void:
	if _sprite.texture == texture:
		return
	_sprite.texture = texture
	var new_size := texture.get_size()
	if new_size != _size:
		_size = new_size
		_origin = Vector2(-floorf(_size.x / 2.0), -_size.y) if layer in ["floor", "top"] else Vector2(-floorf(_size.x / 2.0), -floorf(_size.y / 2.0))
		_sprite.position = _origin
		queue_redraw()


static func get_light_texture() -> GradientTexture2D:
	if _light_texture == null:
		var gradient := Gradient.new()
		gradient.offsets = PackedFloat32Array([0.0, 0.35, 1.0])
		gradient.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.42), Color(1, 1, 1, 0)])
		_light_texture = GradientTexture2D.new()
		_light_texture.gradient = gradient
		_light_texture.width = 128
		_light_texture.height = 128
		_light_texture.fill = GradientTexture2D.FILL_RADIAL
		_light_texture.fill_from = Vector2(0.5, 0.5)
		_light_texture.fill_to = Vector2(1.0, 0.5)
	return _light_texture


func _place_light() -> void:
	if _light == null:
		return
	var offset: Vector2 = def["light"]["offset"]
	if flipped:
		offset.x = _size.x - offset.x
	_light.position = _origin + offset


func _refresh_state() -> void:
	if _light:
		_light.enabled = is_on
	if _kind == "monitor" and not is_on:
		_set_texture(Catalog.sprite("monitor_off"))


func bounds() -> Rect2:
	return Rect2(position + _origin, _size)


func is_interactive() -> bool:
	return _kind in ["lamp", "monitor", "cat", "player"]


## Where small items can rest on this one: {y, x0, x1} in room pixels, or {}.
func surface() -> Dictionary:
	if not def.has("surface"):
		return {}
	var spec: Dictionary = def["surface"]
	var left := position.x + _origin.x
	return {"y": position.y + _origin.y + float(spec["y"]) + 1.0, "x0": left + float(spec["x0"]), "x1": left + float(spec["x1"])}


## True when `point` (room pixels) lands on a non-transparent pixel.
func hit(point: Vector2) -> bool:
	if not bounds().has_point(point):
		return false
	var texture := _sprite.texture
	if not _images.has(texture):
		_images[texture] = texture.get_image()
	var image: Image = _images[texture]
	var local := (point - position - _origin).floor()
	if _sprite.flip_h:
		local.x = _size.x - 1 - local.x
	local = local.clamp(Vector2.ZERO, _size - Vector2.ONE)
	return image.get_pixelv(Vector2i(local)).a > 0.1


func set_flipped(value: bool) -> void:
	flipped = value
	_sprite.flip_h = value
	_place_light()


func variants() -> Array:
	return def.get("variants", [])


func set_variant(value: String) -> void:
	variant = value
	_set_texture(Catalog.texture_for(item_id, variant))


## Click outside decorate mode. Returns true if the item did something.
func interact() -> bool:
	match _kind:
		"lamp", "monitor":
			is_on = not is_on
			_refresh_state()
			AudioMixer.play_sfx("switch")
			return true
		"cat":
			_awake_until = _t + 4.0
			if _mood == "walk":
				_mood = "sit"
				_mood_until = _t + 6.0
			AudioMixer.play_sfx("purr")
			GameState.bump("pets")
			_spawn_hearts()
			return true
		"player":
			AudioMixer.toggle_music()
			AudioMixer.play_sfx("switch")
			return true
	return false


func _spawn_hearts() -> void:
	var hearts := CPUParticles2D.new()
	hearts.position = _origin + Vector2(6, 2)
	hearts.one_shot = true
	hearts.amount = 5
	hearts.lifetime = 1.4
	hearts.explosiveness = 0.6
	hearts.direction = Vector2(0, -1)
	hearts.spread = 35.0
	hearts.gravity = Vector2(0, -6)
	hearts.initial_velocity_min = 8.0
	hearts.initial_velocity_max = 14.0
	hearts.scale_amount_min = 2.0
	hearts.scale_amount_max = 2.0
	hearts.color = Color("ff8fb0")
	add_child(hearts)
	hearts.emitting = true
	hearts.finished.connect(hearts.queue_free)


func _process(delta: float) -> void:
	_t += delta
	if _light and is_on:
		var flicker := 1.0
		if _kind == "fire":
			flicker = 0.82 + 0.12 * sin(_t * 9.0) + 0.08 * sin(_t * 23.0 + 1.3)
		elif _kind == "candle":
			flicker = 0.9 + 0.07 * sin(_t * 11.0) + 0.04 * sin(_t * 29.0)
		_light.energy = _base_energy * flicker * night_boost
	match _kind:
		"cat":
			_cat(delta)
		"avatar":
			_avatar()
		"clock":
			var now := Time.get_time_dict_from_system()
			var centre := _origin + _size / 2.0
			var minute_angle := float(now["minute"]) / 60.0 * TAU - PI / 2.0
			var hour_angle := (float(now["hour"] % 12) + float(now["minute"]) / 60.0) / 12.0 * TAU - PI / 2.0
			_hands[0].points = PackedVector2Array([centre, centre + Vector2.from_angle(minute_angle) * 4.5])
			_hands[1].points = PackedVector2Array([centre, centre + Vector2.from_angle(hour_angle) * 3.0])
		_:
			_animate()


## Generic frame animation from the catalogue's "frames" list.
func _animate() -> void:
	if not def.has("frames") or (_kind == "monitor" and not is_on):
		return
	if def.get("animate_when", "") == "music" and not AudioMixer.is_music_playing():
		return
	var frames: Array = def["frames"]
	_set_texture(Catalog.sprite(frames[int(_t * float(def.get("fps", 1.0))) % frames.size()], variant))


func _cat(delta: float) -> void:
	if frozen and _mood == "walk":
		_mood = "sit"
		_mood_until = _t + 5.0
	if _t >= _mood_until and not frozen:
		match _mood:
			"sleep":
				_mood = "sit"
				_mood_until = _t + randf_range(3.0, 7.0)
			"sit":
				if randf() < 0.6:
					_mood = "walk"
					_target = Vector2(randf_range(WALK_AREA.position.x, WALK_AREA.end.x), randf_range(WALK_AREA.position.y, WALK_AREA.end.y)).round()
					_mood_until = _t + 30.0
				else:
					_mood = "sleep"
					_mood_until = _t + randf_range(25.0, 70.0)
			"walk":
				_mood = "sit"
				_mood_until = _t + randf_range(3.0, 6.0)
	var petted := _t < _awake_until
	match _mood:
		"walk":
			var step := position.move_toward(_target, 11.0 * delta)
			_sprite.flip_h = _target.x > position.x
			position = step
			_set_texture(Catalog.sprite("cat_walk_%d" % (int(_t * 5.0) % 2)))
			if position.distance_to(_target) < 0.5:
				position = position.round()
				_mood_until = 0.0
		"sit":
			_set_texture(Catalog.sprite("cat_sit_%d" % (1 if petted or fmod(_t, 4.0) > 3.8 else 0)))
		_:
			_sprite.flip_h = flipped
			_set_texture(Catalog.sprite(("cat_awake_%d" if petted else "cat_sleep_%d") % (int(_t * (2.0 if petted else 0.6)) % 2)))


func _avatar() -> void:
	var pose := "idle"
	var frame := 1 if fmod(_t, 4.2) > 4.05 else 0
	if FocusTimer.phase == FocusTimer.Phase.FOCUS and not FocusTimer.paused:
		pose = "type"
		frame = int(_t * 5.0) % 2
	elif FocusTimer.phase == FocusTimer.Phase.REST:
		pose = "rest"
		frame = 1 if fmod(_t, 5.0) > 3.6 else 0
	elif hour >= 1.0 and hour < 5.5:
		pose = "sleep"
		frame = int(_t * 0.7) % 2
	_set_texture(Catalog.sprite("avatar_%s_%d" % [pose, frame], variant))


func _draw() -> void:
	if layer == "floor":
		# soft contact shadow
		var w := _size.x * 0.46
		var points := PackedVector2Array()
		for i in 16:
			var a := TAU * i / 16.0
			points.append(Vector2(cos(a) * w, -1.0 + sin(a) * 2.5))
		draw_colored_polygon(points, Color(0, 0, 0, 0.22))
	if not selected:
		return
	var r := Rect2(_origin - Vector2(2, 2), _size + Vector2(4, 4))
	var colour := Color(1.0, 0.85, 0.5)
	var corner := 4.0
	for p: Vector2 in [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]:
		var sx := 1.0 if p.x == r.position.x else -1.0
		var sy := 1.0 if p.y == r.position.y else -1.0
		draw_line(p, p + Vector2(corner * sx, 0), colour, 1.0)
		draw_line(p, p + Vector2(0, corner * sy), colour, 1.0)


func to_save() -> Dictionary:
	return {"id": item_id, "x": int(position.x), "y": int(position.y), "flip": flipped, "on": is_on, "variant": variant}
