class_name ItemSpawnPoint
extends Marker3D

## Spawns an item at this position when the level starts.

@export var item_id: StringName = &""

func _ready() -> void:
	CommandService.dispatch(SpawnItemCommand.new(0, item_id, global_position))
