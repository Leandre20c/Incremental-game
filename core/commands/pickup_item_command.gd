class_name PickupItemCommand
extends Command

var entity_id: int = 0

func _init(p_player_id: int = 1, p_entity_id: int = 0) -> void:
	super(p_player_id)
	entity_id = p_entity_id

func execute() -> bool:
	var item: Dictionary = GameState.get_world_item(entity_id)
	if item.is_empty() or not GameState.can_hold(player_id, item["item_id"]):
		return false
	GameState.remove_world_item(entity_id)
	GameState.add_to_hand(player_id, item["item_id"])
	return true

func to_dict() -> Dictionary:
	var data: Dictionary = super.to_dict()
	data["type"] = "PickupItemCommand"
	data["entity_id"] = entity_id
	return data

static func from_dict(data: Dictionary) -> PickupItemCommand:
	var cmd: PickupItemCommand = PickupItemCommand.new(data.get("player_id", 1), data.get("entity_id", 0))
	cmd.timestamp = data.get("timestamp", 0)
	return cmd
