extends BasePanel
## Decorate mode: switch rooms, buy and place items, recolour things, save
## and load layouts.

var room: Room
var _grid: GridContainer
var _selected_label: Label
var _variant_row: HBoxContainer
var _flip: Button
var _remove: Button
var _room_label: Label
var _filter := "All items"
var _load_buttons: Dictionary = {}


func _ready() -> void:
	build("Decorate", 384)

	# room switcher
	var room_row := HBoxContainer.new()
	room_row.add_theme_constant_override("separation", 6)
	room_row.add_child(UIKit.button("<", func() -> void: _switch_room(-1), 34))
	_room_label = UIKit.label("", 16)
	_room_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_room_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	room_row.add_child(_room_label)
	room_row.add_child(UIKit.button(">", func() -> void: _switch_room(1), 34))
	body.add_child(room_row)

	# layout presets
	var preset_row := HBoxContainer.new()
	preset_row.add_theme_constant_override("separation", 6)
	var preset_label := UIKit.label("Layouts", 15, UIKit.MUTED)
	preset_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preset_row.add_child(preset_label)
	for slot: String in ["1", "2"]:
		var save := UIKit.button(tr("Save %s") % slot, func() -> void:
			GameState.save_preset(slot)
			GameState.toast.emit(tr("Layout %s saved") % slot)
			_refresh_room())
		save.tooltip_text = "Remember how this room looks right now"
		preset_row.add_child(save)
		var load_button := UIKit.button(tr("Load %s") % slot, func() -> void:
			if GameState.load_preset(slot):
				GameState.toast.emit(tr("Layout %s loaded") % slot))
		preset_row.add_child(load_button)
		_load_buttons[slot] = load_button
	var reset := UIKit.button("Reset", GameState.reset_room)
	reset.tooltip_text = "Put this room back to how it started"
	preset_row.add_child(reset)
	body.add_child(preset_row)

	# selected item
	var selected_row := HBoxContainer.new()
	selected_row.add_theme_constant_override("separation", 6)
	_selected_label = UIKit.label("", 15, UIKit.MUTED)
	_selected_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_selected_label.clip_text = true
	_selected_label.tooltip_text = "Drag items to move them. Arrow keys nudge. Small things snap onto furniture."
	_selected_label.mouse_filter = Control.MOUSE_FILTER_STOP
	selected_row.add_child(_selected_label)
	_variant_row = HBoxContainer.new()
	_variant_row.add_theme_constant_override("separation", 4)
	selected_row.add_child(_variant_row)
	_flip = UIKit.button("Flip", func() -> void: room.flip_selected(), 54)
	_remove = UIKit.button("Remove", func() -> void: room.remove_selected(), 74)
	selected_row.add_child(_flip)
	selected_row.add_child(_remove)
	body.add_child(selected_row)

	body.add_child(_swatches("Walls", Catalog.WALLS, func(i: int) -> void: GameState.set_look(i, int(GameState.room()["floor"]))))
	body.add_child(_swatches("Floor", Catalog.FLOORS, func(i: int) -> void: GameState.set_look(int(GameState.room()["wall"]), i)))

	var filter := OptionButton.new()
	for option: String in ["All items", "Owned"] + Catalog.SETS:
		filter.add_item(option)
	filter.item_selected.connect(func(i: int) -> void:
		_filter = filter.get_item_text(i)
		_rebuild())
	body.add_child(filter)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.y = 222
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
	GameState.room_changed.connect(_refresh_room)
	GameState.level_up.connect(func(_l: int) -> void: _refresh_room())
	_on_selection(null)
	_refresh_room()
	_rebuild()


func _switch_room(step: int) -> void:
	var count := Catalog.ROOMS.size()
	var index := posmod(int(GameState.data["room"]) + step, count)
	var reason := GameState.room_lock_reason(index)
	if reason != "":
		GameState.toast.emit("%s: %s" % [tr(Catalog.ROOMS[index]["name"]), reason])
		return
	GameState.switch_room(index)


func _refresh_room() -> void:
	_room_label.text = tr(GameState.room_config()["name"])
	for slot: String in _load_buttons:
		(_load_buttons[slot] as Button).disabled = not GameState.has_preset(slot)


