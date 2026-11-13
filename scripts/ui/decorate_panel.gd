extends BasePanel
## Decorate mode: buy and place items, recolour the walls and floor.

var room: Room
var _grid: GridContainer
var _selected_label: Label
var _flip: Button
var _remove: Button


func _ready() -> void:
	build("Decorate", 380)
	var hint := UIKit.label("Drag anything in the room to move it. Pick an item below to add it.", 13, UIKit.MUTED)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(hint)

	var selected_row := HBoxContainer.new()
	selected_row.add_theme_constant_override("separation", 8)
	_selected_label = UIKit.label("Nothing selected", 15, UIKit.MUTED)
	_selected_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_selected_label.clip_text = true
	selected_row.add_child(_selected_label)
	_flip = UIKit.button("Flip", func() -> void: room.flip_selected(), 60)
	_flip.tooltip_text = "Shortcut: F"
	_remove = UIKit.button("Remove", func() -> void: room.remove_selected(), 80)
	_remove.tooltip_text = "Shortcut: Delete"
	selected_row.add_child(_flip)
	selected_row.add_child(_remove)
	body.add_child(selected_row)

	body.add_child(_swatches("Walls", Catalog.WALLS, func(i: int) -> void: GameState.set_look(i, int(GameState.data["floor"]))))
	body.add_child(_swatches("Floor", Catalog.FLOORS, func(i: int) -> void: GameState.set_look(int(GameState.data["wall"]), i)))

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.y = 318
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_grid = GridContainer.new()
	_grid.columns = 3
	_grid.add_theme_constant_override("h_separation", 6)
	_grid.add_theme_constant_override("v_separation", 6)
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_grid)
	body.add_child(scroll)

	room.selection_changed.connect(_on_selection)
	GameState.unlocks_changed.connect(_rebuild)
	GameState.coins_changed.connect(func(_c: int) -> void: _rebuild())
	_on_selection(null)
	_rebuild()


func _swatches(title: String, options: Array, on_pick: Callable) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var name_label := UIKit.label(title, 15, UIKit.MUTED)
	name_label.custom_minimum_size.x = 56
	row.add_child(name_label)
	for i in options.size():
		var b := Button.new()
		b.custom_minimum_size = Vector2(34, 26)
		b.tooltip_text = options[i]["name"]
		for state: String in ["normal", "hover", "pressed"]:
			b.add_theme_stylebox_override(state, UIKit.box(options[i]["base"], 6, UIKit.ACCENT if state != "normal" else UIKit.BORDER, 0))
		b.pressed.connect(func() -> void:
			AudioMixer.play_sfx("click")
			on_pick.call(i))
		row.add_child(b)
	return row


func _on_selection(item: FurnitureItem) -> void:
	_flip.disabled = item == null
	_remove.disabled = item == null
	_selected_label.text = "Nothing selected" if item == null else str(item.def.get("name", ""))
	_selected_label.add_theme_color_override("font_color", UIKit.MUTED if item == null else UIKit.TEXT)


func _rebuild() -> void:
	for child in _grid.get_children():
		child.queue_free()
	var ids: Array = Catalog.ITEMS.keys()
	# owned first, then cheapest
	ids.sort_custom(func(a: String, b: String) -> bool:
		var owned_a := GameState.is_unlocked(a)
		var owned_b := GameState.is_unlocked(b)
		if owned_a != owned_b:
			return owned_a
		return int(Catalog.ITEMS[a]["price"]) < int(Catalog.ITEMS[b]["price"]))
	for id: String in ids:
		_grid.add_child(_item_button(id))


func _item_button(id: String) -> Button:
	var def: Dictionary = Catalog.ITEMS[id]
	var owned := GameState.is_unlocked(id)
	var price := int(def["price"])
	var b := Button.new()
	b.custom_minimum_size = Vector2(112, 104)
	b.icon = Catalog.texture_for(id)
	b.expand_icon = true
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	b.add_theme_font_size_override("font_size", 12)
	b.add_theme_constant_override("icon_max_width", 80)
	b.clip_text = true
	b.text = "%s\n%s" % [def["name"], "Place" if owned else "%d moonlight" % price]
	if not owned:
		var affordable := GameState.coins() >= price
		b.add_theme_color_override("font_color", UIKit.ACCENT if affordable else UIKit.MUTED.darkened(0.2))
		b.tooltip_text = "Buy and place" if affordable else "Focus a little longer to afford this"
	b.pressed.connect(func() -> void: _pick(id))
	return b


func _pick(id: String) -> void:
	if not GameState.is_unlocked(id):
		if not GameState.buy(id):
			GameState.toast.emit("Not enough moonlight yet")
			return
		AudioMixer.play_sfx("coin")
		GameState.toast.emit("Unlocked %s" % Catalog.ITEMS[id]["name"])
	if not room.spawn(id):
		GameState.toast.emit("The room is full. Remove something first.")
