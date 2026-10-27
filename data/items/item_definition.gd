@tool
class_name ItemDefinition
extends Resource

@export var id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = "" ## Shown in the buy menu. Empty = hidden
@export var icon: Texture2D
@export var world_scene: PackedScene
@export var sellable: bool = false:
	set(value):
		sellable = value
		notify_property_list_changed() # Refresh the inspector
@export var sell_value_stat: StatDefinition
@export var grants_tool: StringName = &"" ## If set, collecting this item gives the player this tool

@export_group("Placement")
@export var placeable: bool = false: ## Can be anchored in place by the player
	set(value):
		placeable = value
		notify_property_list_changed()

@export_group("Grid")
@export var snaps_to_grid: bool = false: ## Snaps on the build grid while held (grid key toggles it). For floors, walls, roofs…
	set(value):
		snaps_to_grid = value
		notify_property_list_changed()
@export var grid_thickness: float = 0.05 ## Size along its local Y: it rests on the grid plane instead of crossing it

@export_group("Power")
@export_range(0, 10) var max_power_levels: int = 0 ## 0 = no power settings. Levels shown in the machine menu
@export var unlocked_power_levels_stat: StatDefinition ## Upgradable number of usable levels. Empty = all of them
@export var starts_powered: bool = true ## Switched on when it appears in the world (bought, spawned, placed in the level)

@export_group("Shop")
@export var buyable: bool = false: ## Listed in the buy menu
	set(value):
		buyable = value
		notify_property_list_changed()
@export var buy_cost: int = 50
@export var buy_cost_resource_id: StringName = &"money"

func _validate_property(property: Dictionary) -> void:
	if property.name == "sell_value_stat" and not sellable:
		property.usage &= ~PROPERTY_USAGE_EDITOR
	if property.name == "snaps_to_grid" and not placeable:
		property.usage &= ~PROPERTY_USAGE_EDITOR
	if property.name == "grid_thickness" and not (placeable and snaps_to_grid):
		property.usage &= ~PROPERTY_USAGE_EDITOR
	if property.name in ["buy_cost", "buy_cost_resource_id"] and not buyable:
		property.usage &= ~PROPERTY_USAGE_EDITOR
	if property.name in ["max_power_levels", "unlocked_power_levels_stat", "starts_powered"] and not placeable:
		property.usage &= ~PROPERTY_USAGE_EDITOR

func can_be_sold() -> bool:
	return sellable and sell_value_stat != null and sell_value_stat.base_value > 0

func has_power_settings() -> bool:
	return max_power_levels > 0

## Levels the players can currently pick (1 at least).
func get_unlocked_power_levels() -> int:
	if unlocked_power_levels_stat == null:
		return max_power_levels
	return clampi(int(Stats.get_value(unlocked_power_levels_stat)), 1, max_power_levels)
