class_name ComputerMenu
extends CanvasLayer

@export var menu_id: StringName = &"computer"
@export var player_id: int = 1

@onready var _root: Control = %Root
@onready var _close_button: Button = %CloseButton

func _ready() -> void:
	_root.hide()
	_close_button.pressed.connect(close)
	EventBus.menu_requested.connect(_on_menu_requested)

func _unhandled_input(event: InputEvent) -> void:
	if _root.visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()

func open() -> void:
	_root.show()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func close() -> void:
	_root.hide()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	EventBus.menu_closed.emit(player_id, menu_id)

func _on_menu_requested(requesting_player_id: int, requested_menu_id: StringName) -> void:
	if requesting_player_id == player_id and requested_menu_id == menu_id:
		open()
