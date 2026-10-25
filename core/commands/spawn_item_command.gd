class_name SpawnItemCommand
extends Command

var item_id: StringName = &""
var spawn_position: Vector3 = Vector3.ZERO

func _init(p_player_id: int = 0, p_item_id: StringName = &"", p_spawn_position: Vector3 = Vector3.ZERO) -> void:
	super(p_player_id)
	item_id = p_item_id
	spawn_position = p_spawn_position

func execute() -> bool:
	if ItemDatabase.get_definition(item_id) == null:
		return false
	GameState.spawn_world_item(item_id, spawn_position)
	return true

func to_dict() -> Dictionary:
	var data: Dictionary = super.to_dict()
	data["type"] = "SpawnItemCommand"
	data["item_id"] = item_id
	data["spawn_position"] = [spawn_position.x, spawn_position.y, spawn_position.z]
	return data

static func from_dict(data: Dictionary) -> SpawnItemCommand:
	var p: Array = data.get("spawn_position", [0.0, 0.0, 0.0])
	var cmd: SpawnItemCommand = SpawnItemCommand.new(
		data.get("player_id", 0), StringName(data.get("item_id", "")), Vector3(p[0], p[1], p[2])
	)
	cmd.timestamp = data.get("timestamp", 0)
	return cmd
