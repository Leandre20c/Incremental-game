class_name GrabHint
extends Label

## Shows the held-item controls while the player is holding something:
## grab controls, then the item's own actions (place, switch on/off…).

@export var player_id: int = 1

const ACTIONS: Dictionary = {
	"drop": "Drop",
	"rotate_held": "Hold + mouse",
	"reset_held_rotation": "Reset",
}

var _tween: Tween
var _entity_id: int = -1

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

## The item's actions can change while held (switched on/off…).
func _process(_delta: float) -> void:
	if _entity_id < 0:
		return
	var new_text: String = _build_text()
	if text != new_text:
		text = new_text


func _on_item_grabbed(grabber_id: int, entity_id: int) -> void:
	if grabber_id != player_id:
		return
	_entity_id = entity_id
	text = _build_text()
	visible = true
	_fade_to(1.0)


func _on_items_released(releaser_id: int, _entity_ids: Array) -> void:
	if releaser_id != player_id:
		return
	_entity_id = -1
	_fade_to(0.0)


func _fade_to(alpha: float) -> void:
	if _tween:
		_tween.kill() # Stop a fade still running (quick grab/release)
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", alpha, 0.15)
	if alpha == 0.0:
		_tween.tween_callback(hide) # Hide once fully transparent


func _build_text() -> String:
	var grab_lines: PackedStringArray = []
	for action: String in ACTIONS:
		grab_lines.append(_format(action, ACTIONS[action]))
	var text_lines: PackedStringArray = [" | ".join(grab_lines)]

	var item_lines: PackedStringArray = []
	if _is_placeable(_entity_id):
		item_lines.append(_format("place_held", "Place"))
		var placer: PlayerPlacer = get_tree().get_first_node_in_group(&"player_placer") as PlayerPlacer
		if placer != null and placer.can_snap():
			item_lines.append(_format("toggle_grid", "Grid: %s" % ("ON" if placer.is_grid_enabled() else "OFF")))
	var action: SecondaryAction = _get_held_action()
	if action != null:
		item_lines.append(_format("interact_secondary", action.get_prompt_text()))
		if action.has_long_action():
			item_lines.append("[Hold %s] %s" % [_get_input_label("interact_secondary"), action.get_long_prompt_text()])
	if not item_lines.is_empty():
		text_lines.append(" | ".join(item_lines))

	return "\n".join(text_lines)


func _format(action: String, label: String) -> String:
	return "[%s] %s" % [_get_input_label(action), label]


func _is_placeable(entity_id: int) -> bool:
	var item: Dictionary = GameState.get_world_item(entity_id)
	if item.is_empty():
		return false
	var definition: ItemDefinition = ItemDatabase.get_definition(item["item_id"])
	return definition != null and definition.placeable


func _get_held_action() -> SecondaryAction:
	var spawner: WorldItemSpawner = get_tree().get_first_node_in_group(&"world_item_spawner") as WorldItemSpawner
	var body: Node = spawner.get_view(_entity_id) if spawner != null else null
	var action: SecondaryAction = SecondaryAction.find_on(body)
	if action == null or not action.usable_while_held or not action.is_available():
		return null
	return action


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
