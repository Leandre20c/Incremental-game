extends Node3D

## Fishing line driven by the hold progress.
## First part of the hold: the line goes down. After hook_ratio: it comes back up with the fish.
## This node is the top of the line.

@export var harvestable: Harvestable
@export var fish_placeholder: MeshInstance3D
@export_range(0.05, 0.95) var hook_ratio: float = 0.5 ## Hold progress at which the fish bites
@export var retract_duration: float = 0.4 ## Line rewind time when released early
@export var fish_fall_distance: float = 5.0
@export var fish_fall_duration: float = 0.6

@onready var _rope_mesh: MeshInstance3D = $MeshInstance3D
@onready var _max_length: float = _rope_mesh.mesh.height

var _length: float = 0.0
var _retract_tween: Tween
var _fall_tween: Tween

func _ready() -> void:
	_rope_mesh.mesh = _rope_mesh.mesh.duplicate() # Own copy: resizing must not affect other ropes
	harvestable.hold_started.connect(_on_hold_started)
	harvestable.hold_progressed.connect(_on_hold_progressed)
	harvestable.hold_ended.connect(_on_hold_ended)
	harvestable.triggered.connect(_on_triggered)
	fish_placeholder.visible = false
	_set_length(0.0)

func _on_hold_started(_player_id: int) -> void:
	_kill_tween(_retract_tween)
	_kill_tween(_fall_tween)
	fish_placeholder.visible = false

func _on_hold_progressed(_player_id: int, ratio: float) -> void:
	if ratio < hook_ratio:
		# Going down: no fish yet
		_set_length(_max_length * ratio / hook_ratio)
		fish_placeholder.visible = false
	else:
		# Coming up: the fish hangs at the end of the line
		_set_length(_max_length * (1.0 - ratio) / (1.0 - hook_ratio))
		fish_placeholder.visible = true
		fish_placeholder.global_position = _get_hook_position()

## Caught: the real fish is spawned by the command, hide the placeholder.
func _on_triggered(_player_id: int) -> void:
	fish_placeholder.visible = false

## Released early: the fish falls back and the line rewinds.
func _on_hold_ended(_player_id: int) -> void:
	if fish_placeholder.visible:
		_drop_fish()
	_kill_tween(_retract_tween)
	_retract_tween = create_tween()
	_retract_tween.tween_method(_set_length, _length, 0.0, retract_duration) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _drop_fish() -> void:
	_kill_tween(_fall_tween)
	var start_y: float = fish_placeholder.global_position.y
	_fall_tween = create_tween().set_parallel()
	_fall_tween.tween_property(fish_placeholder, "global_position:y", start_y - fish_fall_distance, fish_fall_duration) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN) # Accelerates like gravity
	_fall_tween.tween_property(fish_placeholder, "rotation:z", TAU, fish_fall_duration)
	_fall_tween.chain().tween_callback(fish_placeholder.hide)

## Resizes the line so its top stays on this node and it grows downward.
func _set_length(value: float) -> void:
	_length = maxf(value, 0.0)
	_rope_mesh.visible = _length > 0.001
	_rope_mesh.mesh.height = maxf(_length, 0.001) # A mesh height of 0 is invalid
	_rope_mesh.position.y = -_length * 0.5 # The mesh is centered: shift it down by half

func _get_hook_position() -> Vector3:
	return to_global(Vector3.DOWN * _length)

func _kill_tween(tween: Tween) -> void:
	if tween:
		tween.kill()
