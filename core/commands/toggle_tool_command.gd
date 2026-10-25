class_name ToggleToolCommand
extends Command

var tool_id: StringName = &""

func _init(p_player_id: int = 1, p_tool_id: StringName = &"") -> void:
	super(p_player_id)
	tool_id = p_tool_id

func execute() -> bool:
	if not GameState.has_tool(player_id, tool_id):
		return false
	return GameState.set_tool_active(player_id, tool_id, not GameState.is_tool_active(player_id, tool_id))

func to_dict() -> Dictionary:
	var data: Dictionary = super.to_dict()
	data["type"] = "ToggleToolCommand"
	data["tool_id"] = tool_id
	return data

static func from_dict(data: Dictionary) -> ToggleToolCommand:
	var cmd: ToggleToolCommand = ToggleToolCommand.new(data.get("player_id", 1), StringName(data.get("tool_id", "")))
	cmd.timestamp = data.get("timestamp", 0)
	return cmd
