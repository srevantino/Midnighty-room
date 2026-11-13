extends BasePanel
## To-do list. Ticking a task off pays a little moonlight (capped per day).

var _input: LineEdit
var _list: VBoxContainer
var _empty: Label


func _ready() -> void:
	build("Tasks", 330)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	_input = LineEdit.new()
	_input.placeholder_text = "What are you working on?"
	_input.max_length = 80
	_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_input.text_submitted.connect(func(_t: String) -> void: _add())
	row.add_child(_input)
	row.add_child(UIKit.button("Add", _add, 60))
	body.add_child(row)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.y = 300
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 6)
	scroll.add_child(_list)
	body.add_child(scroll)
	_empty = UIKit.label("Nothing here yet. Add the one thing you want to get done.", 14, UIKit.MUTED)
	_empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(_empty)
	body.add_child(UIKit.button("Clear finished tasks", GameState.clear_done_todos))

	GameState.todos_changed.connect(_rebuild)
	_rebuild()


func _add() -> void:
	GameState.add_todo(_input.text)
	_input.clear()


func _rebuild() -> void:
	for child in _list.get_children():
		child.queue_free()
	var todos: Array = GameState.data["todos"]
	_empty.visible = todos.is_empty()
	for i in todos.size():
		var todo: Dictionary = todos[i]
		var row := HBoxContainer.new()
		var check := CheckBox.new()
		check.text = todo["text"]
		check.button_pressed = todo["done"]
		check.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		check.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		check.clip_text = true
		if todo["done"]:
			check.add_theme_color_override("font_color", UIKit.MUTED.darkened(0.2))
			check.add_theme_color_override("font_pressed_color", UIKit.MUTED.darkened(0.2))
		check.toggled.connect(func(on: bool) -> void:
			var reward := GameState.set_todo_done(i, on)
			if reward > 0:
				AudioMixer.play_sfx("coin")
				GameState.toast.emit("Task done  +%d moonlight" % reward))
		row.add_child(check)
		var remove := Button.new()
		remove.icon = UIKit.icon("close")
		remove.flat = true
		remove.tooltip_text = "Delete task"
		remove.pressed.connect(func() -> void: GameState.remove_todo(i))
		row.add_child(remove)
		_list.add_child(row)
