class_name ToolHint
extends Control

## Shows the granted-tool controls when the player collect it.

@export var player_id: int = 1

@onready var tool_display_name: Label = $ToolDisplayName
@onready var tool_hint: Label = $ToolHint

var _tool_name: StringName
var _tween: Tween

func _ready() -> void:
	visible = false
	modulate.a = 0.0
	EventBus.tool_granted.connect(_on_tool_granted)
	
	var grabber := get_tree().get_first_node_in_group(&"player_grabber") as PlayerGrabber
	if grabber:
		grabber.holding_changed.connect(func(holding: bool) -> void:
			if not holding:
				_fade_to(0.0))


func _on_tool_granted(grabber_id: int, tool_id: StringName) -> void:
	if grabber_id != player_id:
		return
	
	_tool_name = ItemDatabase.get_definition(tool_id).display_name
	_build_text()
	visible = true
	_fade_to(1.0)
	await get_tree().create_timer(2.5).timeout
	_fade_to(0.0)

func _fade_to(alpha: float) -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", alpha, 0.5)
	if alpha == 0.0:
		_tween.tween_callback(hide)


func _build_text():
	tool_display_name.text = _tool_name
	tool_hint.text =  "— [%s] %s —" % [_get_input_label("toggle_lighter"), "to toggle lighter"]

func _get_input_label(action_name) -> String:
	var events: Array[InputEvent] = InputMap.action_get_events(action_name)
	if events.is_empty():
		return "?"
	var event: InputEvent = events[0]

	if event is InputEventKey:
		var keycode: Key = event.keycode
		if event.physical_keycode != KEY_NONE:
			# Translate the physical position to the key on the player's layout (QWERTY, AZERTY…)
			keycode = DisplayServer.keyboard_get_keycode_from_physical(event.physical_keycode)
		return OS.get_keycode_string(keycode)

	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_LEFT: return "LMB"
			MOUSE_BUTTON_RIGHT: return "RMB"
			MOUSE_BUTTON_MIDDLE: return "MMB"

	return event.as_text()