func _swatches(title: String, options: Array, on_pick: Callable) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var name_label := UIKit.label(title, 15, UIKit.MUTED)
	name_label.custom_minimum_size.x = 56
	row.add_child(name_label)
	for i in options.size():
		row.add_child(_swatch(options[i]["base"], options[i]["name"], func() -> void: on_pick.call(i)))
	return row


func _swatch(colour: Color, tip: String, on_press: Callable, size: Vector2 = Vector2(34, 26)) -> Button:
	var b := Button.new()
	b.custom_minimum_size = size
	b.tooltip_text = tip
	for state: String in ["normal", "hover", "pressed"]:
		b.add_theme_stylebox_override(state, UIKit.box(colour, 6, UIKit.ACCENT if state != "normal" else UIKit.BORDER, 0))
	b.pressed.connect(func() -> void:
		AudioMixer.play_sfx("click")
		on_press.call())
	return b


func _on_selection(item: FurnitureItem) -> void:
	_flip.disabled = item == null
	_remove.disabled = item == null
	_selected_label.text = tr("Click an item in the room") if item == null else tr(str(item.def.get("name", "")))
	_selected_label.add_theme_color_override("font_color", UIKit.MUTED if item == null else UIKit.TEXT)
	for child in _variant_row.get_children():
		child.queue_free()
	if item:
		for variant: String in item.variants():
			_variant_row.add_child(_swatch(Catalog.variant_colour(item.item_id, variant), "Recolour",
				func() -> void: room.set_selected_variant(variant), Vector2(22, 26)))


func _rebuild() -> void:
	for child in _grid.get_children():
		child.queue_free()
	var ids: Array = Catalog.ITEMS.keys().filter(func(id: String) -> bool:
		match _filter:
			"All items":
				return true
			"Owned":
				return GameState.is_unlocked(id)
		return Catalog.ITEMS[id].get("set", "") == _filter)
	# owned first, then by level, then cheapest
	ids.sort_custom(func(a: String, b: String) -> bool:
		var owned_a := GameState.is_unlocked(a)
		var owned_b := GameState.is_unlocked(b)
		if owned_a != owned_b:
			return owned_a
		if Catalog.level_of(a) != Catalog.level_of(b):
			return Catalog.level_of(a) < Catalog.level_of(b)
		return int(Catalog.ITEMS[a]["price"]) < int(Catalog.ITEMS[b]["price"]))
	for id: String in ids:
		_grid.add_child(_item_button(id))


func _item_button(id: String) -> Button:
	var def: Dictionary = Catalog.ITEMS[id]
	var owned := GameState.is_unlocked(id)
	var b := Button.new()
	b.custom_minimum_size = Vector2(112, 100)
	b.icon = Catalog.texture_for(id)
	b.expand_icon = true
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	b.add_theme_font_size_override("font_size", 12)
	b.add_theme_constant_override("icon_max_width", 76)
	b.clip_text = true
	b.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	var status := tr("Place")
	if not owned:
		var reason := GameState.lock_reason(id)
		var level_locked := GameState.level() < Catalog.level_of(id) or (GameState.is_demo() and not Catalog.in_demo(id))
		status = reason if level_locked else tr("%d moonlight") % int(def["price"])
		b.add_theme_color_override("font_color", UIKit.ACCENT if reason == "" else UIKit.MUTED.darkened(0.2))
		b.tooltip_text = tr("Buy and place") if reason == "" else reason
		if level_locked:
			b.modulate = Color(1, 1, 1, 0.55)
	b.text = "%s\n%s" % [tr(def["name"]), status]
	b.pressed.connect(func() -> void: _pick(id))
	return b


func _pick(id: String) -> void:
	if not GameState.is_unlocked(id):
		var reason := GameState.lock_reason(id)
		if reason != "" or not GameState.buy(id):
			GameState.toast.emit(reason)
			return
		AudioMixer.play_sfx("coin")
		GameState.toast.emit(tr("Unlocked %s") % tr(Catalog.ITEMS[id]["name"]))
	if not room.spawn(id):
		GameState.toast.emit(tr("The room is full. Remove something first."))
