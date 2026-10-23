class_name RespawnZone
extends Area3D

## Trigger volume that sends any player entering it back to a respawn point.
## Reusable for water, pits, out-of-bounds... Configure everything from the inspector.

@export var respawn_point: Node3D
@export_multiline var message: String = ""

@export_group("Penalty")
@export var penalty_resource_id: StringName = &"money"
@export_range(0, 1000000) var penalty_amount: int = 0

func _ready() -> void:
	monitorable = false
	body_entered.connect(_on_body_entered)
	if respawn_point == null:
		push_warning("RespawnZone '%s': no respawn_point assigned" % name)

func _on_body_entered(body: Node3D) -> void:
	var player: PlayerController = body as PlayerController
	if player == null or respawn_point == null:
		return

	CommandService.dispatch(RespawnPlayerCommand.new(
		player.player_id,
		respawn_point.global_position,
		penalty_resource_id,
		penalty_amount,
		message
	))
