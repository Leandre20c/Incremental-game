class_name ToolLight
extends Light3D

## Shows a light while the given tool is active. Also handles its toggle input.

@export var player_id: int = 1
@export var tool_id: StringName = &"lighter"
@export var toggle_action: StringName = &"toggle_lighter"

@export_group("Flicker")
@export var flicker_amount: float = 0.15 ## 0 = steady light
@export var flicker_speed: float = 12.0

var _base_energy: float
var _noise: FastNoiseLite = FastNoiseLite.new()
var _time: float = 0.0

func _ready() -> void:
	_base_energy = light_energy
	visible = GameState.is_tool_active(player_id, tool_id)
	EventBus.tool_toggled.connect(_on_tool_toggled)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(toggle_action):
		CommandService.dispatch(ToggleToolCommand.new(player_id, tool_id))

func _process(delta: float) -> void:
	if not visible or flicker_amount <= 0.0:
		return
	_time += delta * flicker_speed
	light_energy = _base_energy * (1.0 + _noise.get_noise_1d(_time) * abs(flicker_amount))

func _on_tool_toggled(toggled_player_id: int, toggled_tool_id: StringName, active: bool) -> void:
	if toggled_player_id == player_id and toggled_tool_id == tool_id:
		visible = active
