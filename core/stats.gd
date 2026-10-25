extends Node

## Derived, shared stat values computed from GameState upgrade levels.
## Never serialized: always rebuilt from the model, so every peer gets the same values.

var _add: Dictionary[StringName, float] = {}
var _multiply: Dictionary[StringName, float] = {}

func _ready() -> void:
	EventBus.upgrade_level_changed.connect(_on_upgrade_level_changed)
	_rebuild()

## Current value: (base + flat bonuses) * multipliers.
func get_value(stat: StatDefinition) -> float:
	return (stat.base_value + _add.get(stat.id, 0.0)) * _multiply.get(stat.id, 1.0)

## Value if `upgrade_id` were at `level`. Used for UI previews only.
func preview(stat: StatDefinition, upgrade_id: StringName, level: int) -> float:
	var add: float = _add.get(stat.id, 0.0)
	var multiply: float = _multiply.get(stat.id, 1.0)
	var definition: UpgradeDefinition = UpgradeDatabase.get_definition(upgrade_id)
	var current_level: int = GameState.get_upgrade_level(upgrade_id)
	for effect in definition.effects:
		if effect == null or effect.stat == null or effect.stat.id != stat.id:
			continue
		# Swap the current level's contribution for the previewed one
		if effect.operation == UpgradeEffect.Operation.MULTIPLY:
			var current: float = effect.get_value(current_level)
			if not is_zero_approx(current):
				multiply = multiply / current * effect.get_value(level)
		else:
			add += effect.get_value(level) - effect.get_value(current_level)
	return (stat.base_value + add) * multiply

func _on_upgrade_level_changed(_upgrade_id: StringName, _level: int) -> void:
	_rebuild()

func _rebuild() -> void:
	_add.clear()
	_multiply.clear()
	for definition in UpgradeDatabase.get_all():
		var level: int = GameState.get_upgrade_level(definition.id)
		if level == 0:
			continue
		for effect in definition.effects:
			if effect == null or effect.stat == null:
				continue
			var stat_id: StringName = effect.stat.id
			var value: float = effect.get_value(level)
			if effect.operation == UpgradeEffect.Operation.MULTIPLY:
				_multiply[stat_id] = _multiply.get(stat_id, 1.0) * value
			else:
				_add[stat_id] = _add.get(stat_id, 0.0) + value
