class_name PlayerInteraction
extends RayCast3D

## Primary key: focused object (tap or hold, see Interactable.hold_duration).
## Secondary key: the held object's action if it has one, else the focused object's
## (tap, or long press when the action offers one).

signal focus_changed(interactable: Interactable)
signal hold_progress_changed(ratio: float)

@export var player_id: int = 1
@export var long_press_duration: float = 0.4 ## Hold the secondary key this long for the long action

var _current: Interactable = null
var _hold_time: float = 0.0
var _is_holding: bool = false
var _secondary_time: float = -1.0 ## How long the secondary key has been held on the focused object. -1 = not pressed

func _ready() -> void:
	var owner_body: CollisionObject3D = owner as CollisionObject3D
	if owner_body:
		add_exception(owner_body)

func _physics_process(delta: float) -> void:
	_update_focus()

	# A menu is open (mouse visible): no world interaction
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		_stop_hold()
		_cancel_secondary()
		return

	# The held object owns the secondary key, the focused one gets it otherwise
	if not _process_held_secondary():
		_process_focused_secondary(delta)

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
		_cancel_secondary()
		hold_progress_changed.emit(0.0)
		focus_changed.emit(null)

	var next: Interactable = Interactable.find_on(get_collider()) if is_colliding() else null
	if next == _current:
		return

	if _current:
		_stop_hold() # Must end the hold on the OLD target before switching
		_current.unfocus(player_id)
	_cancel_secondary()
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

# --- Secondary key ---------------------------------------------------------

## Tap on the held object. Returns true if the held object owns the key.
func _process_held_secondary() -> bool:
	var action: SecondaryAction = _get_held_secondary()
	if action == null:
		return false
	_cancel_secondary()
	if Input.is_action_just_pressed("interact_secondary"):
		action.perform(player_id)
	return true

## Tap, or long press when the action offers one (the tap then fires on release).
func _process_focused_secondary(delta: float) -> void:
	var action: SecondaryAction = null
	if _current != null and _current.enabled:
		action = _current.get_secondary_action()
	if action == null:
		_cancel_secondary()
		return

	if Input.is_action_just_pressed("interact_secondary"):
		if action.has_long_action():
			_secondary_time = 0.0 # Wait to know if it is a tap or a long press
		else:
			action.perform(player_id)
		return

	if _secondary_time < 0.0:
		return
	if not Input.is_action_pressed("interact_secondary"):
		_cancel_secondary()
		action.perform(player_id) # Released early: it was a tap
		return

	_secondary_time += delta
	hold_progress_changed.emit(minf(_secondary_time / long_press_duration, 1.0))
	if _secondary_time >= long_press_duration:
		_cancel_secondary()
		action.perform_long(player_id)

func _cancel_secondary() -> void:
	if _secondary_time >= 0.0:
		_secondary_time = -1.0
		hold_progress_changed.emit(0.0)

func _get_held_secondary() -> SecondaryAction:
	var held: Array = GameState.get_held(player_id)
	if held.is_empty():
		return null
	var spawner: WorldItemSpawner = get_tree().get_first_node_in_group(&"world_item_spawner") as WorldItemSpawner
	var body: Node = spawner.get_view(held.back()) if spawner != null else null
	var action: SecondaryAction = SecondaryAction.find_on(body)
	if action == null or not action.usable_while_held or not action.is_available():
		return null
	return action
