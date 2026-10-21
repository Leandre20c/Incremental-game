class_name HarvestCommand
extends Command

var target_id: String = ""
var amount: int = 1

func _init(p_player_id: int = 1, p_target_id: String = "", p_amount: int = 1) -> void:
	super(p_player_id)
	target_id = p_target_id
	amount = p_amount


func execute() -> bool:
	if target_id.is_empty():
		return false
	
	# Future step: forward to GameState (e.g. GameState.add_resource(target_id, amount))
	print("[HarvestCommand] Player %d harvested %d of '%s'" % [player_id, amount, target_id])
	return true

func to_dict() -> Dictionary:
	var data: Dictionary = super.to_dict()
	data["type"] = "HarvestCommand"
	data["target_id"] = target_id
	data["amount"] = amount
	return data

static func from_dict(data: Dictionary) -> HarvestCommand:
	var cmd: HarvestCommand = HarvestCommand.new(
		data.get("player_id", 1),
		data.get("target_id", ""),
		data.get("amount", 1)
	)
	cmd.timestamp = data.get("timestamp", 0)
	return cmd
