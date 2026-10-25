@tool
class_name ItemDefinition
extends Resource

@export var id: StringName = &""
@export var display_name: String = ""
@export var world_scene: PackedScene
@export var sellable: bool = false:
	set(value):
		sellable = value
		notify_property_list_changed() # Refresh the inspector
@export var sell_value_stat: StatDefinition
@export var grants_tool: StringName = &"" ## If set, collecting this item gives the player this tool

func _validate_property(property: Dictionary) -> void:
	if property.name == "sell_value_stat" and not sellable:
		property.usage &= ~PROPERTY_USAGE_EDITOR

func can_be_sold() -> bool:
	return sellable and sell_value_stat != null and sell_value_stat.base_value > 0
