class_name BuyItemCommand
extends Command

## Buys an item from the shop: pays its price and delivers it at the given position.

var item_id: StringName = &""
var delivery_position: Vector3 = Vector3.ZERO

func _init(p_player_id: int = 1, p_item_id: StringName = &"", p_delivery_position: Vector3 = Vector3.ZERO) -> void:
	super(p_player_id)
	item_id = p_item_id
	delivery_position = p_delivery_position

func execute() -> bool:
	var definition: ItemDefinition = ItemDatabase.get_definition(item_id)
	if definition == null or not definition.buyable or definition.world_scene == null:
		return false
	if not GameState.try_spend(definition.buy_cost_resource_id, definition.buy_cost):
		return false # Not enough money, or another player spent it first
	var entity_id: int = GameState.spawn_world_item(item_id, delivery_position)
	EventBus.item_bought.emit(player_id, item_id, entity_id)
	return true

func to_dict() -> Dictionary:
	var data: Dictionary = super.to_dict()
	data["type"] = "BuyItemCommand"
	data["item_id"] = String(item_id)
	data["delivery_position"] = [delivery_position.x, delivery_position.y, delivery_position.z]
	return data

static func from_dict(data: Dictionary) -> BuyItemCommand:
	var p: Array = data.get("delivery_position", [0.0, 0.0, 0.0])
	var cmd: BuyItemCommand = BuyItemCommand.new(
		data.get("player_id", 1), StringName(data.get("item_id", "")), Vector3(p[0], p[1], p[2])
	)
	cmd.timestamp = data.get("timestamp", 0)
	return cmd
