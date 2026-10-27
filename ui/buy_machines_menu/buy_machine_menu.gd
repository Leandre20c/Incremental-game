class_name BuyMachinesMenu
extends CanvasLayer

## Shop menu: one ItemSlot per buyable ItemDefinition (cheapest first).
## Bought items are delivered at the level's DeliveryPoint. View only: buying goes through BuyItemCommand.

const SLOT_SCENE: PackedScene = preload("res://ui/buy_machines_menu/item_slot.tscn")

@export var menu_id: StringName = &"buy_machines" ## Same id as the MenuInteractable that opens it
@export var player_id: int = 1

@onready var _root: Control = %Root
@onready var _close_button: Button = %CloseButton
@onready var _grid: GridContainer = %Grid

func _ready() -> void:
	_root.hide()
	_close_button.pressed.connect(close)
	EventBus.menu_requested.connect(_on_menu_requested)
	_build_slots()

func _unhandled_input(event: InputEvent) -> void:
	if _root.visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()

func open() -> void:
	_root.show()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func close() -> void:
	if not _root.visible:
		return
	_root.hide()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	EventBus.menu_closed.emit(player_id, menu_id)

func _build_slots() -> void:
	for child in _grid.get_children():
		child.queue_free() # Preview slots left in the scene
	for definition in ItemDatabase.get_buyable():
		var slot: ItemSlot = SLOT_SCENE.instantiate() as ItemSlot
		_grid.add_child(slot)
		slot.setup(definition)
		slot.buy_requested.connect(_on_buy_requested)

func _on_buy_requested(definition: ItemDefinition) -> void:
	var point: DeliveryPoint = DeliveryPoint.find(get_tree())
	if point == null:
		push_warning("BuyMachinesMenu: no DeliveryPoint in the level")
		return
	CommandService.dispatch(BuyItemCommand.new(player_id, definition.id, point.global_position))

func _on_menu_requested(requesting_player_id: int, requested_menu_id: StringName) -> void:
	if requesting_player_id == player_id and requested_menu_id == menu_id:
		open()
