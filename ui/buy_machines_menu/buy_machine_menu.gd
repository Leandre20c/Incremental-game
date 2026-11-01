class_name BuyMachinesMenu
extends CanvasLayer

## Shop menu: one ItemSlot per buyable ItemDefinition (cheapest first), sorted into tabs by ShopCategory.
## Tabs are built from the categories the buyable items use: adding a tab = adding a ShopCategory .tres.
## Bought items are delivered at the level's DeliveryPoint. View only: buying goes through BuyItemCommand.

const SLOT_SCENE: PackedScene = preload("res://ui/buy_machines_menu/item_slot.tscn")
const OTHER_TAB_NAME: String = "Other" ## Tab for buyable items without a category
const OTHER_TAB_TITLE: String = "Order miscs"

@export var menu_id: StringName = &"buy_machines" ## Same id as the MenuInteractable that opens it
@export var player_id: int = 1

@onready var _root: Control = %Root
@onready var _close_button: Button = %CloseButton
@onready var _tabs: HBoxContainer = %Tabs
@onready var _grid: GridContainer = %Grid
@onready var _title_label: Label = %TitleLabel

var _slots: Array[ItemSlot] = []
var _categories: Array[ShopCategory] = [] ## One per tab. null = items without a category
var _tab_buttons: Array[Button] = []
var _current_tab: int = 0 ## Kept between openings

func _ready() -> void:
	_root.hide()
	_close_button.pressed.connect(close)
	EventBus.menu_requested.connect(_on_menu_requested)
	_build()
	

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

## Shows the items of one tab only.
func show_tab(index: int) -> void:
	if _categories.is_empty():
		return
	_current_tab = clampi(index, 0, _categories.size() - 1)
	_tab_buttons[_current_tab].button_pressed = true
	var category: ShopCategory = _categories[_current_tab]
	_title_label.text = category.get_title() if category != null else OTHER_TAB_TITLE
	for slot in _slots:
		slot.visible = slot.get_definition().shop_category == category

# --- Build -----------------------------------------------------------------

func _build() -> void:
	for child in _grid.get_children():
		child.queue_free() # Preview slots left in the scene
	for child in _tabs.get_children():
		if child != _close_button:
			child.queue_free() # Preview tab buttons left in the scene

	for definition in ItemDatabase.get_buyable():
		var slot: ItemSlot = SLOT_SCENE.instantiate() as ItemSlot
		_grid.add_child(slot)
		slot.setup(definition)
		slot.buy_requested.connect(_on_buy_requested)
		_slots.append(slot)
		if not definition.shop_category in _categories:
			_categories.append(definition.shop_category)
	_categories.sort_custom(func(a: ShopCategory, b: ShopCategory) -> bool: return _tab_order(a) < _tab_order(b))
	
	var remove_button_in_child = _close_button in _tabs.get_children()
	var group: ButtonGroup = ButtonGroup.new()
	for i in _categories.size():
		var button: Button = Button.new()
		button.text = _tab_name(_categories[i])
		button.toggle_mode = true # The active tab stays pressed
		button.button_group = group
		button.pressed.connect(show_tab.bind(i))
		_tabs.add_child(button)
		if remove_button_in_child:
			_tabs.move_child(button, _close_button.get_index())
		_tab_buttons.append(button)
	for button in _tab_buttons:
		button.visible = _categories.size() > 1 # A single tab is not worth a tab bar
	show_tab(_current_tab)

func _tab_name(category: ShopCategory) -> String:
	return category.display_name if category != null else OTHER_TAB_NAME

func _tab_order(category: ShopCategory) -> int:
	return category.order if category != null else 1000000 # "Other" goes last

# --- Actions ---------------------------------------------------------------

func _on_buy_requested(definition: ItemDefinition) -> void:
	var point: DeliveryPoint = DeliveryPoint.find(get_tree())
	if point == null:
		push_warning("BuyMachinesMenu: no DeliveryPoint in the level")
		return
	CommandService.dispatch(BuyItemCommand.new(player_id, definition.id, point.global_position))

func _on_menu_requested(requesting_player_id: int, requested_menu_id: StringName) -> void:
	if requesting_player_id == player_id and requested_menu_id == menu_id:
		open()
