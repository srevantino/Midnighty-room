class_name Catalog
## Every placeable item, room, wall and floor. Add an entry here plus a PNG in
## assets/sprites/ and it shows up in the Decorate panel automatically.
##
## Item keys
##   layer    "wall" (hangs on the wall), "rug" (flat on the floor), "floor"
##            (stands on the floor, depth-sorted), "top" (small things that sit
##            on furniture and snap to surfaces)
##   price    cost in moonlight; 0 means owned from the start
##   level    player level needed before it can be bought (default 1)
##   set      theme used by the Decorate filter
##   kind     optional behaviour, see scripts/room/furniture_item.gd
##   light    optional glow: offset from the sprite's top-left, colour, energy, size
##   frames   optional animation: sprite file names, played at `fps`
##   variants optional recolours; "x" loads <sprite>__x.png, "" is the base sprite
##   surface  optional shelf for "top" items: row `y` and columns x0..x1 in sprite pixels

const SPRITE_DIR := "res://assets/sprites/"
const SETS := ["Basics", "Study nook", "Night glow", "Plant corner", "Music corner", "Play time", "Lounge", "Wall art"]

const WARM := Color(1.0, 0.78, 0.45)

const ITEMS := {
	# ------------------------------------------------------------ floor
	"avatar": {"name": "You", "layer": "floor", "price": 0, "set": "Basics", "kind": "avatar", "sprite": "avatar_idle_0",
		"variants": ["", "teal", "rose", "amber"]},
	"bed": {"name": "Bed", "layer": "floor", "price": 0, "set": "Basics", "variants": ["", "teal", "rose", "amber"]},
	"desk": {"name": "Desk", "layer": "floor", "price": 0, "set": "Basics", "surface": {"y": 8, "x0": 2, "x1": 59}},
	"chair": {"name": "Desk chair", "layer": "floor", "price": 0, "set": "Basics", "variants": ["", "teal", "rose", "slate"]},
	"plant_big": {"name": "Monstera", "layer": "floor", "price": 0, "set": "Plant corner", "frames": ["plant_big", "plant_big_1"], "fps": 0.5},
	"cat": {"name": "Miso the cat", "layer": "floor", "price": 0, "set": "Basics", "kind": "cat", "sprite": "cat_sleep_0"},
	"side_table": {"name": "Side table", "layer": "floor", "price": 15, "set": "Basics", "surface": {"y": 3, "x0": 2, "x1": 19}},
	"nightstand": {"name": "Nightstand", "layer": "floor", "price": 20, "set": "Basics", "surface": {"y": 1, "x0": 2, "x1": 21}},
	"floor_lamp": {"name": "Floor lamp", "layer": "floor", "price": 25, "set": "Night glow", "kind": "lamp",
		"light": {"offset": Vector2(10, 12), "color": WARM, "energy": 1.5, "size": 1.5}},
	"cactus": {"name": "Cactus", "layer": "floor", "price": 20, "set": "Plant corner"},
	"floor_cushion": {"name": "Floor cushion", "layer": "floor", "price": 20, "set": "Lounge", "variants": ["", "rose", "lavender", "amber"]},
	"beanbag": {"name": "Beanbag", "layer": "floor", "price": 30, "set": "Lounge", "variants": ["", "teal", "lavender", "amber"]},
	"lantern": {"name": "Lantern", "layer": "floor", "price": 30, "set": "Night glow", "kind": "candle",
		"light": {"offset": Vector2(7, 12), "color": Color(1.0, 0.7, 0.35), "energy": 1.0, "size": 0.9}},
	"snake_plant": {"name": "Snake plant", "layer": "floor", "price": 30, "level": 2, "set": "Plant corner", "frames": ["snake_plant", "snake_plant_1"], "fps": 0.4},
	"bookshelf_small": {"name": "Low bookshelf", "layer": "floor", "price": 30, "level": 2, "set": "Study nook", "surface": {"y": 1, "x0": 2, "x1": 29}},
	"coffee_table": {"name": "Coffee table", "layer": "floor", "price": 35, "level": 2, "set": "Lounge", "surface": {"y": 3, "x0": 2, "x1": 43}},
	"bookshelf": {"name": "Bookshelf", "layer": "floor", "price": 40, "level": 2, "set": "Study nook", "surface": {"y": 1, "x0": 2, "x1": 35}},
	"dresser": {"name": "Dresser", "layer": "floor", "price": 40, "level": 2, "set": "Basics", "surface": {"y": 1, "x0": 2, "x1": 41}},
	"guitar": {"name": "Guitar", "layer": "floor", "price": 45, "level": 3, "set": "Music corner"},
	"floor_mirror": {"name": "Standing mirror", "layer": "floor", "price": 45, "level": 3, "set": "Basics"},
	"armchair": {"name": "Armchair", "layer": "floor", "price": 50, "level": 3, "set": "Lounge", "variants": ["", "teal", "rose", "lavender"]},
	"easel": {"name": "Easel", "layer": "floor", "price": 50, "level": 3, "set": "Study nook"},
	"cat_tree": {"name": "Cat tree", "layer": "floor", "price": 55, "level": 3, "set": "Play time", "variants": ["", "teal", "rose"]},
	"sofa": {"name": "Sofa", "layer": "floor", "price": 60, "level": 4, "set": "Lounge", "variants": ["", "lavender", "rose", "slate"]},
	"mini_fridge": {"name": "Mini fridge", "layer": "floor", "price": 60, "level": 4, "set": "Lounge", "surface": {"y": 1, "x0": 2, "x1": 23}},
	"wardrobe": {"name": "Wardrobe", "layer": "floor", "price": 65, "level": 4, "set": "Basics"},
	"keyboard": {"name": "Keyboard", "layer": "floor", "price": 70, "level": 4, "set": "Music corner"},
	"telescope": {"name": "Telescope", "layer": "floor", "price": 75, "level": 5, "set": "Night glow"},
	"tv_stand": {"name": "TV", "layer": "floor", "price": 80, "level": 5, "set": "Lounge", "kind": "lamp",
		"light": {"offset": Vector2(25, 12), "color": Color(0.55, 0.7, 1.0), "energy": 0.8, "size": 1.1}},
	"aquarium": {"name": "Aquarium", "layer": "floor", "price": 90, "level": 5, "set": "Plant corner", "frames": ["aquarium", "aquarium_1"], "fps": 1.0,
		"light": {"offset": Vector2(20, 12), "color": Color(0.45, 0.8, 1.0), "energy": 0.7, "size": 0.9}},
	"fireplace": {"name": "Fireplace", "layer": "floor", "price": 90, "level": 6, "set": "Night glow", "kind": "fire",
		"frames": ["fireplace", "fireplace_1"], "fps": 5.0, "surface": {"y": 1, "x0": 2, "x1": 51},
		"light": {"offset": Vector2(27, 38), "color": Color(1.0, 0.55, 0.25), "energy": 1.4, "size": 1.3}},
	"arcade": {"name": "Arcade cabinet", "layer": "floor", "price": 120, "level": 7, "set": "Play time", "kind": "lamp",
		"light": {"offset": Vector2(15, 18), "color": Color(0.6, 0.5, 1.0), "energy": 0.8, "size": 0.9}},
	# ------------------------------------------------------------ small things
	"desk_lamp": {"name": "Desk lamp", "layer": "top", "price": 0, "set": "Study nook", "kind": "lamp",
		"light": {"offset": Vector2(6, 9), "color": Color(1.0, 0.8, 0.5), "energy": 1.5, "size": 1.0}},
	"monitor": {"name": "Monitor", "layer": "top", "price": 0, "set": "Study nook", "kind": "monitor", "sprite": "monitor_on",
		"frames": ["monitor_on", "monitor_on_1"], "fps": 1.5,
		"light": {"offset": Vector2(13, 9), "color": Color(0.5, 0.7, 1.0), "energy": 0.6, "size": 0.8}},
	"mug": {"name": "Hot cocoa", "layer": "top", "price": 0, "set": "Basics", "kind": "mug"},
	"books_stack": {"name": "Book stack", "layer": "top", "price": 0, "set": "Study nook"},
	"candle": {"name": "Candle", "layer": "top", "price": 10, "set": "Night glow", "kind": "candle", "frames": ["candle", "candle_1"], "fps": 3.0,
		"light": {"offset": Vector2(4, 3), "color": Color(1.0, 0.7, 0.35), "energy": 0.8, "size": 0.6}},
	"succulent": {"name": "Succulent", "layer": "top", "price": 10, "set": "Plant corner"},
	"photo_frame": {"name": "Photo frame", "layer": "top", "price": 10, "set": "Basics"},
	"alarm_clock": {"name": "Alarm clock", "layer": "top", "price": 15, "set": "Study nook"},
	"plush_bear": {"name": "Plush bear", "layer": "top", "price": 20, "set": "Play time"},
	"vase": {"name": "Flower vase", "layer": "top", "price": 20, "set": "Plant corner"},
	"teapot": {"name": "Teapot", "layer": "top", "price": 20, "level": 2, "set": "Lounge"},
	"ramen": {"name": "Late-night ramen", "layer": "top", "price": 20, "level": 2, "set": "Lounge", "kind": "mug"},
	"headphones": {"name": "Headphones", "layer": "top", "price": 25, "level": 2, "set": "Music corner"},
	"terrarium": {"name": "Terrarium", "layer": "top", "price": 25, "level": 2, "set": "Plant corner"},
	"lava_lamp": {"name": "Lava lamp", "layer": "top", "price": 30, "level": 2, "set": "Night glow", "kind": "lamp",
		"frames": ["lava_lamp", "lava_lamp_1"], "fps": 0.7,
		"light": {"offset": Vector2(5, 8), "color": Color(0.95, 0.45, 0.85), "energy": 0.8, "size": 0.7}},
	"fairy_jar": {"name": "Firefly jar", "layer": "top", "price": 30, "level": 3, "set": "Night glow", "kind": "candle",
		"light": {"offset": Vector2(5, 8), "color": Color(1.0, 0.9, 0.5), "energy": 0.7, "size": 0.6}},
	"globe": {"name": "Globe", "layer": "top", "price": 30, "level": 3, "set": "Study nook"},
	"snow_globe": {"name": "Snow globe", "layer": "top", "price": 30, "level": 3, "set": "Play time"},
	"laptop": {"name": "Laptop", "layer": "top", "price": 35, "level": 3, "set": "Study nook",
		"light": {"offset": Vector2(11, 6), "color": Color(0.5, 0.7, 1.0), "energy": 0.4, "size": 0.5}},
	"camera": {"name": "Camera", "layer": "top", "price": 35, "level": 3, "set": "Play time"},
	"game_console": {"name": "Handheld console", "layer": "top", "price": 40, "level": 4, "set": "Play time"},
	"typewriter": {"name": "Typewriter", "layer": "top", "price": 45, "level": 4, "set": "Study nook"},
	"radio": {"name": "Radio", "layer": "top", "price": 45, "level": 4, "set": "Music corner", "kind": "player"},
	"record_player": {"name": "Record player", "layer": "top", "price": 50, "level": 5, "set": "Music corner", "kind": "player",
		"frames": ["record_player", "record_player_1"], "fps": 3.0, "animate_when": "music"},
	# ------------------------------------------------------------ wall
	"poster_moon": {"name": "Moon poster", "layer": "wall", "price": 0, "set": "Wall art"},
	"string_lights": {"name": "String lights", "layer": "wall", "price": 0, "set": "Night glow", "kind": "lamp",
		"frames": ["string_lights", "string_lights_1"], "fps": 0.8,
		"light": {"offset": Vector2(50, 9), "color": Color(1.0, 0.82, 0.55), "energy": 1.0, "size": 1.8}},
	"poster_wave": {"name": "Wave poster", "layer": "wall", "price": 15, "set": "Wall art"},
	"frame_cat": {"name": "Cat portrait", "layer": "wall", "price": 15, "set": "Wall art"},
	"wall_clock": {"name": "Wall clock", "layer": "wall", "price": 15, "set": "Study nook", "kind": "clock"},
	"calendar": {"name": "Calendar", "layer": "wall", "price": 15, "set": "Study nook"},
	"pennant": {"name": "Pennant", "layer": "wall", "price": 15, "set": "Wall art"},
	"poster_city": {"name": "Sunset poster", "layer": "wall", "price": 20, "level": 2, "set": "Wall art"},
	"print_botanical": {"name": "Botanical print", "layer": "wall", "price": 20, "level": 2, "set": "Plant corner"},
	"wall_shelf": {"name": "Wall shelf", "layer": "wall", "price": 25, "level": 2, "set": "Study nook"},
	"mirror_round": {"name": "Round mirror", "layer": "wall", "price": 25, "level": 2, "set": "Basics"},
	"hanging_plant": {"name": "Hanging plant", "layer": "wall", "price": 30, "level": 3, "set": "Plant corner", "frames": ["hanging_plant", "hanging_plant_1"], "fps": 0.45},
	"sconce": {"name": "Wall sconce", "layer": "wall", "price": 30, "level": 3, "set": "Night glow", "kind": "lamp",
		"light": {"offset": Vector2(6, 8), "color": WARM, "energy": 1.1, "size": 1.0}},
	"corkboard": {"name": "Corkboard", "layer": "wall", "price": 30, "level": 3, "set": "Study nook"},
	"curtains": {"name": "Curtains", "layer": "wall", "price": 35, "level": 3, "set": "Basics", "variants": ["", "teal", "rose", "amber"]},
	"polaroids": {"name": "Polaroid string", "layer": "wall", "price": 35, "level": 4, "set": "Wall art"},
	"skate_deck": {"name": "Skate deck", "layer": "wall", "price": 35, "level": 4, "set": "Play time"},
	"trophy_shelf": {"name": "Trophy shelf", "layer": "wall", "price": 40, "level": 4, "set": "Play time"},
	"paper_lanterns": {"name": "Paper lanterns", "layer": "wall", "price": 45, "level": 5, "set": "Night glow", "kind": "lamp",
		"light": {"offset": Vector2(32, 13), "color": Color(1.0, 0.65, 0.45), "energy": 0.9, "size": 1.4}},
	"tapestry": {"name": "Moon tapestry", "layer": "wall", "price": 50, "level": 5, "set": "Wall art"},
	"neon_moon": {"name": "Neon moon", "layer": "wall", "price": 55, "level": 6, "set": "Night glow", "kind": "lamp",
		"light": {"offset": Vector2(13, 13), "color": Color(0.8, 0.55, 1.0), "energy": 0.9, "size": 0.9}},
	"neon_heart": {"name": "Neon heart", "layer": "wall", "price": 55, "level": 6, "set": "Night glow", "kind": "lamp",
		"light": {"offset": Vector2(12, 12), "color": Color(1.0, 0.45, 0.7), "energy": 0.9, "size": 0.9}},
	# ------------------------------------------------------------ rugs
	"rug_round": {"name": "Round rug", "layer": "rug", "price": 0, "set": "Basics", "variants": ["", "teal", "rose"]},
	"rug_stripe": {"name": "Striped rug", "layer": "rug", "price": 20, "set": "Lounge"},
	"rug_check": {"name": "Checkered rug", "layer": "rug", "price": 25, "level": 2, "set": "Lounge"},
	"rug_fur": {"name": "Fluffy rug", "layer": "rug", "price": 35, "level": 3, "set": "Lounge"},
	"rug_star": {"name": "Starry rug", "layer": "rug", "price": 40, "level": 4, "set": "Night glow"},
}

