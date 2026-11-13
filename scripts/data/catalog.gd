class_name Catalog
## Every placeable item in the game. Add an entry here plus a PNG in
## assets/sprites/ and it shows up in the Decorate panel automatically.
##
## layer:  "wall" (hangs on the wall), "rug" (flat on the floor),
##         "floor" (stands on the floor, depth-sorted), "top" (small things
##         that sit on furniture, always drawn in front of it)
## price:  cost in moonlight; 0 means owned from the start
## kind:   optional behaviour, see scripts/room/furniture_item.gd
## light:  optional glow: offset from the sprite's top-left corner, colour,
##         energy and size

const SPRITE_DIR := "res://assets/sprites/"

const ITEMS := {
	# --- floor furniture
	"bed": {"name": "Bed", "layer": "floor", "price": 0},
	"desk": {"name": "Desk", "layer": "floor", "price": 0},
	"chair": {"name": "Desk chair", "layer": "floor", "price": 0},
	"plant_big": {"name": "Monstera", "layer": "floor", "price": 0},
	"side_table": {"name": "Side table", "layer": "floor", "price": 15},
	"floor_lamp": {"name": "Floor lamp", "layer": "floor", "price": 25, "kind": "lamp",
		"light": {"offset": Vector2(10, 12), "color": Color(1.0, 0.78, 0.45), "energy": 1.5, "size": 1.5}},
	"beanbag": {"name": "Beanbag", "layer": "floor", "price": 30},
	"bookshelf": {"name": "Bookshelf", "layer": "floor", "price": 40},
	"guitar": {"name": "Guitar", "layer": "floor", "price": 45},
	"sofa": {"name": "Sofa", "layer": "floor", "price": 60},
	"fireplace": {"name": "Fireplace", "layer": "floor", "price": 90, "kind": "fire",
		"light": {"offset": Vector2(27, 38), "color": Color(1.0, 0.55, 0.25), "energy": 1.2, "size": 1.3}},
	"cat": {"name": "Miso the cat", "layer": "floor", "price": 0, "kind": "cat", "sprite": "cat_sleep_0"},
	# --- small things
	"desk_lamp": {"name": "Desk lamp", "layer": "top", "price": 0, "kind": "lamp",
		"light": {"offset": Vector2(6, 9), "color": Color(1.0, 0.8, 0.5), "energy": 1.5, "size": 1.0}},
	"monitor": {"name": "Monitor", "layer": "top", "price": 0, "kind": "monitor", "sprite": "monitor_on",
		"light": {"offset": Vector2(13, 9), "color": Color(0.5, 0.7, 1.0), "energy": 0.6, "size": 0.8}},
	"mug": {"name": "Hot cocoa", "layer": "top", "price": 0, "kind": "mug"},
	"books_stack": {"name": "Book stack", "layer": "top", "price": 0},
	"candle": {"name": "Candle", "layer": "top", "price": 10, "kind": "candle",
		"light": {"offset": Vector2(4, 3), "color": Color(1.0, 0.7, 0.35), "energy": 0.8, "size": 0.6}},
	"succulent": {"name": "Succulent", "layer": "top", "price": 10},
	"lava_lamp": {"name": "Lava lamp", "layer": "top", "price": 30, "kind": "lamp",
		"light": {"offset": Vector2(5, 8), "color": Color(0.95, 0.45, 0.85), "energy": 0.8, "size": 0.7}},
	"laptop": {"name": "Laptop", "layer": "top", "price": 35,
		"light": {"offset": Vector2(11, 6), "color": Color(0.5, 0.7, 1.0), "energy": 0.4, "size": 0.5}},
	"record_player": {"name": "Record player", "layer": "top", "price": 50, "kind": "player"},
	# --- wall
	"poster_moon": {"name": "Moon poster", "layer": "wall", "price": 0},
	"string_lights": {"name": "String lights", "layer": "wall", "price": 0, "kind": "lamp",
		"light": {"offset": Vector2(50, 9), "color": Color(1.0, 0.82, 0.55), "energy": 1.0, "size": 1.8}},
	"poster_wave": {"name": "Wave poster", "layer": "wall", "price": 15},
	"frame_cat": {"name": "Cat portrait", "layer": "wall", "price": 15},
	"wall_clock": {"name": "Wall clock", "layer": "wall", "price": 15, "kind": "clock"},
	"wall_shelf": {"name": "Wall shelf", "layer": "wall", "price": 25},
	"curtains": {"name": "Curtains", "layer": "wall", "price": 35},
	"neon_moon": {"name": "Neon moon", "layer": "wall", "price": 55, "kind": "lamp",
		"light": {"offset": Vector2(13, 13), "color": Color(0.8, 0.55, 1.0), "energy": 0.9, "size": 0.9}},
	# --- rugs
	"rug_round": {"name": "Round rug", "layer": "rug", "price": 0},
	"rug_stripe": {"name": "Striped rug", "layer": "rug", "price": 20},
}

## Layout a new player starts with: {id, x, y} in room pixels (320x180).
const STARTER_ROOM := [
	{"id": "rug_round", "x": 170, "y": 150},
	{"id": "poster_moon", "x": 74, "y": 52},
	{"id": "string_lights", "x": 160, "y": 12},
	{"id": "bed", "x": 250, "y": 146},
	{"id": "desk", "x": 62, "y": 142},
	{"id": "chair", "x": 86, "y": 150},
	{"id": "plant_big", "x": 304, "y": 142},
	{"id": "cat", "x": 168, "y": 152},
	{"id": "monitor", "x": 56, "y": 113},
	{"id": "desk_lamp", "x": 38, "y": 113},
	{"id": "mug", "x": 78, "y": 113},
	{"id": "books_stack", "x": 112, "y": 148},
]

const WALLS := [
	{"name": "Dusk violet", "base": Color("3d3566"), "accent": Color("453c72")},
	{"name": "Midnight blue", "base": Color("2a3460"), "accent": Color("313d6e")},
	{"name": "Rosewood", "base": Color("6b4058"), "accent": Color("774963")},
	{"name": "Sage", "base": Color("4c6658"), "accent": Color("567262")},
	{"name": "Warm sand", "base": Color("8a7460"), "accent": Color("957f6a")},
]

const FLOORS := [
	{"name": "Warm oak", "base": Color("8c6047"), "line": Color("6b4636"), "light": Color("9d6e52")},
	{"name": "Dark walnut", "base": Color("54382f"), "line": Color("3f2924"), "light": Color("614238")},
	{"name": "Grey carpet", "base": Color("5e5874"), "line": Color("544e69"), "light": Color("67617d")},
	{"name": "Honey pine", "base": Color("b08460"), "line": Color("8c6047"), "light": Color("be9470")},
]


static func get_def(id: String) -> Dictionary:
	return ITEMS.get(id, {})


static func texture_for(id: String) -> Texture2D:
	var def: Dictionary = ITEMS.get(id, {})
	var file: String = def.get("sprite", id)
	return load(SPRITE_DIR + file + ".png") as Texture2D


static func sprite(file: String) -> Texture2D:
	return load(SPRITE_DIR + file + ".png") as Texture2D
