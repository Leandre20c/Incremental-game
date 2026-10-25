class_name GrabItemCommand
extends Command

var entity_id: int = 0

func _init(p_player_id: int = 1, p_entity_id: int = 0) -> void:
	super(p_player_id)
	entity_id = p_entity_id

func execute() -> bool:
	return GameState.grab_item(player_id, entity_id)

func to_dict() -> Dictionary:
	var data: Dictionary = super.to_dict()
	data["type"] = "GrabItemCommand"
	data["entity_id"] = entity_id
	return data

static func from_dict(data: Dictionary) -> GrabItemCommand:
	var cmd: GrabItemCommand = GrabItemCommand.new(data.get("player_id", 1), data.get("entity_id", 0))
	cmd.timestamp = data.get("timestamp", 0)
	return cmd