## Rooms. `level` gates the room, `pane` is the see-through part of the window
## in room pixels, `style` picks the wall treatment drawn by room.gd.
const ROOMS := [
	{"id": "bedroom", "name": "Bedroom", "level": 1, "style": "panel", "wall": 0, "floor": 0,
		"window": "window_frame", "window_pos": Vector2(114, 20), "pane": Rect2(119, 25, 82, 54),
		"starter": [
			{"id": "rug_round", "x": 170, "y": 150}, {"id": "poster_moon", "x": 74, "y": 52},
			{"id": "string_lights", "x": 160, "y": 12}, {"id": "bed", "x": 250, "y": 146},
			{"id": "desk", "x": 62, "y": 142}, {"id": "avatar", "x": 88, "y": 151},
			{"id": "plant_big", "x": 304, "y": 142}, {"id": "cat", "x": 168, "y": 152},
			{"id": "monitor", "x": 56, "y": 113}, {"id": "desk_lamp", "x": 38, "y": 113},
			{"id": "mug", "x": 78, "y": 113}, {"id": "books_stack", "x": 112, "y": 148},
		]},
	{"id": "attic", "name": "Attic studio", "level": 3, "style": "attic", "wall": 4, "floor": 1,
		"window": "window_small", "window_pos": Vector2(214, 42), "pane": Rect2(219, 47, 42, 34),
		"starter": [
			{"id": "rug_round", "x": 150, "y": 152, "variant": "teal"}, {"id": "desk", "x": 150, "y": 142},
			{"id": "avatar", "x": 176, "y": 151, "variant": "teal"}, {"id": "desk_lamp", "x": 128, "y": 113},
			{"id": "monitor", "x": 146, "y": 113}, {"id": "cat", "x": 60, "y": 160},
			{"id": "plant_big", "x": 290, "y": 144}, {"id": "poster_moon", "x": 120, "y": 62},
		]},
	{"id": "loft", "name": "City loft", "level": 6, "style": "brick", "wall": 1, "floor": 2,
		"window": "window_wide", "window_pos": Vector2(74, 18), "pane": Rect2(79, 23, 162, 54),
		"starter": [
			{"id": "rug_round", "x": 160, "y": 156, "variant": "rose"}, {"id": "desk", "x": 268, "y": 142},
			{"id": "avatar", "x": 294, "y": 151, "variant": "rose"}, {"id": "monitor", "x": 262, "y": 113},
			{"id": "desk_lamp", "x": 244, "y": 113}, {"id": "cat", "x": 150, "y": 158},
			{"id": "plant_big", "x": 30, "y": 144}, {"id": "bed", "x": 100, "y": 148, "variant": "teal"},
		]},
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

const VARIANT_COLOURS := {
	"": Color("9a89cf"), "lavender": Color("9a89cf"), "teal": Color("57aaa5"), "rose": Color("e08fa8"),
	"amber": Color("f2b866"), "slate": Color("8a84a0"), "sage": Color("6aa861"),
}
## Base colour of items whose un-recoloured sprite is not lavender.
const BASE_VARIANT := {"sofa": "teal", "beanbag": "rose", "armchair": "amber", "floor_cushion": "teal"}

## The demo build only offers the first room and cheap, low-level items.
const DEMO_MAX_LEVEL := 2
const DEMO_MAX_PRICE := 40


static func get_def(id: String) -> Dictionary:
	return ITEMS.get(id, {})


static func level_of(id: String) -> int:
	return int(ITEMS.get(id, {}).get("level", 1))


static func in_demo(id: String) -> bool:
	return level_of(id) <= DEMO_MAX_LEVEL and int(ITEMS[id]["price"]) <= DEMO_MAX_PRICE


## Loads a sprite by file name, using the recoloured file when one exists.
static func sprite(file: String, variant: String = "") -> Texture2D:
	if variant != "":
		var path := "%s%s__%s.png" % [SPRITE_DIR, file, variant]
		if ResourceLoader.exists(path):
			return load(path) as Texture2D
	return load(SPRITE_DIR + file + ".png") as Texture2D


static func texture_for(id: String, variant: String = "") -> Texture2D:
	var def: Dictionary = ITEMS.get(id, {})
	return sprite(def.get("sprite", id), variant)


static func variant_colour(id: String, variant: String) -> Color:
	if variant == "":
		variant = BASE_VARIANT.get(id, "lavender")
	return VARIANT_COLOURS.get(variant, Color.WHITE)
