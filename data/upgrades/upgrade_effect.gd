@tool
class_name UpgradeEffect
extends Resource

## One stat modifier granted by an upgrade, applied once per purchased level.
## Final stat = (base + sum of ADD) * product of MULTIPLY.

enum Operation {
	ADD, ## value_per_level is added per level.
	MULTIPLY, ## value_per_level is multiplied per level (1.1 = +10% per level).
}

@export var stat_id: StringName = &""
@export var operation: Operation = Operation.ADD
@export var value_per_level: float = 1.0

func get_value(level: int) -> float:
	if operation == Operation.MULTIPLY:
		return pow(value_per_level, level)
	return value_per_level * level

func _validate_property(property: Dictionary) -> void:
	if property.name == "stat_id":
		# Suggest known stats in the inspector while still allowing new ones
		property.hint = PROPERTY_HINT_ENUM_SUGGESTION
		property.hint_string = ",".join(PackedStringArray(StatIds.ALL))
