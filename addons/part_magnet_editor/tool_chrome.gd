@tool
extends RefCounted

## One size for every Project → Tools window: 800×600, with a scrollbar
## when the content is taller than the window.

const SIZE := Vector2i(800, 600)
## Width of the text column inside the scroll (window minus padding and bar).
const BODY_WIDTH := 752.0


static func apply(win: Window) -> void:
	if win == null:
		return
	win.min_size = SIZE
	win.size = SIZE


static func popup(win: Window) -> void:
	apply(win)
	win.popup_centered(SIZE)


static func scrolled_body(content: Control) -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.custom_minimum_size.x = BODY_WIDTH
	scroll.add_child(content)
	return scroll
