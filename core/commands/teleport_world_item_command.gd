class_name TeleportWorldItemCommand
extends Command

## Moves a world item to a new position. It is respawned there, so it gets a new entity id.

var entity_id: int = 0
var target_position: Vector3 = Vector3.ZERO

func _init(p_player_id: int = 1, p_entity_id: int = 0, p_target_position: Vector3 = Vector3.ZERO) -> void:
	super(p_player_id)
	entity_id = p_entity_id
	target_position = p_target_position

func execute() -> bool:
	var item: Dictionary = GameState.get_world_item(entity_id)
	if item.is_empty():
		return false # Already removed (zone can fire twice)
	GameState.remove_world_item(entity_id)
	GameState.spawn_world_item(item["item_id"], target_position)
	return true

func to_dict() -> Dictionary:
	var data: Dictionary = super.to_dict()
	data["type"] = "TeleportWorldItemCommand"
	data["entity_id"] = entity_id
	data["target_position"] = [target_position.x, target_position.y, target_position.z]
	return data

static func from_dict(data: Dictionary) -> TeleportWorldItemCommand:
	var p: Array = data.get("target_position", [0.0, 0.0, 0.0])
	var cmd: TeleportWorldItemCommand = TeleportWorldItemCommand.new(
		data.get("player_id", 1),
		data.get("entity_id", 0),
		Vector3(p[0], p[1], p[2])
	)
	cmd.timestamp = data.get("timestamp", 0)
	return cmd
