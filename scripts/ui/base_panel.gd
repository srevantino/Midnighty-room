class_name BasePanel
extends PanelContainer
## A floating panel. Drag it by its title bar, collapse it to just the title,
## or close it. Content taller than the window scrolls. Subclasses add their
## widgets to `body`.

signal close_requested

var body: VBoxContainer
var _scroll: ScrollContainer
var _collapse: Button
var _collapsed := false
var _dragging := false
var _fade: Tween


func build(title: String, width: int) -> void:
	custom_minimum_size.x = width
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 8)
	add_child(outer)

	var header := HBoxContainer.new()
	header.mouse_filter = Control.MOUSE_FILTER_STOP
	header.mouse_default_cursor_shape = Control.CURSOR_MOVE
	header.tooltip_text = "Drag to move this panel"
	header.gui_input.connect(_on_header_input)
	var title_label := UIKit.label(title, 22)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(title_label)
	_collapse = _header_button("collapse", "Collapse", toggle_collapsed)
	header.add_child(_collapse)
	header.add_child(_header_button("close", "Close", func() -> void: close_requested.emit()))
	outer.add_child(header)

	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(_scroll)
	body = VBoxContainer.new()
	body.add_theme_constant_override("separation", 10)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(body)

	body.minimum_size_changed.connect(_queue_fit)
	visibility_changed.connect(_queue_fit)
	get_viewport().size_changed.connect(_queue_fit)


func _header_button(icon_name: String, tip: String, on_press: Callable) -> Button:
	var b := Button.new()
	b.icon = UIKit.icon(icon_name)
	b.flat = true
	b.tooltip_text = tip
	b.custom_minimum_size = Vector2(32, 32)
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.pressed.connect(on_press)
	return b


func _queue_fit() -> void:
	if is_inside_tree():
		fit.call_deferred()


## Sizes the scroll area to the content, capped so the panel stays on screen.
func fit() -> void:
	if _collapsed or not visible:
		return
	var available := get_viewport_rect().size.y - maxf(global_position.y, 0.0) - 158.0
	_scroll.custom_minimum_size.y = clampf(body.get_combined_minimum_size().y, 40.0, maxf(available, 120.0))
	size = Vector2.ZERO


func toggle_collapsed() -> void:
	_collapsed = not _collapsed
	_scroll.visible = not _collapsed
	_collapse.icon = UIKit.icon("expand" if _collapsed else "collapse")
	_collapse.tooltip_text = "Expand" if _collapsed else "Collapse"
	size = Vector2.ZERO
	_queue_fit()


func _on_header_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_dragging = event.pressed
		if event.pressed and event.double_click:
			toggle_collapsed()
	elif event is InputEventMouseMotion and _dragging:
		var limit := get_viewport_rect().size
		position = (position + event.relative).clamp(Vector2(-size.x + 80, 0), Vector2(limit.x - 80, limit.y - 50))


func open() -> void:
	visible = true
	_fade_to(1.0)


func close() -> void:
	if not visible:
		return
	_fade_to(0.0)
	_fade.tween_callback(func() -> void: visible = false)


## Makes the panel see-through, used while an item is being dragged under it.
func set_ghost(on: bool) -> void:
	if visible:
		_fade_to(0.15 if on else 1.0)


func _fade_to(alpha: float) -> void:
	if _fade:
		_fade.kill()
	_fade = create_tween()
	_fade.tween_property(self, "modulate:a", alpha, 0.14)
