class_name Interactable
extends Node3D

## Component: child of any CollisionObject3D. Subclasses override create_command().
## A sibling SecondaryAction, if any, adds a second action on the interact_secondary key.

signal focused(player_id: int)
signal unfocused(player_id: int)
signal hold_started(player_id: int)
signal hold_progressed(player_id: int, ratio: float)
signal hold_ended(player_id: int)
signal triggered(player_id: int)

const META_KEY: StringName = &"interactable"
const OUTLINE_SHADER: Shader = preload("res://components/outline/outline.gdshader")

@export var display_name: String = "Display name"
@export var prompt_text: String = "Interact"
@export var prompt_offset: Vector3 = Vector3(0.0, 0.5, 0.0)
@export var enabled: bool = true:
	set(value):
		enabled = value
		if not enabled:
			_set_outline(false)
## 0 = instant press. > 0 = must hold for this many seconds (repeats while held).
@export var hold_duration: float = 0.0

@export_group("Outline")
@export var outline_enabled: bool = true
@export var outline_color: Color = Color.WHITE
@export_range(0.0, 0.2) var outline_width: float = 0.03
@export var outline_grow_from_center: bool = false

var _body: CollisionObject3D
var _outline_materials: Dictionary[MeshInstance3D, ShaderMaterial] = {} ## One per mesh: cut-out meshes need their own texture
var _secondary: SecondaryAction

func _ready() -> void:
	_body = get_parent() as CollisionObject3D
	assert(_body != null, "Interactable must be a child of a CollisionObject3D")
	_body.set_meta(META_KEY, self)
	_secondary = SecondaryAction.find_on(_body)

	for node in _body.find_children("*", "MeshInstance3D", true, false):
		var mesh: MeshInstance3D = node as MeshInstance3D
		if mesh.mesh != null:
			_outline_materials[mesh] = _make_outline_material(mesh)

static func find_on(collider: Object) -> Interactable:
	if not is_instance_valid(collider) or not collider.has_meta(META_KEY):
		return null
	return collider.get_meta(META_KEY) as Interactable

func focus(player_id: int) -> void:
	_set_outline(enabled)
	focused.emit(player_id)

func unfocus(player_id: int) -> void:
	_set_outline(false)
	unfocused.emit(player_id)

## Override in subclasses. Return null to do nothing.
func create_command(_player_id: int) -> Command:
	return null

## Called by PlayerInteraction. Default: send the command to the simulation.
## Override for purely local actions (UI) that never touch the game state.
func interact(player_id: int) -> void:
	var cmd: Command = create_command(player_id)
	if cmd:
		CommandService.dispatch(cmd)

## Extra actions on the interact_secondary key, or null if none is available right now.
func get_secondary_action() -> SecondaryAction:
	if _secondary != null and _secondary.is_available():
		return _secondary
	return null

func get_prompt_position() -> Vector3:
	return _body.global_position + prompt_offset

func _set_outline(visible_outline: bool) -> void:
	var show: bool = visible_outline and outline_enabled
	for mesh in _outline_materials:
		if is_instance_valid(mesh):
			mesh.material_overlay = _outline_materials[mesh] if show else null

## Outline material for one mesh. Copies the cut-out texture of alpha-scissor materials (grilles…).
func _make_outline_material(mesh: MeshInstance3D) -> ShaderMaterial:
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = OUTLINE_SHADER
	material.set_shader_parameter("outline_color", outline_color)
	material.set_shader_parameter("outline_width", outline_width)
	material.set_shader_parameter("grow_from_center", outline_grow_from_center)

	var source: BaseMaterial3D = mesh.get_active_material(0) as BaseMaterial3D
	var cut_out: bool = source != null and source.albedo_texture != null and source.transparency in [
		BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR, BaseMaterial3D.TRANSPARENCY_ALPHA_HASH,
	]
	if cut_out:
		material.set_shader_parameter("use_alpha_texture", true)
		material.set_shader_parameter("alpha_texture", source.albedo_texture)
		material.set_shader_parameter("alpha_threshold", source.alpha_scissor_threshold)
		material.set_shader_parameter("uv_scale", source.uv1_scale)
		material.set_shader_parameter("uv_offset", source.uv1_offset)
	return material

## Effective hold time. Override to apply upgrades. Read this instead of hold_duration.
func get_hold_duration() -> float:
	return hold_duration

## Presentation hooks, called by PlayerInteraction. Never mutate game state from these.
func begin_hold(player_id: int) -> void:
	hold_started.emit(player_id)

func update_hold(player_id: int, ratio: float) -> void:
	hold_progressed.emit(player_id, ratio)

func end_hold(player_id: int) -> void:
	hold_ended.emit(player_id)

func notify_triggered(player_id: int) -> void:
	triggered.emit(player_id)
