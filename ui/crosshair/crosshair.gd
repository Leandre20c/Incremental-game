class_name Crosshair
extends Control

@export var color: Color = Color.WHITE
@export var outline_color: Color = Color(0.0, 0.0, 0.0, 0.6)
@export var size_px: float = 6.0 ## Half-length of each arm. 0 = dot only
@export var gap_px: float = 2.0 ## Empty space around the center
@export var thickness_px: float = 2.0
@export var show_dot: bool = true

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _draw() -> void:
	var center: Vector2 = (size * 0.5).round()
	# Outline first, then the crosshair on top, for readability on any background
	_draw_shape(center, outline_color, thickness_px + 2.0)
	_draw_shape(center, color, thickness_px)

func _draw_shape(center: Vector2, draw_color: Color, width: float) -> void:
	if show_dot:
		draw_rect(Rect2(center - Vector2.ONE * width * 0.5, Vector2.ONE * width), draw_color)
	if size_px <= 0.0:
		return
	var start: float = gap_px
	var end: float = gap_px + size_px
	for direction in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]:
		draw_line(center + direction * start, center + direction * end, draw_color, width)
