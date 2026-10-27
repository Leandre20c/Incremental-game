class_name ItemSlot
extends Control

## One entry of the buy menu: icon, name, description and a buy button showing the price.
## View only: pressing the button asks the menu to buy, the menu dispatches the command.

signal buy_requested(definition: ItemDefinition)

@onready var _icon: TextureRect = %Icon
@onready var _title_label: Label = %TitleLabel
@onready var _description_label: Label = %DescriptionLabel
@onready var _buy_button: Button = %BuyButton

var _definition: ItemDefinition

func _ready() -> void:
	_buy_button.pressed.connect(_on_buy_pressed)
	EventBus.resource_changed.connect(_on_resource_changed)

## Call after adding the slot to the tree.
func setup(definition: ItemDefinition) -> void:
	_definition = definition
	_icon.texture = definition.icon
	_icon.visible = definition.icon != null
	_title_label.text = definition.display_name
	_description_label.text = definition.description
	_description_label.visible = not definition.description.is_empty()
	tooltip_text = definition.description
	_refresh()

func _refresh() -> void:
	if _definition == null:
		return
	_buy_button.text = "%d $" % _definition.buy_cost
	_buy_button.disabled = GameState.get_amount(_definition.buy_cost_resource_id) < _definition.buy_cost

func _on_buy_pressed() -> void:
	buy_requested.emit(_definition)

func _on_resource_changed(resource_id: StringName, _amount: int) -> void:
	if _definition != null and resource_id == _definition.buy_cost_resource_id:
		_refresh()
