class_name BuyUpgradeCommand
extends Command

## Buys the next level of a shared upgrade with the shared currency.

var upgrade_id: StringName = &""

func _init(p_player_id: int = 1, p_upgrade_id: StringName = &"") -> void:
	super(p_player_id)
	upgrade_id = p_upgrade_id

func execute() -> bool:
	var definition: UpgradeDefinition = UpgradeDatabase.get_definition(upgrade_id)
	if definition == null:
		push_warning("BuyUpgradeCommand: unknown upgrade '%s'" % upgrade_id)
		return false
	var level: int = GameState.get_upgrade_level(upgrade_id)
	if definition.is_maxed(level):
		return false
	if not GameState.try_spend(definition.cost_resource_id, definition.get_cost(level)):
		return false # Not enough money, or another player bought first
	GameState.set_upgrade_level(upgrade_id, level + 1)
	EventBus.upgrade_purchased.emit(player_id, upgrade_id, level + 1)
	return true

func to_dict() -> Dictionary:
	var data: Dictionary = super.to_dict()
	data["type"] = "BuyUpgradeCommand"
	data["upgrade_id"] = String(upgrade_id)
	return data

static func from_dict(data: Dictionary) -> BuyUpgradeCommand:
	var cmd: BuyUpgradeCommand = BuyUpgradeCommand.new(
		data.get("player_id", 1),
		StringName(data.get("upgrade_id", ""))
	)
	cmd.timestamp = data.get("timestamp", 0)
	return cmd
