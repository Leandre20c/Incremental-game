class_name MachineMenu
extends CanvasLayer

## Settings of a machine (placed, loose or held): power off, or pick one of the unlocked intensity levels.
## View only: every choice dispatches a SetPowerCommand.

const MENU_ID: StringName = &"machine"

@export var player_id: int = 1
@export var level_button_size: Vector2 = Vector2(56.0, 36.0)

@onready var _root: Control = %Root
@onready var _title_label: Label = %TitleLabel
@onready var _levels: HBoxContainer = %Levels
@onready var _close_button: Button = %CloseButton

var _entity_id: int = -1

func _ready() -> void:
	_root.hide()
	_close_button.pressed.connect(close)
	EventBus.machine_menu_requested.connect(_on_machine_menu_requested)
	EventBus.item_power_changed.connect(_on_item_power_changed)
	EventBus.item_grabbed.connect(_on_item_grabbed)
	EventBus.world_item_removed.connect(_on_world_item_removed)
	EventBus.upgrade_level_changed.connect(_on_upgrade_level_changed)

func _unhandled_input(event: InputEvent) -> void:
	if not _root.visible:
		return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("interact_secondary"):
		close()
		get_viewport().set_input_as_handled()

func open(entity_id: int) -> void:
	_entity_id = entity_id
	_rebuild()
	_root.show()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	EventBus.menu_requested.emit(player_id, MENU_ID) # Lets other UI hide (world prompt…)

func close() -> void:
	if not _root.visible:
		return
	_root.hide()
	_entity_id = -1
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	EventBus.menu_closed.emit(player_id, MENU_ID)

func _rebuild() -> void:
	for child in _levels.get_children():
		child.queue_free()

	var item: Dictionary = GameState.get_world_item(_entity_id)
	var definition: ItemDefinition = ItemDatabase.get_definition(item.get("item_id", &""))
	if definition == null or not definition.has_power_settings():
		close()
		return

	_title_label.text = definition.display_name
	var powered: bool = item["powered"]
	var current_level: int = item["power_level"]
	var unlocked: int = definition.get_unlocked_power_levels()

	_add_button("Off", not powered, false, _on_off_pressed)
	for level in range(1, definition.max_power_levels + 1):
		var locked: bool = level > unlocked
		_add_button(str(level), powered and level == current_level, locked, _on_level_pressed.bind(level))

func _add_button(label: String, selected: bool, locked: bool, on_pressed: Callable) -> void:
	var button: Button = Button.new()
	button.text = "[%s]" % label if selected else label
	button.custom_minimum_size = level_button_size
	button.disabled = locked
	if locked:
		button.tooltip_text = "Locked: buy an upgrade to unlock"
	button.pressed.connect(on_pressed)
	_levels.add_child(button)

func _on_off_pressed() -> void:
	CommandService.dispatch(SetPowerCommand.new(player_id, _entity_id, false, GameState.get_power_level(_entity_id)))

func _on_level_pressed(level: int) -> void:
	CommandService.dispatch(SetPowerCommand.new(player_id, _entity_id, true, level))

func _on_machine_menu_requested(requesting_player_id: int, entity_id: int) -> void:
	if requesting_player_id == player_id:
		open(entity_id)

func _on_item_power_changed(entity_id: int) -> void:
	if _root.visible and entity_id == _entity_id:
		_rebuild()

## Close if another player picks the machine up.
func _on_item_grabbed(grabber_id: int, entity_id: int) -> void:
	if _root.visible and entity_id == _entity_id and grabber_id != player_id:
		close()

func _on_world_item_removed(entity_id: int) -> void:
	if entity_id == _entity_id:
		close()

## A level may have just been unlocked.
func _on_upgrade_level_changed(_upgrade_id: StringName, _level: int) -> void:
	if _root.visible:
		_rebuild()
