class_name ReleaseItemsCommand
extends Command

func execute() -> bool:
	return not GameState.release_all(player_id).is_empty()

func to_dict() -> Dictionary:
	var data: Dictionary = super.to_dict()
	data["type"] = "ReleaseItemsCommand"
	return data

static func from_dict(data: Dictionary) -> ReleaseItemsCommand:
	var cmd: ReleaseItemsCommand = ReleaseItemsCommand.new(data.get("player_id", 1))
	cmd.timestamp = data.get("timestamp", 0)
	return cmd
