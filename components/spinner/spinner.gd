class_name Spinner
extends Node

## Drives a looping animation (e.g. fan blades) from the machine's power,
## with a smooth spin-up and spin-down.
## Connect Powerable.power_changed to set_power(), or any bool signal to set_active().

@export var animation_player: AnimationPlayer
@export var animation_name: StringName = &"spinning"
@export var acceleration: float = 1.5 ## Speed scale gained or lost per second (spin-up / spin-down)

var _target_scale: float = 0.0
var _current_scale: float = 0.0

func _ready() -> void:
	assert(animation_player != null, "Spinner needs an AnimationPlayer")
	animation_player.play(animation_name)
	animation_player.speed_scale = 0.0 # Starts still, set_power() spins it up

func set_active(value: bool) -> void:
	_target_scale = 1.0 if value else 0.0

## 0 = stopped, 1 = normal speed, 1.5 = 50% faster…
func set_power(value: float) -> void:
	_target_scale = maxf(value, 0.0)

func _process(delta: float) -> void:
	_current_scale = move_toward(_current_scale, _target_scale, acceleration * delta)
	animation_player.speed_scale = _current_scale
