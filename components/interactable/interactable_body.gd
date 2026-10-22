class_name InteractableBody
extends StaticBody3D

## Base class for every interactable object. Subclasses override create_command().

signal focused(player_id: int)
signal unfocused(player_id: int)

const OUTLINE_SHADER: Shader = preload("res://components/outline/outline.gdshader")

@export var prompt_text: String = "Interact"
@export var prompt_offset: Vector3 = Vector3(0.0, 1.5, 0.0)
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

var _meshes: Array[MeshInstance3D] = []
var _outline_material: ShaderMaterial

func _ready() -> void:
	for node in find_children("*", "MeshInstance3D", true, false):
		_meshes.append(node as MeshInstance3D)

	_outline_material = ShaderMaterial.new()
	_outline_material.shader = OUTLINE_SHADER
	_outline_material.set_shader_parameter("outline_color", outline_color)
	_outline_material.set_shader_parameter("outline_width", outline_width)
	_outline_material.set_shader_parameter("grow_from_center", outline_grow_from_center)

## Called by PlayerInteraction. Not meant to be overridden.
func focus(player_id: int) -> void:
	_set_outline(enabled)
	focused.emit(player_id)

func unfocus(player_id: int) -> void:
	_set_outline(false)
	unfocused.emit(player_id)

## Override in subclasses. Return null to do nothing.
func create_command(_player_id: int) -> Command:
	return null

func _set_outline(visible_outline: bool) -> void:
	var material: Material = _outline_material if visible_outline and outline_enabled else null
	for mesh in _meshes:
		mesh.material_overlay = material

## Propmt
func get_prompt_position() -> Vector3:
	return global_position + prompt_offset
