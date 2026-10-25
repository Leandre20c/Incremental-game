class_name SellItemCommand
extends Command

## Sells a world item: removes it from the model and credits its sell value.

var entity_id: int = 0
var currency_id: StringName = &"money"

func _init(p_player_id: int = 1, p_entity_id: int = 0, p_currency_id: StringName = &"money") -> void:
	super(p_player_id)
	entity_id = p_entity_id
	currency_id = p_currency_id

func execute() -> bool:
	var item: Dictionary = GameState.get_world_item(entity_id)
	if item.is_empty():
		return false # Already sold or picked up (zone can fire twice)
	var item_id: StringName = item["item_id"]
	var definition: ItemDefinition = ItemDatabase.get_definition(item_id)
	if definition == null or not definition.can_be_sold():
		return false
	GameState.remove_world_item(entity_id)
	GameState.add_resource(currency_id, definition.sell_value)
	EventBus.item_sold.emit(player_id, item_id, definition.sell_value)
	return true

func to_dict() -> Dictionary:
	var data: Dictionary = super.to_dict()
	data["type"] = "SellItemCommand"
	data["entity_id"] = entity_id
	data["currency_id"] = String(currency_id)
	return data

static func from_dict(data: Dictionary) -> SellItemCommand:
	var cmd: SellItemCommand = SellItemCommand.new(
		data.get("player_id", 1),
		data.get("entity_id", 0),
		StringName(data.get("currency_id", "money"))
	)
	cmd.timestamp = data.get("timestamp", 0)
	return cmd
