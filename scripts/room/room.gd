class_name Room
extends Node2D
## The room itself, rendered at 320x180 inside a SubViewport and scaled up 4x.
## Draws the walls and floor, owns every FurnitureItem, runs the day/night
## cycle and handles pointer input passed down from Main.

signal selection_changed(item: FurnitureItem)
signal layout_changed
signal dragging_changed(active: bool)

const SIZE := Vector2i(320, 180)
const FLOOR_Y := 120
const MAX_ITEMS := 90
const LAYER_ORDER := ["wall", "rug", "floor", "top"]
const SNAP_DISTANCE := 6.0

## hour, sky top, sky bottom, room tint, night amount
const SKY_KEYS := [
	[0.0, Color("0b0d2a"), Color("1c2152"), Color(0.40, 0.40, 0.60), 1.0],
	[5.0, Color("141a45"), Color("3b3470"), Color(0.43, 0.42, 0.61), 1.0],
	[6.5, Color("4a4a8f"), Color("f2a38a"), Color(0.74, 0.65, 0.68), 0.45],
	[8.0, Color("6fb1e8"), Color("cfe8f5"), Color(0.95, 0.93, 0.90), 0.0],
	[12.0, Color("58a6e8"), Color("bfe3f7"), Color(1.0, 1.0, 1.0), 0.0],
	[17.0, Color("5b8fd6"), Color("f5d5a0"), Color(1.0, 0.93, 0.85), 0.05],
	[18.5, Color("3d3f8a"), Color("f08c5a"), Color(0.84, 0.65, 0.60), 0.5],
	[20.0, Color("151a45"), Color("3a2f6b"), Color(0.48, 0.45, 0.63), 0.95],
	[24.0, Color("0b0d2a"), Color("1c2152"), Color(0.40, 0.40, 0.60), 1.0],
]

var decorate_mode := false:
	set(value):
		decorate_mode = value
		FurnitureItem.frozen = value
		if not value:
			select(null)
var selected: FurnitureItem

## Read by sky.gd
var tod := 22.0
var night := 1.0
var rain := 0.0
var sky_top := Color.BLACK
var sky_bottom := Color.BLACK
## The see-through part of the window, in room pixels.
var pane := Rect2(119, 25, 82, 54)
## Set to an hour (0-24) to pin the clock, e.g. for screenshots. -1 = off.
var time_override := -1.0

var _layers: Dictionary = {}
var _modulate: CanvasModulate
var _window_light: PointLight2D
var _window: Sprite2D
var _sky: Node2D
var _style := "panel"
var _dragging := false
var _drag_offset := Vector2.ZERO
var _moved := false
var _riders: Array[FurnitureItem] = []
var _hovered: FurnitureItem


func _ready() -> void:
	_modulate = CanvasModulate.new()
	add_child(_modulate)

	var sky_layer := CanvasLayer.new()
	sky_layer.layer = -1
	add_child(sky_layer)
	_sky = Node2D.new()
	_sky.set_script(load("res://scripts/room/sky.gd"))
	_sky.set("room", self)
	sky_layer.add_child(_sky)

	_window = Sprite2D.new()
	_window.centered = false
	add_child(_window)

	for layer_name: String in LAYER_ORDER:
		var node := Node2D.new()
		node.name = layer_name
		node.y_sort_enabled = layer_name in ["floor", "top"]
		add_child(node)
		_layers[layer_name] = node

	_window_light = PointLight2D.new()
	_window_light.texture = FurnitureItem.get_light_texture()
	_window_light.texture_scale = 2.2
	add_child(_window_light)

	var dust := CPUParticles2D.new()
	dust.position = Vector2(160, 80)
	dust.amount = 16
	dust.lifetime = 9.0
	dust.preprocess = 9.0
	dust.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	dust.emission_rect_extents = Vector2(150, 60)
	dust.direction = Vector2(1, 0.3)
	dust.spread = 180.0
	dust.gravity = Vector2(0, 1.5)
	dust.initial_velocity_min = 0.5
	dust.initial_velocity_max = 2.5
	dust.color = Color(1, 0.95, 0.8, 0.3)
	add_child(dust)

	GameState.look_changed.connect(queue_redraw)
	GameState.room_changed.connect(reload)
	reload()
	_update_time()


