class_name SetPowerCommand
extends Command

## Switches a machine item on/off and sets its intensity level.
## Allowed on a free or placed machine, or on one the same player is carrying.

var entity_id: int = -1
var powered: bool = true
var level: int = 1

func _init(p_player_id: int = 1, p_entity_id: int = -1, p_powered: bool = true, p_level: int = 1) -> void:
	super(p_player_id)
	entity_id = p_entity_id
	powered = p_powered
	level = p_level

func execute() -> bool:
	var item: Dictionary = GameState.get_world_item(entity_id)
	if item.is_empty():
		return false
	if item["holder"] != 0 and item["holder"] != player_id:
		return false # Carried by someone else
	var definition: ItemDefinition = ItemDatabase.get_definition(item["item_id"])
	if definition == null:
		return false
	var max_level: int = definition.get_unlocked_power_levels() if definition.has_power_settings() else 1
	if level < 1 or level > max_level:
		return false # Locked level: the menu should not allow it, the host checks anyway
	return GameState.set_power(entity_id, powered, level)

func to_dict() -> Dictionary:
	var data: Dictionary = super.to_dict()
	data["type"] = "SetPowerCommand"
	data["entity_id"] = entity_id
	data["powered"] = powered
	data["level"] = level
	return data

static func from_dict(data: Dictionary) -> SetPowerCommand:
	var cmd: SetPowerCommand = SetPowerCommand.new(
		data.get("player_id", 1), int(data.get("entity_id", -1)),
		bool(data.get("powered", true)), int(data.get("level", 1))
	)
	cmd.timestamp = data.get("timestamp", 0)
	return cmd
