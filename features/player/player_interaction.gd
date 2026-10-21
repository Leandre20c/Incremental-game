class_name PlayerInteraction
extends RayCast3D

@export var player_id: int = 1 # Overridden by host/session in multiplayer later

func _physics_process(_delta: float) -> void:
	if not is_colliding():
		return

	var target: Object = get_collider()

	# Example: Left click to trigger manual harvest/farm
	if Input.is_action_just_pressed("interact_primary"):
		_handle_primary_interaction(target)

func _handle_primary_interaction(target: Object) -> void:
	if target.is_in_group("harvestable"):
		var target_id: String = target.get_meta("target_id", "default_node")
		
		#var cmd: HarvestCommand = HarvestCommand.new(player_id, target_id)
		#CommandService.dispatch(cmd)