## Rebuilds everything from the save: called at start, when switching rooms,
## loading a layout preset and after a reset.
func reload() -> void:
	select(null)
	_hovered = null
	var config := GameState.room_config()
	_style = config["style"]
	pane = config["pane"]
	_window.texture = Catalog.sprite(config["window"])
	_window.position = config["window_pos"]
	_window_light.position = pane.get_center() + Vector2(0, 30)
	_sky.call("set_rect", pane.grow(2))
	for item in all_items():
		item.get_parent().remove_child(item)
		item.queue_free()
	for entry: Dictionary in GameState.room()["placed"]:
		if Catalog.ITEMS.has(entry.get("id", "")):
			_add_item(entry["id"], Vector2(entry["x"], entry["y"]), entry.get("flip", false), entry.get("on", true), entry.get("variant", ""))
	queue_redraw()


func _add_item(id: String, pos: Vector2, flip: bool = false, on: bool = true, variant: String = "") -> FurnitureItem:
	var item := FurnitureItem.new()
	item.setup(id, pos, flip, on, variant)
	(_layers[item.layer] as Node2D).add_child(item)
	return item


func all_items() -> Array[FurnitureItem]:
	var out: Array[FurnitureItem] = []
	for layer_name: String in LAYER_ORDER:
		for child in (_layers[layer_name] as Node2D).get_children():
			if child is FurnitureItem and not child.is_queued_for_deletion():
				out.append(child)
	return out


# ------------------------------------------------------------- time of day
func _process(_delta: float) -> void:
	_update_time()


func _update_time() -> void:
	if time_override >= 0.0:
		tod = time_override
	else:
		match str(GameState.setting("time_mode")):
			"real":
				var now := Time.get_time_dict_from_system()
				tod = float(now["hour"]) + float(now["minute"]) / 60.0 + float(now["second"]) / 3600.0
			"cycle":
				tod = fmod(20.0 + Time.get_ticks_msec() / 1000.0 / 720.0 * 24.0, 24.0)
			"sunset":
				tod = 18.4
			"day":
				tod = 13.0
			_:
				tod = 23.5
	var a: Array = SKY_KEYS[0]
	var b: Array = SKY_KEYS[1]
	for i in SKY_KEYS.size() - 1:
		if tod >= float(SKY_KEYS[i][0]) and tod <= float(SKY_KEYS[i + 1][0]):
			a = SKY_KEYS[i]
			b = SKY_KEYS[i + 1]
			break
	var t := inverse_lerp(float(a[0]), float(b[0]), tod)
	rain = lerpf(rain, AudioMixer.layer_volume("rain"), 0.05)
	var overcast := Color(0.34, 0.37, 0.45)
	sky_top = (a[1] as Color).lerp(b[1], t)
	sky_bottom = (a[2] as Color).lerp(b[2], t)
	sky_top = sky_top.lerp(overcast * (0.35 + 0.65 * sky_top.v), rain * 0.55)
	sky_bottom = sky_bottom.lerp(overcast * (0.45 + 0.55 * sky_bottom.v), rain * 0.55)
	night = lerpf(float(a[4]), float(b[4]), t)
	var tint: Color = (a[3] as Color).lerp(b[3], t)
	_modulate.color = tint.lerp(tint * Color(0.9, 0.92, 1.0), rain * 0.5)
	FurnitureItem.night_boost = lerpf(0.25, 1.0, night)
	FurnitureItem.hour = tod
	_window_light.color = Color(1.0, 0.95, 0.85).lerp(Color(0.55, 0.65, 1.0), night)
	_window_light.energy = lerpf(0.10, 0.38, night)


