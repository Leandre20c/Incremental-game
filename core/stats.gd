extends Node

## Derived, shared stat modifiers computed from GameState upgrade levels.
## Never serialized: always rebuilt from the model, so every peer gets the same values.

var _add: Dictionary[StringName, float] = {}
var _multiply: Dictionary[StringName, float] = {}

func _ready() -> void:
	EventBus.upgrade_level_changed.connect(_on_upgrade_level_changed)
	_rebuild()

## (base + flat bonuses) * multipliers.
func apply(stat_id: StringName, base: float) -> float:
	return (base + _add.get(stat_id, 0.0)) * _multiply.get(stat_id, 1.0)

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
			if effect == null:
				continue
			var value: float = effect.get_value(level)
			if effect.operation == UpgradeEffect.Operation.MULTIPLY:
				_multiply[effect.stat_id] = _multiply.get(effect.stat_id, 1.0) * value
			else:
				_add[effect.stat_id] = _add.get(effect.stat_id, 0.0) + value
