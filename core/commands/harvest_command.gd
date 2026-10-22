class_name HarvestCommand
extends Command

var item_id: StringName = &""
var amount: int = 1
var spawn_position: Vector3 = Vector3.ZERO

func _init(p_player_id: int = 1, p_item_id: StringName = &"", p_amount: int = 1,
		p_spawn_position: Vector3 = Vector3.ZERO) -> void:
	super(p_player_id)
	item_id = p_item_id
	amount = p_amount
	spawn_position = p_spawn_position

func execute() -> bool:
	if amount <= 0 or ItemDatabase.get_definition(item_id) == null:
		return false
	for i in amount:
		GameState.spawn_world_item(item_id, spawn_position)
	EventBus.harvested.emit(player_id, item_id, amount)
	return true

func to_dict() -> Dictionary:
	var data: Dictionary = super.to_dict()
	data["type"] = "HarvestCommand"
	data["item_id"] = item_id
	data["amount"] = amount
	data["spawn_position"] = [spawn_position.x, spawn_position.y, spawn_position.z]
	return data

static func from_dict(data: Dictionary) -> HarvestCommand:
	var p: Array = data.get("spawn_position", [0.0, 0.0, 0.0])
	var cmd: HarvestCommand = HarvestCommand.new(
		data.get("player_id", 1),
		StringName(data.get("item_id", "")),
		data.get("amount", 1),
		Vector3(p[0], p[1], p[2])
	)
	cmd.timestamp = data.get("timestamp", 0)
	return cmd
