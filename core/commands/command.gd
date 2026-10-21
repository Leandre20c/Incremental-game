class_name Command
extends RefCounted

var player_id: int = 1
var timestamp: int = 0

func _init(p_player_id: int = 1) -> void:
	player_id = p_player_id
	timestamp = Time.get_ticks_msec()

func execute() -> bool:
	# Virtual method to be overridden by subclasses
	return false

func to_dict() -> Dictionary:
	return {
		"type": "Command",
		"player_id": player_id,
		"timestamp": timestamp
	}

static func from_dict(data: Dictionary) -> Command:
	var cmd: Command = Command.new(data.get("player_id", 1))
	cmd.timestamp = data.get("timestamp", 0)
	return cmd
