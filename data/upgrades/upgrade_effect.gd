class_name UpgradeEffect
extends Resource

## One stat modifier granted by an upgrade, applied once per purchased level.
## Final stat = (base + sum of ADD) * product of MULTIPLY.

enum Operation {
	ADD, ## value_per_level is added per level.
	MULTIPLY, ## value_per_level is multiplied per level (0.8 = -20% per level).
}

@export var stat: StatDefinition
@export var operation: Operation = Operation.ADD
@export var value_per_level: float = 1.0

func get_value(level: int) -> float:
	if operation == Operation.MULTIPLY:
		return pow(value_per_level, level)
	return value_per_level * level
