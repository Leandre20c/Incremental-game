class_name PlayerGrabber
extends Node

## Physically drags grabbed items toward the hold point.
## Release throws items with the hold point's recent velocity (camera / player motion).
## Hold "rotate_held" + move the mouse to rotate held items, "reset_held_rotation" to face them back.

@export var player_id: int = 1
@export var interaction: PlayerInteraction
@export var hold_point: Marker3D ## Child of the interaction ray, moved along its -Z axis

@export_group("Follow")
@export var follow_frequency: float = 12.0 ## Spring stiffness. Lower = more elastic, higher = stiffer (keep under ~25)
@export var max_speed: float = 30.0 ## Caps follow and throw speed
@export var max_grab_force: float = 60.0 ## Max push force (N), only while touching an obstacle
@export var stack_spacing: float = 0.2 ## Vertical spacing when holding several items

@export_group("Throw")
@export var throw_multiplier: float = 1.0 ## Extra boost on release
@export var throw_window: float = 0.1 ## Seconds of hold point motion considered for the throw
@export var throw_reference_mass: float = 1.0 ## Objets plus légers ou égaux = vitesse de lancer complète
@export_range(0.0, 1.0) var throw_mass_falloff: float = 0.5 ## 1 = réaliste (v ∝ 1/masse), 0.5 = plus doux, 0 = désactivé
@export_range(0.0, 1.0) var min_throw_factor: float = 0.15 ## Même les objets très lourds gardent au moins ça

@export_group("Rotation")
@export var rotation_strength: float = 10.0 ## How fast items turn toward their target orientation
@export var rotate_sensitivity: float = 0.005 ## Radians per mouse pixel
@export var rotate_with_camera: bool = false

@export_group("Obstacles")
@export_flags_3d_physics var obstacle_mask: int = 1 ## Layers that count as obstacles (NOT the items layer)
@export var wall_margin: float = 1.5 ## Distance kept in front of an obstacle
@export var min_hold_distance: float = 0.5 ## Never closer than this to the camera

@export_group("Breaking")
@export var break_distance: float = 1.0 ## Release if this far from the hold point WHILE touching an obstacle
@export var max_lag_distance: float = 3.0 ## Release if this far from the hold point, no matter what

var _held: Array[RigidBody3D] = []
var _release_requested: bool = false
var _hold_distance: float = 0.0
var _last_hold_position: Vector3 = Vector3.ZERO

var _hold_velocity_history: Array[Vector3] = []
var _throw_on_release: bool = false
var _throw_velocity: Vector3 = Vector3.ZERO

var _rotating: bool = false
var _last_yaw_basis: Basis = Basis.IDENTITY

var _target_basis: Basis = Basis.IDENTITY ## Orientation voulue, en coordonnées monde
var _prev_yaw_basis: Basis = Basis.IDENTITY ## Cap caméra à la frame précédente


func _ready() -> void:
	assert(hold_point != null, "PlayerGrabber needs a hold_point Marker3D")
	assert(interaction != null, "PlayerGrabber needs a PlayerInteraction")
	EventBus.item_grabbed.connect(_on_item_grabbed)
	EventBus.items_released.connect(_on_items_released)


func is_rotating() -> bool:
	return _rotating


# --- Input -----------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("drop") and not _held.is_empty():
		_request_release(true)
		return

	if _held.is_empty():
		_rotating = false
		return

	if event.is_action_pressed("rotate_held"):
		_rotating = true
	elif event.is_action_released("rotate_held"):
		_rotating = false
	elif event.is_action_pressed("reset_held_rotation"):
		_target_basis = _camera_yaw_basis()
	elif _rotating and event is InputEventMouseMotion:
		_rotate_target(event.relative)
		get_viewport().set_input_as_handled()


