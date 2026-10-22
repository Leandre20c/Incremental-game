class_name PsxViewportContainer
extends SubViewportContainer
## Renders the child SubViewport at a low internal resolution and upscales it
## with nearest filtering. Keeps a roughly constant vertical resolution
## whatever the window size.

@export var target_height: int = 240


func _ready() -> void:
	stretch = true
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	get_viewport().size_changed.connect(_update_shrink)
	_update_shrink()


func _update_shrink() -> void:
	var window_height := get_viewport().get_visible_rect().size.y
	stretch_shrink = maxi(1, roundi(window_height / float(target_height)))
