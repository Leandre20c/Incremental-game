extends StaticBody3D

@export var harvestable: Harvestable
@export var fall_distance: float = 15.0 ## How far the fish drops when released
@export var fall_duration: float = 0.8

@onready var fish_from_point: Marker3D = $FishFromPoint
@onready var fish_to_point: Marker3D = $FishToPoint
@onready var fish_placeholder: MeshInstance3D = $FishPlaceholder
@onready var pipe_valve_holder: Node3D = $InterractPanel/pipe_valve_holder_large_12

var _fall_tween: Tween

func _ready() -> void:
	harvestable.hold_started.connect(_on_hold_started)
	harvestable.hold_progressed.connect(_on_hold_progressed)
	harvestable.hold_ended.connect(_on_hold_ended)
	harvestable.triggered.connect(_on_triggered)
	fish_placeholder.visible = false

func _on_hold_started(_player_id: int) -> void:
	_stop_fall()
	fish_placeholder.global_position = fish_from_point.global_position
	fish_placeholder.visible = true
	fish_placeholder.rotation = Vector3(
		randf_range(-0.15, 0.15), # Slight tilt (~±8°)
		randf() * TAU,            # Any direction
		randf_range(-0.15, 0.15)
	)

## The fish follows the line exactly with the hold progress.
func _on_hold_progressed(_player_id: int, ratio: float) -> void:
	fish_placeholder.visible = true
	fish_placeholder.global_position = fish_from_point.global_position.lerp(fish_to_point.global_position, ratio)
	pipe_valve_holder.rotate_z(0.15)
	
## Caught: the real fish is spawned, hide the placeholder. The next loop restarts from the bottom.
func _on_triggered(_player_id: int) -> void:
	fish_placeholder.visible = false

## Released before the end: the fish is still on the line, so it falls.
func _on_hold_ended(_player_id: int) -> void:
	if not fish_placeholder.visible:
		return
	_stop_fall()
	fish_placeholder.rotation = Vector3.ZERO
	var start_y: float = fish_placeholder.global_position.y

	_fall_tween = create_tween().set_parallel()
	_fall_tween.tween_property(fish_placeholder, "global_position:y", start_y - fall_distance, fall_duration) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN) # Accelerates like gravity
	_fall_tween.tween_property(fish_placeholder, "rotation:z", TAU, fall_duration) # Spins while falling
	_fall_tween.chain().tween_callback(fish_placeholder.hide)

func _stop_fall() -> void:
	if _fall_tween:
		_fall_tween.kill()
		_fall_tween = null
