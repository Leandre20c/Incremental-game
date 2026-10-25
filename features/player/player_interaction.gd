class_name PlayerInteraction
extends RayCast3D

signal focus_changed(interactable: Interactable)
signal hold_progress_changed(ratio: float)

@export var player_id: int = 1

var _current: Interactable = null
var _hold_time: float = 0.0
var _is_holding: bool = false

func _ready() -> void:
	var owner_body: CollisionObject3D = owner as CollisionObject3D
	if owner_body:
		add_exception(owner_body)

func _physics_process(delta: float) -> void:
	_update_focus()

	# A menu is open (mouse visible): no world interaction
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		_stop_hold()
		return

	if _current == null or not _current.enabled:
		_stop_hold()
		return

	var hold_duration: float = _current.get_hold_duration()

	# Instant interaction
	if hold_duration <= 0.0:
		if Input.is_action_just_pressed("interact_primary"):
			_trigger()
		return

	# Hold interaction
	if not Input.is_action_pressed("interact_primary"):
		_stop_hold()
		return

	if not _is_holding:
		_is_holding = true
		_current.begin_hold(player_id)

	_hold_time += delta
	var ratio: float = minf(_hold_time / hold_duration, 1.0)
	_current.update_hold(player_id, ratio)
	hold_progress_changed.emit(ratio)

	if _hold_time >= hold_duration:
		_trigger()
		_hold_time = 0.0 # Keep holding = keep harvesting

func _update_focus() -> void:
	# Focused object was freed (picked up, sold…)
	if _current != null and not is_instance_valid(_current):
		_current = null
		_is_holding = false
		_hold_time = 0.0
		hold_progress_changed.emit(0.0)
		focus_changed.emit(null)

	var next: Interactable = Interactable.find_on(get_collider()) if is_colliding() else null
	if next == _current:
		return

	if _current:
		_stop_hold() # Must end the hold on the OLD target before switching
		_current.unfocus(player_id)
	_current = next
	if _current:
		_current.focus(player_id)
	focus_changed.emit(_current)

func _trigger() -> void:
	_current.interact(player_id) # Command for gameplay objects, local action for menus
	_current.notify_triggered(player_id)

func _stop_hold() -> void:
	if _is_holding and is_instance_valid(_current):
		_current.end_hold(player_id)
	_is_holding = false
	if _hold_time > 0.0:
		_hold_time = 0.0
		hold_progress_changed.emit(0.0)