# ------------------------------------------------------------------ drawing
func _draw() -> void:
	var look := GameState.room()
	var wall: Dictionary = Catalog.WALLS[clampi(int(look["wall"]), 0, Catalog.WALLS.size() - 1)]
	var flooring: Dictionary = Catalog.FLOORS[clampi(int(look["floor"]), 0, Catalog.FLOORS.size() - 1)]
	var base: Color = wall["base"]
	var accent: Color = wall["accent"]
	# wall, leaving a hole for the window pane
	for r: Rect2 in _around_pane(Rect2(0, 0, SIZE.x, FLOOR_Y)):
		draw_rect(r, base)
	match _style:
		"brick":
			for y in range(4, 96, 6):
				_wall_rect(Rect2(0, y, SIZE.x, 1), accent.darkened(0.25))
				for x in range((y / 6 % 2) * 8, SIZE.x, 16):
					_wall_rect(Rect2(x, y - 5, 1, 5), accent.darkened(0.25))
		"attic":
			for y in range(10, 96, 12):
				_wall_rect(Rect2(0, y, SIZE.x, 1), accent.darkened(0.2))
				_wall_rect(Rect2(0, y + 1, SIZE.x, 1), base.lightened(0.06))
		_:
			for x in range(8, SIZE.x, 16):
				_wall_rect(Rect2(x, 0, 1, 96), accent)
	# wainscot and baseboard
	draw_rect(Rect2(0, 96, SIZE.x, FLOOR_Y - 96), base.darkened(0.14))
	draw_rect(Rect2(0, 96, SIZE.x, 1), base.lightened(0.12))
	draw_rect(Rect2(0, 97, SIZE.x, 1), base.darkened(0.3))
	draw_rect(Rect2(0, FLOOR_Y - 4, SIZE.x, 4), Color("4a2f2a"))
	draw_rect(Rect2(0, FLOOR_Y - 4, SIZE.x, 1), Color("6b4636"))
	draw_rect(Rect2(0, 0, SIZE.x, 3), base.darkened(0.25))
	if _style == "attic":
		# sloped ceiling with beams
		var roof := Color("3a2620")
		draw_colored_polygon(PackedVector2Array([Vector2(0, 0), Vector2(96, 0), Vector2(0, 58)]), roof)
		draw_colored_polygon(PackedVector2Array([Vector2(SIZE.x, 0), Vector2(SIZE.x - 96, 0), Vector2(SIZE.x, 58)]), roof)
		draw_line(Vector2(98, 0), Vector2(0, 60), Color("6b4636"), 3.0)
		draw_line(Vector2(SIZE.x - 98, 0), Vector2(SIZE.x, 60), Color("6b4636"), 3.0)
		draw_rect(Rect2(96, 0, SIZE.x - 192, 4), Color("6b4636"))
	# floor
	var line: Color = flooring["line"]
	var light: Color = flooring["light"]
	draw_rect(Rect2(0, FLOOR_Y, SIZE.x, SIZE.y - FLOOR_Y), flooring["base"])
	draw_rect(Rect2(0, FLOOR_Y, SIZE.x, 2), (flooring["base"] as Color).darkened(0.3))
	for y in range(FLOOR_Y + 10, SIZE.y, 12):
		draw_rect(Rect2(0, y, SIZE.x, 1), line)
		draw_rect(Rect2(0, y + 1, SIZE.x, 1), light)
	var row := 0
	for y in range(FLOOR_Y, SIZE.y, 12):
		for x in range(20 + (row % 3) * 37, SIZE.x, 96):
			draw_rect(Rect2(x, y + 2, 1, 9), line)
		row += 1


## The parts of `r` that are not over the window pane.
func _around_pane(r: Rect2) -> Array[Rect2]:
	var hole := r.intersection(pane)
	if hole.size.x <= 0 or hole.size.y <= 0:
		return [r]
	var parts: Array[Rect2] = [
		Rect2(r.position.x, r.position.y, r.size.x, hole.position.y - r.position.y),
		Rect2(r.position.x, hole.end.y, r.size.x, r.end.y - hole.end.y),
		Rect2(r.position.x, hole.position.y, hole.position.x - r.position.x, hole.size.y),
		Rect2(hole.end.x, hole.position.y, r.end.x - hole.end.x, hole.size.y),
	]
	return parts.filter(func(p: Rect2) -> bool: return p.size.x > 0 and p.size.y > 0)


func _wall_rect(r: Rect2, colour: Color) -> void:
	for part in _around_pane(r):
		draw_rect(part, colour)


# ----------------------------------------------------------------- surfaces
## Every ledge a small item can sit on: furniture tops plus the window sill.
func surfaces(excluding: FurnitureItem = null) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for item in all_items():
		if item != excluding and not item.surface().is_empty():
			out.append(item.surface())
	var frame_size := _window.texture.get_size()
	out.append({"y": _window.position.y + frame_size.y - 6.0, "x0": _window.position.x + 2.0, "x1": _window.position.x + frame_size.x - 2.0})
	return out


func _snap_to_surface(pos: Vector2) -> Vector2:
	var best := pos
	var best_gap := SNAP_DISTANCE
	for s in surfaces():
		var gap := absf(pos.y - float(s["y"]))
		if gap <= best_gap and pos.x >= float(s["x0"]) and pos.x <= float(s["x1"]):
			best_gap = gap
			best = Vector2(pos.x, float(s["y"]))
	return best


func _riders_of(item: FurnitureItem) -> Array[FurnitureItem]:
	var out: Array[FurnitureItem] = []
	var s := item.surface()
	if s.is_empty():
		return out
	for child in (_layers["top"] as Node2D).get_children():
		var top := child as FurnitureItem
		if top and absf(top.position.y - float(s["y"])) <= 1.0 and top.position.x >= float(s["x0"]) and top.position.x <= float(s["x1"]):
			out.append(top)
	return out


