class_name GrabHint
extends Label

## Shows the held-item controls while the player is holding something.

@export var player_id: int = 1

const ACTIONS: Dictionary = {
	"drop": "Drop",
	"rotate_held": "Hold + mouse",
	"reset_held_rotation": "Reset",
}

var _tween: Tween

func _ready() -> void:
	visible = false
	modulate.a = 0.0
	EventBus.item_grabbed.connect(_on_item_grabbed)
	EventBus.items_released.connect(_on_items_released)
	
	var grabber := get_tree().get_first_node_in_group(&"player_grabber") as PlayerGrabber
	if grabber:
		grabber.holding_changed.connect(func(holding: bool) -> void:
			if not holding:
				_fade_to(0.0))


func _on_item_grabbed(grabber_id: int, _entity_id: int) -> void:
	if grabber_id != player_id:
		return
	text = _build_text()
	visible = true
	_fade_to(1.0)


func _on_items_released(releaser_id: int, _entity_ids: Array) -> void:
	if releaser_id != player_id:
		return
	_fade_to(0.0)


func _fade_to(alpha: float) -> void:
	if _tween:
		_tween.kill() # Stop a fade still running (quick grab/release)
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", alpha, 0.15)
	if alpha == 0.0:
		_tween.tween_callback(hide) # Hide once fully transparent


func _build_text() -> String:
	var lines: PackedStringArray = []
	for action: String in ACTIONS:
		lines.append("[%s] %s" % [_get_input_label(action), ACTIONS[action]])
	return " | ".join(lines)

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
