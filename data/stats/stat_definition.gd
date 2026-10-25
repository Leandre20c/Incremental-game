class_name StatDefinition
extends Resource

## A shared stat that upgrades can modify. Holds its base value so it lives in one place.

@export var id: StringName = &""
@export var display_name: String = ""
@export var base_value: float = 1.0
## Printf format for UI, e.g. "%.1fs".
@export var display_format: String = "%.2f"