func _rotate_target(mouse_delta: Vector2) -> void:
	var yaw := Basis(Vector3.UP, -mouse_delta.x * rotate_sensitivity)
	if _held_is_upright():
		_target_basis = (yaw * _target_basis).orthonormalized() # Flat rotation only
	else:
		var right: Vector3 = _camera_yaw_basis().x
		var pitch := Basis(right, -mouse_delta.y * rotate_sensitivity)
		_target_basis = (yaw * pitch * _target_basis).orthonormalized()


# --- Physics ---------------------------------------------------------------

func _physics_process(delta: float) -> void:
	_held = _held.filter(func(body: RigidBody3D) -> bool: return is_instance_valid(body))
	if _held.is_empty():
		return
	if _release_requested:
		return # Stop pulling while the release command is in flight

	_pull_hold_point_from_obstacles()

	# Feed-forward: items move with the hold point, the spring only corrects the gap
	var hold_velocity: Vector3 = (hold_point.global_position - _last_hold_position) / delta
	_last_hold_position = hold_point.global_position
	_record_hold_velocity(hold_velocity, delta)

	var yaw_now: Basis = _camera_yaw_basis()
	if rotate_with_camera:
		# Apply only how much the camera turned since last frame
		_target_basis = (yaw_now * _prev_yaw_basis.inverse() * _target_basis).orthonormalized()
	_prev_yaw_basis = yaw_now
	var omega: float = follow_frequency

	for i in _held.size():
		var body: RigidBody3D = _held[i]
		var target: Vector3 = hold_point.global_position + hold_point.global_basis.y * stack_spacing * i
		var to_target: Vector3 = target - body.global_position
		var distance: float = to_target.length()
		var touching: bool = _is_touching_obstacle(body)

		if (distance > break_distance and touching) or distance > max_lag_distance:
			_request_release(false)
			return

		# Critically damped spring: elastic, but never overshoots
		var accel: Vector3 = to_target * omega * omega + (hold_velocity - body.linear_velocity) * 2.0 * omega
		var delta_v: Vector3 = accel * delta
		if touching:
			# Bounded force: the held item can never crush other bodies through the floor
			delta_v = delta_v.limit_length(max_grab_force / body.mass * delta)
		body.linear_velocity = (body.linear_velocity + delta_v).limit_length(max_speed)

		_align_to(body, _target_basis)


## If an obstacle is between the camera and the hold point, bring the hold point closer.
## The distance only ever shrinks while holding: it never goes back out.
func _pull_hold_point_from_obstacles() -> void:
	var origin: Vector3 = interaction.global_position
	var direction: Vector3 = -interaction.global_basis.z

	var excluded: Array[RID] = []
	for body in _held:
		excluded.append(body.get_rid())

	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
		origin, origin + direction * _hold_distance, obstacle_mask, excluded
	)
	var hit: Dictionary = interaction.get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		var hit_distance: float = origin.distance_to(hit["position"]) - wall_margin
		_hold_distance = maxf(min_hold_distance, minf(_hold_distance, hit_distance))

	hold_point.position.z = -_hold_distance


## Only real obstacles count, not the items sitting inside a held box.
func _is_touching_obstacle(body: RigidBody3D) -> bool:
	for other in body.get_colliding_bodies():
		if other is CollisionObject3D and (other.collision_layer & obstacle_mask) != 0:
			return true
	return false


# --- Rotation --------------------------------------------------------------
## Same heading as the given basis, but perfectly flat (no tilt).
func _flat_basis(b: Basis) -> Basis:
	var forward: Vector3 = -b.z
	forward.y = 0.0
	if forward.length_squared() < 0.001:
		return _camera_yaw_basis() # Item was standing on its side: face the camera instead
	return Basis.looking_at(forward.normalized(), Vector3.UP)
	
