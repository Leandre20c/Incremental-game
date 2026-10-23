class_name Harvestable
extends Interactable

@export var item_id: StringName = &"perch_fish"
@export var amount: int = 1
@export var spawn_point: Marker3D

func create_command(player_id: int) -> Command:
	var _position: Vector3 = spawn_point.global_position if spawn_point else get_prompt_position()
	return HarvestCommand.new(player_id, item_id, amount, _position)
