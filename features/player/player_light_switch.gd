class_name PlayerLightSwitch
extends Node

## Single light key: turns on the best light the player owns, or turns it off.

@export var player_id: int = 1
@export var toggle_action: StringName = &"toggle_light"
@export var lights: Array[ToolLight] = [] ## Sorted from worst to best. The last owned one is used

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(toggle_action):
		_toggle()

func _toggle() -> void:
	var best: ToolLight = _get_best_owned_light()
	if best == null:
		return
	var turn_on: bool = not GameState.is_tool_active(player_id, best.tool_id)
	for light in lights:
		var is_active: bool = GameState.is_tool_active(player_id, light.tool_id)
		var should_be_active: bool = turn_on and light == best
		if is_active != should_be_active:
			CommandService.dispatch(ToggleToolCommand.new(player_id, light.tool_id))

func _get_best_owned_light() -> ToolLight:
	for i in range(lights.size() - 1, -1, -1):
		if GameState.has_tool(player_id, lights[i].tool_id):
			return lights[i]
	return null
