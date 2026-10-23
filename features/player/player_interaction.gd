class_name PlayerInteraction
extends RayCast3D

signal focus_changed(interactable: Interactable)
signal hold_progress_changed(ratio: float)

@export var player_id: int = 1 # Overridden by host/session in multiplayer later

var _current: Interactable = null
var _hold_time: float = 0.0

func _ready() -> void:
	var owner_body: CollisionObject3D = owner as CollisionObject3D
	if owner_body:
		add_exception(owner_body)

func _physics_process(delta: float) -> void:
	_update_focus()

	if _current == null or not _current.enabled:
		_reset_hold()
		return

	if _current.hold_duration <= 0.0:
		if Input.is_action_just_pressed("interact_primary"):
			_trigger()
		return

	if Input.is_action_pressed("interact_primary"):
		_hold_time += delta
		hold_progress_changed.emit(minf(_hold_time / _current.hold_duration, 1.0))
		if _hold_time >= _current.hold_duration:
			_trigger()
			_hold_time = 0.0 # Keep holding = keep harvesting
	else:
		_reset_hold()

func _update_focus() -> void:
	if _current != null and not is_instance_valid(_current):
		_current = null
		_reset_hold()
		focus_changed.emit(null)

	var next: Interactable = Interactable.find_on(get_collider()) if is_colliding() else null
	if next == _current:
		return
	if _current:
		_current.unfocus(player_id)
	_current = next
	_reset_hold()
	if _current:
		_current.focus(player_id)
	focus_changed.emit(_current)

func _trigger() -> void:
	var cmd: Command = _current.create_command(player_id)
	if cmd:
		CommandService.dispatch(cmd)

func _reset_hold() -> void:
	if _hold_time > 0.0:
		_hold_time = 0.0
		hold_progress_changed.emit(0.0)