# -------------------------------------------------------------------- input
func item_at(point: Vector2, loose: bool = false) -> FurnitureItem:
	for layer_name: String in ["top", "floor", "rug", "wall"]:
		var items := (_layers[layer_name] as Node2D).get_children()
		items.sort_custom(func(x: Node2D, y: Node2D) -> bool: return x.position.y > y.position.y)
		for child in items:
			var item := child as FurnitureItem
			if item and (item.bounds().has_point(point) if loose else item.hit(point)):
				return item
	return null


func pointer_down(point: Vector2) -> void:
	var item := item_at(point)
	if decorate_mode:
		if item == null:
			item = item_at(point, true)
		select(item)
		if item:
			_dragging = true
			_moved = false
			_drag_offset = item.position - point
			_riders = _riders_of(item)
			dragging_changed.emit(true)
	elif item:
		if item.interact():
			_save_layout()


## Returns true when the pointer is over something clickable (for the cursor).
func pointer_move(point: Vector2) -> bool:
	if _dragging and selected:
		var target := _clamp_for(selected, (point + _drag_offset).round())
		if selected.layer == "top":
			target = _snap_to_surface(target)
		if target != selected.position:
			var delta := target - selected.position
			selected.position = target
			for rider in _riders:
				rider.position += delta
			_moved = true
		return true
	var over := item_at(point)
	var clickable := over != null and (decorate_mode or over.is_interactive())
	var hover_target := over if clickable and not decorate_mode else null
	if hover_target != _hovered:
		if _hovered and is_instance_valid(_hovered):
			_hovered.hovered = false
		_hovered = hover_target
		if _hovered:
			_hovered.hovered = true
	return clickable


func pointer_up(_point: Vector2) -> void:
	if _dragging:
		_dragging = false
		_riders.clear()
		dragging_changed.emit(false)
		if _moved:
			AudioMixer.play_sfx("place")
			GameState.bump("moves")
			_save_layout()


## Moves the selected item by whole pixels (arrow keys).
func nudge_selected(delta: Vector2) -> void:
	if selected:
		var riders := _riders_of(selected)
		var target := _clamp_for(selected, selected.position + delta)
		var moved := target - selected.position
		selected.position = target
		for rider in riders:
			rider.position += moved
		_save_layout()


func _clamp_for(item: FurnitureItem, pos: Vector2) -> Vector2:
	match item.layer:
		"wall":
			return pos.clamp(Vector2(6, 6), Vector2(SIZE.x - 6, FLOOR_Y - 14))
		"rug":
			return pos.clamp(Vector2(16, FLOOR_Y + 10), Vector2(SIZE.x - 16, SIZE.y - 6))
		"top":
			return pos.clamp(Vector2(4, 30), Vector2(SIZE.x - 4, SIZE.y - 2))
	return pos.clamp(Vector2(6, FLOOR_Y + 4), Vector2(SIZE.x - 6, SIZE.y - 2))


func select(item: FurnitureItem) -> void:
	if selected and is_instance_valid(selected):
		selected.selected = false
	selected = item
	if selected:
		selected.selected = true
	selection_changed.emit(selected)


# ------------------------------------------------------------- decorating
func spawn(id: String) -> bool:
	if all_items().size() >= MAX_ITEMS:
		return false
	var layer: String = Catalog.get_def(id).get("layer", "floor")
	var pos := Vector2(160, 150)
	match layer:
		"wall":
			pos = Vector2(160, 100)
		"top":
			pos = Vector2(160, 140)
	pos += Vector2(randi_range(-12, 12), randi_range(-4, 4))
	var item := _add_item(id, pos)
	item.position = _clamp_for(item, item.position)
	select(item)
	AudioMixer.play_sfx("place")
	GameState.bump("moves")
	_save_layout()
	return true


func flip_selected() -> void:
	if selected:
		selected.set_flipped(not selected.flipped)
		_save_layout()


func set_selected_variant(variant: String) -> void:
	if selected:
		selected.set_variant(variant)
		_save_layout()


func remove_selected() -> void:
	if selected:
		var item := selected
		select(null)
		item.get_parent().remove_child(item)
		item.queue_free()
		_save_layout()


func _save_layout() -> void:
	var out: Array = []
	for item in all_items():
		out.append(item.to_save())
	GameState.set_placed(out)
	SteamService.on_items_placed(out.size())
	layout_changed.emit()
