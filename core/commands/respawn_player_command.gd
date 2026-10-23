class_name RespawnPlayerCommand
extends Command

## Sends a player back to a respawn point, optionally with a currency penalty and a message.

var respawn_position: Vector3 = Vector3.ZERO
var penalty_resource_id: StringName = &"money"
var penalty_amount: int = 0
var message: String = ""

func _init(p_player_id: int = 1, p_respawn_position: Vector3 = Vector3.ZERO,
		p_penalty_resource_id: StringName = &"money", p_penalty_amount: int = 0,
		p_message: String = "") -> void:
	super(p_player_id)
	respawn_position = p_respawn_position
	penalty_resource_id = p_penalty_resource_id
	penalty_amount = p_penalty_amount
	message = p_message

func execute() -> bool:
	if penalty_amount > 0:
		# Never go below zero: lose what you have, up to the penalty
		var lost: int = mini(penalty_amount, GameState.get_amount(penalty_resource_id))
		if lost > 0:
			GameState.add_resource(penalty_resource_id, -lost)

	EventBus.player_respawned.emit(player_id, respawn_position)

	if not message.is_empty():
		EventBus.player_message.emit(player_id, message)
	return true

func to_dict() -> Dictionary:
	var data: Dictionary = super.to_dict()
	data["type"] = "RespawnPlayerCommand"
	data["respawn_position"] = [respawn_position.x, respawn_position.y, respawn_position.z]
	data["penalty_resource_id"] = String(penalty_resource_id)
	data["penalty_amount"] = penalty_amount
	data["message"] = message
	return data

static func from_dict(data: Dictionary) -> RespawnPlayerCommand:
	var p: Array = data.get("respawn_position", [0.0, 0.0, 0.0])
	var cmd: RespawnPlayerCommand = RespawnPlayerCommand.new(
		data.get("player_id", 1),
		Vector3(p[0], p[1], p[2]),
		StringName(data.get("penalty_resource_id", "money")),
		data.get("penalty_amount", 0),
		data.get("message", "")
	)
	cmd.timestamp = data.get("timestamp", 0)
	return cmd