## Camera heading flattened on the ground: items turn with you but don't tilt when you look up/down.
func _camera_yaw_basis() -> Basis:
	var forward: Vector3 = -interaction.global_basis.z
	forward.y = 0.0
	if forward.length_squared() > 0.001:
		_last_yaw_basis = Basis.looking_at(forward.normalized(), Vector3.UP)
	return _last_yaw_basis # Looking straight up/down: keep the last known heading


func _align_to(body: RigidBody3D, target: Basis) -> void:
	var diff: Quaternion = (target * body.global_basis.orthonormalized().inverse()).get_rotation_quaternion()
	if diff.w < 0.0:
		diff = -diff # Take the short way around
	var angle: float = diff.get_angle()
	if angle < 0.001:
		body.angular_velocity = Vector3.ZERO
		return
	body.angular_velocity = diff.get_axis() * angle * rotation_strength


func _held_is_upright() -> bool:
	return not _held.is_empty() and _held[0].is_in_group(&"hold_upright")


# --- Throw -----------------------------------------------------------------

func _record_hold_velocity(v: Vector3, delta: float) -> void:
	_hold_velocity_history.push_back(v)
	var max_samples: int = maxi(1, int(throw_window / delta))
	while _hold_velocity_history.size() > max_samples:
		_hold_velocity_history.pop_front()


func _peak_hold_velocity() -> Vector3:
	var best := Vector3.ZERO
	for v in _hold_velocity_history:
		if v.length_squared() > best.length_squared():
			best = v
	return best


func _request_release(is_throw: bool) -> void:
	if _release_requested:
		return
	_release_requested = true
	# Snapshot NOW, not when the command is processed
	_throw_on_release = is_throw
	_throw_velocity = _peak_hold_velocity()
	CommandService.dispatch(ReleaseItemsCommand.new(player_id))


# --- Events ----------------------------------------------------------------

func _on_item_grabbed(grabber_id: int, entity_id: int) -> void:
	if grabber_id != player_id:
		return
	var body: RigidBody3D = _get_body(entity_id)
	if body == null:
		return

	# First item: hold it where it was grabbed, with its current orientation
	if _held.is_empty():
		_hold_distance = maxf(min_hold_distance, interaction.global_position.distance_to(body.global_position))
		hold_point.position.z = -_hold_distance
		_last_hold_position = hold_point.global_position # Avoid a velocity spike on the first frame
		_hold_velocity_history.clear()
		_prev_yaw_basis = _camera_yaw_basis()
		if body.is_in_group(&"hold_upright"):
			_target_basis = _flat_basis(body.global_basis)
		else:
			_target_basis = body.global_basis.orthonormalized()

	body.gravity_scale = 0.0
	body.sleeping = false
	body.continuous_cd = true # Prevents tunneling at high speed
	body.contact_monitor = true # Needed for get_colliding_bodies()
	body.max_contacts_reported = 16 # Room for contents + the obstacle
	interaction.add_exception(body)
	_held.append(body)


func _on_items_released(releaser_id: int, _entity_ids: Array) -> void:
	if releaser_id != player_id:
		return
	for body in _held:
		if not is_instance_valid(body):
			continue
		body.gravity_scale = 1.0
		if _throw_on_release:
			var mass_factor: float = clampf(
				pow(throw_reference_mass / body.mass, throw_mass_falloff),
				min_throw_factor, 1.0
			)
			body.linear_velocity = (_throw_velocity * throw_multiplier * mass_factor).limit_length(max_speed)
		# Break: keep current velocity (it's already stuck against something)
		body.angular_velocity = Vector3.ZERO
		body.contact_monitor = false
		interaction.remove_exception(body)
	_held.clear()
	_hold_velocity_history.clear()
	_throw_on_release = false
	_rotating = false
	_release_requested = false


func _get_body(entity_id: int) -> RigidBody3D:
	var spawner: WorldItemSpawner = get_tree().get_first_node_in_group(&"world_item_spawner") as WorldItemSpawner
	if spawner == null:
		return null
	return spawner.get_view(entity_id) as RigidBody3D
