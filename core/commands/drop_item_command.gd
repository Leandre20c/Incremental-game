class_name DropItemCommand
extends Command

var drop_position: Vector3 = Vector3.ZERO

func _init(p_player_id: int = 1, p_drop_position: Vector3 = Vector3.ZERO) -> void:
	super(p_player_id)
	drop_position = p_drop_position

func execute() -> bool:
	var item_id: StringName = GameState.remove_from_hand(player_id)
	if item_id.is_empty():
		return false
	GameState.spawn_world_item(item_id, drop_position)
	return true

func to_dict() -> Dictionary:
	var data: Dictionary = super.to_dict()
	data["type"] = "DropItemCommand"
	data["drop_position"] = [drop_position.x, drop_position.y, drop_position.z]
	return data

static func from_dict(data: Dictionary) -> DropItemCommand:
	var p: Array = data.get("drop_position", [0.0, 0.0, 0.0])
	var cmd: DropItemCommand = DropItemCommand.new(data.get("player_id", 1), Vector3(p[0], p[1], p[2]))
	cmd.timestamp = data.get("timestamp", 0)
	return cmd
