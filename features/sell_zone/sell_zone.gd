class_name SellZone
extends Area3D

## Trigger volume that sell any sellable item here

func _ready() -> void:
	monitorable = false

func _on_body_entered(body: Node3D) -> void:
	# Get the ItemDifinition from here
	pass
