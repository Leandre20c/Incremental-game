class_name Harvestable
extends Interactable

@export var item_id: StringName = &"perch_fish"
@export var amount: int = 1
@export var spawn_point: Marker3D
@export var speed_stat_id: StringName = &""
@export var duration_stat: StatDefinition

func create_command(player_id: int) -> Command:
	var _position: Vector3 = spawn_point.global_position if spawn_point else get_prompt_position()
	return HarvestCommand.new(player_id, item_id, amount, _position)

func get_hold_duration() -> float:
	if duration_stat == null:
		return hold_duration
	return maxf(Stats.get_value(duration_stat), 0.05)
