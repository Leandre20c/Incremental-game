class_name UpgradeDefinition
extends Resource

## Static data of one shared upgrade. Purchased levels will live in GameState, never here.

@export var id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""

@export_group("Cost")
@export var cost_resource_id: StringName = &"money"
@export var base_cost: int = 10
## Cost multiplier applied per level already owned.
@export var cost_growth: float = 1.5
## 0 = unlimited.
@export var max_level: int = 1

@export_group("Preview")
## Stat shown as "current -> next" in menus. Empty = no preview.
@export var preview_stat: StatDefinition


@export_group("Effects")
@export var effects: Array[UpgradeEffect] = []

## Cost of buying the level after `current_level`.
func get_cost(current_level: int) -> int:
	return roundi(base_cost * pow(cost_growth, current_level))

func is_maxed(current_level: int) -> bool:
	return max_level > 0 and current_level >= max_level
