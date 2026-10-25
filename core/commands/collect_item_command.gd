class_name CollectItemCommand
extends Command

var entity_id: int = 0

func _init(p_player_id: int = 1, p_entity_id: int = 0) -> void:
	super(p_player_id)
	entity_id = p_entity_id

func execute() -> bool:
	var item: Dictionary = GameState.get_world_item(entity_id)
	if item.is_empty() or item["holder"] != 0:
		return false
	var definition: ItemDefinition = ItemDatabase.get_definition(item["item_id"])
	if definition == null or definition.grants_tool.is_empty():
		return false
	if GameState.has_tool(player_id, definition.grants_tool):
		return false
	GameState.remove_world_item(entity_id)
	GameState.grant_tool(player_id, definition.grants_tool)
	return true

func to_dict() -> Dictionary:
	var data: Dictionary = super.to_dict()
	data["type"] = "CollectItemCommand"
	data["entity_id"] = entity_id
	return data

static func from_dict(data: Dictionary) -> CollectItemCommand:
	var cmd: CollectItemCommand = CollectItemCommand.new(data.get("player_id", 1), data.get("entity_id", 0))
	cmd.timestamp = data.get("timestamp", 0)
	return cmd
