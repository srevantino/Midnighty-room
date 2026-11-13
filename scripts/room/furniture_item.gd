class_name FurnitureItem
extends Node2D
## One placed item. `position` is the anchor: the bottom-centre for things
## that stand ("floor" and "top" layers), the centre for wall items and rugs.

## Set by Room every frame: lamps glow harder as the room gets darker.
static var night_boost := 1.0
static var _light_texture: GradientTexture2D
static var _images: Dictionary = {}

var item_id := ""
var def: Dictionary = {}
var layer := "floor"
var flipped := false
var is_on := true
var selected := false:
	set(value):
		selected = value
		queue_redraw()

var _sprite: Sprite2D
var _light: PointLight2D
var _base_energy := 0.0
var _size := Vector2.ZERO
var _origin := Vector2.ZERO
var _t := 0.0
var _awake_until := 0.0
var _hands: Array[Line2D] = []


func setup(id: String, pos: Vector2, flip: bool = false, on: bool = true) -> void:
	item_id = id
	def = Catalog.get_def(id)
	layer = def.get("layer", "floor")
	flipped = flip
	is_on = on
	position = pos
	_t = randf() * 10.0

	_sprite = Sprite2D.new()
	_sprite.centered = false
	_sprite.texture = Catalog.texture_for(id)
	add_child(_sprite)
	_size = _sprite.texture.get_size()
	_origin = Vector2(-floorf(_size.x / 2.0), -_size.y) if layer in ["floor", "top"] else Vector2(-floorf(_size.x / 2.0), -floorf(_size.y / 2.0))
	_sprite.position = _origin
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

	match def.get("kind", ""):
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
			for width: float in [1.0, 1.0]:
				var hand := Line2D.new()
				hand.width = width
				hand.default_color = Color("2a2438")
				hand.points = PackedVector2Array([Vector2.ZERO, Vector2.ZERO])
				add_child(hand)
				_hands.append(hand)
	_refresh_state()


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
	if def.get("kind", "") == "monitor":
		_sprite.texture = Catalog.sprite("monitor_on" if is_on else "monitor_off")


func bounds() -> Rect2:
	return Rect2(position + _origin, _size)


## True when `point` (room pixels) lands on a non-transparent pixel.
func hit(point: Vector2) -> bool:
	if not bounds().has_point(point):
		return false
	var texture := _sprite.texture
	if not _images.has(texture):
		_images[texture] = texture.get_image()
	var image: Image = _images[texture]
	var local := (point - position - _origin).floor()
	if flipped:
		local.x = _size.x - 1 - local.x
	local = local.clamp(Vector2.ZERO, _size - Vector2.ONE)
	return image.get_pixelv(Vector2i(local)).a > 0.1


func set_flipped(value: bool) -> void:
	flipped = value
	_sprite.flip_h = value
	_place_light()


## Click outside decorate mode. Returns true if the item did something.
func interact() -> bool:
	match def.get("kind", ""):
		"lamp", "monitor":
			is_on = not is_on
			_refresh_state()
			AudioMixer.play_sfx("switch")
			return true
		"cat":
			_awake_until = _t + 4.0
			AudioMixer.play_sfx("purr")
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
	var kind: String = def.get("kind", "")
	if _light and is_on:
		var flicker := 1.0
		if kind == "fire":
			flicker = 0.82 + 0.12 * sin(_t * 9.0) + 0.08 * sin(_t * 23.0 + 1.3)
		elif kind == "candle":
			flicker = 0.9 + 0.07 * sin(_t * 11.0) + 0.04 * sin(_t * 29.0)
		_light.energy = _base_energy * flicker * night_boost
	match kind:
		"cat":
			var frame := int(_t * (2.0 if _t < _awake_until else 0.6)) % 2
			_sprite.texture = Catalog.sprite(("cat_awake_%d" if _t < _awake_until else "cat_sleep_%d") % frame)
		"clock":
			var now := Time.get_time_dict_from_system()
			var centre := _origin + _size / 2.0
			var minute_angle := float(now["minute"]) / 60.0 * TAU - PI / 2.0
			var hour_angle := (float(now["hour"] % 12) + float(now["minute"]) / 60.0) / 12.0 * TAU - PI / 2.0
			_hands[0].points = PackedVector2Array([centre, centre + Vector2.from_angle(minute_angle) * 4.5])
			_hands[1].points = PackedVector2Array([centre, centre + Vector2.from_angle(hour_angle) * 3.0])


func _draw() -> void:
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
	return {"id": item_id, "x": int(position.x), "y": int(position.y), "flip": flipped, "on": is_on}
