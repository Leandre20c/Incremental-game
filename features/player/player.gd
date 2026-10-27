class_name PlayerController
extends CharacterBody3D

@export var grabber: PlayerGrabber

@export var player_id: int = 1 # Overridden by host/session in multiplayer later
@export var move_speed: float = 5.0
@export var sprint_speed: float = 8.0
@export var jump_velocity: float = 4.5
@export var mouse_sensitivity: float = 0.002
@export var launch_recovery_time: float = 0.8 ## Seconds to smoothly get full movement control back after a launch

@export_group("World pushes")
@export var push_mass: float = 3.0 ## How heavy the player feels to pushes (wind…). Higher = pushed less
@export var push_damping: float = 3.0 ## How fast a push fades once it stops (1/s)

@onready var camera_pivot: Node3D = $CameraPivot


var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _since_launch: float = INF ## Seconds since the last launch. INF = full control
var _push_velocity: Vector3 = Vector3.ZERO ## Horizontal velocity given by the world (wind…), fades out
var _applied_push: Vector3 = Vector3.ZERO ## Part of `velocity` that came from _push_velocity last frame

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	EventBus.player_respawned.connect(_on_player_respawned)

## Throws the player with an external velocity (trampoline, explosion…).
## Movement control then comes back progressively, so the impulse is not cancelled right away.
func launch(launch_velocity: Vector3) -> void:
	velocity = launch_velocity
	_since_launch = 0.0

## Continuous push from the world (wind…), called every physics frame while it lasts.
## Added on top of the player's own movement, so walking still works against or with it.
func push(acceleration: Vector3, delta: float) -> void:
	_push_velocity += Vector3(acceleration.x, 0.0, acceleration.z) * delta
	velocity.y += acceleration.y * delta # Vertical: like gravity, it builds up on its own

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		camera_pivot.rotate_x(-event.relative.y * mouse_sensitivity)
		camera_pivot.rotation.x = clamp(camera_pivot.rotation.x, deg_to_rad(-89.0), deg_to_rad(89.0))

func _physics_process(delta: float) -> void:
	# Work on the player's own velocity: the push is added back right before moving
	velocity -= _applied_push
	_applied_push = Vector3.ZERO
	_push_velocity = _push_velocity.lerp(Vector3.ZERO, clampf(push_damping * delta, 0.0, 1.0))

	_since_launch += delta

	if not is_on_floor():
		velocity.y -= gravity * delta
	elif velocity.y <= 0.0:
		_since_launch = INF # Landed: full control right away, no sliding
		
	var can_control: bool = Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	if !can_control:
		return
	
	if grabber and grabber.is_rotating():
		return

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction: Vector3 = (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()
	var current_speed: float = sprint_speed if Input.is_action_pressed("sprint") else move_speed
	var control: float = _get_control()

	if control < 1.0:
		# Recovering from a launch: steer toward the wanted velocity, gently at first
		var horizontal: Vector2 = Vector2(velocity.x, velocity.z)
		var target: Vector2 = Vector2(direction.x, direction.z) * current_speed
		horizontal = horizontal.move_toward(target, current_speed * control)
		velocity.x = horizontal.x
		velocity.z = horizontal.y
	elif direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, current_speed)
		velocity.z = move_toward(velocity.z, 0.0, current_speed)

	_applied_push = _push_velocity
	velocity += _applied_push
	move_and_slide()

## 0 right after a launch, eases up to 1 (full control) over launch_recovery_time.
func _get_control() -> float:
	if launch_recovery_time <= 0.0:
		return 1.0
	var t: float = clampf(_since_launch / launch_recovery_time, 0.0, 1.0)
	return t * t # Slow start, then faster: the impulse lasts, control still comes back smoothly

func _on_player_respawned(target_player_id: int, target_position: Vector3) -> void:
	if target_player_id != player_id:
		return
	global_position = target_position
	velocity = Vector3.ZERO
	_since_launch = INF
	_push_velocity = Vector3.ZERO
	_applied_push = Vector3.ZERO
	reset_physics_interpolation()
