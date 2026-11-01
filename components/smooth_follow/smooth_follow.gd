class_name SmoothFollow
extends Node3D

## Follows its parent's rotation with a slight delay, like an object held in hand.

@export var follow_speed: float = 12.0 ## Higher = tighter follow

var _target: Node3D

func _ready() -> void:
	_target = get_parent() as Node3D
	top_level = true # Detach from parent transform, we follow it manually
	global_transform = _target.global_transform

func _process(delta: float) -> void:
	var weight: float = 1.0 - exp(-follow_speed * delta)
	var target_basis: Basis = _target.global_basis
	global_basis = global_basis.slerp(target_basis, weight).orthonormalized()
	global_position = _target.global_position
