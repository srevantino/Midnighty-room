extends Node2D
## The view through the window: sky gradient, sun, moon, stars, clouds, a
## skyline with lit windows, and rain. Lives on its own CanvasLayer behind the
## room so the room's night tint and lamp light do not affect it.

const RECT := Rect2(117, 23, 86, 58)

var room: Room
var _stars: Array[Vector3] = []      # x, y, twinkle phase
var _buildings: Array[Dictionary] = []
var _clouds: Array[Vector3] = []     # x, y, width
var _rain: Array[Vector2] = []       # x, phase
var _time := 0.0


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4042
	for i in 34:
		_stars.append(Vector3(rng.randf_range(0, RECT.size.x), rng.randf_range(0, RECT.size.y * 0.7), rng.randf_range(0, TAU)))
	var x := -2.0
	while x < RECT.size.x:
		var w := float(rng.randi_range(6, 13))
		var h := float(rng.randi_range(8, 26))
		var lit: Array[bool] = []
		for j in 40:
			lit.append(rng.randf() < 0.42)
		_buildings.append({"x": x, "w": w, "h": h, "lit": lit, "shade": rng.randf_range(0.0, 0.12)})
		x += w + rng.randi_range(0, 2)
	for i in 4:
		_clouds.append(Vector3(rng.randf_range(0, RECT.size.x), rng.randf_range(4, 22), rng.randf_range(14, 26)))
	for i in 46:
		_rain.append(Vector2(rng.randf_range(-6, RECT.size.x), rng.randf()))


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	if room == null:
		return
	var o := RECT.position
	var top := room.sky_top
	var bottom := room.sky_bottom
	var night := room.night
	var rows := int(RECT.size.y)
	for i in rows:
		draw_rect(Rect2(o.x, o.y + i, RECT.size.x, 1), top.lerp(bottom, float(i) / rows))

	# stars
	if night > 0.05:
		for s in _stars:
			var a := night * (0.55 + 0.45 * sin(_time * 1.3 + s.z)) * (1.0 - room.rain * 0.8)
			draw_rect(Rect2(o.x + floorf(s.x), o.y + floorf(s.y), 1, 1), Color(1, 1, 0.92, a))

	# sun and moon ride an arc from left to right
	var sun_p := (room.tod - 6.0) / 12.0
	if sun_p > -0.05 and sun_p < 1.05:
		var sp := o + Vector2(lerpf(4, RECT.size.x - 4, sun_p), RECT.size.y - 6 - sin(sun_p * PI) * (RECT.size.y - 14))
		draw_circle(sp, 6.5, Color(1, 0.9, 0.6, 0.25))
		draw_circle(sp, 4.5, Color(1, 0.93, 0.7))
	var moon_p := fposmod(room.tod - 18.5, 24.0) / 11.0
	if moon_p < 1.05:
		var mp := o + Vector2(lerpf(6, RECT.size.x - 6, moon_p), RECT.size.y - 10 - sin(moon_p * PI) * (RECT.size.y - 20))
		var sky_here := top.lerp(bottom, clampf((mp.y - o.y) / RECT.size.y, 0, 1))
		draw_circle(mp, 7.5, Color(0.8, 0.85, 1.0, 0.10 * night))
		draw_circle(mp, 5.0, Color(1.0, 0.96, 0.82, clampf(night + 0.25, 0, 1)))
		draw_circle(mp + Vector2(2.5, -1.5), 4.2, sky_here)

	# clouds
	var cloud_col := Color(1, 1, 1, 0.5).lerp(Color(0.55, 0.55, 0.75, 0.35), night)
	cloud_col = cloud_col.lerp(Color(0.6, 0.62, 0.7, 0.7), room.rain)
	for c in _clouds:
		var cx := fposmod(c.x + _time * 0.8, RECT.size.x + 40.0) - 20.0
		for k in 3:
			draw_rect(Rect2(o.x + floorf(cx + k * c.z * 0.22), o.y + c.y - k % 2 * 2, floorf(c.z * 0.55), 3 + k % 2 * 2), cloud_col)

	# skyline
	var base_col := Color("0e1230").lerp(bottom.darkened(0.45), 1.0 - night)
	for b in _buildings:
		var bx: float = o.x + b["x"]
		var by: float = o.y + RECT.size.y - b["h"]
		draw_rect(Rect2(bx, by, b["w"], b["h"]), base_col.lightened(b["shade"]))
		var idx := 0
		var wy := by + 2
		while wy < o.y + RECT.size.y - 2:
			var wx := bx + 1
			while wx < bx + float(b["w"]) - 2:
				var on: bool = b["lit"][idx % 40]
				idx += 1
				if on and night > 0.2:
					var flick := 0.75 + 0.25 * sin(_time * 0.3 + idx * 1.7)
					draw_rect(Rect2(wx, wy, 2, 2), Color(1.0, 0.82, 0.45, night * flick))
				elif night <= 0.2:
					draw_rect(Rect2(wx, wy, 2, 2), base_col.lightened(0.18))
				wx += 4
			wy += 4

	# rain
	if room.rain > 0.02:
		var count := int(_rain.size() * clampf(room.rain * 1.4, 0.15, 1.0))
		var col := Color(0.8, 0.88, 1.0, 0.25 + 0.35 * room.rain)
		for i in count:
			var r := _rain[i]
			var p := fposmod(r.y + _time * (1.5 + (i % 5) * 0.12), 1.0)
			var a := o + Vector2(r.x + p * 8.0, p * (RECT.size.y + 6) - 4)
			draw_line(a, a + Vector2(1.5, 5), col, 1.0)

	# glass sheen
	draw_line(o + Vector2(10, RECT.size.y), o + Vector2(34, 0), Color(1, 1, 1, 0.05), 3.0)
	draw_line(o + Vector2(56, RECT.size.y), o + Vector2(74, 0), Color(1, 1, 1, 0.04), 2.0)
