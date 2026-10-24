class_name WorldPrompt
extends CanvasLayer

## Screen-space prompt anchored to the focused interactable.
## Drawn in the root viewport so it bypasses the low-res PSX viewport.

@export var interaction: PlayerInteraction
@export var action_name: StringName = &"interact_primary"
@export var screen_offset: Vector2 = Vector2(0.0, -8.0)

@onready var _panel: PanelContainer = %Panel
@onready var _prompt_label: Label = %PromptLabel
@onready var _hold_label: Label = %HoldLabel
@onready var _progress: ProgressBar = %HoldProgress

var _target: Interactable = null

func _ready() -> void:
	custom_viewport = get_tree().root
	_panel.hide()

	_progress.min_value = 0.0
	_progress.max_value = 1.0
	_progress.step = 0.0
	_progress.show_percentage = false

	if interaction == null:
		push_warning("WorldPrompt: no PlayerInteraction assigned")
		return
	interaction.focus_changed.connect(_on_focus_changed)
	interaction.hold_progress_changed.connect(_on_hold_progress_changed)

func _process(_delta: float) -> void:
	if not is_instance_valid(_target):
		_panel.hide()
		return

	var camera: Camera3D = interaction.get_viewport().get_camera_3d()
	var world_position: Vector3 = _target.get_prompt_position()
	if camera == null or camera.is_position_behind(world_position):
		_panel.hide()
		return

	var screen_position: Vector2 = _to_root_screen(camera, camera.unproject_position(world_position))
	_panel.position = (screen_position + screen_offset - Vector2(_panel.size.x * 0.5, _panel.size.y)).round()
	_panel.show()

func _on_focus_changed(target: Interactable) -> void:
	_target = target if target and target.enabled else null
	if _target == null:
		_panel.hide()
		return

	_prompt_label.text = "[%s] %s" % [_get_input_label(), _target.prompt_text]

	var hold_duration: float = _target.get_hold_duration()
	var is_hold: bool = hold_duration > 0.0
	_hold_label.visible = is_hold
	_hold_label.text = "Hold %.1f s" % hold_duration
	_set_progress(0.0)

	_panel.reset_size() # Shrink to the new content

func _on_hold_progress_changed(ratio: float) -> void:
	_set_progress(ratio)

func _set_progress(ratio: float) -> void:
	_progress.value = ratio
	# Alpha instead of visible: keeps the panel size stable
	_progress.modulate.a = 1.0 if ratio > 0.0 else 0.0

## Converts a position in the camera's (low-res) viewport to root canvas coordinates.
func _to_root_screen(camera: Camera3D, viewport_position: Vector2) -> Vector2:
	var sub_viewport: SubViewport = camera.get_viewport() as SubViewport
	if sub_viewport == null:
		return viewport_position
	var container: SubViewportContainer = sub_viewport.get_parent() as SubViewportContainer
	if container == null:
		return viewport_position
	var _scale: Vector2 = container.size / Vector2(sub_viewport.size)
	return container.get_global_rect().position + viewport_position * _scale

func _get_input_label() -> String:
	var events: Array[InputEvent] = InputMap.action_get_events(action_name)
	if events.is_empty():
		return "?"
	var event: InputEvent = events[0]
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_LEFT: return "LMB"
			MOUSE_BUTTON_RIGHT: return "RMB"
	return event.as_text()
