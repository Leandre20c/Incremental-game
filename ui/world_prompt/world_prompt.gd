class_name WorldPrompt
extends Node3D

@export var interaction: PlayerInteraction
@export var action_name: StringName = &"interact_primary"

@onready var _viewport: SubViewport = $SubViewport
@onready var _sprite: Sprite3D = $Sprite3D
@onready var _prompt_label: Label = %PromptLabel
@onready var _hold_label: Label = %HoldLabel
@onready var _progress: ProgressBar = %HoldProgress

var _target: InteractableBody = null

func _ready() -> void:
	top_level = true # Do not follow the player's transform
	_sprite.texture = _viewport.get_texture()
	_set_shown(false)
	
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
	if _target:
		global_position = _target.get_prompt_position()

func _on_focus_changed(target: InteractableBody) -> void:
	_target = target if target and target.enabled else null
	if _target == null:
		_set_shown(false)
		return

	_prompt_label.text = "[%s] %s" % [_get_input_label(), _target.prompt_text]

	var is_hold: bool = _target.hold_duration > 0.0
	_hold_label.visible = is_hold
	_hold_label.text = "Hold %.1f s" % _target.hold_duration

	_progress.visible = is_hold
	_set_progress(0.0)

	global_position = _target.get_prompt_position()
	_set_shown(true)

func _on_hold_progress_changed(ratio: float) -> void:
	_set_progress(ratio)

func _set_progress(ratio: float) -> void:
	_progress.value = ratio
	# Alpha instead of visible: keeps the panel size stable
	_progress.modulate.a = 1.0 if ratio > 0.0 else 0.0

func _set_shown(shown: bool) -> void:
	visible = shown
	_viewport.render_target_update_mode = (
		SubViewport.UPDATE_ALWAYS if shown else SubViewport.UPDATE_DISABLED
	)

func _get_input_label() -> String:
	var events: Array[InputEvent] = InputMap.action_get_events(action_name)
	if events.is_empty():
		return "?"
	var event: InputEvent = events[0]
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_LEFT: return "LMB"
			MOUSE_BUTTON_RIGHT: return "RMB"
	return event.as_text()[0]
