class_name PlayerInteraction
extends RayCast3D

signal focus_changed(interactable: Interactable)
signal hold_progress_changed(ratio: float)

@export var player_id: int = 1 # Overridden by host/session in multiplayer later
@export var player_body: CollisionObject3D

var _current: Interactable = null
var _hold_time: float = 0.0
var _press_queued: bool = false # Fresh press not consumed by the UI
var _needs_release: bool = false # Blocks chaining onto the next item after a trigger


func _ready() -> void:
	var body := player_body if player_body else owner as CollisionObject3D
	if body:
		add_exception(body)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact_primary"):
		_press_queued = true
	elif event.is_action_released("interact_primary"):
		_needs_release = false


func _physics_process(delta: float) -> void:
	_update_focus()

	var pressed_now := _press_queued
	_press_queued = false

	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED \
			or _current == null or not _current.enabled or _needs_release:
		_reset_hold()
		return

	var hold_duration: float = _current.get_hold_duration()
	if hold_duration <= 0.0:
		if pressed_now:
			_trigger()
		return

	if Input.is_action_pressed("interact_primary"):
		_hold_time += delta
		hold_progress_changed.emit(minf(_hold_time / hold_duration, 1.0))
		if _hold_time >= hold_duration:
			_trigger()
	else:
		_reset_hold()


func _update_focus() -> void:
	if _current != null and not is_instance_valid(_current):
		_current = null
		_reset_hold()
		focus_changed.emit(null)

	var next: Interactable = null
	if is_colliding():
		var col := get_collider()
		if is_instance_valid(col) and not col.is_queued_for_deletion():
			next = Interactable.find_on(col)

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
	_current.interact(player_id)
	_needs_release = true # Remove for "keep holding = keep harvesting" resources
	_hold_time = 0.0
	hold_progress_changed.emit(0.0)


func _reset_hold() -> void:
	if _hold_time > 0.0:
		_hold_time = 0.0
		hold_progress_changed.emit(0.0)
